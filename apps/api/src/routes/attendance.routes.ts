import { Router, Request, Response, NextFunction } from 'express';
import { AppError } from '../middleware/errorHandler.js';
import { z } from 'zod';
import { attendanceService } from '../services/attendance.service.js';
import { validateBody } from '../middleware/validate.middleware.js';

const router = Router();

// ─── Validation Schemas ────────────────────────────────────────
const clockInSchema = z.object({
    staffId: z.string().min(1, 'staffId wajib diisi'),
    notes:   z.string().max(500).optional(),
});

const clockOutSchema = z.object({
    staffId: z.string().min(1, 'staffId wajib diisi'),
    notes:   z.string().max(500).optional(),
});

// ─── GET / ─────────────────────────────────────
// Query: ?staffId, ?startDate (YYYY-MM-DD), ?endDate, ?branchId, ?page, ?limit
router.get('/', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const records = await attendanceService.findAll({
            staffId:   req.query.staffId   as string | undefined,
            startDate: req.query.startDate as string | undefined,
            endDate:   req.query.endDate   as string | undefined,
            branchId:  req.query.branchId  as string | undefined,
            page:      req.query.page  ? parseInt(req.query.page  as string) : undefined,
            limit:     req.query.limit ? parseInt(req.query.limit as string) : undefined,
        });
        res.json(records);
    } catch (e) { next(e); }
});

// ─── GET /staff/:id/attendance/today ──────────────────────────
// Returns today's clock-in/out status for a specific staff member
router.get('/:id/attendance/today', async (req: Request<{ id: string }>, res: Response, next: NextFunction) => {
    try {
        const record = await attendanceService.getTodayStatus(req.params.id);
        res.json(record ?? { clockedIn: false, clockedOut: false });
    } catch (e) { next(e); }
});

// ─── POST /staff/clock-in ─────────────────────────────────────
router.post('/clock-in', validateBody(clockInSchema), async (req: Request, res: Response, next: NextFunction) => {
    try {
        const record = await attendanceService.clockIn(req.body);
        res.status(201).json(record);
    } catch (e: any) {
        if (e.statusCode === 409) { throw AppError.conflict('Data sudah ada / konflik'); }
        next(e);
    }
});

// ─── POST /staff/clock-out ────────────────────────────────────
router.post('/clock-out', validateBody(clockOutSchema), async (req: Request, res: Response, next: NextFunction) => {
    try {
        const record = await attendanceService.clockOut(req.body);
        res.json(record);
    } catch (e: any) {
        if (e.statusCode === 404) { throw AppError.notFound(); }
        if (e.statusCode === 409) { throw AppError.conflict('Data sudah ada / konflik'); }
        next(e);
    }
});

export default router;
