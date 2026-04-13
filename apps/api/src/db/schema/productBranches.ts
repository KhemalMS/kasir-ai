import { mysqlTable, varchar, boolean, int } from 'drizzle-orm/mysql-core';
import { sql } from 'drizzle-orm';
import { products } from './products';
import { branches } from './branches';

export const productBranches = mysqlTable('product_branches', {
    id: varchar('id', { length: 36 }).primaryKey().$defaultFn(() => sql`(UUID())`),
    productId: varchar('product_id', { length: 36 }).notNull().references(() => products.id, { onDelete: 'cascade' }),
    branchId: varchar('branch_id', { length: 36 }).notNull().references(() => branches.id, { onDelete: 'cascade' }),
    isAvailable: boolean('is_available').default(true),
    stock: int('stock').default(0),
});
