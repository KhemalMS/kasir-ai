import { mysqlTable, varchar, date, datetime, timestamp } from 'drizzle-orm/mysql-core';
import { sql } from 'drizzle-orm';
import { staff } from './staff';

export const attendances = mysqlTable('attendances', {
    id:          varchar('id', { length: 36 }).primaryKey().$defaultFn(() => sql`(UUID())`),
    staffId:     varchar('staff_id', { length: 36 }).notNull().references(() => staff.id, { onDelete: 'cascade' }),
    date:        date('date').notNull(),
    clockInTime: datetime('clock_in_time'),
    clockOutTime: datetime('clock_out_time'),
    // status: 'on-time' | 'late' | 'absent'
    status:      varchar('status', { length: 20 }).notNull().default('on-time'),
    notes:       varchar('notes', { length: 500 }),
    createdAt:   timestamp('created_at').defaultNow().notNull(),
    updatedAt:   timestamp('updated_at').defaultNow().notNull(),
});
