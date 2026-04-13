import { mysqlTable, varchar, text, int, boolean, timestamp, decimal } from 'drizzle-orm/mysql-core';
import { sql } from 'drizzle-orm';
import { categories } from './categories';

export const products = mysqlTable('products', {
    id: varchar('id', { length: 36 }).primaryKey().$defaultFn(() => sql`(UUID())`),
    name: varchar('name', { length: 255 }).notNull(),
    code: varchar('code', { length: 100 }),
    unit: varchar('unit', { length: 50 }),
    description: text('description'),
    basePrice: int('base_price').notNull().default(0),
    markup: decimal('markup', { precision: 10, scale: 2 }).notNull().default('0'),
    price: int('price').notNull(),
    originalPrice: int('original_price'),
    taxInclusive: boolean('tax_inclusive').default(false),
    categoryId: varchar('category_id', { length: 36 }).references(() => categories.id),
    imageUrl: text('image_url'),
    sku: varchar('sku', { length: 100 }),
    isAI: boolean('is_ai').default(false),
    isActive: boolean('is_active').default(true),
    createdAt: timestamp('created_at').defaultNow().notNull(),
    updatedAt: timestamp('updated_at').defaultNow().notNull(),
});
