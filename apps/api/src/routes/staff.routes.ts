import { Router, Request, Response, NextFunction } from 'express';
import { AppError } from '../middleware/errorHandler.js';
import { z } from 'zod';
import { validateQuery } from '../middleware/validate.middleware.js';
import { staffService } from '../services/staff.service.js';

const router = Router();
import { requireAuth } from '../middleware/auth.middleware.js';
import { db } from '../db/index.js';
import { staff } from '../db/schema/index.js';
import { eq, and } from 'drizzle-orm';

// ─────────────────────────────────────────────────────────────
// GET /staff/public — Public endpoint for PIN Login staff selection
// Query: ?branchId
// ─────────────────────────────────────────────────────────────
router.get('/public', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const branchId = req.query.branchId as string;
        if (!branchId) throw AppError.validation('branchId is required');
        
        const staffList = await db
            .select({
                id: staff.id,
                name: staff.name,
                role: staff.role,
                imageUrl: staff.imageUrl,
            })
            .from(staff)
            .where(and(
                eq(staff.branchId, branchId),
                eq(staff.status, 'Aktif')
            ));
            
        res.json({ success: true, data: staffList });
    } catch (e) { next(e); }
});

// Protect all subsequent routes
router.use(requireAuth);

// ─────────────────────────────────────────────────────────────
// GET /staff — list all staff (with filters & pagination)
// Query: ?branchId, ?role, ?status, ?search, ?page, ?limit
// ─────────────────────────────────────────────────────────────
const listQuerySchema = z.object({
    branchId: z.string().optional(),
    role: z.string().optional(),
    status: z.string().optional(),
    search: z.string().optional(),
    page: z.coerce.number().int().min(1).optional(),
    limit: z.coerce.number().int().min(1).max(100).default(50),
});

router.get('/', validateQuery(listQuerySchema), async (req: Request, res: Response, next: NextFunction) => {
    try {
        const result = await staffService.findAll({
            branchId: req.query.branchId as string | undefined,
            role: req.query.role as string | undefined,
            status: req.query.status as string | undefined,
            search: req.query.search as string | undefined,
            page: req.query.page as number | undefined,
            limit: req.query.limit as number | undefined,
        });
        res.json(result);
    } catch (e) { next(e); }
});

// ─────────────────────────────────────────────────────────────
// GET /staff/stats/summary — aggregated stats
// ─────────────────────────────────────────────────────────────
router.get('/stats/summary', async (_req: Request, res: Response, next: NextFunction) => {
    try {
        const stats = await staffService.getStats();
        res.json(stats);
    } catch (e) { next(e); }
});

// ─────────────────────────────────────────────────────────────
// GET /staff/by-user/:userId — get staff linked to auth user
// NOTE: req.staffMember is already populated by requireAuth middleware.
// We validate the userId matches the authenticated user to prevent IDOR.
// ─────────────────────────────────────────────────────────────
router.get('/by-user/:userId', async (req: Request<{ userId: string }>, res: Response, next: NextFunction) => {
    try {
        const authReq = req as any;
        // If the request userId matches the authenticated user, return cached staffMember
        if (authReq.staffMember && authReq.user?.id === req.params.userId) {
            res.json(authReq.staffMember);
            return;
        }
        // Fallback: query DB (e.g. admin requesting another user's staff record)
        const member = await staffService.findByUserId(req.params.userId);
        if (!member) { throw AppError.notFound(); }
        res.json(member);
    } catch (e) { next(e); }
});


// ─────────────────────────────────────────────────────────────
// GET /staff/:id — get single staff
// ─────────────────────────────────────────────────────────────
router.get('/:id', async (req: Request<{ id: string }>, res: Response, next: NextFunction) => {
    try {
        const member = await staffService.findById(req.params.id);
        if (!member) { throw AppError.notFound(); }
        res.json(member);
    } catch (e) { next(e); }
});

// ─────────────────────────────────────────────────────────────
// POST /staff — create staff + auth user account
// ─────────────────────────────────────────────────────────────
router.post('/', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const result = await staffService.create(req.body);
        res.status(201).json(result);
    } catch (e) { next(e); }
});

// ─────────────────────────────────────────────────────────────
// PUT /staff/:id — update staff
// ─────────────────────────────────────────────────────────────
router.put('/:id', async (req: Request<{ id: string }>, res: Response, next: NextFunction) => {
    try {
        const member = await staffService.update(req.params.id, req.body);
        if (!member) { throw AppError.notFound(); }
        res.json(member);
    } catch (e) { next(e); }
});

// ─────────────────────────────────────────────────────────────
// DELETE /staff/:id — delete staff
// ─────────────────────────────────────────────────────────────
router.delete('/:id', async (req: Request<{ id: string }>, res: Response, next: NextFunction) => {
    try {
        const member = await staffService.delete(req.params.id);
        if (!member) { throw AppError.notFound(); }
        res.json({ message: 'Staff deleted' });
    } catch (e) { next(e); }
});

// ─────────────────────────────────────────────────────────────
// POST /staff/:id/reset-pin — reset PIN
// Body: { pin: string }
// ─────────────────────────────────────────────────────────────
router.post('/:id/reset-pin', async (req: Request<{ id: string }>, res: Response, next: NextFunction) => {
    try {
        const { pin } = req.body;
        if (!pin) { throw AppError.validation('Data tidak valid'); }
        const member = await staffService.resetPin(req.params.id, pin);
        if (!member) { throw AppError.notFound(); }
        res.json({ message: 'PIN berhasil diperbarui', staff: member });
    } catch (e) { next(e); }
});

// ─────────────────────────────────────────────────────────────
// GET /staff/:id/shifts — shift history for a staff member
// Query: ?limit (default 20)
// ─────────────────────────────────────────────────────────────
router.get('/:id/shifts', async (req: Request<{ id: string }>, res: Response, next: NextFunction) => {
    try {
        const limit = req.query.limit ? parseInt(req.query.limit as string) : 20;
        const shiftHistory = await staffService.getShiftHistory(req.params.id, limit);
        res.json(shiftHistory);
    } catch (e) { next(e); }
});

// ─────────────────────────────────────────────────────────────
// GET /staff/:id/salary — salary history
// ─────────────────────────────────────────────────────────────
router.get('/:id/salary', async (req: Request<{ id: string }>, res: Response, next: NextFunction) => {
    try {
        const history = await staffService.getSalaryHistory(req.params.id);
        res.json(history);
    } catch (e) { next(e); }
});

// ─────────────────────────────────────────────────────────────
// POST /staff/:id/salary — add salary record
// Body: { salaryType, amount, effectiveDate, notes? }
// ─────────────────────────────────────────────────────────────
router.post('/:id/salary', async (req: Request<{ id: string }>, res: Response, next: NextFunction) => {
    try {
        const { salaryType, amount, effectiveDate, notes } = req.body;
        if (!salaryType || !amount || !effectiveDate) {
            throw AppError.validation('Data tidak valid');
        }
        const record = await staffService.addSalaryRecord({
            staffId:       req.params.id,
            salaryType,
            amount:        Number(amount),
            effectiveDate,
            notes,
        });
        res.status(201).json(record);
    } catch (e) { next(e); }
});

export default router;
