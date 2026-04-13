import { Router, Request, Response } from 'express';
import { reportsService } from '../services/reports.service.js';

const router = Router();

router.get('/daily', async (req: Request, res: Response) => {
    const date = req.query.date ? new Date(req.query.date as string) : new Date();
    const branchId = req.query.branchId as string | undefined;
    const summary = await reportsService.getDailySummary(date, branchId);
    res.json(summary);
});

router.get('/summary', async (req: Request, res: Response) => {
    const branchId = req.query.branchId as string | undefined;
    const summary = await reportsService.getDailySummary(new Date(), branchId);
    res.json(summary);
});

router.get('/top-products', async (req: Request, res: Response) => {
    const limit = req.query.limit ? parseInt(req.query.limit as string) : 10;
    const branchId = req.query.branchId as string | undefined;
    const topProducts = await reportsService.getTopProducts(limit, branchId);
    res.json(topProducts);
});

router.get('/revenue-chart', async (req: Request, res: Response) => {
    const days = req.query.days ? parseInt(req.query.days as string) : 7;
    const branchId = req.query.branchId as string | undefined;
    const chart = await reportsService.getRevenueChart(days, branchId);
    res.json(chart);
});

router.get('/critical-stock', async (req: Request, res: Response) => {
    const branchId = req.query.branchId as string | undefined;
    const criticalStock = await reportsService.getCriticalStock(branchId);
    res.json(criticalStock);
});

router.get('/hourly', async (req: Request, res: Response) => {
    const branchId = req.query.branchId as string | undefined;
    const hourly = await reportsService.getHourlyRevenue(branchId);
    res.json(hourly);
});

router.get('/monthly', async (req: Request, res: Response) => {
    const year = req.query.year ? parseInt(req.query.year as string) : undefined;
    const branchId = req.query.branchId as string | undefined;
    const monthly = await reportsService.getMonthlyRevenue(year, branchId);
    res.json(monthly);
});

// ═══ NEW REPORT ROUTES ═══

router.get('/daily-sales', async (req: Request, res: Response) => {
    const start = req.query.start ? new Date(req.query.start as string) : new Date();
    const end = req.query.end ? new Date(req.query.end as string) : new Date();
    const branchId = req.query.branchId as string | undefined;
    const data = await reportsService.getDailySales(start, end, branchId);
    res.json(data);
});

router.get('/hourly-sales', async (req: Request, res: Response) => {
    const date = req.query.date ? new Date(req.query.date as string) : new Date();
    const branchId = req.query.branchId as string | undefined;
    const data = await reportsService.getHourlySales(date, branchId);
    res.json(data);
});

router.get('/hourly-product-sales', async (req: Request, res: Response) => {
    const date = req.query.date ? new Date(req.query.date as string) : new Date();
    const branchId = req.query.branchId as string | undefined;
    const data = await reportsService.getHourlySalesByProduct(date, branchId);
    res.json(data);
});

router.get('/shift-report', async (req: Request, res: Response) => {
    const start = req.query.start ? new Date(req.query.start as string) : new Date();
    const end = req.query.end ? new Date(req.query.end as string) : new Date();
    const branchId = req.query.branchId as string | undefined;
    const data = await reportsService.getShiftReport(start, end, branchId);
    res.json(data);
});

router.get('/expense-report', async (req: Request, res: Response) => {
    const start = req.query.start ? new Date(req.query.start as string) : new Date();
    const end = req.query.end ? new Date(req.query.end as string) : new Date();
    const branchId = req.query.branchId as string | undefined;
    const data = await reportsService.getExpenseReport(start, end, branchId);
    res.json(data);
});

router.get('/profit-loss', async (req: Request, res: Response) => {
    const start = req.query.start ? new Date(req.query.start as string) : new Date();
    const end = req.query.end ? new Date(req.query.end as string) : new Date();
    const branchId = req.query.branchId as string | undefined;
    const data = await reportsService.getProfitLoss(start, end, branchId);
    res.json(data);
});

router.get('/inventory-report', async (req: Request, res: Response) => {
    const branchId = req.query.branchId as string | undefined;
    const data = await reportsService.getInventoryReport(branchId);
    res.json(data);
});

export default router;

