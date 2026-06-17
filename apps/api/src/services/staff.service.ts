import { db } from '../db/index.js';
import { staff } from '../db/schema/staff.js';
import { staffSalaries } from '../db/schema/staffSalaries.js';
import { shifts } from '../db/schema/shifts.js';
import { eq, and, like, or, desc, sql } from 'drizzle-orm';
import { v4 as uuidv4 } from 'uuid';
import { auth } from '../lib/better-auth.js';

// ─────────────────────────────────────────────────────────────
// Types
// ─────────────────────────────────────────────────────────────
export interface StaffFilters {
    branchId?: string;
    role?: string;
    status?: string;
    search?: string;
    page?: number;
    limit?: number;
}

export interface StaffCreatePayload {
    name: string;
    email: string;
    role?: string;
    branchId: string;
    status?: string;
    phone?: string;
    gender?: string;
    birthDate?: string;
    imageUrl?: string;
    emergencyContactName?: string;
    emergencyContactPhone?: string;
    address?: string;
    joinDate?: string;
    employmentType?: string;
    pinCode?: string;
    notes?: string;
    bankName?: string;
    bankAccountNumber?: string;
    bankAccountName?: string;
    // Optional: caller can pass a userId if user account already exists
    userId?: string;
}

// ─────────────────────────────────────────────────────────────
// Helper: generate temporary password
// ─────────────────────────────────────────────────────────────
function generateTempPassword(): string {
    const chars = 'ABCDEFGHJKMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789';
    return Array.from({ length: 10 }, () => chars[Math.floor(Math.random() * chars.length)]).join('');
}

// ─────────────────────────────────────────────────────────────
// Staff Service
// ─────────────────────────────────────────────────────────────
export const staffService = {

    // ── Find All (with filters + pagination) ─────────────────
    async findAll(filters?: StaffFilters) {
        const conditions: ReturnType<typeof eq>[] = [];

        if (filters?.branchId) conditions.push(eq(staff.branchId, filters.branchId));
        if (filters?.role)     conditions.push(eq(staff.role, filters.role));
        if (filters?.status)   conditions.push(eq(staff.status, filters.status));
        if (filters?.search) {
            conditions.push(
                or(
                    like(staff.name,  `%${filters.search}%`),
                    like(staff.email, `%${filters.search}%`),
                    like(staff.phone, `%${filters.search}%`)
                )!
            );
        }

        const page  = Math.max(1, filters?.page  ?? 1);
        const limit = Math.min(100, filters?.limit ?? 50);
        const offset = (page - 1) * limit;

        const whereClause = conditions.length > 0 ? and(...conditions) : undefined;

        const [rows, [countRow]] = await Promise.all([
            db.select().from(staff)
                .where(whereClause)
                .orderBy(desc(staff.createdAt))
                .limit(limit)
                .offset(offset),
            db.select({ total: sql<number>`COUNT(*)` }).from(staff).where(whereClause),
        ]);

        return {
            data: rows,
            meta: { total: Number(countRow.total), page, limit },
        };
    },

    // ── Find By ID ────────────────────────────────────────────
    async findById(id: string) {
        const [member] = await db.select().from(staff).where(eq(staff.id, id));
        return member || null;
    },

    // ── Find By User ID (used by Flutter on login) ────────────
    async findByUserId(userId: string) {
        const [member] = await db.select().from(staff).where(eq(staff.userId, userId));
        return member || null;
    },

    // ── Create Staff + Auth User Account ─────────────────────
    async create(data: StaffCreatePayload): Promise<{ staff: typeof staff.$inferSelect; tempPassword?: string }> {
        const staffId = uuidv4();
        let userId = data.userId ?? null;
        let tempPassword: string | undefined;

        // If no existing userId, create a Better-Auth user account
        if (!userId) {
            tempPassword = generateTempPassword();
            try {
                const newUser = await auth.api.createUser({
                    body: {
                        name:     data.name,
                        email:    data.email,
                        password: tempPassword,
                    },
                });
                userId = (newUser as any)?.user?.id ?? null;
                console.log(`[StaffService] Created auth user: ${userId} for ${data.email}`);
            } catch (authErr: any) {
                console.warn(`[StaffService] Failed to create auth user for ${data.email}:`, authErr?.message ?? authErr);
                // Throw error so caller knows staff was NOT created with a login account
                throw new Error(`Gagal membuat akun login untuk pegawai: ${authErr?.message ?? 'Unknown error'}`);
            }
        }

        await db.insert(staff).values({
            id:                    staffId,  // FIX: was missing, caused findById to return null
            userId:                userId ?? undefined,
            name:                  data.name,
            email:                 data.email,
            role:                  data.role ?? 'Kasir',
            branchId:              data.branchId,
            status:                data.status ?? 'Aktif',
            imageUrl:              data.imageUrl,
            phone:                 data.phone,
            gender:                data.gender,
            birthDate:             data.birthDate,
            emergencyContactName:  data.emergencyContactName,
            emergencyContactPhone: data.emergencyContactPhone,
            address:               data.address,
            joinDate:              data.joinDate ? new Date(data.joinDate) : undefined,
            employmentType:        data.employmentType ?? 'Tetap',
            pinCode:               data.pinCode,
            notes:                 data.notes,
            bankName:              data.bankName,
            bankAccountNumber:     data.bankAccountNumber,
            bankAccountName:       data.bankAccountName,
        } as any);

        const created = await this.findById(staffId);
        return { staff: created!, tempPassword };
    },

    // ── Update Staff ──────────────────────────────────────────
    async update(id: string, data: Partial<StaffCreatePayload>) {
        await db.update(staff)
            .set({ ...data, joinDate: (data as any).joinDate ? new Date((data as any).joinDate) : undefined, updatedAt: new Date() } as any)
            .where(eq(staff.id, id));

        return this.findById(id);
    },

    // ── Delete Staff ──────────────────────────────────────────
    async delete(id: string) {
        const member = await this.findById(id);
        if (!member) return null;
        await db.delete(staff).where(eq(staff.id, id));
        return member;
    },

    // ── Reset PIN ─────────────────────────────────────────────
    async resetPin(staffId: string, pin: string) {
        if (!/^\d{4,6}$/.test(pin)) {
            throw new Error('PIN harus 4-6 digit angka');
        }
        await db.update(staff)
            .set({ pinCode: pin, updatedAt: new Date() })
            .where(eq(staff.id, staffId));
        return this.findById(staffId);
    },

    // ── Get Shift History ─────────────────────────────────────
    async getShiftHistory(staffId: string, limit = 20) {
        return db.select().from(shifts)
            .where(eq(shifts.staffId, staffId))
            .orderBy(desc(shifts.startedAt))
            .limit(limit);
    },

    // ── Get Salary History ────────────────────────────────────
    async getSalaryHistory(staffId: string) {
        return db.select().from(staffSalaries)
            .where(eq(staffSalaries.staffId, staffId))
            .orderBy(desc(staffSalaries.effectiveDate));
    },

    // ── Add Salary Record ─────────────────────────────────────
    async addSalaryRecord(data: {
        staffId: string;
        salaryType: string;
        amount: number;
        effectiveDate: string;
        notes?: string;
    }) {
        await db.insert(staffSalaries).values({
            staffId:       data.staffId,
            salaryType:    data.salaryType,
            amount:        data.amount,
            effectiveDate: new Date(data.effectiveDate),
            notes:         data.notes,
        } as any);
        const [record] = await db.select().from(staffSalaries)
            .where(eq(staffSalaries.staffId, data.staffId))
            .orderBy(desc(staffSalaries.createdAt))
            .limit(1);
        return record;
    },

    // ── Stats Summary ─────────────────────────────────────────
    // Uses SQL GROUP BY instead of fetching all rows into JS memory.
    async getStats() {
        const [byRoleRows, byStatusRows, totalRows] = await Promise.all([
            db.select({
                role:  staff.role,
                count: sql<number>`COUNT(*)`,
            }).from(staff).groupBy(staff.role),

            db.select({
                status: staff.status,
                count:  sql<number>`COUNT(*)`,
            }).from(staff).groupBy(staff.status),

            db.select({ count: sql<number>`COUNT(*)` }).from(staff),
        ]);

        const byRole: Record<string, number> = {};
        for (const r of byRoleRows) byRole[r.role] = Number(r.count);

        const byStatus: Record<string, number> = {};
        for (const r of byStatusRows) byStatus[r.status] = Number(r.count);

        return {
            totalStaff: Number(totalRows[0]?.count ?? 0),
            byRole,
            byStatus,
        };
    },
};
