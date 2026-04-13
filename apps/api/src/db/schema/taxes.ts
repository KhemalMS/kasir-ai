import { mysqlTable, varchar, text, decimal, boolean, timestamp } from 'drizzle-orm/mysql-core';
import { sql } from 'drizzle-orm';

export const taxes = mysqlTable('taxes', {
    id: varchar('id', { length: 36 }).primaryKey().$defaultFn(() => sql`(UUID())`),
    name: varchar('name', { length: 100 }).notNull(),
    description: text('description'),
    rate: decimal('rate', { precision: 5, scale: 2 }).notNull(),
    isActive: boolean('is_active').default(true),
    createdAt: timestamp('created_at').defaultNow().notNull(),
    updatedAt: timestamp('updated_at').defaultNow().notNull(),
});
