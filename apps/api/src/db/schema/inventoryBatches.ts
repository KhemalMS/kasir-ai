import { mysqlTable, varchar, decimal, text, timestamp } from 'drizzle-orm/mysql-core';
import { sql } from 'drizzle-orm';
import { inventory } from './inventory';

export const inventoryBatches = mysqlTable('inventory_batches', {
    id: varchar('id', { length: 36 }).primaryKey().$defaultFn(() => sql`(UUID())`),
    inventoryId: varchar('inventory_id', { length: 36 }).notNull().references(() => inventory.id, { onDelete: 'cascade' }),
    batchNumber: varchar('batch_number', { length: 100 }),
    supplierName: varchar('supplier_name', { length: 255 }),
    quantityReceived: decimal('quantity_received', { precision: 10, scale: 2 }).notNull(),
    quantityRemaining: decimal('quantity_remaining', { precision: 10, scale: 2 }).notNull(),
    costPrice: decimal('cost_price', { precision: 10, scale: 2 }).notNull().default('0'),
    receivedAt: timestamp('received_at').defaultNow().notNull(),
    expirationDate: timestamp('expiration_date'),
    notes: text('notes'),
    paymentStatus: varchar('payment_status', { length: 20 }).notNull().default('Paid'),
    amountPaid: decimal('amount_paid', { precision: 10, scale: 2 }).notNull().default('0'),
    dueDate: timestamp('due_date'),
    createdAt: timestamp('created_at').defaultNow().notNull(),
});
