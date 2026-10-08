/**
 * Market Basket Analysis Job
 *
 * Menghitung pasangan produk yang sering dibeli bersamaan menggunakan
 * metrik Support, Confidence, dan Lift. Berjalan sebagai cron job
 * (jam 02:00 setiap hari) dan menyimpan hasilnya ke tabel `market_basket_cache`.
 *
 * Desain:
 * - TIDAK real-time — dijalankan di background untuk menghindari self-join berat
 * - Hanya pasangan dengan lift > 1.0 yang disimpan (asosiasi bermakna)
 * - Dibatasi 200 pasangan teratas berdasarkan lift untuk efisiensi storage
 */

import cron from 'node-cron';
import { db } from '../db/index.js';
import { orders } from '../db/schema/orders.js';
import { orderItems } from '../db/schema/orderItems.js';
import { products } from '../db/schema/products.js';
import { marketBasketCache } from '../db/schema/marketBasketCache.js';
import { eq, sql, count, sum } from 'drizzle-orm';

interface ProductFreqInfo {
    name: string;
    freq: number;
}

interface BasketPairWithMetrics {
    productAId:   string;
    productAName: string;
    productBId:   string;
    productBName: string;
    frequency:    number;
    support:      number;
    confidence:   number;
    lift:         number;
}

async function computeMarketBasket(): Promise<void> {
    console.log('[MarketBasket] Memulai komputasi Market Basket Analysis...');
    const startTime = Date.now();

    try {
        // 1. Hitung total transaksi (N) — semua order berstatus Sukses
        const [totalRow] = await db
            .select({ n: sql<number>`CAST(COUNT(DISTINCT ${orders.id}) AS UNSIGNED)` })
            .from(orders)
            .where(eq(orders.status, 'Sukses'));
        const N = Number(totalRow?.n) || 0;
        if (N === 0) {
            console.log('[MarketBasket] Tidak ada transaksi. Melewati komputasi.');
            return;
        }

        // 2. Hitung frekuensi per produk — Freq(A)
        const productFreqRows = await db
            .select({
                productId:   orderItems.productId,
                productName: products.name,
                freq:        sql<number>`CAST(COUNT(DISTINCT ${orderItems.orderId}) AS UNSIGNED)`,
            })
            .from(orderItems)
            .innerJoin(orders,   eq(orderItems.orderId,   orders.id))
            .innerJoin(products, eq(orderItems.productId, products.id))
            .where(eq(orders.status, 'Sukses'))
            .groupBy(orderItems.productId, products.name);

        const productFreqMap = new Map<string, ProductFreqInfo>(
            productFreqRows.map(r => [String(r.productId), { name: r.productName, freq: Number(r.freq) }])
        );

        // 3. Hitung frekuensi pasangan produk (A, B) dalam satu order yang sama
        //    Menggunakan self-join pada orderItems, dengan filter A.productId < B.productId
        //    untuk menghindari duplikat (A,B) dan (B,A)
        //    Menggunakan raw SQL dan cast hasilnya sebagai unknown terlebih dahulu
        const pairResult = await db.execute(sql`
            SELECT
                a.product_id   AS product_a_id,
                b.product_id   AS product_b_id,
                CAST(COUNT(DISTINCT a.order_id) AS UNSIGNED) AS pair_frequency
            FROM order_items a
            INNER JOIN order_items b
                ON a.order_id = b.order_id
               AND a.product_id < b.product_id
            INNER JOIN \`orders\` o
                ON a.order_id = o.id
               AND o.status = 'Sukses'
            GROUP BY a.product_id, b.product_id
            HAVING pair_frequency >= 2
            ORDER BY pair_frequency DESC
            LIMIT 500
        `);

        // mysql2 execute returns [RowDataPacket[], FieldPacket[]] — row data is first element
        const pairRows = (Array.isArray(pairResult) ? pairResult[0] : pairResult) as unknown as Array<Record<string, unknown>>;

        const pairs: BasketPairWithMetrics[] = [];

        for (const row of pairRows) {
            const aId  = String(row['product_a_id']);
            const bId  = String(row['product_b_id']);
            const freq = Number(row['pair_frequency']);

            const infoA = productFreqMap.get(aId);
            const infoB = productFreqMap.get(bId);
            if (!infoA || !infoB) continue;

            // Hitung metrik
            const supportAB    = freq / N;
            const supportA     = infoA.freq / N;
            const supportB     = infoB.freq / N;
            const confidenceAB = supportA > 0 ? supportAB / supportA : 0;  // P(B|A)
            const lift         = supportB > 0 ? confidenceAB / supportB : 0;

            // Filter: hanya simpan pasangan dengan lift > 1.0 (bermakna)
            if (lift <= 1.0) continue;

            pairs.push({
                productAId:   aId,
                productAName: infoA.name,
                productBId:   bId,
                productBName: infoB.name,
                frequency:    freq,
                support:      supportAB,
                confidence:   confidenceAB,
                lift:         lift,
            });
        }

        // Urutkan berdasarkan lift (tertinggi dulu), batasi 200 pasangan
        const topPairs = pairs
            .sort((a, b) => b.lift - a.lift)
            .slice(0, 200);

        // 4. Hapus data lama lalu insert hasil baru
        await db.delete(marketBasketCache);

        if (topPairs.length > 0) {
            await db.insert(marketBasketCache).values(
                topPairs.map(p => ({
                    productAId:   p.productAId,
                    productAName: p.productAName,
                    productBId:   p.productBId,
                    productBName: p.productBName,
                    support:      p.support.toFixed(6),
                    confidence:   p.confidence.toFixed(6),
                    lift:         p.lift.toFixed(4),
                    frequency:    p.frequency,
                    branchId:     null,
                }))
            );
        }

        const elapsed = ((Date.now() - startTime) / 1000).toFixed(2);
        console.log(`[MarketBasket] Selesai: ${topPairs.length} pasangan disimpan dalam ${elapsed}s`);
    } catch (err) {
        console.error('[MarketBasket] ERROR saat komputasi:', err);
    }
}

/**
 * Inisialisasi cron job Market Basket Analysis.
 * - Berjalan setiap hari pukul 02:00 pagi.
 * - Juga dijalankan sekali saat server start (setelah 10 detik delay).
 */
export function initMarketBasketJob(): void {
    // Jalankan saat startup (delay 10 detik agar DB siap)
    setTimeout(() => {
        computeMarketBasket().catch(err =>
            console.error('[MarketBasket] Gagal saat startup:', err)
        );
    }, 10_000);

    // Jadwalkan cron setiap hari jam 02:00
    cron.schedule('0 2 * * *', () => {
        computeMarketBasket().catch(err =>
            console.error('[MarketBasket] Gagal saat cron:', err)
        );
    });

    console.log('[MarketBasket] Cron job terdaftar — berjalan setiap hari pukul 02:00');
}
