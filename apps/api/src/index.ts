import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import 'dotenv/config';
import { toNodeHandler } from 'better-auth/node';

import { errorHandler } from './middleware/errorHandler.js';
import { requireAuth, requireRole } from './middleware/auth.middleware.js';
import { auth } from './lib/better-auth.js';

// Route imports
import branchesRoutes from './routes/branches.routes.js';
import categoriesRoutes from './routes/categories.routes.js';
import productsRoutes from './routes/products.routes.js';
import inventoryRoutes from './routes/inventory.routes.js';
import ordersRoutes from './routes/orders.routes.js';
import paymentsRoutes from './routes/payments.routes.js';
import expensesRoutes from './routes/expenses.routes.js';
import staffRoutes from './routes/staff.routes.js';
import shiftsRoutes from './routes/shifts.routes.js';
import settingsRoutes from './routes/settings.routes.js';
import reportsRoutes from './routes/reports.routes.js';
import kitchenRoutes from './routes/kitchen.routes.js';
import uploadRoutes from './routes/upload.routes.js';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const PORT = process.env.PORT || 3001;

// ── Security Headers ────────────────────────────────────────────
app.use(helmet({
    contentSecurityPolicy: false, // Disabled for API server
    crossOriginEmbedderPolicy: false,
}));

// ── CORS - Manual headers to guarantee cross-origin access ─────
app.use((req, res, next) => {
    const origin = req.headers.origin;
    if (origin) {
        res.setHeader('Access-Control-Allow-Origin', origin);
    } else {
        res.setHeader('Access-Control-Allow-Origin', '*');
    }
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, PATCH, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, Cookie');
    res.setHeader('Access-Control-Allow-Credentials', 'true');

    if (req.method === 'OPTIONS') {
        res.status(204).end();
        return;
    }
    next();
});

// ── Better-Auth (public - no auth required) ─────────────────────
app.all('/api/auth/*', toNodeHandler(auth));

app.use(express.json());

// ── Static file serving for uploads ─────────────────────────────
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

// ── Health Check (public) ───────────────────────────────────────
app.get('/api/health', (_req, res) => {
    res.json({
        status: 'ok',
        timestamp: new Date().toISOString(),
        version: '1.0.0',
    });
});

// ══════════════════════════════════════════════════════════════════
// ── PROTECTED ROUTES (require login) ─────────────────────────────
// ══════════════════════════════════════════════════════════════════

// ── Routes accessible by ALL authenticated users (kasir, admin, dapur) ──
app.use('/api/products', requireAuth, productsRoutes);
app.use('/api/categories', requireAuth, categoriesRoutes);
app.use('/api/orders', requireAuth, ordersRoutes);
app.use('/api/payments', requireAuth, paymentsRoutes);
app.use('/api/shifts', requireAuth, shiftsRoutes);
app.use('/api/kitchen', requireAuth, kitchenRoutes);
app.use('/api/staff', requireAuth, staffRoutes);
app.use('/api/settings', requireAuth, settingsRoutes);
app.use('/api/upload', requireAuth, uploadRoutes);

// ── Routes accessible ONLY by admin ─────────────────────────────
app.use('/api/branches', requireAuth, requireRole('admin'), branchesRoutes);
app.use('/api/inventory', requireAuth, requireRole('admin'), inventoryRoutes);
app.use('/api/expenses', requireAuth, requireRole('admin'), expensesRoutes);
app.use('/api/reports', requireAuth, requireRole('admin'), reportsRoutes);

// ── Error Handler ───────────────────────────────────────────────
app.use(errorHandler);

// ── Start Server ────────────────────────────────────────────────
app.listen(Number(PORT), '0.0.0.0', () => {
    console.log(`🚀 Kasir-AI API running on http://0.0.0.0:${PORT}`);
    console.log(`📋 Health check: http://localhost:${PORT}/api/health`);
    console.log(`🔒 All API routes are protected with authentication`);

    // Security warnings
    const secret = process.env.BETTER_AUTH_SECRET || '';
    if (!secret || secret.includes('kasir-ai-secret') || secret.length < 32) {
        console.warn('⚠️  WARNING: BETTER_AUTH_SECRET is weak! Generate a strong one with:');
        console.warn('   node -e "console.log(require(\'crypto\').randomBytes(32).toString(\'base64\'))"');
    }
});

export default app;
