import { Request, Response, NextFunction } from 'express';
import { randomUUID } from 'crypto';

/**
 * Middleware: tambahkan X-Request-Id ke setiap request.
 * Terima dari header client (untuk tracing), atau generate UUID baru.
 * Response selalu menyertakan requestId agar frontend bisa menghubungkan
 * error UI dengan log backend.
 */
export function requestIdMiddleware(req: Request, res: Response, next: NextFunction): void {
    let requestId = req.headers['x-request-id'];
    
    // Validasi & sanitasi incoming RequestID
    if (Array.isArray(requestId)) {
        requestId = requestId[0];
    }
    
    if (typeof requestId !== 'string' || requestId.length < 10 || requestId.length > 50 || !/^[a-zA-Z0-9-]+$/.test(requestId)) {
        requestId = randomUUID();
    }

    // Attach ke request untuk dipakai di log dan error handler
    (req as any).requestId = requestId;

    // Kembalikan ke client agar bisa di-log di Flutter
    res.setHeader('X-Request-Id', requestId);

    next();
}
