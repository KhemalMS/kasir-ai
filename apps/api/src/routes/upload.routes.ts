import { Router, Request, Response } from 'express';
import multer from 'multer';
import path from 'path';
import { fileURLToPath } from 'url';
import fs from 'fs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// ── Products upload directory ─────────────────────────────────────
const productsDir = path.join(__dirname, '../../uploads/products');
if (!fs.existsSync(productsDir)) {
    fs.mkdirSync(productsDir, { recursive: true });
}

// ── Avatars upload directory ──────────────────────────────────────
const avatarsDir = path.join(__dirname, '../../uploads/avatars');
if (!fs.existsSync(avatarsDir)) {
    fs.mkdirSync(avatarsDir, { recursive: true });
}

// ── Helper: image file filter ─────────────────────────────────────
const imageFilter: multer.Options['fileFilter'] = (_req, file, cb) => {
    const allowed = /jpeg|jpg|png|webp/;
    const ext = allowed.test(path.extname(file.originalname).toLowerCase());
    const mime = allowed.test(file.mimetype);
    if (ext && mime) cb(null, true);
    else cb(new Error('Only .jpg, .jpeg, .png, .webp files are allowed'));
};

// ── Multer: products (5 MB) ───────────────────────────────────────
const productUpload = multer({
    storage: multer.diskStorage({
        destination: (_req, _file, cb) => cb(null, productsDir),
        filename: (_req, file, cb) => {
            const uniqueSuffix = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;
            cb(null, `product-${uniqueSuffix}${path.extname(file.originalname)}`);
        },
    }),
    limits: { fileSize: 5 * 1024 * 1024 },
    fileFilter: imageFilter,
});

// ── Multer: avatars (2 MB) ────────────────────────────────────────
const avatarUpload = multer({
    storage: multer.diskStorage({
        destination: (_req, _file, cb) => cb(null, avatarsDir),
        filename: (_req, file, cb) => {
            const uniqueSuffix = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;
            cb(null, `avatar-${uniqueSuffix}${path.extname(file.originalname)}`);
        },
    }),
    limits: { fileSize: 2 * 1024 * 1024 }, // 2 MB max
    fileFilter: imageFilter,
});

// ── Helper: build absolute public URL ────────────────────────────
const buildUrl = (req: Request, relativePath: string): string => {
    const host = req.headers['x-forwarded-host'] ?? req.headers.host ?? 'localhost:3001';
    const protocol = req.headers['x-forwarded-proto'] ?? (req.secure ? 'https' : 'http');
    return `${protocol}://${host}${relativePath}`;
};

const router = Router();

// POST /api/upload          → product image
router.post('/', productUpload.single('image'), (req: Request, res: Response) => {
    if (!req.file) {
        res.status(400).json({ success: false, error: 'No image file provided' });
        return;
    }
    const imageUrl = buildUrl(req, `/uploads/products/${req.file.filename}`);
    res.json({ success: true, imageUrl });
});

// POST /api/upload/avatar   → staff avatar (2 MB, jpg/png/webp only)
router.post('/avatar', avatarUpload.single('image'), (req: Request, res: Response) => {
    if (!req.file) {
        res.status(400).json({ success: false, error: 'No image file provided' });
        return;
    }
    const imageUrl = buildUrl(req, `/uploads/avatars/${req.file.filename}`);
    res.json({ success: true, imageUrl });
});

export default router;
