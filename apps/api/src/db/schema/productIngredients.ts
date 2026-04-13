import { mysqlTable, varchar, decimal, timestamp } from 'drizzle-orm/mysql-core';
import { sql } from 'drizzle-orm';
import { products } from './products';
import { inventory } from './inventory';
import { productVariants } from './productVariants';

export const productIngredients = mysqlTable('product_ingredients', {
    id: varchar('id', { length: 36 }).primaryKey().$defaultFn(() => sql`(UUID())`),
    productId: varchar('product_id', { length: 36 }).notNull().references(() => products.id, { onDelete: 'cascade' }),
    variantId: varchar('variant_id', { length: 36 }).references(() => productVariants.id, { onDelete: 'cascade' }),
    inventoryId: varchar('inventory_id', { length: 36 }).notNull().references(() => inventory.id, { onDelete: 'cascade' }),
    quantityUsed: decimal('quantity_used', { precision: 10, scale: 2 }).notNull(),
    createdAt: timestamp('created_at').defaultNow().notNull(),
});
