import { Router, Request, Response } from 'express';
import { AppError, asyncHandler } from '../middleware/errorHandler.js';
import { financeReportsService } from '../services/financeReports.service.js';

const router = Router();

function getParams(req: Request) {
    return {
        start: req.query.start as string | undefined,
        end: req.query.end as string | undefined,
        branchId: req.query.branchId as string | undefined,
    };
}

// ─── 23. Laba Rugi ────────────────────────────────────────────────────────
router.get('/profit-loss', asyncHandler(async (req: Request, res: Response) => {
    const data = await financeReportsService.getProfitLoss(getParams(req));
    res.json(data);
}));

// ─── 24. HPP / COGS ───────────────────────────────────────────────────────
router.get('/cogs', asyncHandler(async (req: Request, res: Response) => {
    const data = await financeReportsService.getCogs(getParams(req));
    res.json(data);
}));

// ─── 25. Gross Margin ─────────────────────────────────────────────────────
router.get('/gross-margin', asyncHandler(async (req: Request, res: Response) => {
    const data = await financeReportsService.getGrossMargin(getParams(req));
    res.json(data);
}));

// ─── 26. Arus Kas ─────────────────────────────────────────────────────────
router.get('/cash-flow', asyncHandler(async (req: Request, res: Response) => {
    const data = await financeReportsService.getCashFlow(getParams(req));
    res.json(data);
}));

// ─── 27. Rekonsiliasi Kas ─────────────────────────────────────────────────
router.get('/cash-reconciliation', asyncHandler(async (req: Request, res: Response) => {
    const data = await financeReportsService.getCashReconciliation(getParams(req));
    res.json(data);
}));

// ─── 28. Piutang ──────────────────────────────────────────────────────────
router.get('/accounts-receivable', asyncHandler(async (req: Request, res: Response) => {
    const data = await financeReportsService.getAccountsReceivable(getParams(req));
    res.json(data);
}));

// ─── 29. Utang Supplier ───────────────────────────────────────────────────
router.get('/accounts-payable', asyncHandler(async (req: Request, res: Response) => {
    const data = await financeReportsService.getAccountsPayable(getParams(req));
    res.json(data);
}));

export default router;
