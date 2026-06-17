import { mysqlTable, varchar, text, timestamp, date } from 'drizzle-orm/mysql-core';
import { sql } from 'drizzle-orm';
import { branches } from './branches';

export const staff = mysqlTable('staff', {
    id:                    varchar('id', { length: 36 }).primaryKey().$defaultFn(() => sql`(UUID())`),
    userId:                varchar('user_id', { length: 36 }).unique(),
    name:                  varchar('name', { length: 255 }).notNull(),
    email:                 varchar('email', { length: 255 }).notNull(),
    role:                  varchar('role', { length: 50 }).notNull().default('Kasir'),
    branchId:              varchar('branch_id', { length: 36 }).notNull().references(() => branches.id),
    status:                varchar('status', { length: 20 }).notNull().default('Aktif'),
    imageUrl:              text('image_url'),
    phone:                 varchar('phone', { length: 20 }),
    gender:                varchar('gender', { length: 20 }),
    birthDate:             varchar('birth_date', { length: 10 }),

    // Renamed from emergency_contact
    emergencyContactName:  varchar('emergency_contact_name', { length: 100 }),

    // New columns
    address:               text('address'),
    joinDate:              date('join_date'),
    employmentType:        varchar('employment_type', { length: 20 }).default('Tetap'),
    pinCode:               varchar('pin_code', { length: 6 }),
    emergencyContactPhone: varchar('emergency_contact_phone', { length: 20 }),
    notes:                 text('notes'),
    bankName:              varchar('bank_name', { length: 50 }),
    bankAccountNumber:     varchar('bank_account_number', { length: 30 }),
    bankAccountName:       varchar('bank_account_name', { length: 100 }),

    createdAt:             timestamp('created_at').defaultNow().notNull(),
    updatedAt:             timestamp('updated_at').defaultNow().notNull(),
});
