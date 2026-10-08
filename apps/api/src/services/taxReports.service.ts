import { db } from '../db/index.js';
import { orders } from '../db/schema/index.js';
import { eq, and, gte, lte, sql, desc } from 'drizzle-orm';

interface ReportParams {
    start?: string;
    end?: string;
    branchId?: string;
}

function parseDates(params: ReportParams) {
    const start = params.start ? new Date(params.start) : undefined;
    const end   = params.end   ? new Date(params.end + 'T23:59:59') : undefined;
    return { start, end };
}

// ─── 42. Laporan PPN — Ringkasan per Hari ─────────────────────────────────
export async function getPpnReport(params: ReportParams) {
    const { start, end } = parseDates(params);
    const { branchId } = params;

    const conditions: any[] = [eq(orders.status, 'Sukses')];
    if (start)    conditions.push(gte(orders.createdAt, start));
    if (end)      conditions.push(lte(orders.createdAt, end));
    if (branchId) conditions.push(eq(orders.branchId, branchId));

    const rows = await db
        .select({
            date:             sql<string>`DATE(${orders.createdAt})`,
            transactionCount: sql<number>`COUNT(${orders.id})`,
            totalSubtotal:    sql<number>`COALESCE(SUM(${orders.subtotal}), 0)`,
            totalTax:         sql<number>`COALESCE(SUM(${orders.taxAmount}), 0)`,
            totalAmount:      sql<number>`COALESCE(SUM(${orders.totalAmount}), 0)`,
        })
        .from(orders)
        .where(and(...conditions, sql`${orders.taxAmount} > 0`))
        .groupBy(sql`DATE(${orders.createdAt})`)
        .orderBy(desc(sql`DATE(${orders.createdAt})`));

    return rows.map(r => ({
        ...r,
        transactionCount: Number(r.transactionCount),
        totalSubtotal:    Number(r.totalSubtotal),
        totalTax:         Number(r.totalTax),
        totalAmount:      Number(r.totalAmount),
    }));
}

// ─── 43. Laporan Faktur Pajak — Detail per Transaksi ──────────────────────
export async function getTaxInvoices(params: ReportParams) {
    const { start, end } = parseDates(params);
    const { branchId } = params;

    const conditions: any[] = [eq(orders.status, 'Sukses')];
    if (start)    conditions.push(gte(orders.createdAt, start));
    if (end)      conditions.push(lte(orders.createdAt, end));
    if (branchId) conditions.push(eq(orders.branchId, branchId));

    const rows = await db
        .select({
            orderNumber:      orders.orderNumber,
            createdAt:        orders.createdAt,
            taxInvoiceNumber: orders.taxInvoiceNumber,
            subtotal:         orders.subtotal,
            taxAmount:        orders.taxAmount,
            totalAmount:      orders.totalAmount,
        })
        .from(orders)
        .where(and(...conditions, sql`${orders.taxAmount} > 0`))
        .orderBy(desc(orders.createdAt))
        .limit(500);

    return rows.map(r => ({
        ...r,
        subtotal:    Number(r.subtotal),
        taxAmount:   Number(r.taxAmount),
        totalAmount: Number(r.totalAmount),
    }));
}

// ─── 44. Rekap Pajak Bulanan — untuk SPT ──────────────────────────────────
export async function getMonthlySummary(params: ReportParams) {
    const { start, end } = parseDates(params);
    const { branchId } = params;

    const conditions: any[] = [eq(orders.status, 'Sukses')];
    if (start)    conditions.push(gte(orders.createdAt, start));
    if (end)      conditions.push(lte(orders.createdAt, end));
    if (branchId) conditions.push(eq(orders.branchId, branchId));

    const rows = await db
        .select({
            month:            sql<string>`DATE_FORMAT(${orders.createdAt}, '%Y-%m')`,
            transactionCount: sql<number>`COUNT(${orders.id})`,
            totalSubtotal:    sql<number>`COALESCE(SUM(${orders.subtotal}), 0)`,
            totalTax:         sql<number>`COALESCE(SUM(${orders.taxAmount}), 0)`,
            totalAmount:      sql<number>`COALESCE(SUM(${orders.totalAmount}), 0)`,
        })
        .from(orders)
        .where(and(...conditions))
        .groupBy(sql`DATE_FORMAT(${orders.createdAt}, '%Y-%m')`)
        .orderBy(desc(sql`DATE_FORMAT(${orders.createdAt}, '%Y-%m')`));

    return rows.map(r => ({
        ...r,
        transactionCount: Number(r.transactionCount),
        totalSubtotal:    Number(r.totalSubtotal),
        totalTax:         Number(r.totalTax),
        totalAmount:      Number(r.totalAmount),
    }));
}

export const taxReportsService = {
    getPpnReport,
    getTaxInvoices,
    getMonthlySummary,
};
