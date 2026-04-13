import { db } from '../db/index.js';
import { expenses } from '../db/schema/expenses.js';
import { eq, and, desc, between } from 'drizzle-orm';
import { AppError } from '../middleware/errorHandler.js';
import { v4 as uuidv4 } from 'uuid';

export const expensesService = {
    async findAll(filters?: {
        branchId?: string;
        category?: string;
        status?: string;
        startDate?: Date;
        endDate?: Date;
    }) {
        const conditions = [];
        if (filters?.branchId) conditions.push(eq(expenses.branchId, filters.branchId));
        if (filters?.category) conditions.push(eq(expenses.category, filters.category));
        if (filters?.status) conditions.push(eq(expenses.status, filters.status));
        if (filters?.startDate && filters?.endDate) {
            conditions.push(between(expenses.createdAt, filters.startDate, filters.endDate));
        }

        const query = conditions.length > 0 ? and(...conditions) : undefined;
        return db.select().from(expenses).where(query).orderBy(desc(expenses.createdAt));
    },

    async findById(id: string) {
        const [expense] = await db.select().from(expenses).where(eq(expenses.id, id));
        return expense || null;
    },

    async create(data: typeof expenses.$inferInsert) {
        const id = data.id || uuidv4();
        await db.insert(expenses).values({ ...data, id });
        return this.findById(id);
    },

    async update(id: string, data: Partial<typeof expenses.$inferInsert>) {
        await db
            .update(expenses)
            .set({ ...data, updatedAt: new Date() })
            .where(eq(expenses.id, id));
        return this.findById(id);
    },

    async approve(id: string, status: 'Disetujui' | 'Ditolak') {
        await db
            .update(expenses)
            .set({ status, updatedAt: new Date() })
            .where(eq(expenses.id, id));
        const expense = await this.findById(id);
        if (!expense) throw new AppError('Expense not found', 404);
        return expense;
    },

    async delete(id: string) {
        const expense = await this.findById(id);
        await db.delete(expenses).where(eq(expenses.id, id));
        return expense;
    },
};
