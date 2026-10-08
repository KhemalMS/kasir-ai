import { db } from '../db/index.js';
import { orders } from '../db/schema/orders.js';
import { orderItems } from '../db/schema/orderItems.js';
import { payments } from '../db/schema/payments.js';
import { products } from '../db/schema/products.js';
import { categories } from '../db/schema/categories.js';
import { inventory } from '../db/schema/inventory.js';
import { shifts } from '../db/schema/shifts.js';
import { staff } from '../db/schema/staff.js';
import { expenses } from '../db/schema/expenses.js';
import { branches } from '../db/schema/branches.js';
import { marketBasketCache } from '../db/schema/marketBasketCache.js';
import { eq, and, between, desc, asc, sum, count, avg, sql, lte, gte, like } from 'drizzle-orm';

interface TransactionFilterParams {
    start: Date;
    end: Date;
    page: number;
    limit: number;
    branchId?: string;
    staffId?: string;
    paymentMethod?: string;
    search?: string;
    sortBy?: string;
    sortOrder?: string;
}

export const reportsService = {
    async getDailySummary(date: Date, branchId?: string) {
        const startOfDay = new Date(date);
        startOfDay.setHours(0, 0, 0, 0);
        const endOfDay = new Date(date);
        endOfDay.setHours(23, 59, 59, 999);

        const conditions = [
            between(orders.createdAt, startOfDay, endOfDay),
            eq(orders.status, 'Sukses'),
        ];
        if (branchId) conditions.push(eq(orders.branchId, branchId));

        const [result] = await db
            .select({
                totalRevenue: sum(orders.totalAmount),
                totalTransactions: count(orders.id),
                avgCart: sql<number>`COALESCE(AVG(${orders.totalAmount}), 0)`,
            })
            .from(orders)
            .where(and(...conditions));

        return {
            totalRevenue: Number(result?.totalRevenue) || 0,
            totalTransactions: Number(result?.totalTransactions) || 0,
            avgCart: Math.round(Number(result?.avgCart) || 0),
            date: date.toISOString().split('T')[0],
        };
    },

    async getTopProducts(limit: number = 10, branchId?: string, offset: number = 0) {
        const conditions = [eq(orders.status, 'Sukses')];
        if (branchId) conditions.push(eq(orders.branchId, branchId));

        return db
            .select({
                productId: orderItems.productId,
                productName: products.name,
                totalQuantity: sum(orderItems.quantity),
                totalRevenue: sql<number>`SUM(${orderItems.quantity} * ${orderItems.priceAtOrder})`,
            })
            .from(orderItems)
            .innerJoin(orders, eq(orderItems.orderId, orders.id))
            .innerJoin(products, eq(orderItems.productId, products.id))
            .where(and(...conditions))
            .groupBy(orderItems.productId, products.name)
            .orderBy(desc(sql`SUM(${orderItems.quantity})`))
            .limit(limit)
            .offset(offset);
    },

    async getCriticalStock(branchId?: string, limit: number = 50, offset: number = 0) {
        const conditions = [
            lte(inventory.quantity, sql`${inventory.reorderThreshold}`),
        ];
        if (branchId) conditions.push(eq(inventory.branchId, branchId));

        return db
            .select()
            .from(inventory)
            .where(and(...conditions))
            .limit(limit)
            .offset(offset);
    },

    async getRevenueChart(days: number = 7, branchId?: string) {
        // Single GROUP BY query instead of N per-day queries
        const end = new Date();
        end.setHours(23, 59, 59, 999);
        const start = new Date();
        start.setDate(start.getDate() - (days - 1));
        start.setHours(0, 0, 0, 0);

        const conditions: any[] = [
            gte(orders.createdAt, start),
            lte(orders.createdAt, end),
            eq(orders.status, 'Sukses'),
        ];
        if (branchId) conditions.push(eq(orders.branchId, branchId));

        const rows = await db
            .select({
                dateStr: sql<string>`DATE_FORMAT(${orders.createdAt}, '%Y-%m-%d')`,
                totalRevenue: sum(orders.totalAmount),
                totalTransactions: count(orders.id),
                avgCart: sql<number>`COALESCE(AVG(${orders.totalAmount}), 0)`,
            })
            .from(orders)
            .where(and(...conditions))
            .groupBy(sql`DATE(${orders.createdAt})`)
            .orderBy(sql`DATE(${orders.createdAt})`);

        // Fill full range; days with no orders get zeros
        const rowMap = new Map(rows.map(r => [r.dateStr, r]));
        const results = [];
        for (let i = days - 1; i >= 0; i--) {
            const d = new Date();
            d.setDate(d.getDate() - i);
            const dateStr = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
            const row = rowMap.get(dateStr);
            results.push({
                date: dateStr,
                totalRevenue: Number(row?.totalRevenue) || 0,
                totalTransactions: Number(row?.totalTransactions) || 0,
                avgCart: Math.round(Number(row?.avgCart) || 0),
            });
        }
        return results;
    },

    async getHourlyRevenue(branchId?: string) {
        const conditions: any[] = [
            sql`DATE(${orders.createdAt}) = CURDATE()`,
            eq(orders.status, 'Sukses'),
        ];
        if (branchId) conditions.push(eq(orders.branchId, branchId));

        const rows = await db
            .select({
                hour: sql<number>`HOUR(${orders.createdAt})`,
                totalRevenue: sum(orders.totalAmount),
                totalTransactions: count(orders.id),
            })
            .from(orders)
            .where(and(...conditions))
            .groupBy(sql`HOUR(${orders.createdAt})`)
            .orderBy(sql`HOUR(${orders.createdAt})`);

        const hourMap = new Map(rows.map(r => [Number(r.hour), r]));
        const results = [];
        for (let hour = 0; hour < 24; hour++) {
            const row = hourMap.get(hour);
            results.push({
                hour,
                label: `${hour.toString().padStart(2, '0')}:00`,
                totalRevenue: Number(row?.totalRevenue) || 0,
                totalTransactions: Number(row?.totalTransactions) || 0,
            });
        }
        return results;
    },

    async getMonthlyRevenue(year?: number, branchId?: string) {
        // Single GROUP BY MONTH query instead of 12 sequential queries
        const targetYear = year || new Date().getFullYear();
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
        const yearStart = new Date(targetYear, 0, 1, 0, 0, 0, 0);
        const yearEnd = new Date(targetYear, 11, 31, 23, 59, 59, 999);

        const conditions: any[] = [
            gte(orders.createdAt, yearStart),
            lte(orders.createdAt, yearEnd),
            eq(orders.status, 'Sukses'),
        ];
        if (branchId) conditions.push(eq(orders.branchId, branchId));

        const rows = await db
            .select({
                monthNum: sql<number>`MONTH(${orders.createdAt})`,
                totalRevenue: sum(orders.totalAmount),
                totalTransactions: count(orders.id),
            })
            .from(orders)
            .where(and(...conditions))
            .groupBy(sql`MONTH(${orders.createdAt})`)
            .orderBy(sql`MONTH(${orders.createdAt})`);

        const rowMap = new Map(rows.map(r => [Number(r.monthNum), r]));
        return Array.from({ length: 12 }, (_, i) => {
            const row = rowMap.get(i + 1);
            return {
                month: i + 1,
                label: months[i],
                totalRevenue: Number(row?.totalRevenue) || 0,
                totalTransactions: Number(row?.totalTransactions) || 0,
            };
        });
    },

    async getDailySales(startDate: Date, endDate: Date, branchId?: string) {
        // Single GROUP BY DATE query instead of N per-day queries
        const start = new Date(startDate);
        start.setHours(0, 0, 0, 0);
        const end = new Date(endDate);
        end.setHours(23, 59, 59, 999);

        const conditions: any[] = [
            gte(orders.createdAt, start),
            lte(orders.createdAt, end),
            eq(orders.status, 'Sukses'),
        ];
        if (branchId) conditions.push(eq(orders.branchId, branchId));

        const rows = await db
            .select({
                dateStr: sql<string>`DATE_FORMAT(${orders.createdAt}, '%Y-%m-%d')`,
                totalRevenue: sum(orders.totalAmount),
                totalTransactions: count(orders.id),
                avgCart: sql<number>`COALESCE(AVG(${orders.totalAmount}), 0)`,
            })
            .from(orders)
            .where(and(...conditions))
            .groupBy(sql`DATE(${orders.createdAt})`)
            .orderBy(sql`DATE(${orders.createdAt})`);

        const rowMap = new Map(rows.map(r => [r.dateStr, r]));

        // Fill full range (days with no orders get zeros)
        const results = [];
        const current = new Date(start);
        while (current <= end) {
            const dateStr = `${current.getFullYear()}-${String(current.getMonth() + 1).padStart(2, '0')}-${String(current.getDate()).padStart(2, '0')}`;
            const row = rowMap.get(dateStr);
            results.push({
                date: dateStr,
                totalRevenue: Number(row?.totalRevenue) || 0,
                totalTransactions: Number(row?.totalTransactions) || 0,
                avgCart: Math.round(Number(row?.avgCart) || 0),
            });
            current.setDate(current.getDate() + 1);
        }
        return results;
    },

    async getHourlySales(date: Date, branchId?: string, limit: number = 50, offset: number = 0) {
        const dateStr = date.toISOString().split('T')[0];
        const conditions: any[] = [
            sql`DATE(${orders.createdAt}) = ${dateStr}`,
            eq(orders.status, 'Sukses'),
        ];
        if (branchId) conditions.push(eq(orders.branchId, branchId));

        const rows = await db
            .select({
                hour: sql<number>`HOUR(${orders.createdAt})`,
                totalRevenue: sum(orders.totalAmount),
                totalTransactions: count(orders.id),
            })
            .from(orders)
            .where(and(...conditions))
            .groupBy(sql`HOUR(${orders.createdAt})`)
            .orderBy(sql`HOUR(${orders.createdAt})`);

        const hourMap = new Map(rows.map(r => [Number(r.hour), r]));
        const results = [];
        for (let hour = 0; hour < 24; hour++) {
            const row = hourMap.get(hour);
            results.push({
                hour,
                label: `${hour.toString().padStart(2, '0')}:00`,
                totalRevenue: Number(row?.totalRevenue) || 0,
                totalTransactions: Number(row?.totalTransactions) || 0,
            });
        }
        return results;
    },

    async getHourlySalesByProduct(date: Date, branchId?: string) {
        const startOfDay = new Date(date);
        startOfDay.setHours(0, 0, 0, 0);
        const endOfDay = new Date(date);
        endOfDay.setHours(23, 59, 59, 999);

        const conditions: any[] = [
            between(orders.createdAt, startOfDay, endOfDay),
            eq(orders.status, 'Sukses'),
        ];
        if (branchId) conditions.push(eq(orders.branchId, branchId));

        const rows = await db
            .select({
                hour: sql<number>`HOUR(${orders.createdAt})`,
                productId: orderItems.productId,
                productName: products.name,
                totalQuantity: sum(orderItems.quantity),
                totalRevenue: sql<number>`SUM(${orderItems.quantity} * ${orderItems.priceAtOrder})`,
            })
            .from(orderItems)
            .innerJoin(orders, eq(orderItems.orderId, orders.id))
            .innerJoin(products, eq(orderItems.productId, products.id))
            .where(and(...conditions))
            .groupBy(sql`HOUR(${orders.createdAt})`, orderItems.productId, products.name)
            .orderBy(sql`HOUR(${orders.createdAt})`, desc(sql`SUM(${orderItems.quantity})`));

        return rows.map(r => ({
            hour: Number(r.hour),
            label: `${Number(r.hour).toString().padStart(2, '0')}:00`,
            productId: r.productId,
            productName: r.productName,
            totalQuantity: Number(r.totalQuantity) || 0,
            totalRevenue: Number(r.totalRevenue) || 0,
        }));
    },

    async getShiftReport(startDate: Date, endDate: Date, branchId?: string) {
        const start = new Date(startDate);
        start.setHours(0, 0, 0, 0);
        const end = new Date(endDate);
        end.setHours(23, 59, 59, 999);

        const conditions: any[] = [between(shifts.startedAt, start, end)];
        if (branchId) conditions.push(eq(shifts.branchId, branchId));

        const rows = await db
            .select({
                id: shifts.id,
                staffName: staff.name,
                staffEmail: staff.email,
                startingCash: shifts.startingCash,
                endingCash: shifts.endingCash,
                expectedCash: shifts.expectedCash,
                cashDifference: shifts.cashDifference,
                totalCashSales: shifts.totalCashSales,
                totalQrisSales: shifts.totalQrisSales,
                totalExpenses: shifts.totalExpenses,
                status: shifts.status,
                startedAt: shifts.startedAt,
                closedAt: shifts.closedAt,
            })
            .from(shifts)
            .innerJoin(staff, eq(shifts.staffId, staff.id))
            .where(and(...conditions))
            .orderBy(desc(shifts.startedAt));

        return rows;
    },

    async getExpenseReport(startDate: Date, endDate: Date, branchId?: string) {
        const start = new Date(startDate);
        start.setHours(0, 0, 0, 0);
        const end = new Date(endDate);
        end.setHours(23, 59, 59, 999);

        const conditions: any[] = [between(expenses.createdAt, start, end)];
        if (branchId) conditions.push(eq(expenses.branchId, branchId));

        const rows = await db
            .select({
                id: expenses.id,
                staffName: staff.name,
                amount: expenses.amount,
                category: expenses.category,
                description: expenses.description,
                source: expenses.source,
                status: expenses.status,
                createdAt: expenses.createdAt,
            })
            .from(expenses)
            .innerJoin(staff, eq(expenses.staffId, staff.id))
            .where(and(...conditions))
            .orderBy(desc(expenses.createdAt));

        return rows;
    },

    async getProfitLoss(startDate: Date, endDate: Date, branchId?: string) {
        const start = new Date(startDate);
        start.setHours(0, 0, 0, 0);
        const end = new Date(endDate);
        end.setHours(23, 59, 59, 999);

        const revConditions: any[] = [
            between(orders.createdAt, start, end),
            eq(orders.status, 'Sukses'),
        ];
        if (branchId) revConditions.push(eq(orders.branchId, branchId));

        const [rev] = await db
            .select({ total: sum(orders.totalAmount) })
            .from(orders)
            .where(and(...revConditions));

        const expConditions: any[] = [between(expenses.createdAt, start, end)];
        if (branchId) expConditions.push(eq(expenses.branchId, branchId));

        const [exp] = await db
            .select({ total: sum(expenses.amount) })
            .from(expenses)
            .where(and(...expConditions));

        const totalRevenue = Number(rev?.total) || 0;
        const totalExpenses = Number(exp?.total) || 0;

        return {
            totalRevenue,
            totalExpenses,
            profit: totalRevenue - totalExpenses,
            startDate: startDate.toISOString().split('T')[0],
            endDate: endDate.toISOString().split('T')[0],
        };
    },

    async getInventoryReport(branchId?: string, limit: number = 50, offset: number = 0) {
        const conditions: any[] = [];
        if (branchId) conditions.push(eq(inventory.branchId, branchId));

        const rows = conditions.length > 0
            ? await db.select().from(inventory).where(and(...conditions))
            : await db.select().from(inventory);

        return rows.map(r => ({
            id: r.id,
            name: r.name,
            sku: r.sku,
            quantity: Number(r.quantity) || 0,
            unit: r.unit,
            reorderThreshold: Number(r.reorderThreshold) || 0,
            isCritical: Number(r.quantity) <= Number(r.reorderThreshold),
        }));
    },

    async getCashFlow(startDate: Date, endDate: Date, branchId?: string) {
        // 2 single GROUP BY queries instead of 2N per-day queries
        const start = new Date(startDate);
        start.setHours(0, 0, 0, 0);
        const end = new Date(endDate);
        end.setHours(23, 59, 59, 999);

        // Revenue grouped by date
        const revConditions: any[] = [
            gte(orders.createdAt, start),
            lte(orders.createdAt, end),
            eq(orders.status, 'Sukses'),
        ];
        if (branchId) revConditions.push(eq(orders.branchId, branchId));

        const revRows = await db
            .select({
                dateStr: sql<string>`DATE_FORMAT(${orders.createdAt}, '%Y-%m-%d')`,
                total: sum(orders.totalAmount),
                cnt: count(orders.id),
            })
            .from(orders)
            .where(and(...revConditions))
            .groupBy(sql`DATE(${orders.createdAt})`);

        // Expenses grouped by date
        const expConditions: any[] = [
            gte(expenses.createdAt, start),
            lte(expenses.createdAt, end),
        ];
        if (branchId) expConditions.push(eq(expenses.branchId, branchId));

        const expRows = await db
            .select({
                dateStr: sql<string>`DATE_FORMAT(${expenses.createdAt}, '%Y-%m-%d')`,
                total: sum(expenses.amount),
                cnt: count(expenses.id),
            })
            .from(expenses)
            .where(and(...expConditions))
            .groupBy(sql`DATE(${expenses.createdAt})`);

        // Merge into full date range (gaps filled with zeros)
        const revMap = new Map(revRows.map(r => [r.dateStr, r]));
        const expMap = new Map(expRows.map(r => [r.dateStr, r]));

        const results = [];
        const current = new Date(start);
        while (current <= end) {
            const dateStr = `${current.getFullYear()}-${String(current.getMonth() + 1).padStart(2, '0')}-${String(current.getDate()).padStart(2, '0')}`;
            const rev = revMap.get(dateStr);
            const exp = expMap.get(dateStr);
            const cashIn = Number(rev?.total) || 0;
            const cashOut = Number(exp?.total) || 0;
            results.push({
                date: dateStr,
                label: current.toLocaleDateString('id-ID', { day: 'numeric', month: 'short' }),
                cashIn,
                cashOut,
                netFlow: cashIn - cashOut,
                transactionCount: Number(rev?.cnt) || 0,
                expenseCount: Number(exp?.cnt) || 0,
            });
            current.setDate(current.getDate() + 1);
        }

        let runningBalance = 0;
        for (const row of results) {
            runningBalance += row.netFlow;
            (row as any).runningBalance = runningBalance;
        }

        return results;
    },

    async getExpenseSummaryByCategory(startDate: Date, endDate: Date, branchId?: string) {
        const start = new Date(startDate);
        start.setHours(0, 0, 0, 0);
        const end = new Date(endDate);
        end.setHours(23, 59, 59, 999);

        const conditions: any[] = [between(expenses.createdAt, start, end)];
        if (branchId) conditions.push(eq(expenses.branchId, branchId));

        const rows = await db
            .select({
                category: expenses.category,
                total: sum(expenses.amount),
                count: count(expenses.id),
            })
            .from(expenses)
            .where(and(...conditions))
            .groupBy(expenses.category)
            .orderBy(desc(sum(expenses.amount)));

        const totalExpenses = rows.reduce((acc, r) => acc + (Number(r.total) || 0), 0);

        return {
            categories: rows.map(r => ({
                category: r.category,
                total: Number(r.total) || 0,
                count: Number(r.count) || 0,
                percentage: totalExpenses > 0 ? Math.round(((Number(r.total) || 0) / totalExpenses) * 100) : 0,
            })),
            totalExpenses,
        };
    },

    // ─── Best Sellers ─────────────────────────────────────────────────────────
    async getBestSellers(startDate: Date, endDate: Date, limit: number = 10, branchId?: string) {
        const start = new Date(startDate); start.setHours(0, 0, 0, 0);
        const end   = new Date(endDate);   end.setHours(23, 59, 59, 999);

        const conditions: any[] = [between(orders.createdAt, start, end), eq(orders.status, 'Sukses')];
        if (branchId) conditions.push(eq(orders.branchId, branchId));

        const rows = await db
            .select({
                productId:     orderItems.productId,
                productName:   products.name,
                totalQuantity: sql<number>`CAST(SUM(${orderItems.quantity}) AS UNSIGNED)`,
                totalRevenue:  sql<number>`CAST(SUM(${orderItems.quantity} * ${orderItems.priceAtOrder}) AS UNSIGNED)`,
            })
            .from(orderItems)
            .innerJoin(orders,   eq(orderItems.orderId,   orders.id))
            .innerJoin(products, eq(orderItems.productId, products.id))
            .where(and(...conditions))
            .groupBy(orderItems.productId, products.name)
            .orderBy(desc(sql`SUM(${orderItems.quantity})`))
            ;

        return rows.map(r => ({
            productId:     r.productId,
            productName:   r.productName,
            totalQuantity: Number(r.totalQuantity) || 0,
            totalRevenue:  Number(r.totalRevenue)  || 0,
        }));
    },

    // ─── Payment Method Breakdown ─────────────────────────────────────────────
    async getPaymentMethodBreakdown(startDate: Date, endDate: Date, branchId?: string) {
        const start = new Date(startDate); start.setHours(0, 0, 0, 0);
        const end   = new Date(endDate);   end.setHours(23, 59, 59, 999);

        const orderConditions: any[] = [between(orders.createdAt, start, end), eq(orders.status, 'Sukses')];
        if (branchId) orderConditions.push(eq(orders.branchId, branchId));

        const rows = await db
            .select({
                method:            payments.method,
                totalTransactions: sql<number>`CAST(COUNT(DISTINCT ${orders.id}) AS UNSIGNED)`,
                totalAmount:       sql<number>`CAST(SUM(${orders.totalAmount}) AS UNSIGNED)`,
            })
            .from(orders)
            .innerJoin(payments, eq(payments.orderId, orders.id))
            .where(and(...orderConditions))
            .groupBy(payments.method)
            .orderBy(desc(sql`SUM(${orders.totalAmount})`));

        const grandTotal = rows.reduce((s, r) => s + (Number(r.totalAmount) || 0), 0);
        return rows.map(r => ({
            method:            r.method,
            totalTransactions: Number(r.totalTransactions) || 0,
            totalAmount:       Number(r.totalAmount)       || 0,
            percentage:        grandTotal > 0 ? parseFloat(((Number(r.totalAmount) / grandTotal) * 100).toFixed(1)) : 0,
        }));
    },

    // ─── Audit Log ────────────────────────────────────────────────────────────
    async getAuditLog(startDate: Date, endDate: Date, staffId?: string, branchId?: string) {
        const start = new Date(startDate); start.setHours(0, 0, 0, 0);
        const end   = new Date(endDate);   end.setHours(23, 59, 59, 999);

        const conditions: any[] = [between(shifts.startedAt, start, end)];
        if (staffId)  conditions.push(eq(shifts.staffId, staffId));
        if (branchId) conditions.push(eq(shifts.branchId, branchId));

        const rows = await db
            .select({
                shiftId:      shifts.id,
                staffName:    staff.name,
                startedAt:    shifts.startedAt,
                closedAt:     shifts.closedAt,
                status:       shifts.status,
                startingCash: shifts.startingCash,
                endingCash:   shifts.endingCash,
            })
            .from(shifts)
            .innerJoin(staff, eq(shifts.staffId, staff.id))
            .where(and(...conditions))
            .orderBy(desc(shifts.startedAt));

        return rows;
    },

    // ─── Sales by Category ────────────────────────────────────────────────────
    async getSalesByCategory(startDate: Date, endDate: Date, branchId?: string) {
        const start = new Date(startDate); start.setHours(0, 0, 0, 0);
        const end   = new Date(endDate);   end.setHours(23, 59, 59, 999);

        const conditions: any[] = [between(orders.createdAt, start, end), eq(orders.status, 'Sukses')];
        if (branchId) conditions.push(eq(orders.branchId, branchId));

        const rows = await db
            .select({
                categoryId:   categories.id,
                categoryName: categories.name,
                totalQty:     sql<number>`CAST(SUM(${orderItems.quantity}) AS UNSIGNED)`,
                totalRevenue: sql<number>`CAST(SUM(${orderItems.quantity} * ${orderItems.priceAtOrder}) AS UNSIGNED)`,
            })
            .from(orderItems)
            .innerJoin(orders,     eq(orderItems.orderId,   orders.id))
            .innerJoin(products,   eq(orderItems.productId, products.id))
            .innerJoin(categories, eq(products.categoryId,  categories.id))
            .where(and(...conditions))
            .groupBy(categories.id, categories.name)
            .orderBy(desc(sql`SUM(${orderItems.quantity} * ${orderItems.priceAtOrder})`));

        return rows.map(r => ({
            categoryId:   r.categoryId,
            categoryName: r.categoryName,
            totalQty:     Number(r.totalQty)     || 0,
            totalRevenue: Number(r.totalRevenue) || 0,
        }));
    },

    // ─── Sales by Staff ───────────────────────────────────────────────────────
    async getSalesByStaff(startDate: Date, endDate: Date, branchId?: string) {
        const start = new Date(startDate); start.setHours(0, 0, 0, 0);
        const end   = new Date(endDate);   end.setHours(23, 59, 59, 999);

        const conditions: any[] = [between(orders.createdAt, start, end), eq(orders.status, 'Sukses')];
        if (branchId) conditions.push(eq(orders.branchId, branchId));

        const rows = await db
            .select({
                staffId:       staff.id,
                staffName:     staff.name,
                staffRole:     staff.role,
                totalOrders:   sql<number>`CAST(COUNT(${orders.id}) AS UNSIGNED)`,
                totalRevenue:  sql<number>`CAST(SUM(${orders.totalAmount}) AS UNSIGNED)`,
                avgOrderValue: sql<number>`COALESCE(AVG(${orders.totalAmount}), 0)`,
            })
            .from(orders)
            .innerJoin(staff, eq(orders.staffId, staff.id))
            .where(and(...conditions))
            .groupBy(staff.id, staff.name, staff.role)
            .orderBy(desc(sql`SUM(${orders.totalAmount})`));

        return rows.map(r => ({
            staffId:       r.staffId,
            staffName:     r.staffName,
            staffRole:     r.staffRole,
            totalOrders:   Number(r.totalOrders)   || 0,
            totalRevenue:  Number(r.totalRevenue)  || 0,
            avgOrderValue: Math.round(Number(r.avgOrderValue) || 0),
        }));
    },

    // ─── Transaction Details (paginated, original) ────────────────────────────
    async getTransactionDetails(startDate: Date, endDate: Date, page: number = 1, limit: number = 50, branchId?: string) {
        const start = new Date(startDate); start.setHours(0, 0, 0, 0);
        const end   = new Date(endDate);   end.setHours(23, 59, 59, 999);
        const offset = (page - 1) * limit;

        const conditions: any[] = [between(orders.createdAt, start, end)];
        if (branchId) conditions.push(eq(orders.branchId, branchId));

        const [rows, [totalRow]] = await Promise.all([
            db
                .select({
                    orderId:        orders.id,
                    orderNumber:    orders.orderNumber,
                    createdAt:      orders.createdAt,
                    staffName:      staff.name,
                    orderType:      orders.orderType,
                    tableNumber:    orders.tableNumber,
                    subtotal:       orders.subtotal,
                    discountAmount: orders.discountAmount,
                    taxAmount:      orders.taxAmount,
                    totalAmount:    orders.totalAmount,
                    status:         orders.status,
                })
                .from(orders)
                .innerJoin(staff, eq(orders.staffId, staff.id))
                .where(and(...conditions))
                .orderBy(desc(orders.createdAt))
                
                .offset(offset),
            db.select({ total: count(orders.id) }).from(orders).where(and(...conditions)),
        ]);

        return {
            data: rows.map(r => ({
                orderId:        r.orderId,
                orderNumber:    r.orderNumber,
                createdAt:      r.createdAt,
                staffName:      r.staffName,
                orderType:      r.orderType,
                tableNumber:    r.tableNumber ?? '-',
                subtotal:       Number(r.subtotal)       || 0,
                discountAmount: Number(r.discountAmount) || 0,
                taxAmount:      Number(r.taxAmount)      || 0,
                totalAmount:    Number(r.totalAmount)    || 0,
                status:         r.status,
            })),
            pagination: {
                page,
                limit,
                total:      Number(totalRow?.total) || 0,
                totalPages: Math.ceil((Number(totalRow?.total) || 0) / limit),
            },
        };
    },

    // ─── Void Transactions ────────────────────────────────────────────────────
    async getVoidTransactions(startDate: Date, endDate: Date, branchId?: string) {
        const start = new Date(startDate); start.setHours(0, 0, 0, 0);
        const end   = new Date(endDate);   end.setHours(23, 59, 59, 999);

        const conditions: any[] = [between(orders.createdAt, start, end), eq(orders.status, 'Batal')];
        if (branchId) conditions.push(eq(orders.branchId, branchId));

        const rows = await db
            .select({
                orderId:     orders.id,
                orderNumber: orders.orderNumber,
                createdAt:   orders.createdAt,
                staffName:   staff.name,
                totalAmount: orders.totalAmount,
                notes:       orders.notes,
            })
            .from(orders)
            .innerJoin(staff, eq(orders.staffId, staff.id))
            .where(and(...conditions))
            .orderBy(desc(orders.createdAt));

        return rows.map(r => ({
            orderId:     r.orderId,
            orderNumber: r.orderNumber,
            createdAt:   r.createdAt,
            staffName:   r.staffName,
            totalAmount: Number(r.totalAmount) || 0,
            reason:      r.notes ?? '-',
        }));
    },

    // ─── Refund Transactions ──────────────────────────────────────────────────
    async getRefundTransactions(startDate: Date, endDate: Date, branchId?: string) {
        const start = new Date(startDate); start.setHours(0, 0, 0, 0);
        const end   = new Date(endDate);   end.setHours(23, 59, 59, 999);

        const conditions: any[] = [between(orders.createdAt, start, end), eq(orders.status, 'Refund')];
        if (branchId) conditions.push(eq(orders.branchId, branchId));

        const rows = await db
            .select({
                orderId:     orders.id,
                orderNumber: orders.orderNumber,
                createdAt:   orders.createdAt,
                staffName:   staff.name,
                totalAmount: orders.totalAmount,
                notes:       orders.notes,
            })
            .from(orders)
            .innerJoin(staff, eq(orders.staffId, staff.id))
            .where(and(...conditions))
            .orderBy(desc(orders.createdAt));

        return rows.map(r => ({
            orderId:     r.orderId,
            orderNumber: r.orderNumber,
            createdAt:   r.createdAt,
            staffName:   r.staffName,
            totalAmount: Number(r.totalAmount) || 0,
            notes:       r.notes ?? '-',
        }));
    },

    // ─── Discount Summary ─────────────────────────────────────────────────────
    async getDiscountSummary(startDate: Date, endDate: Date, branchId?: string) {
        const start = new Date(startDate); start.setHours(0, 0, 0, 0);
        const end   = new Date(endDate);   end.setHours(23, 59, 59, 999);

        const conditions: any[] = [
            between(orders.createdAt, start, end),
            eq(orders.status, 'Sukses'),
            sql`${orders.discountAmount} > 0`,
        ];
        if (branchId) conditions.push(eq(orders.branchId, branchId));

        const [summaryRow, rows] = await Promise.all([
            db.select({
                totalDiscountGiven:      sql<number>`CAST(SUM(${orders.discountAmount}) AS UNSIGNED)`,
                totalOrdersWithDiscount: sql<number>`CAST(COUNT(${orders.id}) AS UNSIGNED)`,
            }).from(orders).where(and(...conditions)),
            db.select({
                orderId:        orders.id,
                orderNumber:    orders.orderNumber,
                createdAt:      orders.createdAt,
                staffName:      staff.name,
                discountAmount: orders.discountAmount,
                totalAmount:    orders.totalAmount,
            }).from(orders)
              .innerJoin(staff, eq(orders.staffId, staff.id))
              .where(and(...conditions))
              .orderBy(desc(orders.createdAt)),
        ]);

        return {
            totalDiscountGiven:      Number(summaryRow[0]?.totalDiscountGiven)      || 0,
            totalOrdersWithDiscount: Number(summaryRow[0]?.totalOrdersWithDiscount) || 0,
            rows: rows.map(r => ({
                orderId:        r.orderId,
                orderNumber:    r.orderNumber,
                date:           r.createdAt,
                staffName:      r.staffName,
                discountAmount: Number(r.discountAmount) || 0,
                totalAmount:    Number(r.totalAmount)    || 0,
            })),
        };
    },

    // ─── Busiest Days ─────────────────────────────────────────────────────────
    async getBusiestDays(startDate: Date, endDate: Date, branchId?: string) {
        const start = new Date(startDate); start.setHours(0, 0, 0, 0);
        const end   = new Date(endDate);   end.setHours(23, 59, 59, 999);

        const conditions: any[] = [between(orders.createdAt, start, end), eq(orders.status, 'Sukses')];
        if (branchId) conditions.push(eq(orders.branchId, branchId));

        const dayNames = ['', 'Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];

        const rows = await db
            .select({
                dayOfWeek:    sql<number>`DAYOFWEEK(${orders.createdAt})`,
                totalOrders:  sql<number>`CAST(COUNT(${orders.id}) AS UNSIGNED)`,
                totalRevenue: sql<number>`CAST(SUM(${orders.totalAmount}) AS UNSIGNED)`,
            })
            .from(orders)
            .where(and(...conditions))
            .groupBy(sql`DAYOFWEEK(${orders.createdAt})`)
            .orderBy(sql`DAYOFWEEK(${orders.createdAt})`);

        const dayMap = new Map(rows.map(r => [Number(r.dayOfWeek), r]));
        const result = [];
        for (let d = 1; d <= 7; d++) {
            const row = dayMap.get(d);
            result.push({
                dayOfWeek:    d,
                dayName:      dayNames[d],
                totalOrders:  Number(row?.totalOrders)  || 0,
                totalRevenue: Number(row?.totalRevenue) || 0,
            });
        }
        return result;
    },

    // ─── Filter Lanjutan: Detail Transaksi ────────────────────────────────────
    async getTransactionDetailsFiltered(params: TransactionFilterParams) {
        const { start, end, page, limit, branchId, staffId, paymentMethod, search, sortBy, sortOrder } = params;
        const offset = (Math.max(1, page) - 1) * limit;

        const conditions: any[] = [
            gte(orders.createdAt, start),
            lte(orders.createdAt, end),
        ];
        if (branchId) conditions.push(eq(orders.branchId, branchId));
        if (staffId)  conditions.push(eq(orders.staffId, staffId));
        if (search)   conditions.push(like(orders.orderNumber, `%${search}%`));

        const hasPaymentFilter = !!paymentMethod;

        const sortColumn: Record<string, any> = {
            createdAt:   orders.createdAt,
            totalAmount: orders.totalAmount,
            orderNumber: orders.orderNumber,
            status:      orders.status,
        };
        const orderCol = sortColumn[sortBy ?? 'createdAt'] ?? orders.createdAt;
        const orderDir = sortOrder === 'asc' ? asc(orderCol) : desc(orderCol);

        const whereConditions = and(
            ...conditions,
            hasPaymentFilter ? eq(payments.method, paymentMethod!) : undefined,
        );

        const [rows, [totalRow]] = await Promise.all([
            db
                .select({
                    orderId:        orders.id,
                    orderNumber:    orders.orderNumber,
                    createdAt:      orders.createdAt,
                    staffName:      staff.name,
                    orderType:      orders.orderType,
                    tableNumber:    orders.tableNumber,
                    subtotal:       orders.subtotal,
                    discountAmount: orders.discountAmount,
                    taxAmount:      orders.taxAmount,
                    totalAmount:    orders.totalAmount,
                    status:         orders.status,
                    paymentMethod:  payments.method,
                })
                .from(orders)
                .innerJoin(staff,   eq(orders.staffId,  staff.id))
                .leftJoin(payments, eq(payments.orderId, orders.id))
                .where(whereConditions)
                .orderBy(orderDir)
                
                .offset(offset),
            db
                .select({ total: count(orders.id) })
                .from(orders)
                .innerJoin(staff,   eq(orders.staffId,  staff.id))
                .leftJoin(payments, eq(payments.orderId, orders.id))
                .where(whereConditions),
        ]);

        return {
            data: rows.map(r => ({
                orderId:        r.orderId,
                orderNumber:    r.orderNumber,
                createdAt:      r.createdAt,
                staffName:      r.staffName,
                orderType:      r.orderType,
                tableNumber:    r.tableNumber ?? '-',
                subtotal:       Number(r.subtotal)       || 0,
                discountAmount: Number(r.discountAmount) || 0,
                taxAmount:      Number(r.taxAmount)      || 0,
                totalAmount:    Number(r.totalAmount)    || 0,
                status:         r.status,
                paymentMethod:  r.paymentMethod ?? '-',
            })),
            pagination: {
                page,
                limit,
                total:      Number(totalRow?.total) || 0,
                totalPages: Math.ceil((Number(totalRow?.total) || 0) / limit),
            },
        };
    },

    // ─── Data Referensi untuk Filter Dropdown ─────────────────────────────────
    async getFilterOptions() {
        const [staffList, paymentMethodRows, branchesList] = await Promise.all([
            db.select({ id: staff.id, name: staff.name })
              .from(staff)
              .where(eq(staff.status, 'Aktif')),
            db.selectDistinct({ method: payments.method })
              .from(payments),
            db.select({ id: branches.id, name: branches.name })
              .from(branches)
              .where(eq(branches.status, 'Buka'))
              .orderBy(branches.name),
        ]);
        return {
            staff:          staffList,
            paymentMethods: paymentMethodRows.map(p => p.method).filter(Boolean),
            branches:       branchesList,
        };
    },

    // ─── Modul 14: Visualisasi Data & Eksekutif Dashboard ─────────────────────

    /**
     * 14.1 — KPI Summary
     * Mengembalikan metrik utama: total pendapatan, jumlah transaksi,
     * rata-rata nilai transaksi, dan estimasi laba kotor (revenue - expenses).
     */
    async getKpiSummary(start: Date, end: Date, branchId?: string) {
        const orderConditions: any[] = [
            between(orders.createdAt, start, end),
            eq(orders.status, 'Sukses'),
        ];
        if (branchId) orderConditions.push(eq(orders.branchId, branchId));

        const expenseConditions: any[] = [
            between(expenses.createdAt, start, end),
        ];
        if (branchId) expenseConditions.push(eq(expenses.branchId, branchId));

        const [[orderResult], [expenseResult]] = await Promise.all([
            db.select({
                totalRevenue:       sum(orders.totalAmount),
                totalTransactions:  count(orders.id),
                avgTransactionValue: sql<number>`COALESCE(AVG(${orders.totalAmount}), 0)`,
            })
            .from(orders)
            .where(and(...orderConditions)),

            db.select({
                totalExpenses: sum(expenses.amount),
            })
            .from(expenses)
            .where(and(...expenseConditions)),
        ]);

        const totalRevenue  = Number(orderResult?.totalRevenue)   || 0;
        const totalExpenses = Number(expenseResult?.totalExpenses) || 0;

        return {
            totalRevenue,
            totalTransactions:      Number(orderResult?.totalTransactions)   || 0,
            averageTransactionValue: Math.round(Number(orderResult?.avgTransactionValue) || 0),
            totalProfit:            totalRevenue - totalExpenses,   // gross profit estimasi
        };
    },

    /**
     * 14.4 — Distribution (Pie/Donut Chart)
     * Distribusi pendapatan berdasarkan kategori produk dan metode pembayaran.
     */
    async getDistribution(start: Date, end: Date, branchId?: string) {
        const orderConditions: any[] = [
            between(orders.createdAt, start, end),
            eq(orders.status, 'Sukses'),
        ];
        if (branchId) orderConditions.push(eq(orders.branchId, branchId));

        const [byCategory, byPaymentMethod] = await Promise.all([
            // Kategori produk: join orderItems → products → categories
            db.select({
                category: categories.name,
                total:    sql<number>`SUM(${orderItems.quantity} * ${orderItems.priceAtOrder})`,
            })
            .from(orderItems)
            .innerJoin(orders,     eq(orderItems.orderId,    orders.id))
            .innerJoin(products,   eq(orderItems.productId,  products.id))
            .leftJoin(categories,  eq(products.categoryId,   categories.id))
            .where(and(...orderConditions))
            .groupBy(categories.id, categories.name)
            .orderBy(desc(sql`SUM(${orderItems.quantity} * ${orderItems.priceAtOrder})`)),

            // Metode pembayaran
            db.select({
                method: payments.method,
                total:  sum(orders.totalAmount),
            })
            .from(orders)
            .innerJoin(payments, eq(payments.orderId, orders.id))
            .where(and(...orderConditions))
            .groupBy(payments.method)
            .orderBy(desc(sum(orders.totalAmount))),
        ]);

        return {
            byCategory: byCategory.map(r => ({
                category: r.category ?? 'Tanpa Kategori',
                total:    Number(r.total) || 0,
            })),
            byPaymentMethod: byPaymentMethod.map(r => ({
                method: r.method ?? 'Tidak Diketahui',
                total:  Number(r.total) || 0,
            })),
        };
    },

    /**
     * 14.5 — Heatmap (Jam & Hari Sibuk)
     * Matriks intensitas transaksi per hari-dalam-minggu (0=Minggu..6=Sabtu)
     * dan jam (0-23). Mengembalikan semua kombinasi yang memiliki transaksi > 0.
     */
    async getHeatmap(start: Date, end: Date, branchId?: string) {
        const conditions: any[] = [
            between(orders.createdAt, start, end),
            eq(orders.status, 'Sukses'),
        ];
        if (branchId) conditions.push(eq(orders.branchId, branchId));

        const rows = await db
            .select({
                dayOfWeek:        sql<number>`DAYOFWEEK(${orders.createdAt}) - 1`,  // 0=Minggu
                hour:             sql<number>`HOUR(${orders.createdAt})`,
                transactionCount: count(orders.id),
                revenue:          sum(orders.totalAmount),
            })
            .from(orders)
            .where(and(...conditions))
            .groupBy(
                sql`DAYOFWEEK(${orders.createdAt})`,
                sql`HOUR(${orders.createdAt})`,
            )
            .orderBy(
                sql`DAYOFWEEK(${orders.createdAt})`,
                sql`HOUR(${orders.createdAt})`,
            );

        return rows.map(r => ({
            dayOfWeek:        Number(r.dayOfWeek),
            hour:             Number(r.hour),
            transactionCount: Number(r.transactionCount) || 0,
            revenue:          Number(r.revenue)          || 0,
        }));
    },

    /**
     * 14.7 — Sales Target Progress
     * Membandingkan pendapatan aktual bulan berjalan dengan target yang
     * dapat dikonfigurasi via query param `target` (default: 50_000_000).
     * Jika period=weekly, menggunakan minggu berjalan.
     */
    async getSalesTarget(target: number, period: 'monthly' | 'weekly' = 'monthly', branchId?: string) {
        const now   = new Date();
        let start: Date;
        let end: Date;

        if (period === 'weekly') {
            // Mulai Senin minggu ini
            const dayOfWeek = now.getDay();          // 0=Minggu
            const diff      = (dayOfWeek === 0) ? -6 : 1 - dayOfWeek;
            start = new Date(now);
            start.setDate(now.getDate() + diff);
            start.setHours(0, 0, 0, 0);
        } else {
            // Bulan berjalan
            start = new Date(now.getFullYear(), now.getMonth(), 1, 0, 0, 0, 0);
        }
        end = new Date(now);
        end.setHours(23, 59, 59, 999);

        const conditions: any[] = [
            between(orders.createdAt, start, end),
            eq(orders.status, 'Sukses'),
        ];
        if (branchId) conditions.push(eq(orders.branchId, branchId));

        const [result] = await db
            .select({ actual: sum(orders.totalAmount) })
            .from(orders)
            .where(and(...conditions));

        const actual     = Number(result?.actual) || 0;
        const percentage = target > 0 ? Math.min(Math.round((actual / target) * 100), 100) : 0;

        return { target, actual, percentage, period };
    },
    // ─── Modul 15: Analitik Lanjutan ──────────────────────────────────────────

    /**
     * 15.1 — Period Comparison
     * Membandingkan metrik utama antara dua periode (A vs B) dengan selisih % growth.
     */
    async getPeriodComparison(
        start1: Date, end1: Date,
        start2: Date, end2: Date,
        branchId?: string
    ) {
        const makeConditions = (s: Date, e: Date) => {
            const c: any[] = [between(orders.createdAt, s, e), eq(orders.status, 'Sukses')];
            if (branchId) c.push(eq(orders.branchId, branchId));
            return c;
        };
        const makeExpConditions = (s: Date, e: Date) => {
            const c: any[] = [between(expenses.createdAt, s, e)];
            if (branchId) c.push(eq(expenses.branchId, branchId));
            return c;
        };

        const [[r1], [r2], [e1], [e2]] = await Promise.all([
            db.select({
                revenue:      sum(orders.totalAmount),
                transactions: count(orders.id),
                avgTx:        avg(orders.totalAmount),
            }).from(orders).where(and(...makeConditions(start1, end1))),
            db.select({
                revenue:      sum(orders.totalAmount),
                transactions: count(orders.id),
                avgTx:        avg(orders.totalAmount),
            }).from(orders).where(and(...makeConditions(start2, end2))),
            db.select({ total: sum(expenses.amount) }).from(expenses).where(and(...makeExpConditions(start1, end1))),
            db.select({ total: sum(expenses.amount) }).from(expenses).where(and(...makeExpConditions(start2, end2))),
        ]);

        const rev1  = Number(r1?.revenue)      || 0;
        const tx1   = Number(r1?.transactions) || 0;
        const avg1  = Math.round(Number(r1?.avgTx) || 0);
        const exp1  = Number(e1?.total)        || 0;
        const rev2  = Number(r2?.revenue)      || 0;
        const tx2   = Number(r2?.transactions) || 0;
        const avg2  = Math.round(Number(r2?.avgTx) || 0);
        const exp2  = Number(e2?.total)        || 0;

        const growth = (a: number, b: number) =>
            b === 0 ? (a > 0 ? 100 : 0) : parseFloat((((a - b) / b) * 100).toFixed(1));

        return {
            periodA: { revenue: rev1, transactions: tx1, avgTransaction: avg1, estimatedProfit: rev1 - exp1 },
            periodB: { revenue: rev2, transactions: tx2, avgTransaction: avg2, estimatedProfit: rev2 - exp2 },
            growth: {
                revenue:         growth(rev1, rev2),
                transactions:    growth(tx1,  tx2),
                avgTransaction:  growth(avg1, avg2),
                estimatedProfit: growth(rev1 - exp1, rev2 - exp2),
            },
        };
    },

    /**
     * 15.2 — Sales Forecast (Weighted Moving Average + koefisien musiman hari-dalam-minggu)
     * Mengembalikan data historis + array proyeksi untuk N hari ke depan.
     * Data proyeksi diberi flag `isEstimate: true` untuk transparansi ke user.
     */
    async getSalesForecast(historicalDays: number = 30, forecastDays: number = 7, branchId?: string) {
        const end = new Date();
        end.setHours(23, 59, 59, 999);
        const start = new Date();
        start.setDate(start.getDate() - (historicalDays - 1));
        start.setHours(0, 0, 0, 0);

        const conditions: any[] = [gte(orders.createdAt, start), lte(orders.createdAt, end), eq(orders.status, 'Sukses')];
        if (branchId) conditions.push(eq(orders.branchId, branchId));

        const rows = await db
            .select({
                dateStr:    sql<string>`DATE_FORMAT(${orders.createdAt}, '%Y-%m-%d')`,
                dayOfWeek:  sql<number>`DAYOFWEEK(${orders.createdAt})`,  // 1=Minggu..7=Sabtu
                revenue:    sum(orders.totalAmount),
            })
            .from(orders)
            .where(and(...conditions))
            .groupBy(sql`DATE(${orders.createdAt})`, sql`DAYOFWEEK(${orders.createdAt})`)
            .orderBy(sql`DATE(${orders.createdAt})`);

        // Isi gap hari yang tidak ada transaksi dengan 0
        const rowMap = new Map(rows.map(r => [r.dateStr, r]));
        const historical: { date: string; revenue: number; isEstimate: boolean }[] = [];
        const current = new Date(start);
        while (current <= end) {
            const dateStr = `${current.getFullYear()}-${String(current.getMonth()+1).padStart(2,'0')}-${String(current.getDate()).padStart(2,'0')}`;
            const row = rowMap.get(dateStr);
            historical.push({
                date: dateStr,
                revenue: Number(row?.revenue) || 0,
                isEstimate: false,
            });
            current.setDate(current.getDate() + 1);
        }

        // Hitung Koefisien Musiman per hari-dalam-minggu (1=Minggu..7=Sabtu)
        const dayTotals: Record<number, { sum: number; count: number }> = {};
        for (let d = 1; d <= 7; d++) dayTotals[d] = { sum: 0, count: 0 };
        rows.forEach(r => {
            const dow = Number(r.dayOfWeek);
            dayTotals[dow].sum += Number(r.revenue) || 0;
            dayTotals[dow].count += 1;
        });

        const overallAvg = historical.reduce((s, r) => s + r.revenue, 0) / (historicalDays || 1);
        const seasonCoeff: Record<number, number> = {};
        for (let d = 1; d <= 7; d++) {
            const dayAvg = dayTotals[d].count > 0 ? dayTotals[d].sum / dayTotals[d].count : overallAvg;
            seasonCoeff[d] = overallAvg > 0 ? dayAvg / overallAvg : 1;
        }

        // Weighted Moving Average (window = min(14, historicalDays))
        const window = Math.min(14, historical.length);
        const recentRevenues = historical.slice(-window).map(r => r.revenue);
        let weightedSum = 0;
        let weightTotal = 0;
        recentRevenues.forEach((rev, i) => {
            const w = i + 1;  // Bobot: posisi terbaru = bobot terbesar
            weightedSum += rev * w;
            weightTotal += w;
        });
        const wmaBase = weightTotal > 0 ? weightedSum / weightTotal : overallAvg;

        // Generate proyeksi
        const forecastResults: { date: string; revenue: number; isEstimate: boolean }[] = [];
        const forecastStart = new Date(end);
        forecastStart.setDate(forecastStart.getDate() + 1);
        forecastStart.setHours(0, 0, 0, 0);

        for (let i = 0; i < forecastDays; i++) {
            const forecastDate = new Date(forecastStart);
            forecastDate.setDate(forecastStart.getDate() + i);
            const dateStr = `${forecastDate.getFullYear()}-${String(forecastDate.getMonth()+1).padStart(2,'0')}-${String(forecastDate.getDate()).padStart(2,'0')}`;
            const dow = forecastDate.getDay() + 1;  // getDay() 0=Minggu → DAYOFWEEK 1=Minggu
            const estimatedRevenue = Math.round(wmaBase * (seasonCoeff[dow] ?? 1));
            forecastResults.push({ date: dateStr, revenue: estimatedRevenue, isEstimate: true });
        }

        return { historical, forecast: forecastResults };
    },

    /**
     * 15.3 — Market Basket (baca dari tabel cache, bukan real-time)
     * Data dihitung oleh cron job marketBasket.job.ts setiap hari jam 02:00.
     */
    async getMarketBasket(branchId?: string, limit: number = 50) {
        const conditions: any[] = [];
        // Jika branchId disediakan, filter cache by branchId; juga sertakan cache global (branchId=null)
        // Untuk simplifikasi MVP: hanya baca cache global (branchId IS NULL)
        if (!branchId) {
            conditions.push(sql`${marketBasketCache.branchId} IS NULL`);
        } else {
            conditions.push(eq(marketBasketCache.branchId, branchId));
        }

        const rows = await db
            .select()
            .from(marketBasketCache)
            .where(and(...conditions))
            .orderBy(desc(marketBasketCache.lift)).limit(limit)
            ;

        return rows.map(r => ({
            productAId:   r.productAId,
            productAName: r.productAName,
            productBId:   r.productBId,
            productBName: r.productBName,
            lift:         Number(r.lift),
            confidence:   Number(r.confidence),
            support:      Number(r.support),
            frequency:    r.frequency,
            computedAt:   r.computedAt,
        }));
    },

    /**
     * 15.4 — Product Growth Analysis
     * Membandingkan kuantitas penjualan per produk antara periode current vs previous.
     * Output terpisah menjadi trending_up (pertumbuhan positif) dan trending_down (churn).
     */
    async getProductGrowth(
        currentStart: Date, currentEnd: Date,
        previousStart: Date, previousEnd: Date,
        branchId?: string,
        topN: number = 10
    ) {
        const makeConditions = (s: Date, e: Date) => {
            const c: any[] = [between(orders.createdAt, s, e), eq(orders.status, 'Sukses')];
            if (branchId) c.push(eq(orders.branchId, branchId));
            return c;
        };

        const queryProductSales = (s: Date, e: Date) =>
            db.select({
                productId:   orderItems.productId,
                productName: products.name,
                totalQty:    sql<number>`CAST(SUM(${orderItems.quantity}) AS UNSIGNED)`,
            })
            .from(orderItems)
            .innerJoin(orders,   eq(orderItems.orderId,   orders.id))
            .innerJoin(products, eq(orderItems.productId, products.id))
            .where(and(...makeConditions(s, e)))
            .groupBy(orderItems.productId, products.name);

        const [currentRows, previousRows] = await Promise.all([
            queryProductSales(currentStart, currentEnd),
            queryProductSales(previousStart, previousEnd),
        ]);

        const previousMap = new Map(previousRows.map(r => [r.productId, Number(r.totalQty) || 0]));

        const results = currentRows.map(r => {
            const currentQty  = Number(r.totalQty) || 0;
            const previousQty = previousMap.get(r.productId) ?? 0;
            const growth = previousQty === 0
                ? (currentQty > 0 ? 100 : 0)
                : parseFloat((((currentQty - previousQty) / previousQty) * 100).toFixed(1));
            return { productId: r.productId, productName: r.productName, currentQty, previousQty, growth };
        });

        // Tambahkan produk yang ada di previous tapi tidak di current (churn total)
        previousRows.forEach(r => {
            if (!currentRows.find(c => c.productId === r.productId)) {
                results.push({
                    productId: r.productId,
                    productName: r.productName,
                    currentQty: 0,
                    previousQty: Number(r.totalQty) || 0,
                    growth: -100,
                });
            }
        });

        const sorted = results.sort((a, b) => b.growth - a.growth);

        return {
            trending_up:   sorted.filter(r => r.growth > 0).slice(0, topN),
            trending_down: sorted.filter(r => r.growth < 0).sort((a, b) => a.growth - b.growth).slice(0, topN),
        };
    },

    /**
     * 15.5 — Seasonality Analysis
     * Rata-rata pendapatan per hari-dalam-minggu atau per bulan berdasarkan seluruh data historis.
     */
    async getSeasonality(groupBy: 'day_of_week' | 'month' = 'day_of_week', branchId?: string) {
        const conditions: any[] = [eq(orders.status, 'Sukses')];
        if (branchId) conditions.push(eq(orders.branchId, branchId));

        if (groupBy === 'day_of_week') {
            const dayNames = ['', 'Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
            const rows = await db.select({
                dayOfWeek: sql<number>`DAYOFWEEK(${orders.createdAt})`.as('dayOfWeek'),
                avgRevenue: sql<number>`ROUND(SUM(${orders.totalAmount}) / COUNT(DISTINCT DATE(${orders.createdAt})))`.as('avgRevenue'),
                occurrences: sql<number>`COUNT(DISTINCT DATE(${orders.createdAt}))`.as('occurrences'),
            })
            .from(orders)
            .where(and(...conditions))
            .groupBy(sql`DAYOFWEEK(${orders.createdAt})`)
            .orderBy(sql`DAYOFWEEK(${orders.createdAt})`);

            const rowMap = new Map(rows.map(r => [Number(r.dayOfWeek), r]));
            return {
                group_by: 'day_of_week',
                data: Array.from({ length: 7 }, (_, i) => {
                    const dow = i + 1;
                    const row = rowMap.get(dow);
                    return {
                        label: dayNames[dow],
                        avgRevenue: Math.round(Number(row?.avgRevenue) || 0),
                        totalOccurrences: Number(row?.occurrences) || 0,
                    };
                }),
            };
        } else {
            const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
            const rows = await db.select({
                monthNum: sql<number>`MONTH(${orders.createdAt})`.as('monthNum'),
                avgRevenue: sql<number>`ROUND(SUM(${orders.totalAmount}) / COUNT(DISTINCT DATE(${orders.createdAt})))`.as('avgRevenue'),
                occurrences: sql<number>`COUNT(DISTINCT DATE(${orders.createdAt}))`.as('occurrences'),
            })
            .from(orders)
            .where(and(...conditions))
            .groupBy(sql`MONTH(${orders.createdAt})`)
            .orderBy(sql`MONTH(${orders.createdAt})`);

            const rowMap = new Map(rows.map(r => [Number(r.monthNum), r]));
            return {
                group_by: 'month',
                data: Array.from({ length: 12 }, (_, i) => {
                    const monthNum = i + 1;
                    const row = rowMap.get(monthNum);
                    return {
                        label: monthNames[i],
                        avgRevenue: Math.round(Number(row?.avgRevenue) || 0),
                        totalOccurrences: Number(row?.occurrences) || 0,
                    };
                }),
            };
        }
    },
};
