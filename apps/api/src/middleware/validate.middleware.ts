import { Request, Response, NextFunction } from 'express';
import { ZodSchema, ZodError } from 'zod';

/**
 * Middleware factory: Validate request body against a Zod schema.
 * Error format mengikuti API Error Contract KSR:
 *   { success: false, code: 'KSR-400', category: 'VALIDATION', ... }
 */
export function validateBody(schema: ZodSchema) {
    return (req: Request, res: Response, next: NextFunction): void => {
        try {
            req.body = schema.parse(req.body);
            next();
        } catch (error: any) {
            if (error instanceof ZodError) {
                const fields = error.issues.map((e: any) => ({
                    field: e.path.join('.'),
                    message: e.message,
                    code: e.code,
                }));
                console.warn('[VALIDATION]', req.method, req.path, JSON.stringify(fields));
                res.status(400).json({
                    success: false,
                    code: 'KSR-400',
                    category: 'VALIDATION',
                    severity: 'info',
                    message: 'Data yang dikirim tidak valid. Periksa kembali isian form.',
                    details: { fields },
                    requestId: (req as any).requestId || 'unknown',
                    timestamp: new Date().toISOString(),
                });
                return;
            }
            next(error);
        }
    };
}

/**
 * Middleware factory: Validate query parameters against a Zod schema.
 */
export function validateQuery(schema: ZodSchema) {
    return (req: Request, res: Response, next: NextFunction): void => {
        try {
            // Hanya validasi, tidak assign ke req.query (read-only di Express 5+)
            schema.parse(req.query);
            next();
        } catch (error: any) {
            if (error instanceof ZodError) {
                const fields = error.issues.map((e: any) => ({
                    field: e.path.join('.'),
                    message: e.message,
                }));
                res.status(400).json({
                    success: false,
                    code: 'KSR-400',
                    category: 'VALIDATION',
                    severity: 'info',
                    message: 'Parameter query tidak valid.',
                    details: { fields },
                    requestId: (req as any).requestId || 'unknown',
                    timestamp: new Date().toISOString(),
                });
                return;
            }
            next(error);
        }
    };
}

/**
 * Sanitize string input - strip potential XSS/injection characters
 */
export function sanitizeString(input: string): string {
    return input
        .replace(/[<>]/g, '') // Remove HTML brackets
        .trim();
}
