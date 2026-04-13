import { mysqlTable, varchar, int, boolean, timestamp } from 'drizzle-orm/mysql-core';
import { sql } from 'drizzle-orm';
import { products } from './products';

export const productVariants = mysqlTable('product_variants', {
    id: varchar('id', { length: 36 }).primaryKey().$defaultFn(() => sql`(UUID())`),
    productId: varchar('product_id', { length: 36 }).notNull().references(() => products.id, { onDelete: 'cascade' }),
    name: varchar('name', { length: 255 }).notNull(),
    priceModifier: int('price_modifier').notNull().default(0),
    isActive: boolean('is_active').default(true),
    sortOrder: int('sort_order').default(0),
    createdAt: timestamp('created_at').defaultNow().notNull(),
});
