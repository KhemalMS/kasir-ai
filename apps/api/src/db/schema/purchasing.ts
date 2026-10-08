import { mysqlTable, varchar, int, text, timestamp } from 'drizzle-orm/mysql-core';
import { sql } from 'drizzle-orm';
import { branches } from './branches';

export const suppliers = mysqlTable('suppliers', {
    id: varchar('id', { length: 36 }).primaryKey().$defaultFn(() => sql`(UUID())`),
    name: varchar('name', { length: 255 }).notNull(),
    phone: varchar('phone', { length: 50 }),
    address: text('address'),
    createdAt: timestamp('created_at').defaultNow().notNull(),
});

export const purchaseOrders = mysqlTable('purchase_orders', {
    id: varchar('id', { length: 36 }).primaryKey().$defaultFn(() => sql`(UUID())`),
    poNumber: varchar('po_number', { length: 50 }).notNull().unique(),
    supplierId: varchar('supplier_id', { length: 36 }).notNull().references(() => suppliers.id),
    branchId: varchar('branch_id', { length: 36 }).notNull().references(() => branches.id),
    status: varchar('status', { length: 30 }).notNull().default('Pending'), // Pending, Diterima, Batal
    totalAmount: int('total_amount').notNull().default(0),
    expectedDate: timestamp('expected_date'),
    receivedDate: timestamp('received_date'),
    createdAt: timestamp('created_at').defaultNow().notNull(),
});

export const supplierReturns = mysqlTable('supplier_returns', {
    id: varchar('id', { length: 36 }).primaryKey().$defaultFn(() => sql`(UUID())`),
    returnNumber: varchar('return_number', { length: 50 }).notNull().unique(),
    supplierId: varchar('supplier_id', { length: 36 }).notNull().references(() => suppliers.id),
    branchId: varchar('branch_id', { length: 36 }).notNull().references(() => branches.id),
    poId: varchar('po_id', { length: 36 }).references(() => purchaseOrders.id),
    totalAmount: int('total_amount').notNull().default(0),
    reason: text('reason'),
    createdAt: timestamp('created_at').defaultNow().notNull(),
});
