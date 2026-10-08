import { db } from '../db/index.js';
import { staff, orders, attendances, activityLogs } from '../db/schema/index.js';
import { eq, and, gte, lte, sql, desc, inArray } from 'drizzle-orm';

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

const COMMISSION_RATE = 0.01;

// ─── 38. Performa Kasir ────────────────────────────────────────────────────
export async function getCashierPerformance(params: ReportParams) {
    const { start, end } = parseDates(params);
    const { branchId } = params;

    // Build date conditions for orders
    const baseConditions: any[] = [];
    if (start)    baseConditions.push(gte(orders.createdAt, start));
    if (end)      baseConditions.push(lte(orders.createdAt, end));
    if (branchId) baseConditions.push(eq(orders.branchId, branchId));

    const rows = await db
        .select({
            staffId:           orders.staffId,
            staffName:         staff.name,
            transactionCount:  sql<number>`COALESCE(SUM(CASE WHEN ${orders.status} = 'Sukses' THEN 1 ELSE 0 END), 0)`,
            totalSales:        sql<number>`COALESCE(SUM(CASE WHEN ${orders.status} = 'Sukses' THEN ${orders.totalAmount} ELSE 0 END), 0)`,
            avgServiceSeconds: sql<number>`ROUND(AVG(CASE WHEN ${orders.status} = 'Sukses' THEN TIMESTAMPDIFF(SECOND, ${orders.createdAt}, ${orders.updatedAt}) ELSE NULL END), 0)`,
            errorCount:        sql<number>`COALESCE(SUM(CASE WHEN ${orders.status} IN ('Dibatalkan', 'Void') THEN 1 ELSE 0 END), 0)`,
            totalOrders:       sql<number>`COUNT(${orders.id})`,
        })
        .from(orders)
        .innerJoin(staff, eq(orders.staffId, staff.id))
        .where(baseConditions.length > 0 ? and(...baseConditions) : undefined)
        .groupBy(orders.staffId, staff.name)
        .orderBy(desc(sql`COALESCE(SUM(CASE WHEN ${orders.status} = 'Sukses' THEN ${orders.totalAmount} ELSE 0 END), 0)`));

    return rows.map(r => ({
        ...r,
        transactionCount:  Number(r.transactionCount),
        totalSales:        Number(r.totalSales),
        avgServiceSeconds: Number(r.avgServiceSeconds ?? 0),
        errorCount:        Number(r.errorCount),
        totalOrders:       Number(r.totalOrders),
        errorRate:         Number(r.totalOrders) > 0
            ? parseFloat((Number(r.errorCount) / Number(r.totalOrders) * 100).toFixed(2))
            : 0,
    }));
}

// ─── 39. Absensi & Jam Kerja ───────────────────────────────────────────────
export async function getAttendanceReport(params: ReportParams) {
    const { start, end } = parseDates(params);
    const { branchId } = params;

    const conditions: any[] = [];
    // attendances.date is a DATE column → compare with Date objects (time ignored by MySQL)
    if (start) conditions.push(gte(attendances.date, start));
    if (end)   conditions.push(lte(attendances.date, end));

    // branchId filter via staff join
    const staffConditions: any[] = [];
    if (branchId) staffConditions.push(eq(staff.branchId, branchId));

    const rows = await db
        .select({
            staffName:       staff.name,
            date:            attendances.date,
            clockInTime:     attendances.clockInTime,
            clockOutTime:    attendances.clockOutTime,
            status:          attendances.status,
            notes:           attendances.notes,
            durationMinutes: sql<number>`TIMESTAMPDIFF(MINUTE, ${attendances.clockInTime}, ${attendances.clockOutTime})`,
        })
        .from(attendances)
        .innerJoin(staff, eq(attendances.staffId, staff.id))
        .where(
            [...conditions, ...staffConditions].length > 0
                ? and(...conditions, ...staffConditions)
                : undefined
        )
        .orderBy(desc(attendances.date), staff.name);

    return rows.map(r => ({
        ...r,
        durationMinutes: Number(r.durationMinutes ?? 0),
    }));
}

// ─── 40. Komisi Sales ─────────────────────────────────────────────────────
export async function getSalesCommissions(params: ReportParams) {
    const { start, end } = parseDates(params);
    const { branchId } = params;

    const conditions: any[] = [eq(orders.status, 'Sukses')];
    if (start)    conditions.push(gte(orders.createdAt, start));
    if (end)      conditions.push(lte(orders.createdAt, end));
    if (branchId) conditions.push(eq(orders.branchId, branchId));

    const rows = await db
        .select({
            staffId:    orders.staffId,
            staffName:  staff.name,
            totalSales: sql<number>`COALESCE(SUM(${orders.totalAmount}), 0)`,
        })
        .from(orders)
        .innerJoin(staff, eq(orders.staffId, staff.id))
        .where(and(...conditions))
        .groupBy(orders.staffId, staff.name)
        .orderBy(desc(sql`COALESCE(SUM(CASE WHEN ${orders.status} = 'Sukses' THEN ${orders.totalAmount} ELSE 0 END), 0)`));

    return rows.map(r => ({
        staffId:          r.staffId,
        staffName:        r.staffName,
        totalSales:       Number(r.totalSales),
        commissionRate:   '1%',
        commissionAmount: Math.round(Number(r.totalSales) * COMMISSION_RATE),
    }));
}

// ─── 41. Log Aktivitas User ───────────────────────────────────────────────
export async function getActivityLogs(params: ReportParams) {
    const { start, end } = parseDates(params);

    const conditions: any[] = [];
    if (start) conditions.push(gte(activityLogs.createdAt, start));
    if (end)   conditions.push(lte(activityLogs.createdAt, end));

    const rows = await db
        .select({
            id:          activityLogs.id,
            createdAt:   activityLogs.createdAt,
            staffName:   staff.name,
            action:      activityLogs.action,
            description: activityLogs.description,
        })
        .from(activityLogs)
        .innerJoin(staff, eq(activityLogs.staffId, staff.id))
        .where(conditions.length > 0 ? and(...conditions) : undefined)
        .orderBy(desc(activityLogs.createdAt))
        .limit(500);

    return rows;
}


