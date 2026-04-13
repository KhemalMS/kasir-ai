import { db } from '../db/index.js';
import { payments } from '../db/schema/payments.js';
import { eq } from 'drizzle-orm';

export const paymentsService = {
    async findByOrderId(orderId: string) {
        return db.select().from(payments).where(eq(payments.orderId, orderId));
    },

    async findAll() {
        return db.select().from(payments);
    },
};
