import { db } from '../db/index.js';
import { orders } from '../db/schema/orders.js';
import { orderItems } from '../db/schema/orderItems.js';
import { payments } from '../db/schema/payments.js';
import { products } from '../db/schema/products.js';
import { inventory } from '../db/schema/inventory.js';
import { shifts } from '../db/schema/shifts.js';
import { staff } from '../db/schema/staff.js';
import { expenses } from '../db/schema/expenses.js';
import { eq, and, between, desc, sum, count, sql, lte, gte } from 'drizzle-orm';

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

    async getTopProducts(limit: number = 10, branchId?: string) {
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
            .limit(limit);
    },

    async getCriticalStock(branchId?: string) {
        const conditions = [
            lte(inventory.quantity, sql`${inventory.reorderThreshold}`),
        ];
        if (branchId) conditions.push(eq(inventory.branchId, branchId));

        return db
            .select()
            .from(inventory)
            .where(and(...conditions));
    },

    async getRevenueChart(days: number = 7, branchId?: string) {
        const results = [];
        for (let i = days - 1; i >= 0; i--) {
            const date = new Date();
            date.setDate(date.getDate() - i);
            const summary = await this.getDailySummary(date, branchId);
            results.push(summary);
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

        // Build full 24-hour array, filling missing hours with 0
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
        const targetYear = year || new Date().getFullYear();
        const results = [];
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

        for (let month = 0; month < 12; month++) {
            const monthStart = new Date(targetYear, month, 1, 0, 0, 0, 0);
            const monthEnd = new Date(targetYear, month + 1, 0, 23, 59, 59, 999);

            const conditions = [
                between(orders.createdAt, monthStart, monthEnd),
                eq(orders.status, 'Sukses'),
            ];
            if (branchId) conditions.push(eq(orders.branchId, branchId));

            const [row] = await db
                .select({
                    totalRevenue: sum(orders.totalAmount),
                    totalTransactions: count(orders.id),
                })
                .from(orders)
                .where(and(...conditions));

            results.push({
                month: month + 1,
                label: months[month],
                totalRevenue: Number(row?.totalRevenue) || 0,
                totalTransactions: Number(row?.totalTransactions) || 0,
            });
        }
        return results;
    },

    // ═══ NEW REPORT METHODS ═══

    async getDailySales(startDate: Date, endDate: Date, branchId?: string) {
        const results = [];
        const current = new Date(startDate);
        current.setHours(0, 0, 0, 0);
        const end = new Date(endDate);
        end.setHours(23, 59, 59, 999);

        while (current <= end) {
            const summary = await this.getDailySummary(new Date(current), branchId);
            results.push(summary);
            current.setDate(current.getDate() + 1);
        }
        return results;
    },

    async getHourlySales(date: Date, branchId?: string) {
        // Format date as YYYY-MM-DD string to avoid timezone issues
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

        const conditions: any[] = [
            between(shifts.startedAt, start, end),
        ];
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

        const conditions: any[] = [
            between(expenses.createdAt, start, end),
        ];
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

        // Revenue
        const revConditions: any[] = [
            between(orders.createdAt, start, end),
            eq(orders.status, 'Sukses'),
        ];
        if (branchId) revConditions.push(eq(orders.branchId, branchId));

        const [rev] = await db
            .select({ total: sum(orders.totalAmount) })
            .from(orders)
            .where(and(...revConditions));

        // Expenses
        const expConditions: any[] = [
            between(expenses.createdAt, start, end),
        ];
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

    async getInventoryReport(branchId?: string) {
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
};

