import { Router, Request, Response } from 'express';
import { AppError, asyncHandler } from '../middleware/errorHandler.js';
import { reportsService } from '../services/reports.service.js';
import { parseLocalDate, parseLocalDateRange } from '../utils/dateHelpers.js';
import { z } from 'zod';
import { validateQuery } from '../middleware/validate.middleware.js';

const router = Router();

const dateQuerySchema = z.object({
    date: z.string().optional(),
    branchId: z.string().optional(),
    limit: z.coerce.number().int().min(1).max(100).default(50),
    offset: z.coerce.number().int().min(0).default(0),
});

const dateRangeQuerySchema = z.object({
    start: z.string().optional(),
    end: z.string().optional(),
    branchId: z.string().optional(),
    limit: z.coerce.number().int().min(1).max(100).default(50),
    offset: z.coerce.number().int().min(0).default(0),
});

const defaultPaginationSchema = z.object({
    branchId: z.string().optional(),
    limit: z.coerce.number().int().min(1).max(100).default(50),
    offset: z.coerce.number().int().min(0).default(0),
});

const daysQuerySchema = z.object({
    days: z.coerce.number().int().min(1).max(365).default(7),
    branchId: z.string().optional()
});

const yearQuerySchema = z.object({
    year: z.coerce.number().int().min(2000).max(2100).optional(),
    branchId: z.string().optional()
});

const salesTargetQuerySchema = z.object({
    target: z.coerce.number().optional(),
    period: z.string().optional(),
    branchId: z.string().optional()
});

const periodComparisonQuerySchema = z.object({
    start1: z.string().optional(),
    end1: z.string().optional(),
    start2: z.string().optional(),
    end2: z.string().optional(),
    branchId: z.string().optional()
});

const salesForecastQuerySchema = z.object({
    historicalDays: z.coerce.number().optional(),
    forecastDays: z.coerce.number().optional(),
    branchId: z.string().optional()
});

const marketBasketQuerySchema = z.object({
    branchId: z.string().optional(),
    limit: z.coerce.number().int().min(1).max(100).default(50),
});

const productGrowthQuerySchema = z.object({
    currentStart: z.string().optional(),
    currentEnd: z.string().optional(),
    previousStart: z.string().optional(),
    previousEnd: z.string().optional(),
    branchId: z.string().optional(),
    topN: z.coerce.number().optional()
});

const seasonalityQuerySchema = z.object({
    groupBy: z.string().optional(),
    branchId: z.string().optional()
});


router.get('/daily', validateQuery(dateQuerySchema), async (req: Request, res: Response) => {
    const date = req.query.date ? parseLocalDate(req.query.date as string) : new Date();
    const branchId = req.query.branchId as string | undefined;
    const summary = await reportsService.getDailySummary(date, branchId);
    res.json(summary);
});

router.get('/summary', validateQuery(defaultPaginationSchema), async (req: Request, res: Response) => {
    const branchId = req.query.branchId as string | undefined;
    const summary = await reportsService.getDailySummary(new Date(), branchId);
    res.json(summary);
});

router.get('/top-products', validateQuery(defaultPaginationSchema), async (req: Request, res: Response) => {
    const limit = req.query.limit ? parseInt(req.query.limit as string) : 10;
    const branchId = req.query.branchId as string | undefined;
    const topProducts = await reportsService.getTopProducts(limit, branchId);
    res.json(topProducts);
});

router.get('/revenue-chart', validateQuery(daysQuerySchema), async (req: Request, res: Response) => {
    const days = req.query.days ? parseInt(req.query.days as string) : 7;
    const branchId = req.query.branchId as string | undefined;
    const chart = await reportsService.getRevenueChart(days, branchId);
    res.json(chart);
});

router.get('/critical-stock', validateQuery(defaultPaginationSchema), async (req: Request, res: Response) => {
    const branchId = req.query.branchId as string | undefined;
    const criticalStock = await reportsService.getCriticalStock(branchId);
    res.json(criticalStock);
});

router.get('/hourly', validateQuery(defaultPaginationSchema), async (req: Request, res: Response) => {
    const branchId = req.query.branchId as string | undefined;
    const hourly = await reportsService.getHourlyRevenue(branchId);
    res.json(hourly);
});

router.get('/monthly', validateQuery(yearQuerySchema), async (req: Request, res: Response) => {
    const year = req.query.year ? parseInt(req.query.year as string) : undefined;
    const branchId = req.query.branchId as string | undefined;
    const monthly = await reportsService.getMonthlyRevenue(year, branchId);
    res.json(monthly);
});

// ═══ NEW REPORT ROUTES ═══

router.get('/daily-sales', validateQuery(dateRangeQuerySchema), async (req: Request, res: Response) => {
    const { start, end } = parseLocalDateRange(
        req.query.start as string | undefined,
        req.query.end as string | undefined,
    );
    const branchId = req.query.branchId as string | undefined;
    const data = await reportsService.getDailySales(start, end, branchId);
    res.json(data);
});

router.get('/hourly-sales', validateQuery(dateQuerySchema), async (req: Request, res: Response) => {
    const date = req.query.date ? parseLocalDate(req.query.date as string) : new Date();
    const branchId = req.query.branchId as string | undefined;
    const data = await reportsService.getHourlySales(date, branchId);
    res.json(data);
});

router.get('/hourly-product-sales', validateQuery(dateQuerySchema), async (req: Request, res: Response) => {
    const date = req.query.date ? parseLocalDate(req.query.date as string) : new Date();
    const branchId = req.query.branchId as string | undefined;
    const data = await reportsService.getHourlySalesByProduct(date, branchId);
    res.json(data);
});

router.get('/shift-report', validateQuery(dateRangeQuerySchema), async (req: Request, res: Response) => {
    const { start, end } = parseLocalDateRange(
        req.query.start as string | undefined,
        req.query.end as string | undefined,
    );
    const branchId = req.query.branchId as string | undefined;
    const data = await reportsService.getShiftReport(start, end, branchId);
    res.json(data);
});

router.get('/expense-report', validateQuery(dateRangeQuerySchema), async (req: Request, res: Response) => {
    const { start, end } = parseLocalDateRange(
        req.query.start as string | undefined,
        req.query.end as string | undefined,
    );
    const branchId = req.query.branchId as string | undefined;
    const data = await reportsService.getExpenseReport(start, end, branchId);
    res.json(data);
});

router.get('/profit-loss', validateQuery(dateRangeQuerySchema), async (req: Request, res: Response) => {
    const { start, end } = parseLocalDateRange(
        req.query.start as string | undefined,
        req.query.end as string | undefined,
    );
    const branchId = req.query.branchId as string | undefined;
    const data = await reportsService.getProfitLoss(start, end, branchId);
    res.json(data);
});

router.get('/inventory-report', validateQuery(defaultPaginationSchema), async (req: Request, res: Response) => {
    const branchId = req.query.branchId as string | undefined;
    const data = await reportsService.getInventoryReport(branchId);
    res.json(data);
});

router.get('/cash-flow', async (req: Request, res: Response) => {
    const { start, end } = parseLocalDateRange(
        req.query.start as string | undefined,
        req.query.end as string | undefined,
        7,  // default 7 hari
    );
    const branchId = req.query.branchId as string | undefined;
    const data = await reportsService.getCashFlow(start, end, branchId);
    res.json(data);
});

router.get('/expense-summary', async (req: Request, res: Response) => {
    const { start, end } = parseLocalDateRange(
        req.query.start as string | undefined,
        req.query.end as string | undefined,
    );
    const branchId = req.query.branchId as string | undefined;
    const data = await reportsService.getExpenseSummaryByCategory(start, end, branchId);
    res.json(data);
});

// ─────────────────────────────────────────────────────────────
// NEW ENDPOINTS
// ─────────────────────────────────────────────────────────────

// ENDPOINT 1: Best Sellers
// GET /reports/best-sellers?start=YYYY-MM-DD&end=YYYY-MM-DD&limit=10&branchId=...
router.get('/best-sellers', async (req: Request, res: Response) => {
    const { start, end } = parseLocalDateRange(
        req.query.start as string | undefined,
        req.query.end as string | undefined,
    );
    const limit = req.query.limit ? parseInt(req.query.limit as string) : 10;
    const branchId = req.query.branchId as string | undefined;
    const data = await reportsService.getBestSellers(start, end, limit, branchId);
    res.json(data);
});

// ENDPOINT 2: Payment Method Breakdown
// GET /reports/payment-methods?start=YYYY-MM-DD&end=YYYY-MM-DD&branchId=...
router.get('/payment-methods', async (req: Request, res: Response) => {
    const { start, end } = parseLocalDateRange(
        req.query.start as string | undefined,
        req.query.end as string | undefined,
    );
    const branchId = req.query.branchId as string | undefined;
    const data = await reportsService.getPaymentMethodBreakdown(start, end, branchId);
    res.json(data);
});

// ENDPOINT 3: Audit Log (Shift Activity)
// GET /reports/audit-log?start=YYYY-MM-DD&end=YYYY-MM-DD&staffId=...&branchId=...
router.get('/audit-log', async (req: Request, res: Response) => {
    const { start, end } = parseLocalDateRange(
        req.query.start as string | undefined,
        req.query.end as string | undefined,
    );
    const staffId = req.query.staffId as string | undefined;
    const branchId = req.query.branchId as string | undefined;
    const data = await reportsService.getAuditLog(start, end, staffId, branchId);
    res.json(data);
});

// ─────────────────────────────────────────────────────────────
// LAPORAN PENJUALAN — 7 Endpoint Baru
// ─────────────────────────────────────────────────────────────

// GET /reports/sales-by-category?start=YYYY-MM-DD&end=YYYY-MM-DD&branchId=...
router.get('/sales-by-category', async (req: Request, res: Response) => {
    const { start, end } = parseLocalDateRange(
        req.query.start as string | undefined,
        req.query.end as string | undefined,
    );
    const branchId = req.query.branchId as string | undefined;
    const data = await reportsService.getSalesByCategory(start, end, branchId);
    res.json(data);
});

// GET /reports/sales-by-staff?start=YYYY-MM-DD&end=YYYY-MM-DD&branchId=...
router.get('/sales-by-staff', async (req: Request, res: Response) => {
    const { start, end } = parseLocalDateRange(
        req.query.start as string | undefined,
        req.query.end as string | undefined,
    );
    const branchId = req.query.branchId as string | undefined;
    const data = await reportsService.getSalesByStaff(start, end, branchId);
    res.json(data);
});

// GET /reports/transaction-details
// Query params: start, end, page, limit, branchId, staffId, paymentMethod, search, sortBy, sortOrder
router.get('/transaction-details', validateQuery(dateRangeQuerySchema), asyncHandler(async (req: Request, res: Response) => {
    const { start, end } = parseLocalDateRange(
        req.query.start as string | undefined,
        req.query.end as string | undefined,
    );
    const page          = req.query.page   ? parseInt(req.query.page   as string) : 1;
    const limit         = req.query.limit  ? parseInt(req.query.limit  as string) : 20;
    const branchId      = req.query.branchId      as string | undefined;
    const staffId       = req.query.staffId       as string | undefined;
    const paymentMethod = req.query.paymentMethod as string | undefined;
    const search        = req.query.search        as string | undefined;
    const sortBy        = (req.query.sortBy        as string) || 'createdAt';
    const sortOrder     = (req.query.sortOrder     as string) || 'desc';

    const data = await reportsService.getTransactionDetailsFiltered({
        start, end, page, limit, branchId, staffId, paymentMethod, search, sortBy, sortOrder
    });
    res.json(data);
}));

// GET /reports/void-transactions?start=YYYY-MM-DD&end=YYYY-MM-DD&branchId=...
router.get('/void-transactions', validateQuery(dateRangeQuerySchema), async (req: Request, res: Response) => {
    const { start, end } = parseLocalDateRange(
        req.query.start as string | undefined,
        req.query.end as string | undefined,
    );
    const branchId = req.query.branchId as string | undefined;
    const data = await reportsService.getVoidTransactions(start, end, branchId);
    res.json(data);
});

// GET /reports/refund-transactions?start=YYYY-MM-DD&end=YYYY-MM-DD&branchId=...
router.get('/refund-transactions', validateQuery(dateRangeQuerySchema), async (req: Request, res: Response) => {
    const { start, end } = parseLocalDateRange(
        req.query.start as string | undefined,
        req.query.end as string | undefined,
    );
    const branchId = req.query.branchId as string | undefined;
    const data = await reportsService.getRefundTransactions(start, end, branchId);
    res.json(data);
});

// GET /reports/discount-summary?start=YYYY-MM-DD&end=YYYY-MM-DD&branchId=...
router.get('/discount-summary', validateQuery(dateRangeQuerySchema), async (req: Request, res: Response) => {
    const { start, end } = parseLocalDateRange(
        req.query.start as string | undefined,
        req.query.end as string | undefined,
    );
    const branchId = req.query.branchId as string | undefined;
    const data = await reportsService.getDiscountSummary(start, end, branchId);
    res.json(data);
});

// GET /reports/busiest-days?start=YYYY-MM-DD&end=YYYY-MM-DD&branchId=...
router.get('/busiest-days', validateQuery(dateRangeQuerySchema), async (req: Request, res: Response) => {
    const { start, end } = parseLocalDateRange(
        req.query.start as string | undefined,
        req.query.end as string | undefined,
    );
    const branchId = req.query.branchId as string | undefined;
    const data = await reportsService.getBusiestDays(start, end, branchId);
    res.json(data);
});

// GET /reports/filter-options — daftar kasir aktif, metode pembayaran & cabang untuk dropdown filter
router.get('/filter-options', validateQuery(defaultPaginationSchema), asyncHandler(async (req: Request, res: Response) => {
    const data = await reportsService.getFilterOptions();
    res.json(data);
}));

// ─── Modul 14: Visualisasi Data & Eksekutif Dashboard ─────────────────────────

// GET /reports/kpi-summary?start=YYYY-MM-DD&end=YYYY-MM-DD&branchId=...
router.get('/kpi-summary', validateQuery(dateRangeQuerySchema), asyncHandler(async (req: Request, res: Response) => {
    const { start, end } = parseLocalDateRange(
        req.query.start as string | undefined,
        req.query.end   as string | undefined,
    );
    const branchId = req.query.branchId as string | undefined;
    const data = await reportsService.getKpiSummary(start, end, branchId);
    res.json(data);
}));

// GET /reports/distribution?start=YYYY-MM-DD&end=YYYY-MM-DD&branchId=...
router.get('/distribution', validateQuery(dateRangeQuerySchema), asyncHandler(async (req: Request, res: Response) => {
    const { start, end } = parseLocalDateRange(
        req.query.start as string | undefined,
        req.query.end   as string | undefined,
    );
    const branchId = req.query.branchId as string | undefined;
    const data = await reportsService.getDistribution(start, end, branchId);
    res.json(data);
}));

// GET /reports/heatmap?start=YYYY-MM-DD&end=YYYY-MM-DD&branchId=...
router.get('/heatmap', validateQuery(dateRangeQuerySchema), asyncHandler(async (req: Request, res: Response) => {
    const { start, end } = parseLocalDateRange(
        req.query.start as string | undefined,
        req.query.end   as string | undefined,
        30,  // default 30 hari agar heatmap memiliki data yang representatif
    );
    const branchId = req.query.branchId as string | undefined;
    const data = await reportsService.getHeatmap(start, end, branchId);
    res.json(data);
}));

// GET /reports/sales-target?target=50000000&period=monthly&branchId=...
router.get('/sales-target', validateQuery(salesTargetQuerySchema), asyncHandler(async (req: Request, res: Response) => {
    const target   = req.query.target ? parseInt(req.query.target as string) : 50_000_000;
    const period   = (req.query.period === 'weekly') ? 'weekly' : 'monthly';
    const branchId = req.query.branchId as string | undefined;
    const data = await reportsService.getSalesTarget(target, period, branchId);
    res.json(data);
}));

// ─── Modul 15: Analitik Lanjutan ───────────────────────────────────────────

// GET /reports/period-comparison?start1=&end1=&start2=&end2=&branchId=
router.get('/period-comparison', validateQuery(periodComparisonQuerySchema), asyncHandler(async (req: Request, res: Response) => {
    const start1 = parseLocalDate((req.query.start1 as string) || '');
    const end1   = parseLocalDate((req.query.end1   as string) || '');
    const start2 = parseLocalDate((req.query.start2 as string) || '');
    const end2   = parseLocalDate((req.query.end2   as string) || '');
    if (!req.query.start1 || !req.query.end1 || !req.query.start2 || !req.query.end2) {
        throw AppError.validation('Parameter start1, end1, start2, end2 wajib diisi (YYYY-MM-DD)');
    }
    end1.setHours(23, 59, 59, 999);
    end2.setHours(23, 59, 59, 999);
    const branchId = req.query.branchId as string | undefined;
    const data = await reportsService.getPeriodComparison(start1, end1, start2, end2, branchId);
    res.json(data);
}));

// GET /reports/sales-forecast?historicalDays=30&forecastDays=7&branchId=
router.get('/sales-forecast', validateQuery(salesForecastQuerySchema), asyncHandler(async (req: Request, res: Response) => {
    const historicalDays = req.query.historicalDays ? parseInt(req.query.historicalDays as string) : 30;
    const forecastDays   = req.query.forecastDays   ? parseInt(req.query.forecastDays   as string) : 7;
    const branchId       = req.query.branchId as string | undefined;
    const data = await reportsService.getSalesForecast(historicalDays, forecastDays, branchId);
    res.json(data);
}));

// GET /reports/market-basket?branchId=&limit=50
router.get('/market-basket', validateQuery(marketBasketQuerySchema), asyncHandler(async (req: Request, res: Response) => {
    const branchId = req.query.branchId as string | undefined;
    const limit    = req.query.limit ? parseInt(req.query.limit as string) : 50;
    const data = await reportsService.getMarketBasket(branchId, limit);
    res.json(data);
}));

// GET /reports/product-growth?currentStart=&currentEnd=&previousStart=&previousEnd=&branchId=&topN=10
router.get('/product-growth', validateQuery(productGrowthQuerySchema), asyncHandler(async (req: Request, res: Response) => {
    if (!req.query.currentStart || !req.query.currentEnd || !req.query.previousStart || !req.query.previousEnd) {
        throw AppError.validation('Parameter currentStart, currentEnd, previousStart, previousEnd wajib diisi (YYYY-MM-DD)');
    }
    const currentStart  = parseLocalDate(req.query.currentStart  as string);
    const currentEnd    = parseLocalDate(req.query.currentEnd    as string);
    const previousStart = parseLocalDate(req.query.previousStart as string);
    const previousEnd   = parseLocalDate(req.query.previousEnd   as string);
    currentEnd.setHours(23, 59, 59, 999);
    previousEnd.setHours(23, 59, 59, 999);
    const branchId = req.query.branchId as string | undefined;
    const topN     = req.query.topN ? parseInt(req.query.topN as string) : 10;
    const data = await reportsService.getProductGrowth(currentStart, currentEnd, previousStart, previousEnd, branchId, topN);
    res.json(data);
}));

// GET /reports/seasonality?groupBy=day_of_week&branchId=
router.get('/seasonality', validateQuery(seasonalityQuerySchema), asyncHandler(async (req: Request, res: Response) => {
    const groupBy  = (req.query.groupBy === 'month') ? 'month' : 'day_of_week';
    const branchId = req.query.branchId as string | undefined;
    const data = await reportsService.getSeasonality(groupBy, branchId);
    res.json(data);
}));

export default router;
