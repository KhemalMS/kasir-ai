import { db } from '../db/index.js';
import { attendances } from '../db/schema/attendances.js';
import { staff } from '../db/schema/staff.js';
import { eq, and, gte, lte, desc, sql } from 'drizzle-orm';

// ─────────────────────────────────────────────────────────────
// Types
// ─────────────────────────────────────────────────────────────
export interface ClockInInput {
    staffId: string;
    notes?: string;
}

export interface ClockOutInput {
    staffId: string;
    notes?: string;
}

// ─────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────

/** Returns YYYY-MM-DD string in LOCAL timezone */
function todayString(): string {
    const d = new Date();
    const yyyy = d.getFullYear();
    const mm   = String(d.getMonth() + 1).padStart(2, '0');
    const dd   = String(d.getDate()).padStart(2, '0');
    return `${yyyy}-${mm}-${dd}`;
}

/** Parse a YYYY-MM-DD string into a plain Date at midnight UTC */
function parseDate(dateStr: string): Date {
    const [y, m, d] = dateStr.split('-').map(Number);
    return new Date(Date.UTC(y, m - 1, d));
}

function determineStatus(clockInTime: Date): 'on-time' | 'late' {
    // Consider "late" if clock-in hour is >= LATE_HOUR (default 9)
    const LATE_HOUR = parseInt(process.env.LATE_HOUR || '9', 10);
    return clockInTime.getHours() >= LATE_HOUR ? 'late' : 'on-time';
}

// ─────────────────────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────────────────────
export const attendanceService = {

    /**
     * Clock-In: Creates a new attendance record for today.
     * Prevents double clock-in on the same day.
     */
    async clockIn({ staffId, notes }: ClockInInput) {
        const todayStr  = todayString();
        const todayDate = parseDate(todayStr);

        // Prevent double clock-in
        const existing = await db
            .select()
            .from(attendances)
            .where(and(eq(attendances.staffId, staffId), eq(attendances.date, todayDate)))
            .limit(1);

        if (existing.length > 0 && existing[0].clockInTime) {
            throw Object.assign(new Error('Anda sudah melakukan Clock-In hari ini'), { statusCode: 409 });
        }

        const now    = new Date();
        const status = determineStatus(now);

        const [{ insertId }] = await db.insert(attendances).values({
            staffId,
            date:        todayDate,
            clockInTime: now,
            status,
            notes:       notes ?? null,
        });

        // Fetch and return the inserted row
        const [record] = await db
            .select()
            .from(attendances)
            .where(eq(attendances.date, todayDate))
            .orderBy(desc(attendances.createdAt))
            .limit(1);
        return record;
    },

    /**
     * Clock-Out: Updates the existing today's attendance record.
     */
    async clockOut({ staffId, notes }: ClockOutInput) {
        const todayDate = parseDate(todayString());

        const [existing] = await db
            .select()
            .from(attendances)
            .where(and(eq(attendances.staffId, staffId), eq(attendances.date, todayDate)))
            .limit(1);

        if (!existing) {
            throw Object.assign(new Error('Anda belum melakukan Clock-In hari ini'), { statusCode: 404 });
        }
        if (existing.clockOutTime) {
            throw Object.assign(new Error('Anda sudah melakukan Clock-Out hari ini'), { statusCode: 409 });
        }

        await db
            .update(attendances)
            .set({ clockOutTime: new Date(), notes: notes ?? existing.notes, updatedAt: new Date() })
            .where(eq(attendances.id, existing.id));

        const [updated] = await db.select().from(attendances).where(eq(attendances.id, existing.id)).limit(1);
        return updated;
    },

    /**
     * List attendance records with optional filters.
     */
    async findAll(filters: {
        staffId?: string;
        startDate?: string; // YYYY-MM-DD
        endDate?: string;   // YYYY-MM-DD
        branchId?: string;
        page?: number;
        limit?: number;
    }) {
        const page   = filters.page  ?? 1;
        const limit  = filters.limit ?? 30;
        const offset = (page - 1) * limit;

        const conditions: ReturnType<typeof eq>[] = [];
        if (filters.staffId) conditions.push(eq(attendances.staffId, filters.staffId));
        if (filters.startDate) conditions.push(gte(attendances.date, parseDate(filters.startDate)));
        if (filters.endDate)   conditions.push(lte(attendances.date, parseDate(filters.endDate)));

        const rows = await db
            .select({
                id:           attendances.id,
                staffId:      attendances.staffId,
                staffName:    staff.name,
                date:         attendances.date,
                clockInTime:  attendances.clockInTime,
                clockOutTime: attendances.clockOutTime,
                status:       attendances.status,
                notes:        attendances.notes,
                createdAt:    attendances.createdAt,
            })
            .from(attendances)
            .leftJoin(staff, eq(attendances.staffId, staff.id))
            .where(conditions.length > 0 ? and(...conditions) : undefined)
            .orderBy(desc(attendances.date), desc(attendances.clockInTime))
            .limit(limit)
            .offset(offset);

        return rows;
    },

    /** Get today's attendance status for a single staff member */
    async getTodayStatus(staffId: string) {
        const todayDate = parseDate(todayString());
        const [row] = await db
            .select()
            .from(attendances)
            .where(and(eq(attendances.staffId, staffId), eq(attendances.date, todayDate)))
            .limit(1);
        return row ?? null;
    },
};
