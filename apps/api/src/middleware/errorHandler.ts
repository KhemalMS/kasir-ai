import { Request, Response, NextFunction } from 'express';

// ─────────────────────────────────────────────────────────────────────────────
// Error Contract — semua response error dari API wajib menggunakan format ini:
//
//   {
//     "success": false,
//     "code": "KSR-...",
//     "category": "AUTH|VALIDATION|API|DATABASE|BUSINESS_RULE|UNKNOWN",
//     "severity": "info|warning|error|critical",
//     "message": "pesan aman untuk user",
//     "details": {} | undefined,
//     "requestId": "uuid",
//     "timestamp": "ISO-8601"
//   }
//
// Stack trace HANYA dikirim saat NODE_ENV=development.
// ─────────────────────────────────────────────────────────────────────────────

export type ErrorCategory =
    | 'AUTH'
    | 'VALIDATION'
    | 'API'
    | 'DATABASE'
    | 'BUSINESS_RULE'
    | 'NETWORK'
    | 'REPORT'
    | 'UPLOAD'
    | 'PRINT'
    | 'BUILD'
    | 'UNKNOWN';

export type ErrorSeverity = 'info' | 'warning' | 'error' | 'critical';

// Semua AppError harus pakai kode KSR-XXX
const ERROR_CODES: Record<string, string> = {
    // Auth
    UNAUTHORIZED:    'KSR-401',
    FORBIDDEN:       'KSR-403',
    SESSION_EXPIRED: 'KSR-4010',
    // Validation
    VALIDATION:      'KSR-400',
    BAD_REQUEST:     'KSR-4001',
    // Business
    NOT_FOUND:       'KSR-404',
    CONFLICT:        'KSR-409',
    BUSINESS_RULE:   'KSR-422',
    STOCK_INSUFFICIENT: 'KSR-4221',
    // Server
    INTERNAL_ERROR:  'KSR-500',
    DB_ERROR:        'KSR-5001',
};

/**
 * Global Express error handler — WAJIB sebagai middleware terakhir.
 * Semua error yang melewati next(err) akan ditangkap di sini.
 */
export function errorHandler(
    err: Error,
    req: Request,
    res: Response,
    _next: NextFunction
): void {
    const appErr = err as AppError;
    const statusCode  = appErr.statusCode || 500;
    const requestId   = (req as any).requestId || 'unknown';
    const isProduction = process.env.NODE_ENV === 'production';

    // Tentukan category dan severity dari statusCode/jenis error
    const { category, severity } = classifyError(appErr, statusCode);

    // Pesan yang aman untuk user (jangan bocorkan stack di produksi)
    const userMessage = statusCode === 500 && isProduction
        ? 'Terjadi kesalahan pada server. Silakan coba beberapa saat lagi.'
        : appErr.userMessage || err.message;

    // Structured server log
    const duration = (req as any)._startTime
        ? `${Date.now() - (req as any)._startTime}ms`
        : undefined;

    const logEntry = {
        level: severity === 'critical' || statusCode >= 500 ? 'error' : 'warn',
        requestId,
        method: req.method,
        path: req.path,
        statusCode,
        category,
        code: appErr.code || 'INTERNAL_ERROR',
        message: err.message,
        ...(duration && { duration }),
        ...(appErr.details && { details: appErr.details }),
        ...(err.stack && !isProduction && { stack: err.stack.split('\n').slice(0, 8) }),
    };
    console.error(JSON.stringify(logEntry));

    res.status(statusCode).json({
        success: false,
        code: ERROR_CODES[appErr.code || ''] || appErr.code || 'KSR-500',
        category,
        severity,
        message: userMessage,
        ...(appErr.details && { details: appErr.details }),
        requestId,
        timestamp: new Date().toISOString(),
        ...(process.env.NODE_ENV === 'development' && {
            _dev: {
                originalMessage: err.message,
                stack: err.stack?.split('\n').slice(0, 6),
            },
        }),
    });
}

function classifyError(
    err: AppError,
    statusCode: number
): { category: ErrorCategory; severity: ErrorSeverity } {
    if (statusCode === 401) return { category: 'AUTH', severity: 'warning' };
    if (statusCode === 403) return { category: 'AUTH', severity: 'warning' };
    if (statusCode === 400) return { category: 'VALIDATION', severity: 'info' };
    if (statusCode === 422) return { category: 'BUSINESS_RULE', severity: 'warning' };
    if (statusCode === 404) return { category: 'API', severity: 'info' };
    if (statusCode === 409) return { category: 'BUSINESS_RULE', severity: 'warning' };
    if (statusCode >= 500) return { category: 'API', severity: 'critical' };
    if (err.category) return { category: err.category, severity: err.severity || 'error' };
    return { category: 'UNKNOWN', severity: 'error' };
}

// ─────────────────────────────────────────────────────────────────────────────
// AppError — kelas error standar untuk semua business logic
// ─────────────────────────────────────────────────────────────────────────────

export class AppError extends Error {
    statusCode: number;
    code: string;
    category?: ErrorCategory;
    severity?: ErrorSeverity;
    userMessage?: string;
    details?: Record<string, any>;

    constructor(
        message: string,
        statusCode: number = 500,
        code: string = 'KSR-500',
        options?: {
            category?: ErrorCategory;
            severity?: ErrorSeverity;
            userMessage?: string;
            details?: Record<string, any>;
        }
    ) {
        super(message);
        this.statusCode = statusCode;
        this.code = code;
        this.name = 'AppError';
        this.category  = options?.category;
        this.severity  = options?.severity;
        this.userMessage = options?.userMessage;
        this.details   = options?.details;
    }

    // Factory shortcuts
    static unauthorized(msg = 'Sesi tidak valid, silakan login kembali.'): AppError {
        return new AppError(msg, 401, 'UNAUTHORIZED', { category: 'AUTH', severity: 'warning', userMessage: msg });
    }
    static forbidden(msg = 'Anda tidak memiliki akses ke fitur ini.'): AppError {
        return new AppError(msg, 403, 'FORBIDDEN', { category: 'AUTH', severity: 'warning', userMessage: msg });
    }
    static notFound(resource = 'Data'): AppError {
        const msg = `${resource} tidak ditemukan.`;
        return new AppError(msg, 404, 'NOT_FOUND', { category: 'API', severity: 'info', userMessage: msg });
    }
    static validation(msg: string, details?: Record<string, any>): AppError {
        return new AppError(msg, 400, 'VALIDATION', { category: 'VALIDATION', severity: 'info', userMessage: msg, details });
    }
    static conflict(msg: string): AppError {
        return new AppError(msg, 409, 'CONFLICT', { category: 'BUSINESS_RULE', severity: 'warning', userMessage: msg });
    }
    static businessRule(msg: string, code = 'BUSINESS_RULE'): AppError {
        return new AppError(msg, 422, code, { category: 'BUSINESS_RULE', severity: 'warning', userMessage: msg });
    }
    static internal(msg = 'Terjadi kesalahan server.'): AppError {
        return new AppError(msg, 500, 'INTERNAL_ERROR', { category: 'API', severity: 'critical' });
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Async route wrapper — bungkus async handler agar error masuk ke errorHandler
// ─────────────────────────────────────────────────────────────────────────────
export function asyncHandler(fn: (req: any, res: Response, next: NextFunction) => Promise<any>) {
    return (req: Request, res: Response, next: NextFunction) => {
        fn(req, res, next).catch(next);
    };
}
