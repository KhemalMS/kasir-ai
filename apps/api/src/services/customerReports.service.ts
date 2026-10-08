import { db } from '../db/index.js';
import { customers, orders } from '../db/schema/index.js';
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

function orderConditions(params: ReportParams) {
    const { start, end } = parseDates(params);
    const conds: any[] = [eq(orders.status, 'Sukses')];
    if (start) conds.push(gte(orders.createdAt, start));
    if (end)   conds.push(lte(orders.createdAt, end));
    if (params.branchId) conds.push(eq(orders.branchId, params.branchId));
    return conds;
}

// ─── 30. Daftar Pelanggan ─────────────────────────────────────────────────
export async function getCustomerList(params: ReportParams) {
    const conds = orderConditions(params);

    const stats = db
        .select({
            customerId: orders.customerId,
            orderCount: sql<number>`COUNT(${orders.id})`.as('order_count'),
            totalSpent: sql<number>`COALESCE(SUM(${orders.totalAmount}), 0)`.as('total_spent'),
            lastOrderAt: sql<string>`MAX(${orders.createdAt})`.as('last_order_at'),
        })
        .from(orders)
        .where(and(...conds))
        .groupBy(orders.customerId)
        .as('stats');

    const rows = await db
        .select({
            id: customers.id,
            name: customers.name,
            phone: customers.phone,
            email: customers.email,
            points: customers.points,
            tier: customers.tier,
            createdAt: customers.createdAt,
            orderCount: stats.orderCount,
            totalSpent: stats.totalSpent,
            lastOrderAt: stats.lastOrderAt,
        })
        .from(customers)
        .leftJoin(stats, eq(customers.id, stats.customerId))
        .orderBy(desc(customers.createdAt));

    return rows.map(r => ({
        ...r,
        orderCount: Number(r.orderCount ?? 0),
        totalSpent: Number(r.totalSpent ?? 0),
    }));
}

// ─── 31. Pelanggan Paling Sering Beli ────────────────────────────────────
export async function getTopFrequency(params: ReportParams) {
    const conds = orderConditions(params);

    const rows = await db
        .select({
            name: customers.name,
            phone: customers.phone,
            tier: customers.tier,
            orderCount: sql<number>`COUNT(${orders.id})`.as('order_count'),
        })
        .from(customers)
        .innerJoin(orders, and(eq(orders.customerId, customers.id), ...conds))
        .groupBy(customers.id, customers.name, customers.phone, customers.tier)
        .orderBy(desc(sql`COUNT(${orders.id})`))
        .limit(50);

    return rows.map((r, i) => ({ rank: i + 1, ...r, orderCount: Number(r.orderCount) }));
}

// ─── 32. Top Spender ─────────────────────────────────────────────────────
export async function getTopSpender(params: ReportParams) {
    const conds = orderConditions(params);

    const rows = await db
        .select({
            name: customers.name,
            phone: customers.phone,
            tier: customers.tier,
            orderCount: sql<number>`COUNT(${orders.id})`.as('order_count'),
            totalSpent: sql<number>`SUM(${orders.totalAmount})`.as('total_spent'),
        })
        .from(customers)
        .innerJoin(orders, and(eq(orders.customerId, customers.id), ...conds))
        .groupBy(customers.id, customers.name, customers.phone, customers.tier)
        .orderBy(desc(sql`SUM(${orders.totalAmount})`))
        .limit(50);

    return rows.map((r, i) => ({
        rank: i + 1, ...r,
        orderCount: Number(r.orderCount),
        totalSpent: Number(r.totalSpent),
    }));
}

// ─── 33. Analisis RFM ────────────────────────────────────────────────────
export async function getRFM(params: ReportParams) {
    const conds = orderConditions(params);

    const rows = await db
        .select({
            name: customers.name,
            phone: customers.phone,
            recencyDays: sql<number>`DATEDIFF(NOW(), MAX(${orders.createdAt}))`.as('recency_days'),
            frequency:   sql<number>`COUNT(${orders.id})`.as('frequency'),
            monetary:    sql<number>`SUM(${orders.totalAmount})`.as('monetary'),
        })
        .from(customers)
        .innerJoin(orders, and(eq(orders.customerId, customers.id), ...conds))
        .groupBy(customers.id, customers.name, customers.phone)
        .orderBy(desc(sql`SUM(${orders.totalAmount})`));

    return rows.map(r => ({
        ...r,
        recencyDays: Number(r.recencyDays),
        frequency: Number(r.frequency),
        monetary: Number(r.monetary),
    }));
}

// ─── 34. Status Loyalitas ─────────────────────────────────────────────────
export async function getLoyaltyStatus(_params: ReportParams) {
    const rows = await db
        .select({
            name: customers.name,
            phone: customers.phone,
            points: customers.points,
            tier: customers.tier,
            orderCount: sql<number>`COUNT(${orders.id})`.as('order_count'),
        })
        .from(customers)
        .leftJoin(orders, and(eq(orders.customerId, customers.id), eq(orders.status, 'Sukses')))
        .groupBy(customers.id, customers.name, customers.phone, customers.points, customers.tier)
        .orderBy(desc(customers.points));

    return rows.map(r => ({ ...r, orderCount: Number(r.orderCount) }));
}

// ─── 35. Retensi Pelanggan ────────────────────────────────────────────────
export async function getRetentionRate(params: ReportParams) {
    const conds = orderConditions(params);

    // Subquery: count orders per customer
    const perCustomer = await db
        .select({
            customerId: orders.customerId,
            cnt: sql<number>`COUNT(${orders.id})`.as('cnt'),
        })
        .from(orders)
        .where(and(...conds))
        .groupBy(orders.customerId);

    const totalCustomers = perCustomer.length;
    const returningCount = perCustomer.filter(r => Number(r.cnt) > 1).length;
    const oneTimeCount   = totalCustomers - returningCount;
    const retentionRatePct = totalCustomers > 0
        ? Number(((returningCount / totalCustomers) * 100).toFixed(1))
        : 0;

    return { totalCustomers, returningCount, oneTimeCount, retentionRatePct };
}

// ─── 36. Akuisisi Pelanggan Baru ─────────────────────────────────────────
export async function getNewAcquisitions(params: ReportParams) {
    const { start, end } = parseDates(params);
    const conds: any[] = [];
    if (start) conds.push(gte(customers.createdAt, start));
    if (end)   conds.push(lte(customers.createdAt, end));

    const dailyBreakdown = await db
        .select({
            date: sql<string>`DATE(${customers.createdAt})`.as('date'),
            newCustomers: sql<number>`COUNT(*)`.as('new_customers'),
        })
        .from(customers)
        .where(conds.length > 0 ? and(...conds) : undefined)
        .groupBy(sql`DATE(${customers.createdAt})`)
        .orderBy(sql`DATE(${customers.createdAt})`);

    const total = dailyBreakdown.reduce((s, r) => s + Number(r.newCustomers), 0);

    return {
        total,
        dailyBreakdown: dailyBreakdown.map(r => ({
            date: r.date,
            newCustomers: Number(r.newCustomers),
        })),
    };
}

// ─── 37. Ulang Tahun Pelanggan ────────────────────────────────────────────
export async function getUpcomingBirthdays(_params: ReportParams) {
    const rows = await db
        .select({
            name: customers.name,
            phone: customers.phone,
            birthdate: customers.birthdate,
            tier: customers.tier,
        })
        .from(customers)
        .where(sql`MONTH(${customers.birthdate}) IN (MONTH(CURDATE()), MONTH(DATE_ADD(CURDATE(), INTERVAL 1 MONTH)))`)
        .orderBy(sql`MONTH(${customers.birthdate})`, sql`DAY(${customers.birthdate})`);

    const currentMonth = new Date().getMonth() + 1;
    return rows.map(r => ({
        ...r,
        isBirthdayThisMonth: r.birthdate ? new Date(r.birthdate).getMonth() + 1 === currentMonth : false,
    }));
}

export const customerReportsService = {
    getCustomerList,
    getTopFrequency,
    getTopSpender,
    getRFM,
    getLoyaltyStatus,
    getRetentionRate,
    getNewAcquisitions,
    getUpcomingBirthdays,
};
