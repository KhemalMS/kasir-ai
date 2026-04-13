import { mysqlTable, varchar, text, timestamp } from 'drizzle-orm/mysql-core';
import { sql } from 'drizzle-orm';
import { branches } from './branches';

export const staff = mysqlTable('staff', {
    id: varchar('id', { length: 36 }).primaryKey().$defaultFn(() => sql`(UUID())`),
    userId: varchar('user_id', { length: 36 }).unique(),
    name: varchar('name', { length: 255 }).notNull(),
    email: varchar('email', { length: 255 }).notNull(),
    role: varchar('role', { length: 50 }).notNull().default('Kasir'),
    branchId: varchar('branch_id', { length: 36 }).notNull().references(() => branches.id),
    status: varchar('status', { length: 20 }).notNull().default('Aktif'),
    imageUrl: text('image_url'),
    createdAt: timestamp('created_at').defaultNow().notNull(),
    updatedAt: timestamp('updated_at').defaultNow().notNull(),
});
