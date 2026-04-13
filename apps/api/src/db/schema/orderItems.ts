import { mysqlTable, varchar, int, text, timestamp } from 'drizzle-orm/mysql-core';
import { sql } from 'drizzle-orm';
import { orders } from './orders';
import { products } from './products';
import { productVariants } from './productVariants';

export const orderItems = mysqlTable('order_items', {
    id: varchar('id', { length: 36 }).primaryKey().$defaultFn(() => sql`(UUID())`),
    orderId: varchar('order_id', { length: 36 }).notNull().references(() => orders.id, { onDelete: 'cascade' }),
    productId: varchar('product_id', { length: 36 }).notNull().references(() => products.id),
    variantId: varchar('variant_id', { length: 36 }).references(() => productVariants.id),
    quantity: int('quantity').notNull(),
    priceAtOrder: int('price_at_order').notNull(),
    variantPriceAtOrder: int('variant_price_at_order').notNull().default(0),
    notes: text('notes'),
    createdAt: timestamp('created_at').defaultNow().notNull(),
});
