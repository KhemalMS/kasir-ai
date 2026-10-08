import { db } from '../db/index.js';
import { inventory, inventoryBatches, stockAdjustments, staff } from '../db/schema/index.js';
import { eq, lte, gte, and, inArray, notInArray, sql, isNotNull, lt, or } from 'drizzle-orm';

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

// ─── 14. Stok Saat Ini ─────────────────────────────────────────────────────
export async function getCurrentStock(params: ReportParams) {
    const { branchId } = params;

    const conditions = [];
    if (branchId) conditions.push(eq(inventory.branchId, branchId));

    const items = await db
        .select({
            id: inventory.id,
            name: inventory.name,
            sku: inventory.sku,
            unit: inventory.unit,
            quantity: inventory.quantity,
            reorderThreshold: inventory.reorderThreshold,
        })
        .from(inventory)
        .where(conditions.length > 0 ? and(...conditions) : undefined);

    // Calculate asset value per item from batches (weighted average cost)
    const batchValues = await db
        .select({
            inventoryId: inventoryBatches.inventoryId,
            totalValue: sql<number>`SUM(CAST(${inventoryBatches.quantityRemaining} AS DECIMAL) * CAST(${inventoryBatches.costPrice} AS DECIMAL))`,
            avgCostPrice: sql<number>`CASE WHEN SUM(CAST(${inventoryBatches.quantityRemaining} AS DECIMAL)) > 0 
                THEN SUM(CAST(${inventoryBatches.quantityRemaining} AS DECIMAL) * CAST(${inventoryBatches.costPrice} AS DECIMAL)) / SUM(CAST(${inventoryBatches.quantityRemaining} AS DECIMAL))
                ELSE 0 END`,
        })
        .from(inventoryBatches)
        .groupBy(inventoryBatches.inventoryId);

    const batchMap = new Map(batchValues.map(b => [b.inventoryId, b]));

    return items.map(item => ({
        ...item,
        quantity: Number(item.quantity),
        reorderThreshold: Number(item.reorderThreshold),
        assetValue: batchMap.get(item.id)?.totalValue ?? 0,
        avgCostPrice: batchMap.get(item.id)?.avgCostPrice ?? 0,
    }));
}

// ─── 15. Stok Masuk ────────────────────────────────────────────────────────
export async function getStockIn(params: ReportParams) {
    const { start, end } = parseDates(params);

    const conditions = [];
    if (start) conditions.push(gte(inventoryBatches.receivedAt, start));
    if (end) conditions.push(lte(inventoryBatches.receivedAt, end));

    const batches = await db
        .select({
            id: inventoryBatches.id,
            batchNumber: inventoryBatches.batchNumber,
            supplierName: inventoryBatches.supplierName,
            quantityReceived: inventoryBatches.quantityReceived,
            quantityRemaining: inventoryBatches.quantityRemaining,
            costPrice: inventoryBatches.costPrice,
            receivedAt: inventoryBatches.receivedAt,
            expirationDate: inventoryBatches.expirationDate,
            notes: inventoryBatches.notes,
            inventoryName: inventory.name,
            inventorySku: inventory.sku,
            inventoryUnit: inventory.unit,
        })
        .from(inventoryBatches)
        .innerJoin(inventory, eq(inventoryBatches.inventoryId, inventory.id))
        .where(conditions.length > 0 ? and(...conditions) : undefined)
        .orderBy(inventoryBatches.receivedAt);

    return batches.map(b => ({
        ...b,
        quantityReceived: Number(b.quantityReceived),
        quantityRemaining: Number(b.quantityRemaining),
        costPrice: Number(b.costPrice),
        totalValue: Number(b.quantityReceived) * Number(b.costPrice),
    }));
}

// ─── 16. Stok Keluar ───────────────────────────────────────────────────────
export async function getStockOut(params: ReportParams) {
    const { start, end } = parseDates(params);

    const conditions: any[] = [
        inArray(stockAdjustments.type, ['OUT', 'ORDER']),
    ];
    if (start) conditions.push(gte(stockAdjustments.createdAt, start));
    if (end) conditions.push(lte(stockAdjustments.createdAt, end));

    const rows = await db
        .select({
            id: stockAdjustments.id,
            type: stockAdjustments.type,
            quantity: stockAdjustments.quantity,
            reason: stockAdjustments.reason,
            createdAt: stockAdjustments.createdAt,
            inventoryName: inventory.name,
            inventorySku: inventory.sku,
            inventoryUnit: inventory.unit,
            staffName: staff.name,
        })
        .from(stockAdjustments)
        .innerJoin(inventory, eq(stockAdjustments.inventoryId, inventory.id))
        .leftJoin(staff, eq(stockAdjustments.staffId, staff.id))
        .where(and(...conditions))
        .orderBy(stockAdjustments.createdAt);

    return rows.map(r => ({ ...r, quantity: Number(r.quantity) }));
}

// ─── 17. Stok Menipis (Low Stock) ─────────────────────────────────────────
export async function getLowStock(params: ReportParams) {
    const { branchId } = params;

    const conditions: any[] = [
        sql`CAST(${inventory.quantity} AS DECIMAL) <= CAST(${inventory.reorderThreshold} AS DECIMAL)`,
    ];
    if (branchId) conditions.push(eq(inventory.branchId, branchId));

    const items = await db
        .select({
            id: inventory.id,
            name: inventory.name,
            sku: inventory.sku,
            unit: inventory.unit,
            quantity: inventory.quantity,
            reorderThreshold: inventory.reorderThreshold,
        })
        .from(inventory)
        .where(and(...conditions))
        .orderBy(inventory.quantity);

    return items.map(item => ({
        ...item,
        quantity: Number(item.quantity),
        reorderThreshold: Number(item.reorderThreshold),
        deficit: Math.max(0, Number(item.reorderThreshold) - Number(item.quantity)),
    }));
}

// ─── 18. Stok Kadaluarsa ──────────────────────────────────────────────────
export async function getExpiredStock(_params: ReportParams) {
    // Show batches expiring within 30 days from now OR already expired
    const thirtyDaysFromNow = new Date();
    thirtyDaysFromNow.setDate(thirtyDaysFromNow.getDate() + 30);

    const batches = await db
        .select({
            id: inventoryBatches.id,
            batchNumber: inventoryBatches.batchNumber,
            quantityRemaining: inventoryBatches.quantityRemaining,
            expirationDate: inventoryBatches.expirationDate,
            inventoryName: inventory.name,
            inventorySku: inventory.sku,
            inventoryUnit: inventory.unit,
        })
        .from(inventoryBatches)
        .innerJoin(inventory, eq(inventoryBatches.inventoryId, inventory.id))
        .where(
            and(
                isNotNull(inventoryBatches.expirationDate),
                lte(inventoryBatches.expirationDate, thirtyDaysFromNow),
            )
        )
        .orderBy(inventoryBatches.expirationDate);

    const now = new Date();
    return batches.map(b => {
        const expDate = b.expirationDate ? new Date(b.expirationDate) : null;
        const daysUntilExpiry = expDate
            ? Math.floor((expDate.getTime() - now.getTime()) / (1000 * 60 * 60 * 24))
            : null;
        return {
            ...b,
            quantityRemaining: Number(b.quantityRemaining),
            daysUntilExpiry,
            status: daysUntilExpiry !== null && daysUntilExpiry < 0 ? 'Expired' : 'Expiring Soon',
        };
    });
}

// ─── 19. Penyesuaian Stok (Stock Opname) ─────────────────────────────────
export async function getStockAdjustments(params: ReportParams) {
    const { start, end } = parseDates(params);

    const conditions: any[] = [eq(stockAdjustments.type, 'ADJUSTMENT')];
    if (start) conditions.push(gte(stockAdjustments.createdAt, start));
    if (end) conditions.push(lte(stockAdjustments.createdAt, end));

    const rows = await db
        .select({
            id: stockAdjustments.id,
            quantity: stockAdjustments.quantity,
            reason: stockAdjustments.reason,
            createdAt: stockAdjustments.createdAt,
            inventoryName: inventory.name,
            inventorySku: inventory.sku,
            inventoryUnit: inventory.unit,
            staffName: staff.name,
        })
        .from(stockAdjustments)
        .innerJoin(inventory, eq(stockAdjustments.inventoryId, inventory.id))
        .leftJoin(staff, eq(stockAdjustments.staffId, staff.id))
        .where(and(...conditions))
        .orderBy(stockAdjustments.createdAt);

    return rows.map(r => ({ ...r, quantity: Number(r.quantity) }));
}

// ─── 20. Perputaran Inventori (Turnover) ──────────────────────────────────
export async function getInventoryTurnover(params: ReportParams) {
    const { start, end, branchId } = params;

    // Get all inventory items
    const inventoryConditions = [];
    if (branchId) inventoryConditions.push(eq(inventory.branchId, branchId));
    const allItems = await db.select().from(inventory)
        .where(inventoryConditions.length > 0 ? and(...inventoryConditions) : undefined);

    // Get total OUT+ORDER per item in date range
    const adjustmentConditions: any[] = [inArray(stockAdjustments.type, ['OUT', 'ORDER'])];
    if (start) adjustmentConditions.push(gte(stockAdjustments.createdAt, new Date(start)));
    if (end) adjustmentConditions.push(lte(stockAdjustments.createdAt, new Date(end + 'T23:59:59')));

    const outTotals = await db
        .select({
            inventoryId: stockAdjustments.inventoryId,
            totalOut: sql<number>`SUM(CAST(${stockAdjustments.quantity} AS DECIMAL))`,
        })
        .from(stockAdjustments)
        .where(and(...adjustmentConditions))
        .groupBy(stockAdjustments.inventoryId);

    const outMap = new Map(outTotals.map(o => [o.inventoryId, Number(o.totalOut)]));

    return allItems.map(item => {
        const totalOut = outMap.get(item.id) ?? 0;
        const currentStock = Number(item.quantity);
        const avgStock = currentStock > 0 ? (currentStock + totalOut) / 2 : totalOut > 0 ? totalOut / 2 : 0;
        const turnoverRatio = avgStock > 0 ? totalOut / avgStock : 0;

        return {
            id: item.id,
            name: item.name,
            sku: item.sku,
            unit: item.unit,
            currentStock,
            totalOut,
            avgStock: Number(avgStock.toFixed(2)),
            turnoverRatio: Number(turnoverRatio.toFixed(2)),
        };
    }).sort((a, b) => b.turnoverRatio - a.turnoverRatio);
}

// ─── 21. Dead Stock / Slow-Moving ─────────────────────────────────────────
export async function getDeadStock(params: ReportParams) {
    const { branchId } = params;

    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    // Find items that HAD OUT/ORDER in last 30 days
    const activeItemIds = await db
        .selectDistinct({ inventoryId: stockAdjustments.inventoryId })
        .from(stockAdjustments)
        .where(
            and(
                inArray(stockAdjustments.type, ['OUT', 'ORDER']),
                gte(stockAdjustments.createdAt, thirtyDaysAgo),
            )
        );

    const activeIds = activeItemIds.map(a => a.inventoryId);

    // Get all items NOT in that list
    const inventoryConditions: any[] = [];
    if (activeIds.length > 0) inventoryConditions.push(notInArray(inventory.id, activeIds));
    if (branchId) inventoryConditions.push(eq(inventory.branchId, branchId));

    const deadItems = await db
        .select({
            id: inventory.id,
            name: inventory.name,
            sku: inventory.sku,
            unit: inventory.unit,
            quantity: inventory.quantity,
        })
        .from(inventory)
        .where(inventoryConditions.length > 0 ? and(...inventoryConditions) : undefined);

    // Get last movement date for each dead item
    const lastMovements = await db
        .select({
            inventoryId: stockAdjustments.inventoryId,
            lastMovement: sql<Date>`MAX(${stockAdjustments.createdAt})`,
        })
        .from(stockAdjustments)
        .where(
            deadItems.length > 0
                ? inArray(stockAdjustments.inventoryId, deadItems.map(d => d.id))
                : sql`1=0`
        )
        .groupBy(stockAdjustments.inventoryId);

    const lastMovementMap = new Map(lastMovements.map(l => [l.inventoryId, l.lastMovement]));

    return deadItems.map(item => ({
        ...item,
        quantity: Number(item.quantity),
        lastMovement: lastMovementMap.get(item.id) ?? null,
        daysSinceMovement: lastMovementMap.get(item.id)
            ? Math.floor((Date.now() - new Date(lastMovementMap.get(item.id)!).getTime()) / (1000 * 60 * 60 * 24))
            : null,
    }));
}

// ─── 22. Nilai Inventori (Valuation) ──────────────────────────────────────
export async function getInventoryValuation(params: ReportParams) {
    const { branchId } = params;

    const inventoryConditions = [];
    if (branchId) inventoryConditions.push(eq(inventory.branchId, branchId));

    const items = await db
        .select({
            id: inventory.id,
            name: inventory.name,
            sku: inventory.sku,
            unit: inventory.unit,
            quantity: inventory.quantity,
        })
        .from(inventory)
        .where(inventoryConditions.length > 0 ? and(...inventoryConditions) : undefined);

    const batchValues = await db
        .select({
            inventoryId: inventoryBatches.inventoryId,
            totalValue: sql<number>`SUM(CAST(${inventoryBatches.quantityRemaining} AS DECIMAL) * CAST(${inventoryBatches.costPrice} AS DECIMAL))`,
            avgCostPrice: sql<number>`CASE WHEN SUM(CAST(${inventoryBatches.quantityRemaining} AS DECIMAL)) > 0 
                THEN SUM(CAST(${inventoryBatches.quantityRemaining} AS DECIMAL) * CAST(${inventoryBatches.costPrice} AS DECIMAL)) / SUM(CAST(${inventoryBatches.quantityRemaining} AS DECIMAL))
                ELSE 0 END`,
        })
        .from(inventoryBatches)
        .groupBy(inventoryBatches.inventoryId);

    const batchMap = new Map(batchValues.map(b => [b.inventoryId, b]));

    const result = items.map(item => ({
        ...item,
        quantity: Number(item.quantity),
        avgCostPrice: Number(batchMap.get(item.id)?.avgCostPrice ?? 0),
        totalValue: Number(batchMap.get(item.id)?.totalValue ?? 0),
    }));

    const grandTotalValue = result.reduce((sum, item) => sum + item.totalValue, 0);
    const totalItems = result.length;

    return {
        items: result,
        summary: {
            totalItems,
            grandTotalValue: Number(grandTotalValue.toFixed(2)),
        },
    };
}

export const inventoryReportsService = {
    getCurrentStock,
    getStockIn,
    getStockOut,
    getLowStock,
    getExpiredStock,
    getStockAdjustments,
    getInventoryTurnover,
    getDeadStock,
    getInventoryValuation,
};
