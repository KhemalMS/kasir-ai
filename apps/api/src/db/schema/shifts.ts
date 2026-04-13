import { mysqlTable, varchar, int, timestamp, datetime } from 'drizzle-orm/mysql-core';
import { sql } from 'drizzle-orm';
import { staff } from './staff';
import { branches } from './branches';

export const shifts = mysqlTable('shifts', {
    id: varchar('id', { length: 36 }).primaryKey().$defaultFn(() => sql`(UUID())`),
    staffId: varchar('staff_id', { length: 36 }).notNull().references(() => staff.id),
    branchId: varchar('branch_id', { length: 36 }).notNull().references(() => branches.id),
    startingCash: int('starting_cash').notNull(),
    endingCash: int('ending_cash'),
    expectedCash: int('expected_cash'),
    cashDifference: int('cash_difference'),
    totalCashSales: int('total_cash_sales'),
    totalQrisSales: int('total_qris_sales'),
    totalCardSales: int('total_card_sales'),
    totalExpenses: int('total_expenses'),
    status: varchar('status', { length: 20 }).notNull().default('Open'),
    startedAt: timestamp('started_at').defaultNow().notNull(),
    closedAt: datetime('closed_at'),
});
