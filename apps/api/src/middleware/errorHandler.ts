import { Request, Response, NextFunction } from 'express';

// ─────────────────────────────────────────────────────────────
// Standardized API Error Response Format:
//   Success: { success: true, data: any, message?: string }
//   Error:   { success: false, message: string, code: string }
// ─────────────────────────────────────────────────────────────

export function errorHandler(
    err: Error,
    req: Request,
    res: Response,
    _next: NextFunction
): void {
    const statusCode = (err as any).statusCode || 500;
    const message = statusCode === 500 ? 'Internal server error' : err.message;
    const code = (err as any).code || err.name || 'INTERNAL_ERROR';

    // Structured error log with location info
    console.error(`\n🔴 [ERROR] ${req.method} ${req.path}`);
    console.error(`   Status : ${statusCode}`);
    console.error(`   Message: ${err.message}`);
    if (err.stack) {
        const stackLines = err.stack.split('\n').slice(0, 5).join('\n   ');
        console.error(`   Stack  :\n   ${stackLines}`);
    }
    console.error('');

    res.status(statusCode).json({
        success: false,
        message,
        code,
        ...(process.env.NODE_ENV === 'development' && {
            detail: err.message,
            stack: err.stack,
        }),
    });
}

export class AppError extends Error {
    statusCode: number;
    code: string;

    constructor(message: string, statusCode: number = 400, code: string = 'APP_ERROR') {
        super(message);
        this.statusCode = statusCode;
        this.code = code;
        this.name = 'AppError';
    }
}
