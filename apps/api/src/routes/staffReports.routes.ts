import { Router, Request, Response } from 'express';
import { AppError, asyncHandler } from '../middleware/errorHandler.js';
import * as staffReportsService from '../services/staffReports.service.js';

const router = Router();

// GET /api/reports/staff/performance
router.get('/performance', asyncHandler(async (req: Request, res: Response) => {
    const data = await staffReportsService.getCashierPerformance(req.query as any);
    res.json(data);
}));

// GET /api/reports/staff/attendance
router.get('/attendance', asyncHandler(async (req: Request, res: Response) => {
    const data = await staffReportsService.getAttendanceReport(req.query as any);
    res.json(data);
}));

// GET /api/reports/staff/commissions
router.get('/commissions', asyncHandler(async (req: Request, res: Response) => {
    const data = await staffReportsService.getSalesCommissions(req.query as any);
    res.json(data);
}));

// GET /api/reports/staff/activity-logs
router.get('/activity-logs', asyncHandler(async (req: Request, res: Response) => {
    const data = await staffReportsService.getActivityLogs(req.query as any);
    res.json(data);
}));

export default router;
