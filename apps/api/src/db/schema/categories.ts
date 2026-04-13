import { mysqlTable, varchar, timestamp } from 'drizzle-orm/mysql-core';
import { sql } from 'drizzle-orm';

export const categories = mysqlTable('categories', {
    id: varchar('id', { length: 36 }).primaryKey().$defaultFn(() => sql`(UUID())`),
    name: varchar('name', { length: 100 }).unique().notNull(),
    createdAt: timestamp('created_at').defaultNow().notNull(),
});
