import { db } from '../db/index.js';
import { settings } from '../db/schema/settings.js';
import { paymentMethods } from '../db/schema/paymentMethods.js';
import { taxes } from '../db/schema/taxes.js';
import { eq } from 'drizzle-orm';
import { v4 as uuidv4 } from 'uuid';

export const settingsService = {
    // General settings
    async findAll() {
        return db.select().from(settings);
    },

    async findByGroup(group: string) {
        return db.select().from(settings).where(eq(settings.group, group));
    },

    async upsert(key: string, value: string, group: string) {
        const existing = await db.select().from(settings).where(eq(settings.key, key));
        if (existing.length > 0) {
            await db
                .update(settings)
                .set({ value, updatedAt: new Date() })
                .where(eq(settings.key, key));
            const [setting] = await db.select().from(settings).where(eq(settings.key, key));
            return setting;
        }
        const id = uuidv4();
        await db.insert(settings).values({ id, key, value, group });
        const [setting] = await db.select().from(settings).where(eq(settings.id, id));
        return setting;
    },

    async bulkUpdate(items: { key: string; value: string; group: string }[]) {
        const results = [];
        for (const item of items) {
            const result = await this.upsert(item.key, item.value, item.group);
            results.push(result);
        }
        return results;
    },

    // Payment methods
    async getPaymentMethods() {
        return db.select().from(paymentMethods);
    },

    async createPaymentMethod(data: typeof paymentMethods.$inferInsert) {
        const id = data.id || uuidv4();
        await db.insert(paymentMethods).values({ ...data, id });
        const [method] = await db.select().from(paymentMethods).where(eq(paymentMethods.id, id));
        return method;
    },

    async updatePaymentMethod(id: string, data: Partial<typeof paymentMethods.$inferInsert>) {
        await db
            .update(paymentMethods)
            .set({ ...data, updatedAt: new Date() })
            .where(eq(paymentMethods.id, id));
        const [method] = await db.select().from(paymentMethods).where(eq(paymentMethods.id, id));
        return method;
    },

    async deletePaymentMethod(id: string) {
        const [method] = await db.select().from(paymentMethods).where(eq(paymentMethods.id, id));
        await db.delete(paymentMethods).where(eq(paymentMethods.id, id));
        return method;
    },

    // Taxes
    async getTaxes() {
        return db.select().from(taxes);
    },

    async createTax(data: typeof taxes.$inferInsert) {
        const id = data.id || uuidv4();
        await db.insert(taxes).values({ ...data, id });
        const [tax] = await db.select().from(taxes).where(eq(taxes.id, id));
        return tax;
    },

    async updateTax(id: string, data: Partial<typeof taxes.$inferInsert>) {
        await db
            .update(taxes)
            .set({ ...data, updatedAt: new Date() })
            .where(eq(taxes.id, id));
        const [tax] = await db.select().from(taxes).where(eq(taxes.id, id));
        return tax;
    },

    async deleteTax(id: string) {
        const [tax] = await db.select().from(taxes).where(eq(taxes.id, id));
        await db.delete(taxes).where(eq(taxes.id, id));
        return tax;
    },
};
