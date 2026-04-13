import { db } from '../db/index.js';
import { categories } from '../db/schema/categories.js';
import { eq } from 'drizzle-orm';
import { v4 as uuidv4 } from 'uuid';

export const categoriesService = {
    async findAll() {
        return db.select().from(categories);
    },

    async findById(id: string) {
        const [category] = await db.select().from(categories).where(eq(categories.id, id));
        return category || null;
    },

    async create(data: typeof categories.$inferInsert) {
        const id = data.id || uuidv4();
        await db.insert(categories).values({ ...data, id });
        return this.findById(id);
    },

    async update(id: string, data: Partial<typeof categories.$inferInsert>) {
        await db
            .update(categories)
            .set(data)
            .where(eq(categories.id, id));
        return this.findById(id);
    },

    async delete(id: string) {
        const category = await this.findById(id);
        await db.delete(categories).where(eq(categories.id, id));
        return category;
    },
};
