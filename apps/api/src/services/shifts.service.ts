import { db } from '../db/index.js';
import { shifts } from '../db/schema/shifts.js';
import { orders } from '../db/schema/orders.js';
import { payments } from '../db/schema/payments.js';
import { expenses } from '../db/schema/expenses.js';
import { eq, and, sum, desc } from 'drizzle-orm';
import { AppError } from '../middleware/errorHandler.js';
import { v4 as uuidv4 } from 'uuid';

export const shiftsService = {
    async findAll(filters?: { branchId?: string; staffId?: string }) {
        const conditions = [];
        if (filters?.branchId) conditions.push(eq(shifts.branchId, filters.branchId));
        if (filters?.staffId) conditions.push(eq(shifts.staffId, filters.staffId));

        const query = conditions.length > 0 ? and(...conditions) : undefined;
        return db.select().from(shifts).where(query).orderBy(desc(shifts.startedAt));
    },

    async findCurrent(staffId: string) {
        const [shift] = await db
            .select()
            .from(shifts)
            .where(and(eq(shifts.staffId, staffId), eq(shifts.status, 'Open')));
        return shift || null;
    },

    async start(data: { staffId: string; branchId: string; startingCash: number }) {
        const existing = await this.findCurrent(data.staffId);
        if (existing) return existing; // Return existing open shift instead of error

        const id = uuidv4();
        await db
            .insert(shifts)
            .values({
                id,
                staffId: data.staffId,
                branchId: data.branchId,
                startingCash: data.startingCash,
                status: 'Open',
            });
        const [shift] = await db.select().from(shifts).where(eq(shifts.id, id));
        return shift;
    },

    async close(id: string, endingCash: number) {
        const [shift] = await db.select().from(shifts).where(eq(shifts.id, id));
        if (!shift) throw new AppError('Shift not found', 404);
        if (shift.status === 'Closed') throw new AppError('Shift already closed', 400);

        const cashSalesResult = await db
            .select({ total: sum(payments.amount) })
            .from(payments)
            .innerJoin(orders, eq(payments.orderId, orders.id))
            .where(and(eq(orders.shiftId, id), eq(payments.method, 'Tunai')));

        const qrisSalesResult = await db
            .select({ total: sum(payments.amount) })
            .from(payments)
            .innerJoin(orders, eq(payments.orderId, orders.id))
            .where(and(eq(orders.shiftId, id), eq(payments.method, 'QRIS')));

        const cardSalesResult = await db
            .select({ total: sum(payments.amount) })
            .from(payments)
            .innerJoin(orders, eq(payments.orderId, orders.id))
            .where(
                and(
                    eq(orders.shiftId, id),
                )
            );

        const expensesResult = await db
            .select({ total: sum(expenses.amount) })
            .from(expenses)
            .where(eq(expenses.shiftId, id));

        const totalCashSales = Number(cashSalesResult[0]?.total) || 0;
        const totalQrisSales = Number(qrisSalesResult[0]?.total) || 0;
        const totalCardSales = Number(cardSalesResult[0]?.total) || 0;
        const totalExpenses = Number(expensesResult[0]?.total) || 0;

        const expectedCash = shift.startingCash + totalCashSales - totalExpenses;
        const cashDifference = endingCash - expectedCash;

        await db
            .update(shifts)
            .set({
                endingCash,
                expectedCash,
                cashDifference,
                totalCashSales,
                totalQrisSales,
                totalCardSales,
                totalExpenses,
                status: 'Closed',
                closedAt: new Date(),
            })
            .where(eq(shifts.id, id));

        const [closedShift] = await db.select().from(shifts).where(eq(shifts.id, id));
        return closedShift;
    },

    async getSummary(id: string) {
        const [shift] = await db.select().from(shifts).where(eq(shifts.id, id));
        if (!shift) return null;

        // For open shifts, calculate live sales from payments table
        if (shift.status === 'Open') {
            const cashResult = await db
                .select({ total: sum(payments.amount) })
                .from(payments)
                .innerJoin(orders, eq(payments.orderId, orders.id))
                .where(and(eq(orders.shiftId, id), eq(payments.method, 'Tunai')));

            const qrisResult = await db
                .select({ total: sum(payments.amount) })
                .from(payments)
                .innerJoin(orders, eq(payments.orderId, orders.id))
                .where(and(eq(orders.shiftId, id), eq(payments.method, 'QRIS')));

            const cardResult = await db
                .select({ total: sum(payments.amount) })
                .from(payments)
                .innerJoin(orders, eq(payments.orderId, orders.id))
                .where(and(eq(orders.shiftId, id), eq(payments.method, 'Kartu')));

            const orderCount = await db
                .select({ count: sum(orders.totalAmount) })
                .from(orders)
                .where(eq(orders.shiftId, id));

            return {
                ...shift,
                totalCashSales: Number(cashResult[0]?.total) || 0,
                totalQrisSales: Number(qrisResult[0]?.total) || 0,
                totalCardSales: Number(cardResult[0]?.total) || 0,
                totalSales: Number(orderCount[0]?.count) || 0,
            };
        }

        // For closed shifts, data is already in the shift record
        return shift;
    },
};
