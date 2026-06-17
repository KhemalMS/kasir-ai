import { Router, Request, Response, NextFunction } from 'express';
import { toNodeHandler } from 'better-auth/node';
import { auth } from '../lib/better-auth.js';
import { requireAuth, requireRole, type AuthenticatedRequest } from '../middleware/auth.middleware.js';

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
