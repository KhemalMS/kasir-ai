-- Migration: Recreate market_basket_cache dengan product_id sebagai VARCHAR(36)
-- products.id adalah UUID (varchar 36), jadi foreign key harus cocok

DROP TABLE IF EXISTS `market_basket_cache`;

CREATE TABLE `market_basket_cache` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `product_a_id` VARCHAR(36) NOT NULL,
    `product_a_name` VARCHAR(255) NOT NULL,
    `product_b_id` VARCHAR(36) NOT NULL,
    `product_b_name` VARCHAR(255) NOT NULL,
    `support` DECIMAL(8, 6) NOT NULL,
    `confidence` DECIMAL(8, 6) NOT NULL,
    `lift` DECIMAL(10, 4) NOT NULL,
    `frequency` INT NOT NULL,
    `branch_id` VARCHAR(36) DEFAULT NULL,
    `computed_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Composite indexes untuk query cepat
CREATE INDEX `idx_mbc_branch_computed` ON `market_basket_cache` (`branch_id`, `computed_at`);
CREATE INDEX `idx_mbc_lift` ON `market_basket_cache` (`lift` DESC);
CREATE INDEX `idx_mbc_product_a` ON `market_basket_cache` (`product_a_id`);
