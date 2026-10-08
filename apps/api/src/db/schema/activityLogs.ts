import { mysqlTable, varchar, text, timestamp } from 'drizzle-orm/mysql-core';
import { sql } from 'drizzle-orm';
import { staff } from './staff.js';

export const activityLogs = mysqlTable('activity_logs', {
    id:          varchar('id', { length: 36 }).primaryKey().$defaultFn(() => sql`(UUID())`),
    staffId:     varchar('staff_id', { length: 36 }).notNull().references(() => staff.id, { onDelete: 'cascade' }),
    action:      varchar('action', { length: 50 }).notNull(),
    description: text('description'),
    createdAt:   timestamp('created_at').defaultNow().notNull(),
});
