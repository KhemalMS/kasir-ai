import { Router, Request, Response } from 'express';
import { AppError, asyncHandler } from '../middleware/errorHandler.js';
import { inventoryReportsService } from '../services/inventoryReports.service.js';

const router = Router();

function getParams(req: Request) {
    return {
        start: req.query.start as string | undefined,
        end: req.query.end as string | undefined,
        branchId: req.query.branchId as string | undefined,
    };
}

// ─── 14. Stok Saat Ini ────────────────────────────────────────────────────
router.get('/current', asyncHandler(async (req: Request, res: Response) => {
    const data = await inventoryReportsService.getCurrentStock(getParams(req));
    res.json(data);
}));

// ─── 15. Stok Masuk ───────────────────────────────────────────────────────
router.get('/in', asyncHandler(async (req: Request, res: Response) => {
    const data = await inventoryReportsService.getStockIn(getParams(req));
    res.json(data);
}));

// ─── 16. Stok Keluar ──────────────────────────────────────────────────────
router.get('/out', asyncHandler(async (req: Request, res: Response) => {
    const data = await inventoryReportsService.getStockOut(getParams(req));
    res.json(data);
}));

// ─── 17. Stok Menipis ─────────────────────────────────────────────────────
router.get('/low-stock', asyncHandler(async (req: Request, res: Response) => {
    const data = await inventoryReportsService.getLowStock(getParams(req));
    res.json(data);
}));

// ─── 18. Stok Kadaluarsa ──────────────────────────────────────────────────
router.get('/expired', asyncHandler(async (req: Request, res: Response) => {
    const data = await inventoryReportsService.getExpiredStock(getParams(req));
    res.json(data);
}));

// ─── 19. Penyesuaian Stok ─────────────────────────────────────────────────
router.get('/adjustments', asyncHandler(async (req: Request, res: Response) => {
    const data = await inventoryReportsService.getStockAdjustments(getParams(req));
    res.json(data);
}));

// ─── 20. Perputaran Inventori ─────────────────────────────────────────────
router.get('/turnover', asyncHandler(async (req: Request, res: Response) => {
    const data = await inventoryReportsService.getInventoryTurnover(getParams(req));
    res.json(data);
}));

// ─── 21. Dead Stock ───────────────────────────────────────────────────────
router.get('/dead-stock', asyncHandler(async (req: Request, res: Response) => {
    const data = await inventoryReportsService.getDeadStock(getParams(req));
    res.json(data);
}));

// ─── 22. Nilai Inventori ──────────────────────────────────────────────────
router.get('/valuation', asyncHandler(async (req: Request, res: Response) => {
    const data = await inventoryReportsService.getInventoryValuation(getParams(req));
    res.json(data);
}));

export default router;
