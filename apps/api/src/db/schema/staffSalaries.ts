import { mysqlTable, varchar, int, text, timestamp, date } from 'drizzle-orm/mysql-core';
import { sql } from 'drizzle-orm';
import { staff } from './staff';

export const staffSalaries = mysqlTable('staff_salaries', {
    id:            varchar('id', { length: 36 }).primaryKey().$defaultFn(() => sql`(UUID())`),
    staffId:       varchar('staff_id', { length: 36 }).notNull().references(() => staff.id, { onDelete: 'cascade' }),
    salaryType:    varchar('salary_type', { length: 20 }).notNull(), // 'Tetap' | 'Per Jam'
    amount:        int('amount').notNull(),                           // Nominal dalam Rupiah
    effectiveDate: date('effective_date').notNull(),
    notes:         text('notes'),
    createdAt:     timestamp('created_at').defaultNow().notNull(),
});
