import { mysqlTable, varchar, text, timestamp } from 'drizzle-orm/mysql-core';
import { sql } from 'drizzle-orm';

export const settings = mysqlTable('settings', {
    id: varchar('id', { length: 36 }).primaryKey().$defaultFn(() => sql`(UUID())`),
    key: varchar('key', { length: 100 }).unique().notNull(),
    value: text('value').notNull(),
    group: varchar('group', { length: 50 }).notNull(),
    updatedAt: timestamp('updated_at').defaultNow().notNull(),
});
