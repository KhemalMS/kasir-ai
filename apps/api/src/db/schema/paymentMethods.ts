import { mysqlTable, varchar, text, boolean, json, timestamp } from 'drizzle-orm/mysql-core';
import { sql } from 'drizzle-orm';

export const paymentMethods = mysqlTable('payment_methods', {
    id: varchar('id', { length: 36 }).primaryKey().$defaultFn(() => sql`(UUID())`),
    name: varchar('name', { length: 100 }).notNull(),
    description: text('description'),
    isActive: boolean('is_active').default(true),
    config: json('config'),
    createdAt: timestamp('created_at').defaultNow().notNull(),
    updatedAt: timestamp('updated_at').defaultNow().notNull(),
});
