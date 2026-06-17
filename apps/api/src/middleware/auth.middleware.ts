import { Request, Response, NextFunction } from 'express';
import { fromNodeHeaders } from 'better-auth/node';
import { auth } from '../lib/better-auth.js';
import { staffService } from '../services/staff.service.js';
import { db } from '../db/index.js';
import { sql } from 'drizzle-orm';
import { LRUCache } from 'lru-cache';
import type { staff as staffTable } from '../db/schema/staff.js';

// ─────────────────────────────────────────────────────────────
// Types
// ─────────────────────────────────────────────────────────────
type StaffRecord = typeof staffTable.$inferSelect;

interface CachedSession {
    userId: string;
    userEmail: string;
    userName: string;
    userRole?: string;
    staffMember: StaffRecord | null;
}

export interface AuthenticatedRequest extends Request {
    user?: {
        id: string;
        email: string;
        name: string;
        role?: string;
    };
    session?: {
        id: string;
        userId: string;
        expiresAt: Date;
    };
    staffRole?: string;
    staffMember?: StaffRecord | null;
}

// ─────────────────────────────────────────────────────────────
// LRU Session Cache
// Caches token → { user, staff } for 60 seconds.
// Prevents repeated DB queries on every request to protected routes.
// Max 500 entries covers concurrent users comfortably.
// ─────────────────────────────────────────────────────────────
const sessionCache = new LRUCache<string, CachedSession>({
    max: 500,
    ttl: 60_000, // 60 seconds
});

/**
 * Invalidate the cache for a given token (e.g. on sign-out).
 */
export function invalidateSessionCache(token: string): void {
    sessionCache.delete(token);
}

/**
 * Middleware: Require authentication
 * Supports:
 * 1. Cookie-based auth (browser with proper cookie handling)
 * 2. Authorization Bearer token (web Flutter app, Android app)
 * Rejects with 401 if no valid session
 *
 * Perf: Results are cached in LRU cache for 60s — avoids DB hit on
 * every subsequent request for the same token.
 * Also attaches `req.staffMember` (full object) so route handlers
 * do NOT need to call findByUserId() again.
 */
export async function requireAuth(
    req: AuthenticatedRequest,
    res: Response,
    next: NextFunction
): Promise<void> {
    try {
        let session: any = null;
        let token: string | null = null;

        // 1. Try Bearer token first (works on web + Android)
        const authHeader = req.headers.authorization;
        if (authHeader && authHeader.startsWith('Bearer ')) {
            token = authHeader.slice(7);

            // ── Cache hit: skip all DB queries ──
            const cached = sessionCache.get(token);
            if (cached) {
                req.user = {
                    id: cached.userId,
                    email: cached.userEmail,
                    name: cached.userName,
                    role: cached.userRole,
                };
                req.staffMember = cached.staffMember;
                req.staffRole = cached.staffMember?.role?.toLowerCase()
                    ?? cached.userRole?.toLowerCase()
                    ?? 'kasir';
                return next();
            }

            // ── Cache miss: query DB ──
            const rows = await db.execute(sql`
                SELECT s.id as sessionId, s.token, s.user_id, s.expires_at,
                       u.id as uid, u.name, u.email, u.role
                FROM session s
                JOIN user u ON s.user_id = u.id
                WHERE s.token = ${token}
                AND s.expires_at > NOW()
                LIMIT 1
            `);

            // mysql2 returns [rows, fields] — handle both pool and connection results
            const resultRows = Array.isArray((rows as any)[0])
                ? (rows as any)[0]
                : Array.isArray(rows)
                ? rows
                : [];
            const row = resultRows[0];

            if (row) {
                session = {
                    user: {
                        id: row.user_id ?? row.uid,
                        name: row.name,
                        email: row.email,
                        role: row.role,
                    },
                    session: {
                        id: row.sessionId ?? row.uid,
                        userId: row.user_id,
                        expiresAt: row.expires_at,
                    },
                };
            }
        }

        // 2. Fallback: cookie-based auth via better-auth
        if (!session) {
            const headers = fromNodeHeaders(req.headers);
            const result = await auth.api.getSession({ headers });
            if (result) {
                session = result;
            }
        }

        if (!session) {
            res.status(401).json({ error: 'Unauthorized: Login required' });
            return;
        }

        req.user = session.user;
        req.session = session.session;

        // ── Fetch staff once and attach to req ──
        // Route handlers MUST use req.staffMember instead of querying again.
        let staffMember: StaffRecord | null = null;
        try {
            staffMember = await staffService.findByUserId(session.user.id) as StaffRecord | null;
        } catch {
            staffMember = null;
        }

        req.staffMember = staffMember;
        req.staffRole = staffMember?.role?.toLowerCase()
            ?? (session.user as any).role?.toLowerCase()
            ?? 'kasir';

        // ── Populate cache if we arrived via Bearer token ──
        if (token) {
            sessionCache.set(token, {
                userId: session.user.id,
                userEmail: session.user.email,
                userName: session.user.name,
                userRole: (session.user as any).role,
                staffMember,
            });
        }

        next();
    } catch (error) {
        res.status(401).json({ error: 'Unauthorized: Invalid session' });
    }
}

/**
 * Middleware: Require specific role(s)
 * Must be used AFTER requireAuth
 * Rejects with 403 if user doesn't have required role
 */
export function requireRole(...roles: string[]) {
    return (req: AuthenticatedRequest, res: Response, next: NextFunction): void => {
        const userRole = req.staffRole || 'kasir';

        if (!roles.includes(userRole)) {
            res.status(403).json({
                error: 'Forbidden: Insufficient permissions',
                required: roles,
                current: userRole,
            });
            return;
        }

        next();
    };
}
