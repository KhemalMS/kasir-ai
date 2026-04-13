import { mysqlTable, varchar, text, int, timestamp } from 'drizzle-orm/mysql-core';
import { sql } from 'drizzle-orm';
import { staff } from './staff';
import { branches } from './branches';
import { shifts } from './shifts';

export const orders = mysqlTable('orders', {
    id: varchar('id', { length: 36 }).primaryKey().$defaultFn(() => sql`(UUID())`),
    orderNumber: varchar('order_number', { length: 50 }).unique().notNull(),
    staffId: varchar('staff_id', { length: 36 }).notNull().references(() => staff.id),
    branchId: varchar('branch_id', { length: 36 }).notNull().references(() => branches.id),
    shiftId: varchar('shift_id', { length: 36 }).references(() => shifts.id),
    orderType: varchar('order_type', { length: 30 }).notNull().default('Makan di Tempat'),
    tableNumber: varchar('table_number', { length: 20 }),
    subtotal: int('subtotal').notNull().default(0),
    taxAmount: int('tax_amount').notNull().default(0),
    serviceAmount: int('service_amount').notNull().default(0),
    discountAmount: int('discount_amount').notNull().default(0),
    totalAmount: int('total_amount').notNull().default(0),
    status: varchar('status', { length: 30 }).notNull().default('Pending'),
    notes: text('notes'),
    createdAt: timestamp('created_at').defaultNow().notNull(),
    updatedAt: timestamp('updated_at').defaultNow().notNull(),
});
