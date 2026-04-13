import { mysqlTable, varchar, text, timestamp, int } from 'drizzle-orm/mysql-core';
import { sql } from 'drizzle-orm';

export const branches = mysqlTable('branches', {
    id: varchar('id', { length: 36 }).primaryKey().$defaultFn(() => sql`(UUID())`),
    name: varchar('name', { length: 255 }).notNull(),
    locationCode: varchar('location_code', { length: 50 }).unique().notNull(),
    address: text('address').notNull(),
    manager: varchar('manager', { length: 255 }),
    staffCount: int('staff_count').default(0),
    status: varchar('status', { length: 20 }).notNull().default('Buka'),
    imageUrl: text('image_url'),
    createdAt: timestamp('created_at').defaultNow().notNull(),
    updatedAt: timestamp('updated_at').defaultNow().notNull(),
});
