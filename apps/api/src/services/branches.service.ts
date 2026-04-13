import { db } from '../db/index.js';
import { branches } from '../db/schema/branches.js';
import { eq } from 'drizzle-orm';
import { v4 as uuidv4 } from 'uuid';

export const branchesService = {
    async findAll() {
        return db.select().from(branches);
    },

    async findById(id: string) {
        const [branch] = await db.select().from(branches).where(eq(branches.id, id));
        return branch || null;
    },

    async create(data: typeof branches.$inferInsert) {
        const id = data.id || uuidv4();
        await db.insert(branches).values({ ...data, id });
        return this.findById(id);
    },

    async update(id: string, data: Partial<typeof branches.$inferInsert>) {
        await db
            .update(branches)
            .set({ ...data, updatedAt: new Date() })
            .where(eq(branches.id, id));
        return this.findById(id);
    },

    async delete(id: string) {
        const branch = await this.findById(id);
        await db.delete(branches).where(eq(branches.id, id));
        return branch;
    },
};
