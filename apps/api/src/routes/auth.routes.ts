import { Router, Request, Response, NextFunction } from 'express';
import { AppError } from '../middleware/errorHandler.js';
import { toNodeHandler } from 'better-auth/node';
import { auth } from '../lib/better-auth.js';
import { requireAuth, requireRole, type AuthenticatedRequest, invalidateSessionCache } from '../middleware/auth.middleware.js';
import bcrypt from 'bcryptjs';
import { db } from '../db/index.js';
import { staff, user, session, activityLogs } from '../db/schema/index.js';
import { eq, sql } from 'drizzle-orm';
import { v4 as uuidv4 } from 'uuid';

const router = Router();

// ─────────────────────────────────────────────────────────────
// GET /auth/me — returns current user + linked staff in ONE call
// Replaces the 2-call pattern: GET /auth/get-session + GET /staff/by-user/:id
// Protected by requireAuth; reuses req.staffMember attached by middleware.
// ─────────────────────────────────────────────────────────────
router.get('/me', requireAuth, (req: AuthenticatedRequest, res: Response) => {
    res.json({
        user: req.user ?? null,
        staff: req.staffMember ?? null,
    });
});

// ─────────────────────────────────────────────────────────────
// POST /auth/login-pin — PIN Login endpoint
// Body: { staffProfileId: string, pin: string }
// ─────────────────────────────────────────────────────────────
router.post('/login-pin', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const { staffProfileId, pin } = req.body;
        if (!staffProfileId || !pin) {
            throw AppError.validation('staffProfileId dan pin wajib diisi');
        }

        // 1. Fetch staff + user
        const staffData = await db
            .select({ staff, user })
            .from(staff)
            .where(eq(staff.id, staffProfileId))
            .innerJoin(user, eq(user.id, staff.userId))
            .limit(1);

        if (!staffData.length) {
            throw AppError.unauthorized('Staff tidak ditemukan');
        }

        const { staff: s, user: u } = staffData[0];

        // 2. Check lockout
        const now = new Date();
        if (s.pinLockedUntil && now < s.pinLockedUntil) {
            res.status(429).json({
                success: false,
                code: 'KSR-AUTH-429',
                category: 'AUTH',
                severity: 'warning',
                message: 'Akun terkunci karena terlalu banyak percobaan gagal.',
                lockedUntil: s.pinLockedUntil.toISOString(),
            });
            return;
        }

        // 3. Verify PIN
        if (!s.pinCode) {
            throw AppError.unauthorized('Staff belum memiliki PIN');
        }

        const isValid = await bcrypt.compare(pin, s.pinCode);

        // 4. Handle Failed Attempt
        if (!isValid) {
            let shouldLock = false;
            let lockUntilTimestamp: string | null = null;

            await db.transaction(async (tx) => {
                const newAttempts = (s.pinAttempts || 0) + 1;
                shouldLock = newAttempts >= 5;
                const lockUntil = shouldLock 
                    ? new Date(Date.now() + 5 * 60 * 1000) // 5 minutes
                    : null;

                await tx.update(staff)
                    .set({
                        pinAttempts: newAttempts,
                        pinLockedUntil: lockUntil,
                    })
                    .where(eq(staff.id, staffProfileId));

                await tx.insert(activityLogs).values({
                    staffId: staffProfileId,
                    action: 'PIN_LOGIN_FAILED',
                    description: `Failed PIN attempt (${newAttempts}/5)`,
                });

                if (shouldLock && lockUntil) {
                    lockUntilTimestamp = lockUntil.toISOString();
                }
            });

            if (shouldLock && lockUntilTimestamp) {
                res.status(429).json({
                    success: false,
                    code: 'KSR-AUTH-429',
                    category: 'AUTH',
                    severity: 'warning',
                    message: 'Terlalu banyak percobaan gagal. Akun terkunci.',
                    lockedUntil: lockUntilTimestamp,
                });
                return;
            }
            throw AppError.unauthorized('PIN salah');
        }

        // 5. Handle Success Attempt
        const token = uuidv4();
        await db.transaction(async (tx) => {
            // Reset attempts
            await tx.update(staff)
                .set({ pinAttempts: 0, pinLockedUntil: null })
                .where(eq(staff.id, staffProfileId));

            // Log success
            await tx.insert(activityLogs).values({
                staffId: staffProfileId,
                action: 'PIN_LOGIN_SUCCESS',
                description: 'Successful PIN login',
            });

            // Create Opaque Session for Better-Auth
            await tx.insert(session).values({
                id: uuidv4(),
                token,
                userId: u.id,
                expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 days
                ipAddress: req.ip || null,
                userAgent: req.get('user-agent') || null,
            });
        });

        // 6. Return standard auth response
        res.json({
            accessToken: token, // This is the opaque token Flutter will use as Bearer
            refreshToken: token,
            user: { id: u.id, email: u.email, name: u.name },
            staff: {
                id: s.id,
                name: s.name,
                role: s.role,
                branchId: s.branchId,
            },
        });
    } catch (e) {
        next(e);
    }
});

// ─────────────────────────────────────────────────────────────
// Admin: Change password for any user (used by admin panel)
// POST /auth/admin/change-password
// Body: { userId: string, password: string }
// ─────────────────────────────────────────────────────────────
router.post('/admin/change-password', requireAuth, requireRole('admin'), async (req: Request, res: Response, next: NextFunction) => {
    try {
        const { userId, password } = req.body;
        if (!userId || !password) {
            res.status(400).json({ error: 'userId dan password wajib diisi' });
            return;
        }
        if (password.length < 6) {
            res.status(400).json({ error: 'Password minimal 6 karakter' });
            return;
        }
        await (auth.api as any).setPassword({
            body: { userId, newPassword: password },
        });
        res.json({ message: 'Password berhasil diperbarui' });
    } catch (e: any) {
        const msg = e?.message ?? String(e);
        if (msg.includes('not found') || msg.includes('404')) {
            res.status(404).json({ error: 'User tidak ditemukan' });
        } else {
            next(e);
        }
    }
});

// ─────────────────────────────────────────────────────────────
// Admin: Update a user's role
// POST /auth/admin/set-role
// Body: { userId: string, role: string }
// ─────────────────────────────────────────────────────────────
router.post('/admin/set-role', requireAuth, requireRole('admin'), async (req: Request, res: Response, next: NextFunction) => {
    try {
        const { userId, role } = req.body;
        if (!userId || !role) {
            res.status(400).json({ error: 'userId dan role wajib diisi' });
            return;
        }
        await (auth.api as any).setRole({ body: { userId, role: role.toLowerCase() } });
        res.json({ message: 'Role berhasil diperbarui' });
    } catch (e) { next(e); }
});

// ─────────────────────────────────────────────────────────────
// Admin: Ban / unban a user
// POST /auth/admin/ban-user — Body: { userId, reason?, banExpiresIn? }
// POST /auth/admin/unban-user — Body: { userId }
// ─────────────────────────────────────────────────────────────
router.post('/admin/ban-user', requireAuth, requireRole('admin'), async (req: Request, res: Response, next: NextFunction) => {
    try {
        const { userId, reason, banExpiresIn } = req.body;
        if (!userId) { res.status(400).json({ error: 'userId wajib diisi' }); return; }
        await auth.api.banUser({ body: { userId, banReason: reason, banExpiresIn } });
        res.json({ message: 'User berhasil diblokir' });
    } catch (e) { next(e); }
});

router.post('/admin/unban-user', requireAuth, requireRole('admin'), async (req: Request, res: Response, next: NextFunction) => {
    try {
        const { userId } = req.body;
        if (!userId) { res.status(400).json({ error: 'userId wajib diisi' }); return; }
        await auth.api.unbanUser({ body: { userId } });
        res.json({ message: 'User berhasil diaktifkan kembali' });
    } catch (e) { next(e); }
});

// ─────────────────────────────────────────────────────────────
// Update own profile name
// POST /auth/update-user
// Body: { name: string }
// ─────────────────────────────────────────────────────────────
router.post('/update-user', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const { name } = req.body;
        if (!name) { res.status(400).json({ error: 'name wajib diisi' }); return; }

        // Get session from cookie/header and update user
        const session = await auth.api.getSession({ headers: req.headers as any });
        if (!session?.user) { res.status(401).json({ error: 'Tidak terautentikasi' }); return; }

        await auth.api.updateUser({
            body: { name },
            headers: req.headers as any,
        });
        res.json({ message: 'Profil berhasil diperbarui' });
    } catch (e) { next(e); }
});

// ─────────────────────────────────────────────────────────────
// Change own password
// POST /auth/change-password
// Body: { currentPassword, newPassword, revokeOtherSessions? }
// ─────────────────────────────────────────────────────────────
router.post('/change-password', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const { currentPassword, newPassword } = req.body;
        if (!currentPassword || !newPassword) {
            res.status(400).json({ error: 'currentPassword dan newPassword wajib diisi' });
            return;
        }
        await auth.api.changePassword({
            body: {
                currentPassword,
                newPassword,
                revokeOtherSessions: req.body.revokeOtherSessions ?? false,
            },
            headers: req.headers as any,
        });
        res.json({ message: 'Password berhasil diperbarui' });
    } catch (e: any) {
        const msg = e?.message ?? String(e);
        if (msg.toLowerCase().includes('incorrect') || msg.toLowerCase().includes('invalid')) {
            res.status(401).json({ error: 'Password lama tidak sesuai' });
        } else {
            next(e);
        }
    }
});

// ─────────────────────────────────────────────────────────────
// Better-Auth handles ALL other auth routes automatically
// (sign-in, sign-up, sign-out, session, etc.)
// ─────────────────────────────────────────────────────────────
router.all('/*splat', toNodeHandler(auth));

export default router;
