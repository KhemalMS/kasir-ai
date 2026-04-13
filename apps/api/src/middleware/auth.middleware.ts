import { Request, Response, NextFunction } from 'express';
import { fromNodeHeaders } from 'better-auth/node';
import { auth } from '../lib/better-auth.js';
import { staffService } from '../services/staff.service.js';
import { db } from '../db/index.js';
import { sql } from 'drizzle-orm';

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
}

/**
 * Middleware: Require authentication
 * Supports:
 * 1. Cookie-based auth (browser with proper cookie handling)
 * 2. Authorization Bearer token (web Flutter app, Android app)
 * Rejects with 401 if no valid session
 */
export async function requireAuth(
    req: AuthenticatedRequest,
    res: Response,
    next: NextFunction
): Promise<void> {
    try {
        let session: any = null;

        // 1. Try Bearer token first (works on web + Android)
        const authHeader = req.headers.authorization;
        if (authHeader && authHeader.startsWith('Bearer ')) {
            const token = authHeader.slice(7);
            // Look up session directly from database by raw token
            const rows = await db.execute(sql`
                SELECT s.id as sessionId, s.token, s.user_id, s.expires_at,
                       u.id, u.name, u.email, u.role
                FROM session s
                JOIN user u ON s.user_id = u.id
                WHERE s.token = ${token}
                AND s.expires_at > NOW()
                LIMIT 1
            `);
            
            const row = (rows as any)?.[0]?.[0] || (rows as any)?.rows?.[0] || (rows as any)?.[0];
            if (row) {
                session = {
                    user: {
                        id: row.user_id || row.id,
                        name: row.name,
                        email: row.email,
                        role: row.role,
                    },
                    session: {
                        id: row.sessionId || row.id,
                        userId: row.user_id,
                        expiresAt: row.expires_at,
                    },
                };
            }
        }

        // 2. Fallback: try cookie-based auth via better-auth
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

        // Determine user role: staff table > user table > default
        try {
            const staff = await staffService.findByUserId(session.user.id);
            if (staff) {
                req.staffRole = (staff as any).role?.toLowerCase() || 'kasir';
            } else {
                req.staffRole = (session.user as any).role?.toLowerCase() || 'kasir';
            }
        } catch {
            req.staffRole = (session.user as any).role?.toLowerCase() || 'kasir';
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
