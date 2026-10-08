import { Router, Request, Response } from 'express';
import { AppError, asyncHandler } from '../middleware/errorHandler.js';
import * as purchasingReportsService from '../services/purchasingReports.service.js';

const router = Router();

// ─── GET /api/reports/purchasing/po ───────────────────────────────────────
router.get('/po', asyncHandler(async (req: Request, res: Response) => {
    const data = await purchasingReportsService.getPoReport(req.query as any);
    res.json(data);
}));

// ─── GET /api/reports/purchasing/by-supplier ─────────────────────────────
router.get('/by-supplier', asyncHandler(async (req: Request, res: Response) => {
    const data = await purchasingReportsService.getPurchasesBySupplier(req.query as any);
    res.json(data);
}));

// ─── GET /api/reports/purchasing/returns ──────────────────────────────────
router.get('/returns', asyncHandler(async (req: Request, res: Response) => {
    const data = await purchasingReportsService.getReturnsReport(req.query as any);
    res.json(data);
}));

// ─── GET /api/reports/purchasing/performance ──────────────────────────────
router.get('/performance', asyncHandler(async (req: Request, res: Response) => {
    const data = await purchasingReportsService.getSupplierPerformance(req.query as any);
    res.json(data);
}));

export default router;
