import { db } from '../db/index.js';
import {
    orders, orderItems, payments, expenses, shifts, inventoryBatches, inventory, staff, products,
} from '../db/schema/index.js';
import { eq, and, gte, lte, ne, sql, sum, desc } from 'drizzle-orm';

interface ReportParams {
    start?: string;
    end?: string;
    branchId?: string;
}

function parseDates(params: ReportParams) {
    const start = params.start ? new Date(params.start) : undefined;
    const end = params.end ? new Date(params.end + 'T23:59:59') : undefined;
    return { start, end };
}

// ─── 23. Laba Rugi (Profit & Loss) ────────────────────────────────────────
export async function getProfitLoss(params: ReportParams) {
    const { start, end } = parseDates(params);
    const { branchId } = params;

    const orderConditions: any[] = [eq(orders.status, 'Sukses')];
    if (start) orderConditions.push(gte(orders.createdAt, start));
    if (end) orderConditions.push(lte(orders.createdAt, end));
    if (branchId) orderConditions.push(eq(orders.branchId, branchId));

    // Total Revenue
    const [revenueRow] = await db
        .select({ total: sql<number>`COALESCE(SUM(${orders.totalAmount}), 0)` })
        .from(orders)
        .where(and(...orderConditions));
    const totalRevenue = Number(revenueRow?.total ?? 0);

    // Total COGS — join order_items to orders for same filter
    const [cogsRow] = await db
        .select({
            total: sql<number>`COALESCE(SUM(CAST(${orderItems.cogsAtOrder} AS DECIMAL) * ${orderItems.quantity}), 0)`,
        })
        .from(orderItems)
        .innerJoin(orders, eq(orderItems.orderId, orders.id))
        .where(and(...orderConditions));
    const totalCogs = Number(cogsRow?.total ?? 0);

    // Total Expenses
    const expenseConditions: any[] = [];
    if (start) expenseConditions.push(gte(expenses.createdAt, start));
    if (end) expenseConditions.push(lte(expenses.createdAt, end));
    if (branchId) expenseConditions.push(eq(expenses.branchId, branchId));

    const [expRow] = await db
        .select({ total: sql<number>`COALESCE(SUM(${expenses.amount}), 0)` })
        .from(expenses)
        .where(expenseConditions.length > 0 ? and(...expenseConditions) : undefined);
    const totalExpenses = Number(expRow?.total ?? 0);

    const grossProfit = totalRevenue - totalCogs;
    const netProfit = grossProfit - totalExpenses;

    return {
        totalRevenue,
        totalCogs,
        grossProfit,
        totalExpenses,
        netProfit,
    };
}

// ─── 24. HPP / COGS per Produk ────────────────────────────────────────────
export async function getCogs(params: ReportParams) {
    const { start, end } = parseDates(params);
    const { branchId } = params;

    const orderConditions: any[] = [eq(orders.status, 'Sukses')];
    if (start) orderConditions.push(gte(orders.createdAt, start));
    if (end) orderConditions.push(lte(orders.createdAt, end));
    if (branchId) orderConditions.push(eq(orders.branchId, branchId));

    const rows = await db
        .select({
            productId: products.id,
            productName: products.name,
            totalQtySold: sql<number>`SUM(${orderItems.quantity})`,
            cogsPerUnit: sql<number>`ROUND(AVG(CAST(${orderItems.cogsAtOrder} AS DECIMAL)), 2)`,
            totalCogs: sql<number>`SUM(CAST(${orderItems.cogsAtOrder} AS DECIMAL) * ${orderItems.quantity})`,
        })
        .from(orderItems)
        .innerJoin(orders, eq(orderItems.orderId, orders.id))
        .innerJoin(products, eq(orderItems.productId, products.id))
        .where(and(...orderConditions))
        .groupBy(products.id, products.name)
        .orderBy(desc(sql`SUM(CAST(${orderItems.cogsAtOrder} AS DECIMAL) * ${orderItems.quantity})`));

    return rows.map(r => ({
        ...r,
        totalQtySold: Number(r.totalQtySold),
        cogsPerUnit: Number(r.cogsPerUnit),
        totalCogs: Number(r.totalCogs),
    }));
}

// ─── 25. Gross Margin per Produk ──────────────────────────────────────────
export async function getGrossMargin(params: ReportParams) {
    const { start, end } = parseDates(params);
    const { branchId } = params;

    const orderConditions: any[] = [eq(orders.status, 'Sukses')];
    if (start) orderConditions.push(gte(orders.createdAt, start));
    if (end) orderConditions.push(lte(orders.createdAt, end));
    if (branchId) orderConditions.push(eq(orders.branchId, branchId));

    const rows = await db
        .select({
            productName: products.name,
            totalQtySold: sql<number>`SUM(${orderItems.quantity})`,
            totalRevenue: sql<number>`SUM(CAST(${orderItems.priceAtOrder} AS DECIMAL) * ${orderItems.quantity})`,
            totalCogs: sql<number>`SUM(CAST(${orderItems.cogsAtOrder} AS DECIMAL) * ${orderItems.quantity})`,
        })
        .from(orderItems)
        .innerJoin(orders, eq(orderItems.orderId, orders.id))
        .innerJoin(products, eq(orderItems.productId, products.id))
        .where(and(...orderConditions))
        .groupBy(products.id, products.name)
        .orderBy(desc(sql`SUM(CAST(${orderItems.priceAtOrder} AS DECIMAL) * ${orderItems.quantity})`));

    return rows.map(r => {
        const revenue = Number(r.totalRevenue);
        const cogs = Number(r.totalCogs);
        const grossMargin = revenue - cogs;
        const marginPct = revenue > 0 ? Number(((grossMargin / revenue) * 100).toFixed(2)) : 0;
        return {
            productName: r.productName,
            totalQtySold: Number(r.totalQtySold),
            totalRevenue: revenue,
            totalCogs: cogs,
            grossMargin,
            marginPct,
        };
    }).sort((a, b) => b.marginPct - a.marginPct);
}

// ─── 26. Arus Kas (Cash Flow) ─────────────────────────────────────────────
export async function getCashFlow(params: ReportParams) {
    const { start, end } = parseDates(params);
    const { branchId } = params;

    const orderConditions: any[] = [eq(orders.status, 'Sukses')];
    if (start) orderConditions.push(gte(orders.createdAt, start));
    if (end) orderConditions.push(lte(orders.createdAt, end));
    if (branchId) orderConditions.push(eq(orders.branchId, branchId));

    // Inflows: payments grouped by method, via completed orders
    const inflows = await db
        .select({
            method: payments.method,
            total: sql<number>`SUM(${payments.amount})`,
        })
        .from(payments)
        .innerJoin(orders, eq(payments.orderId, orders.id))
        .where(and(...orderConditions))
        .groupBy(payments.method);

    // Outflows: expenses grouped by category
    const expenseConditions: any[] = [];
    if (start) expenseConditions.push(gte(expenses.createdAt, start));
    if (end) expenseConditions.push(lte(expenses.createdAt, end));
    if (branchId) expenseConditions.push(eq(expenses.branchId, branchId));

    const outflows = await db
        .select({
            category: expenses.category,
            total: sql<number>`SUM(${expenses.amount})`,
        })
        .from(expenses)
        .where(expenseConditions.length > 0 ? and(...expenseConditions) : undefined)
        .groupBy(expenses.category);

    const totalInflow = inflows.reduce((s, r) => s + Number(r.total), 0);
    const totalOutflow = outflows.reduce((s, r) => s + Number(r.total), 0);

    return {
        inflows: inflows.map(r => ({ method: r.method, total: Number(r.total) })),
        outflows: outflows.map(r => ({ category: r.category, total: Number(r.total) })),
        totalInflow,
        totalOutflow,
        netCashFlow: totalInflow - totalOutflow,
    };
}

// ─── 27. Rekonsiliasi Kas ─────────────────────────────────────────────────
export async function getCashReconciliation(params: ReportParams) {
    const { start, end } = parseDates(params);
    const { branchId } = params;

    const conditions: any[] = [];
    if (start) conditions.push(gte(shifts.startedAt, start));
    if (end) conditions.push(lte(shifts.startedAt, end));
    if (branchId) conditions.push(eq(shifts.branchId, branchId));

    const rows = await db
        .select({
            id: shifts.id,
            startingCash: shifts.startingCash,
            endingCash: shifts.endingCash,
            expectedCash: shifts.expectedCash,
            cashDifference: shifts.cashDifference,
            totalCashSales: shifts.totalCashSales,
            totalExpenses: shifts.totalExpenses,
            status: shifts.status,
            startedAt: shifts.startedAt,
            closedAt: shifts.closedAt,
            staffName: staff.name,
        })
        .from(shifts)
        .leftJoin(staff, eq(shifts.staffId, staff.id))
        .where(conditions.length > 0 ? and(...conditions) : undefined)
        .orderBy(desc(shifts.startedAt));

    return rows;
}

// ─── 28. Piutang (Accounts Receivable) ───────────────────────────────────
export async function getAccountsReceivable(params: ReportParams) {
    const { start, end } = parseDates(params);
    const { branchId } = params;

    const conditions: any[] = [eq(orders.status, 'Sukses')];
    if (start) conditions.push(gte(orders.createdAt, start));
    if (end) conditions.push(lte(orders.createdAt, end));
    if (branchId) conditions.push(eq(orders.branchId, branchId));

    // Get all completed orders with their total payments
    const allOrders = await db
        .select({
            id: orders.id,
            orderNumber: orders.orderNumber,
            totalAmount: orders.totalAmount,
            createdAt: orders.createdAt,
        })
        .from(orders)
        .where(and(...conditions));

    if (allOrders.length === 0) return [];

    // Get payment sums per order
    const paymentSums = await db
        .select({
            orderId: payments.orderId,
            amountPaid: sql<number>`COALESCE(SUM(${payments.amount}), 0)`,
        })
        .from(payments)
        .groupBy(payments.orderId);

    const paymentMap = new Map(paymentSums.map(p => [p.orderId, Number(p.amountPaid)]));

    // Filter only orders where payment < total (receivable)
    return allOrders
        .map(o => {
            const amountPaid = paymentMap.get(o.id) ?? 0;
            const balanceDue = Number(o.totalAmount) - amountPaid;
            return {
                orderNumber: o.orderNumber,
                date: o.createdAt,
                totalAmount: Number(o.totalAmount),
                amountPaid,
                balanceDue,
            };
        })
        .filter(o => o.balanceDue > 0)
        .sort((a, b) => b.balanceDue - a.balanceDue);
}

// ─── 29. Utang ke Supplier (Accounts Payable) ────────────────────────────
export async function getAccountsPayable(params: ReportParams) {
    const { start, end } = parseDates(params);

    const conditions: any[] = [ne(inventoryBatches.paymentStatus, 'Paid')];
    if (start) conditions.push(gte(inventoryBatches.receivedAt, start));
    if (end) conditions.push(lte(inventoryBatches.receivedAt, end));

    const rows = await db
        .select({
            id: inventoryBatches.id,
            batchNumber: inventoryBatches.batchNumber,
            supplierName: inventoryBatches.supplierName,
            quantityReceived: inventoryBatches.quantityReceived,
            costPrice: inventoryBatches.costPrice,
            receivedAt: inventoryBatches.receivedAt,
            dueDate: inventoryBatches.dueDate,
            amountPaid: inventoryBatches.amountPaid,
            paymentStatus: inventoryBatches.paymentStatus,
            inventoryName: inventory.name,
        })
        .from(inventoryBatches)
        .innerJoin(inventory, eq(inventoryBatches.inventoryId, inventory.id))
        .where(and(...conditions))
        .orderBy(inventoryBatches.receivedAt);

    return rows.map(r => {
        const totalAmount = Number(r.quantityReceived) * Number(r.costPrice);
        const amountPaid = Number(r.amountPaid);
        return {
            batchNumber: r.batchNumber ?? '-',
            inventoryName: r.inventoryName,
            supplierName: r.supplierName ?? '-',
            receivedAt: r.receivedAt,
            dueDate: r.dueDate,
            totalAmount,
            amountPaid,
            balanceDue: totalAmount - amountPaid,
            paymentStatus: r.paymentStatus,
        };
    });
}

export const financeReportsService = {
    getProfitLoss,
    getCogs,
    getGrossMargin,
    getCashFlow,
    getCashReconciliation,
    getAccountsReceivable,
    getAccountsPayable,
};
