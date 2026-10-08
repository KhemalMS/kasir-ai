import { sql } from 'drizzle-orm';

/**
 * Membangun kondisi WHERE untuk sortir.
 * @param column - Objek kolom Drizzle (contoh: orders.createdAt)
 * @param order - 'asc' atau 'desc' (default: 'desc')
 */
export function buildOrderBy(column: any, order: string = 'desc') {
    return order === 'asc' ? column : sql`${column} DESC`;
}

/**
 * Menghitung offset untuk paginasi.
 */
export function calcOffset(page: number, limit: number): number {
    return (Math.max(1, page) - 1) * limit;
}

/**
 * Menghitung jumlah total halaman.
 */
export function calcTotalPages(total: number, limit: number): number {
    return Math.ceil(total / Math.max(1, limit));
}
