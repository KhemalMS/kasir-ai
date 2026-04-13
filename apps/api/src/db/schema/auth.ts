import { mysqlTable, varchar, timestamp, boolean, datetime } from 'drizzle-orm/mysql-core';

export const user = mysqlTable('user', {
    id: varchar('id', { length: 36 }).primaryKey(),
    name: varchar('name', { length: 255 }).notNull(),
    email: varchar('email', { length: 255 }).notNull().unique(),
    emailVerified: boolean('email_verified').notNull().default(false),
    image: varchar('image', { length: 500 }),
    role: varchar('role', { length: 50 }).notNull().default('kasir'),
    createdAt: timestamp('created_at').notNull().defaultNow(),
    updatedAt: timestamp('updated_at').notNull().defaultNow(),
});

export const session = mysqlTable('session', {
    id: varchar('id', { length: 36 }).primaryKey(),
    expiresAt: datetime('expires_at').notNull(),
    token: varchar('token', { length: 255 }).notNull().unique(),
    createdAt: timestamp('created_at').notNull().defaultNow(),
    updatedAt: timestamp('updated_at').notNull().defaultNow(),
    ipAddress: varchar('ip_address', { length: 255 }),
    userAgent: varchar('user_agent', { length: 500 }),
    userId: varchar('user_id', { length: 36 }).notNull().references(() => user.id),
});

export const account = mysqlTable('account', {
    id: varchar('id', { length: 36 }).primaryKey(),
    accountId: varchar('account_id', { length: 255 }).notNull(),
    providerId: varchar('provider_id', { length: 255 }).notNull(),
    userId: varchar('user_id', { length: 36 }).notNull().references(() => user.id),
    accessToken: varchar('access_token', { length: 500 }),
    refreshToken: varchar('refresh_token', { length: 500 }),
    idToken: varchar('id_token', { length: 500 }),
    accessTokenExpiresAt: datetime('access_token_expires_at'),
    refreshTokenExpiresAt: datetime('refresh_token_expires_at'),
    scope: varchar('scope', { length: 255 }),
    password: varchar('password', { length: 255 }),
    createdAt: timestamp('created_at').notNull().defaultNow(),
    updatedAt: timestamp('updated_at').notNull().defaultNow(),
});

export const verification = mysqlTable('verification', {
    id: varchar('id', { length: 36 }).primaryKey(),
    identifier: varchar('identifier', { length: 255 }).notNull(),
    value: varchar('value', { length: 500 }).notNull(),
    expiresAt: datetime('expires_at').notNull(),
    createdAt: timestamp('created_at').defaultNow(),
    updatedAt: timestamp('updated_at').defaultNow(),
});
