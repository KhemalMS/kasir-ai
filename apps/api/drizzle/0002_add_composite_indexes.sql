-- 0002_add_composite_indexes.sql
CREATE INDEX IF NOT EXISTS idx_orders_created_status ON orders(createdAt, status);
CREATE INDEX IF NOT EXISTS idx_orders_branch_created ON orders(branchId, createdAt);
CREATE INDEX IF NOT EXISTS idx_order_items_orderId ON order_items(orderId);
CREATE INDEX IF NOT EXISTS idx_order_items_productId ON order_items(productId);
CREATE INDEX IF NOT EXISTS idx_payments_orderId ON payments(orderId);
CREATE INDEX IF NOT EXISTS idx_inventory_branch_low ON inventory(branchId, quantity, reorderThreshold);
