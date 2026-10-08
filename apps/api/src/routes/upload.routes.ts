import { Router, Request, Response, NextFunction } from 'express';
import { AppError, asyncHandler } from '../middleware/errorHandler.js';
import multer from 'multer';
import path from 'path';
import { fileURLToPath } from 'url';
import fsOrig from 'fs';
import { v4 as uuidv4 } from 'uuid';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// ── Products upload directory ─────────────────────────────────────
const productsDir = path.join(__dirname, '../../uploads/products');
if (!fsOrig.existsSync(productsDir)) {
    fsOrig.mkdirSync(productsDir, { recursive: true });
}

// ── Avatars upload directory ──────────────────────────────────────
const avatarsDir = path.join(__dirname, '../../uploads/avatars');
if (!fsOrig.existsSync(avatarsDir)) {
    fsOrig.mkdirSync(avatarsDir, { recursive: true });
}

// ── Helper: image file filter ─────────────────────────────────────
const imageFilter: multer.Options['fileFilter'] = (_req, file, cb) => {
    // Only JPG, PNG, WEBP allowed
    const allowedExtensions = ['.jpeg', '.jpg', '.png', '.webp'];
    const originalExt = path.extname(file.originalname).toLowerCase();
    
    // Validate MIME type
    const allowedMimeTypes = ['image/jpeg', 'image/png', 'image/webp'];
    const isMimeAllowed = allowedMimeTypes.includes(file.mimetype);
    
    // Validate Extension
    const isExtAllowed = allowedExtensions.includes(originalExt);
    
    if (isExtAllowed && isMimeAllowed) {
        cb(null, true);
    } else {
        cb(new Error('Only .jpg, .jpeg, .png, .webp files are allowed'));
    }
};

// Helper: safe extension extractor
const getSafeExt = (originalname: string) => {
    const ext = path.extname(originalname).toLowerCase();
    if (['.jpeg', '.jpg', '.png', '.webp'].includes(ext)) {
        return ext;
    }
    return '.jpg'; // Fallback safely
};

// ── Multer: products (5 MB) ───────────────────────────────────────
const productUpload = multer({
    storage: multer.diskStorage({
        destination: (_req, _file, cb) => cb(null, productsDir),
        filename: (_req, file, cb) => {
            // UUID only to prevent path traversal
            cb(null, `product-${uuidv4()}${getSafeExt(file.originalname)}`);
        },
    }),
    limits: { fileSize: 5 * 1024 * 1024 }, // 5 MB max
    fileFilter: imageFilter,
});

// ── Multer: avatars (5 MB) ────────────────────────────────────────
const avatarUpload = multer({
    storage: multer.diskStorage({
        destination: (_req, _file, cb) => cb(null, avatarsDir),
        filename: (_req, file, cb) => {
            // UUID only to prevent path traversal
            cb(null, `avatar-${uuidv4()}${getSafeExt(file.originalname)}`);
        },
    }),
    limits: { fileSize: 5 * 1024 * 1024 }, // 5 MB max
    fileFilter: imageFilter,
});

// ── Helper: build absolute public URL ────────────────────────────
const buildUrl = (req: Request, relativePath: string): string => {
    const host = req.headers['x-forwarded-host'] ?? req.headers.host ?? 'localhost:3001';
    const protocol = req.headers['x-forwarded-proto'] ?? (req.secure ? 'https' : 'http');
    return `${protocol}://${host}${relativePath}`;
};

const router = Router();

// Error handler middleware for multer
const handleMulterError = (err: any, req: Request, res: Response, next: NextFunction) => {
    if (err instanceof multer.MulterError) {
        if (err.code === 'LIMIT_FILE_SIZE') {
            next(AppError.validation('File size exceeds the 5MB limit'));
        } else {
            next(AppError.validation(`Upload error: ${err.message}`));
        }
    } else if (err) {
        next(AppError.validation(err.message));
    } else {
        next();
    }
};

// POST /api/upload          → product image
router.post('/', (req, res, next) => {
    productUpload.single('image')(req, res, (err) => handleMulterError(err, req, res, next));
}, asyncHandler(async (req: Request, res: Response) => {
    if (!req.file) {
        throw AppError.validation('No image file provided');
    }
    const imageUrl = buildUrl(req, `/uploads/products/${req.file.filename}`);
    res.json({ success: true, imageUrl });
}));

// POST /api/upload/avatar   → staff avatar
router.post('/avatar', (req, res, next) => {
    avatarUpload.single('image')(req, res, (err) => handleMulterError(err, req, res, next));
}, asyncHandler(async (req: Request, res: Response) => {
    if (!req.file) {
        throw AppError.validation('No image file provided');
    }
    const imageUrl = buildUrl(req, `/uploads/avatars/${req.file.filename}`);
    res.json({ success: true, imageUrl });
}));

export default router;
