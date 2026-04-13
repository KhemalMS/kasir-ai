import { mysqlTable, varchar, decimal, text, timestamp } from 'drizzle-orm/mysql-core';
import { sql } from 'drizzle-orm';
import { inventory } from './inventory';
import { staff } from './staff';

export const stockAdjustments = mysqlTable('stock_adjustments', {
    id: varchar('id', { length: 36 }).primaryKey().$defaultFn(() => sql`(UUID())`),
    inventoryId: varchar('inventory_id', { length: 36 }).notNull().references(() => inventory.id, { onDelete: 'cascade' }),
    staffId: varchar('staff_id', { length: 36 }).references(() => staff.id),
    type: varchar('type', { length: 20 }).notNull(), // IN, OUT, ADJUSTMENT, ORDER
    quantity: decimal('quantity', { precision: 10, scale: 2 }).notNull(),
    reason: text('reason'),
    createdAt: timestamp('created_at').defaultNow().notNull(),
});
