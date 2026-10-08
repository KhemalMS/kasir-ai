/**
 * Date utilities untuk menghindari masalah timezone saat parsing date string
 * dari query parameter API.
 *
 * Masalah: new Date('2024-01-15') → UTC midnight (2024-01-15T00:00:00Z)
 * Di server UTC+7 (Jakarta), ini setara dengan 07:00 Jakarta, bukan 00:00.
 * Akibatnya data dini hari Jakarta (00:00-06:59) masuk ke hari sebelumnya.
 *
 * Solusi: parseLocalDate() selalu membuat Date di lokal midnight server,
 * sehingga konsisten dengan timezone di mana server berjalan.
 */

/**
 * Parse "YYYY-MM-DD" string sebagai lokal midnight (bukan UTC).
 * Aman untuk date-only strings dari query params.
 */
export function parseLocalDate(dateStr: string): Date {
    const parts = dateStr.split('-').map(Number);
    if (parts.length !== 3 || parts.some(isNaN)) {
        // Fallback ke new Date() jika format tidak dikenali
        return new Date(dateStr);
    }
    const [year, month, day] = parts;
    return new Date(year, month - 1, day, 0, 0, 0, 0);
}

/**
 * Parse start/end date strings dari query params menjadi:
 * - start: lokal midnight (00:00:00.000)
 * - end  : lokal end-of-day (23:59:59.999)
 *
 * Mendukung "YYYY-MM-DD" dan ISO-8601 dengan timezone offset.
 */
export function parseLocalDateRange(
    startStr: string | undefined,
    endStr: string | undefined,
    defaultDays: number = 30,
): { start: Date; end: Date } {
    const end = endStr ? parseLocalDate(endStr) : new Date();
    end.setHours(23, 59, 59, 999);

    const start = startStr ? parseLocalDate(startStr) : (() => {
        const d = new Date(end);
        d.setDate(d.getDate() - (defaultDays - 1));
        d.setHours(0, 0, 0, 0);
        return d;
    })();

    return { start, end };
}

/**
 * Format Date ke "YYYY-MM-DD" menggunakan lokal timezone server.
 * Menghindari toISOString() yang selalu menghasilkan UTC.
 */
export function formatLocalDate(date: Date): string {
    const y = date.getFullYear();
    const m = String(date.getMonth() + 1).padStart(2, '0');
    const d = String(date.getDate()).padStart(2, '0');
    return `${y}-${m}-${d}`;
}
