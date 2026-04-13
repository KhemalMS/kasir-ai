import { db } from '../db/index.js';
import { staff } from '../db/schema/staff.js';
import { eq, and, like, or } from 'drizzle-orm';
import { v4 as uuidv4 } from 'uuid';

export const staffService = {
    async findAll(filters?: { branchId?: string; role?: string; search?: string }) {
        const conditions = [];
        if (filters?.branchId) conditions.push(eq(staff.branchId, filters.branchId));
        if (filters?.role) conditions.push(eq(staff.role, filters.role));
        if (filters?.search) {
            conditions.push(
                or(
                    like(staff.name, `%${filters.search}%`),
                    like(staff.email, `%${filters.search}%`)
                )!
            );
        }

        if (conditions.length > 0) {
            return db.select().from(staff).where(and(...conditions));
        }
        return db.select().from(staff);
    },

    async findById(id: string) {
        const [member] = await db.select().from(staff).where(eq(staff.id, id));
        return member || null;
    },

    async findByUserId(userId: string) {
        const [member] = await db.select().from(staff).where(eq(staff.userId, userId));
        return member || null;
    },

    async create(data: typeof staff.$inferInsert) {
        const id = data.id || uuidv4();
        await db.insert(staff).values({ ...data, id });
        return this.findById(id);
    },

    async update(id: string, data: Partial<typeof staff.$inferInsert>) {
        await db
            .update(staff)
            .set({ ...data, updatedAt: new Date() })
            .where(eq(staff.id, id));
        return this.findById(id);
    },

    async delete(id: string) {
        const member = await this.findById(id);
        if (!member) return null;
        await db.delete(staff).where(eq(staff.id, id));
        return member;
    },
};
