import { mysqlTable, varchar, int, date, timestamp } from 'drizzle-orm/mysql-core';
import { sql } from 'drizzle-orm';

export const customers = mysqlTable('customers', {
    id:        varchar('id', { length: 36 }).primaryKey().$defaultFn(() => sql`(UUID())`),
    name:      varchar('name', { length: 100 }).notNull(),
    phone:     varchar('phone', { length: 20 }).unique(),
    email:     varchar('email', { length: 100 }),
    birthdate: date('birthdate'),
    points:    int('points').notNull().default(0),
    tier:      varchar('tier', { length: 20 }).notNull().default('Bronze'),
    createdAt: timestamp('created_at').defaultNow().notNull(),
    updatedAt: timestamp('updated_at').defaultNow().notNull(),
});
