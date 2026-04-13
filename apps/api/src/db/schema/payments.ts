import { mysqlTable, varchar, int, timestamp } from 'drizzle-orm/mysql-core';
import { sql } from 'drizzle-orm';
import { orders } from './orders';

export const payments = mysqlTable('payments', {
    id: varchar('id', { length: 36 }).primaryKey().$defaultFn(() => sql`(UUID())`),
    orderId: varchar('order_id', { length: 36 }).notNull().references(() => orders.id, { onDelete: 'cascade' }),
    method: varchar('method', { length: 50 }).notNull(),
    amount: int('amount').notNull(),
    reference: varchar('reference', { length: 255 }),
    createdAt: timestamp('created_at').defaultNow().notNull(),
});
