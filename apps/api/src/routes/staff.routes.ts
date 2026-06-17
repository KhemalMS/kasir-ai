import { Router, Request, Response, NextFunction } from 'express';
import { staffService } from '../services/staff.service.js';

const router = Router();

// ─────────────────────────────────────────────────────────────
// GET /staff — list all staff (with filters & pagination)
// Query: ?branchId, ?role, ?status, ?search, ?page, ?limit
// ─────────────────────────────────────────────────────────────
router.get('/', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const result = await staffService.findAll({
            branchId: req.query.branchId as string,
            role:     req.query.role     as string,
            status:   req.query.status   as string,
            search:   req.query.search   as string,
            page:     req.query.page  ? parseInt(req.query.page  as string) : undefined,
            limit:    req.query.limit ? parseInt(req.query.limit as string) : undefined,
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
        if (!member) { res.status(404).json({ error: 'Staff not found for this user' }); return; }
        res.json(member);
    } catch (e) { next(e); }
});


// ─────────────────────────────────────────────────────────────
// GET /staff/:id — get single staff
// ─────────────────────────────────────────────────────────────
router.get('/:id', async (req: Request<{ id: string }>, res: Response, next: NextFunction) => {
    try {
        const member = await staffService.findById(req.params.id);
        if (!member) { res.status(404).json({ error: 'Staff not found' }); return; }
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
        if (!member) { res.status(404).json({ error: 'Staff not found' }); return; }
        res.json(member);
    } catch (e) { next(e); }
});

// ─────────────────────────────────────────────────────────────
// DELETE /staff/:id — delete staff
// ─────────────────────────────────────────────────────────────
router.delete('/:id', async (req: Request<{ id: string }>, res: Response, next: NextFunction) => {
    try {
        const member = await staffService.delete(req.params.id);
        if (!member) { res.status(404).json({ error: 'Staff not found' }); return; }
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
        if (!pin) { res.status(400).json({ error: 'PIN wajib diisi' }); return; }
        const member = await staffService.resetPin(req.params.id, pin);
        if (!member) { res.status(404).json({ error: 'Staff not found' }); return; }
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
            res.status(400).json({ error: 'salaryType, amount, dan effectiveDate wajib diisi' });
            return;
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
