import { Router, Request, Response } from 'express';
import { AppError, asyncHandler } from '../middleware/errorHandler.js';
import { taxReportsService } from '../services/taxReports.service.js';

const router = Router();

function getParams(req: Request) {
    return {
        start:    req.query.start    as string | undefined,
        end:      req.query.end      as string | undefined,
        branchId: req.query.branchId as string | undefined,
    };
}

// ─── GET /api/reports/tax/ppn ──────────────────────────────────────────────
router.get('/ppn', asyncHandler(async (req: Request, res: Response) => {
    const data = await taxReportsService.getPpnReport(getParams(req));
    res.json(data);
}));

// ─── GET /api/reports/tax/invoices ────────────────────────────────────────
router.get('/invoices', asyncHandler(async (req: Request, res: Response) => {
    const data = await taxReportsService.getTaxInvoices(getParams(req));
    res.json(data);
}));

// ─── GET /api/reports/tax/summary ─────────────────────────────────────────
router.get('/summary', asyncHandler(async (req: Request, res: Response) => {
    const data = await taxReportsService.getMonthlySummary(getParams(req));
    res.json(data);
}));

export default router;
