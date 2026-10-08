-- Migration: tambah index pada tabel-tabel utama untuk performa query laporan
-- Kolom-kolom yang sering dipakai di WHERE, JOIN, dan GROUP BY

-- ─── orders ────────────────────────────────────────────────────
-- createdAt: dipakai di semua laporan (range filter)
-- status: dipakai di hampir semua WHERE (status = 'Sukses')
-- branchId: filter per-cabang
-- staffId: laporan pegawai
-- shiftId: laporan shift
-- customerId: laporan pelanggan
ALTER TABLE `orders`
  ADD INDEX `idx_orders_created_at` (`created_at`),
  ADD INDEX `idx_orders_status` (`status`),
  ADD INDEX `idx_orders_branch_id` (`branch_id`),
  ADD INDEX `idx_orders_staff_id` (`staff_id`),
  ADD INDEX `idx_orders_shift_id` (`shift_id`),
  ADD INDEX `idx_orders_customer_id` (`customer_id`);
--> statement-breakpoint

-- Composite: paling umum dipakai bersama (status + createdAt + branchId)
ALTER TABLE `orders`
  ADD INDEX `idx_orders_status_created` (`status`, `created_at`),
  ADD INDEX `idx_orders_branch_status` (`branch_id`, `status`, `created_at`);
--> statement-breakpoint

-- ─── order_items ───────────────────────────────────────────────
-- orderId: JOIN dari orders ke order_items
-- productId: laporan best-seller per-produk
ALTER TABLE `order_items`
  ADD INDEX `idx_order_items_order_id` (`order_id`),
  ADD INDEX `idx_order_items_product_id` (`product_id`);
--> statement-breakpoint

-- ─── payments ──────────────────────────────────────────────────
-- orderId: JOIN dari orders ke payments
-- method: laporan metode pembayaran
ALTER TABLE `payments`
  ADD INDEX `idx_payments_order_id` (`order_id`),
  ADD INDEX `idx_payments_method` (`method`);
--> statement-breakpoint

-- ─── expenses ──────────────────────────────────────────────────
-- createdAt: range filter laporan pengeluaran
-- branchId: filter per-cabang
ALTER TABLE `expenses`
  ADD INDEX `idx_expenses_created_at` (`created_at`),
  ADD INDEX `idx_expenses_branch_id` (`branch_id`);
--> statement-breakpoint

-- ─── shifts ────────────────────────────────────────────────────
-- startedAt: range filter laporan shift
-- staffId: filter per-pegawai
-- branchId: filter per-cabang
-- status: filter shift aktif/selesai
ALTER TABLE `shifts`
  ADD INDEX `idx_shifts_started_at` (`started_at`),
  ADD INDEX `idx_shifts_staff_id` (`staff_id`),
  ADD INDEX `idx_shifts_branch_id` (`branch_id`),
  ADD INDEX `idx_shifts_status` (`status`);
--> statement-breakpoint

-- ─── attendances ───────────────────────────────────────────────
-- staffId: filter per-pegawai
-- date: range filter absensi
ALTER TABLE `attendances`
  ADD INDEX `idx_attendances_staff_id` (`staff_id`),
  ADD INDEX `idx_attendances_date` (`date`);
--> statement-breakpoint

-- ─── customers ─────────────────────────────────────────────────
-- phone: pencarian/lookup cepat per nomor telepon
-- createdAt: laporan pelanggan baru
ALTER TABLE `customers`
  ADD INDEX `idx_customers_phone` (`phone`),
  ADD INDEX `idx_customers_created_at` (`created_at`);
--> statement-breakpoint

-- ─── inventory ─────────────────────────────────────────────────
-- branchId: filter stok per-cabang
ALTER TABLE `inventory`
  ADD INDEX `idx_inventory_branch_id` (`branch_id`),
  ADD INDEX `idx_inventory_product_id` (`product_id`);
