import { mysqlTable, varchar, text, int, timestamp } from 'drizzle-orm/mysql-core';
import { sql } from 'drizzle-orm';
import { staff } from './staff';
import { branches } from './branches';
import { shifts } from './shifts';

export const expenses = mysqlTable('expenses', {
    id: varchar('id', { length: 36 }).primaryKey().$defaultFn(() => sql`(UUID())`),
    staffId: varchar('staff_id', { length: 36 }).notNull().references(() => staff.id),
    branchId: varchar('branch_id', { length: 36 }).notNull().references(() => branches.id),
    shiftId: varchar('shift_id', { length: 36 }).references(() => shifts.id),
    amount: int('amount').notNull(),
    category: varchar('category', { length: 100 }).notNull(),
    source: varchar('source', { length: 50 }).notNull().default('Kasir'),
    description: text('description'),
    receiptImageUrl: text('receipt_image_url'),
    status: varchar('status', { length: 30 }).notNull().default('Pending'),
    createdAt: timestamp('created_at').defaultNow().notNull(),
    updatedAt: timestamp('updated_at').defaultNow().notNull(),
});
