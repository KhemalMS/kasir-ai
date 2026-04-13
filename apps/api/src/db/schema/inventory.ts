import { mysqlTable, varchar, text, decimal, timestamp } from 'drizzle-orm/mysql-core';
import { sql } from 'drizzle-orm';
import { categories } from './categories';
import { branches } from './branches';

export const inventory = mysqlTable('inventory', {
    id: varchar('id', { length: 36 }).primaryKey().$defaultFn(() => sql`(UUID())`),
    name: varchar('name', { length: 255 }).notNull(),
    sku: varchar('sku', { length: 100 }).unique().notNull(),
    categoryId: varchar('category_id', { length: 36 }).references(() => categories.id),
    branchId: varchar('branch_id', { length: 36 }).notNull().references(() => branches.id),
    quantity: decimal('quantity', { precision: 10, scale: 2 }).notNull().default('0'),
    unit: varchar('unit', { length: 50 }).notNull(),
    reorderThreshold: decimal('reorder_threshold', { precision: 10, scale: 2 }).default('10'),
    imageUrl: text('image_url'),
    createdAt: timestamp('created_at').defaultNow().notNull(),
    updatedAt: timestamp('updated_at').defaultNow().notNull(),
});
