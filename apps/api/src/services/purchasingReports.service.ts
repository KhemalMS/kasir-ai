import { db } from '../db/index.js';
import { suppliers, purchaseOrders, supplierReturns } from '../db/schema/index.js';
import { eq, and, gte, lte, sql, desc, ne } from 'drizzle-orm';

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

// ─── 45. Laporan Purchase Order (PO) ──────────────────────────────────────
export async function getPoReport(params: ReportParams) {
    const { start, end } = parseDates(params);
    const { branchId } = params;

    const conditions: any[] = [];
    if (start)    conditions.push(gte(purchaseOrders.createdAt, start));
    if (end)      conditions.push(lte(purchaseOrders.createdAt, end));
    if (branchId) conditions.push(eq(purchaseOrders.branchId, branchId));

    const rows = await db
        .select({
            poNumber:     purchaseOrders.poNumber,
            createdAt:    purchaseOrders.createdAt,
            expectedDate: purchaseOrders.expectedDate,
            receivedDate: purchaseOrders.receivedDate,
            supplierName: suppliers.name,
            status:       purchaseOrders.status,
            totalAmount:  purchaseOrders.totalAmount,
        })
        .from(purchaseOrders)
        .leftJoin(suppliers, eq(purchaseOrders.supplierId, suppliers.id))
        .where(conditions.length > 0 ? and(...conditions) : undefined)
        .orderBy(desc(purchaseOrders.createdAt));

    return rows.map(r => ({
        ...r,
        totalAmount: Number(r.totalAmount),
    }));
}

// ─── 46. Laporan Pembelian dari Supplier ──────────────────────────────────
export async function getPurchasesBySupplier(params: ReportParams) {
    const { start, end } = parseDates(params);
    const { branchId } = params;

    const conditions: any[] = [ne(purchaseOrders.status, 'Batal')];
    if (start)    conditions.push(gte(purchaseOrders.createdAt, start));
    if (end)      conditions.push(lte(purchaseOrders.createdAt, end));
    if (branchId) conditions.push(eq(purchaseOrders.branchId, branchId));

    const rows = await db
        .select({
            supplierName:     suppliers.name,
            transactionCount: sql<number>`COUNT(${purchaseOrders.id})`,
            totalAmount:      sql<number>`COALESCE(SUM(${purchaseOrders.totalAmount}), 0)`,
        })
        .from(purchaseOrders)
        .innerJoin(suppliers, eq(purchaseOrders.supplierId, suppliers.id))
        .where(and(...conditions))
        .groupBy(purchaseOrders.supplierId, suppliers.name)
        .orderBy(desc(sql`COALESCE(SUM(${purchaseOrders.totalAmount}), 0)`));

    return rows.map(r => ({
        ...r,
        transactionCount: Number(r.transactionCount),
        totalAmount:      Number(r.totalAmount),
    }));
}

// ─── 47. Laporan Retur ke Supplier ────────────────────────────────────────
export async function getReturnsReport(params: ReportParams) {
    const { start, end } = parseDates(params);
    const { branchId } = params;

    const conditions: any[] = [];
    if (start)    conditions.push(gte(supplierReturns.createdAt, start));
    if (end)      conditions.push(lte(supplierReturns.createdAt, end));
    if (branchId) conditions.push(eq(supplierReturns.branchId, branchId));

    const rows = await db
        .select({
            returnNumber: supplierReturns.returnNumber,
            createdAt:    supplierReturns.createdAt,
            supplierName: suppliers.name,
            reason:       supplierReturns.reason,
            totalAmount:  supplierReturns.totalAmount,
            poId:         supplierReturns.poId,
        })
        .from(supplierReturns)
        .leftJoin(suppliers, eq(supplierReturns.supplierId, suppliers.id))
        .where(conditions.length > 0 ? and(...conditions) : undefined)
        .orderBy(desc(supplierReturns.createdAt));

    return rows.map(r => ({
        ...r,
        totalAmount: Number(r.totalAmount),
    }));
}

// ─── 48. Laporan Performa Supplier ────────────────────────────────────────
export async function getSupplierPerformance(params: ReportParams) {
    const { start, end } = parseDates(params);
    const { branchId } = params;

    // Kondisi untuk PO
    const poConditions: any[] = [];
    if (start)    poConditions.push(gte(purchaseOrders.createdAt, start));
    if (end)      poConditions.push(lte(purchaseOrders.createdAt, end));
    if (branchId) poConditions.push(eq(purchaseOrders.branchId, branchId));

    // Query 1: PO count per supplier
    const poStats = await db
        .select({
            supplierId:   purchaseOrders.supplierId,
            supplierName: suppliers.name,
            totalPoCount: sql<number>`COUNT(${purchaseOrders.id})`,
        })
        .from(purchaseOrders)
        .innerJoin(suppliers, eq(purchaseOrders.supplierId, suppliers.id))
        .where(poConditions.length > 0 ? and(...poConditions) : undefined)
        .groupBy(purchaseOrders.supplierId, suppliers.name);

    // Kondisi untuk Retur
    const returnConditions: any[] = [];
    if (start)    returnConditions.push(gte(supplierReturns.createdAt, start));
    if (end)      returnConditions.push(lte(supplierReturns.createdAt, end));
    if (branchId) returnConditions.push(eq(supplierReturns.branchId, branchId));

    // Query 2: Return count per supplier
    const returnStats = await db
        .select({
            supplierId:       supplierReturns.supplierId,
            totalReturnCount: sql<number>`COUNT(${supplierReturns.id})`,
        })
        .from(supplierReturns)
        .where(returnConditions.length > 0 ? and(...returnConditions) : undefined)
        .groupBy(supplierReturns.supplierId);

    // Gabungkan di TypeScript
    const returnMap = new Map(returnStats.map(r => [r.supplierId, Number(r.totalReturnCount)]));

    return poStats.map(p => {
        const totalPoCount     = Number(p.totalPoCount);
        const totalReturnCount = returnMap.get(p.supplierId) ?? 0;
        const returnRate       = totalPoCount > 0
            ? parseFloat((totalReturnCount / totalPoCount * 100).toFixed(2))
            : 0;
        return {
            supplierName:     p.supplierName,
            totalPoCount,
            totalReturnCount,
            returnRate,
        };
    });
}
