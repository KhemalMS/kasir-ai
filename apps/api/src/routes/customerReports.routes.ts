import { Router, Request, Response } from 'express';
import { AppError, asyncHandler } from '../middleware/errorHandler.js';
import { customerReportsService } from '../services/customerReports.service.js';

const router = Router();

function getParams(req: Request) {
    return {
        start: req.query.start as string | undefined,
        end: req.query.end as string | undefined,
        branchId: req.query.branchId as string | undefined,
    };
}

// ─── 30. Daftar Pelanggan ─────────────────────────────────────────────────
router.get('/list', asyncHandler(async (req: Request, res: Response) => {
    const data = await customerReportsService.getCustomerList(getParams(req));
    res.json(data);
}));

// ─── 31. Paling Sering Beli ──────────────────────────────────────────────
router.get('/top-frequency', asyncHandler(async (req: Request, res: Response) => {
    const data = await customerReportsService.getTopFrequency(getParams(req));
    res.json(data);
}));

// ─── 32. Top Spender ─────────────────────────────────────────────────────
router.get('/top-spender', asyncHandler(async (req: Request, res: Response) => {
    const data = await customerReportsService.getTopSpender(getParams(req));
    res.json(data);
}));

// ─── 33. Analisis RFM ────────────────────────────────────────────────────
router.get('/rfm', asyncHandler(async (req: Request, res: Response) => {
    const data = await customerReportsService.getRFM(getParams(req));
    res.json(data);
}));

// ─── 34. Loyalty & Poin ──────────────────────────────────────────────────
router.get('/loyalty', asyncHandler(async (req: Request, res: Response) => {
    const data = await customerReportsService.getLoyaltyStatus(getParams(req));
    res.json(data);
}));

// ─── 35. Retensi Pelanggan ───────────────────────────────────────────────
router.get('/retention', asyncHandler(async (req: Request, res: Response) => {
    const data = await customerReportsService.getRetentionRate(getParams(req));
    res.json(data);
}));

// ─── 36. Akuisisi Pelanggan Baru ─────────────────────────────────────────
router.get('/acquisition', asyncHandler(async (req: Request, res: Response) => {
    const data = await customerReportsService.getNewAcquisitions(getParams(req));
    res.json(data);
}));

// ─── 37. Ulang Tahun Pelanggan ───────────────────────────────────────────
router.get('/birthdays', asyncHandler(async (req: Request, res: Response) => {
    const data = await customerReportsService.getUpcomingBirthdays(getParams(req));
    res.json(data);
}));

export default router;
