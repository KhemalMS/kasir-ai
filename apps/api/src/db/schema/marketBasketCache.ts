import { mysqlTable, int, decimal, timestamp, varchar } from 'drizzle-orm/mysql-core';

export const marketBasketCache = mysqlTable('market_basket_cache', {
    id:           int('id').autoincrement().primaryKey(),
    productAId:   varchar('product_a_id', { length: 36 }).notNull(),
    productAName:   varchar('product_a_name', { length: 255 }).notNull(),
    productBId:   varchar('product_b_id', { length: 36 }).notNull(),
    productBName: varchar('product_b_name', { length: 255 }).notNull(),
    support:      decimal('support',    { precision: 8, scale: 6 }).notNull(),
    confidence:   decimal('confidence', { precision: 8, scale: 6 }).notNull(),
    lift:         decimal('lift',       { precision: 10, scale: 4 }).notNull(),
    frequency:    int('frequency').notNull(),
    branchId:     varchar('branch_id', { length: 36 }),  // null = semua cabang
    computedAt:   timestamp('computed_at').defaultNow().notNull(),
});
