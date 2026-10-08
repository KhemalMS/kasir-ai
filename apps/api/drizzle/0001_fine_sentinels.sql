CREATE TABLE `activity_logs` (
	`id` varchar(36) NOT NULL,
	`staff_id` varchar(36) NOT NULL,
	`action` varchar(50) NOT NULL,
	`description` text,
	`created_at` timestamp NOT NULL DEFAULT (now()),
	CONSTRAINT `activity_logs_id` PRIMARY KEY(`id`)
);
--> statement-breakpoint
CREATE TABLE `customers` (
	`id` varchar(36) NOT NULL,
	`name` varchar(100) NOT NULL,
	`phone` varchar(20),
	`email` varchar(100),
	`birthdate` date,
	`points` int NOT NULL DEFAULT 0,
	`tier` varchar(20) NOT NULL DEFAULT 'Bronze',
	`created_at` timestamp NOT NULL DEFAULT (now()),
	`updated_at` timestamp NOT NULL DEFAULT (now()),
	CONSTRAINT `customers_id` PRIMARY KEY(`id`),
	CONSTRAINT `customers_phone_unique` UNIQUE(`phone`)
);
--> statement-breakpoint
CREATE TABLE `inventory_batches` (
	`id` varchar(36) NOT NULL,
	`inventory_id` varchar(36) NOT NULL,
	`batch_number` varchar(100),
	`supplier_name` varchar(255),
	`quantity_received` decimal(10,2) NOT NULL,
	`quantity_remaining` decimal(10,2) NOT NULL,
	`cost_price` decimal(10,2) NOT NULL DEFAULT '0',
	`received_at` timestamp NOT NULL DEFAULT (now()),
	`expiration_date` timestamp,
	`notes` text,
	`payment_status` varchar(20) NOT NULL DEFAULT 'Paid',
	`amount_paid` decimal(10,2) NOT NULL DEFAULT '0',
	`due_date` timestamp,
	`created_at` timestamp NOT NULL DEFAULT (now()),
	CONSTRAINT `inventory_batches_id` PRIMARY KEY(`id`)
);
--> statement-breakpoint
CREATE TABLE `market_basket_cache` (
	`id` int AUTO_INCREMENT NOT NULL,
	`product_a_id` int NOT NULL,
	`product_a_name` varchar(255) NOT NULL,
	`product_b_id` int NOT NULL,
	`product_b_name` varchar(255) NOT NULL,
	`support` decimal(8,6) NOT NULL,
	`confidence` decimal(8,6) NOT NULL,
	`lift` decimal(10,4) NOT NULL,
	`frequency` int NOT NULL,
	`branch_id` varchar(36),
	`computed_at` timestamp NOT NULL DEFAULT (now()),
	CONSTRAINT `market_basket_cache_id` PRIMARY KEY(`id`)
);
--> statement-breakpoint
CREATE TABLE `purchase_orders` (
	`id` varchar(36) NOT NULL,
	`po_number` varchar(50) NOT NULL,
	`supplier_id` varchar(36) NOT NULL,
	`branch_id` varchar(36) NOT NULL,
	`status` varchar(30) NOT NULL DEFAULT 'Pending',
	`total_amount` int NOT NULL DEFAULT 0,
	`expected_date` timestamp,
	`received_date` timestamp,
	`created_at` timestamp NOT NULL DEFAULT (now()),
	CONSTRAINT `purchase_orders_id` PRIMARY KEY(`id`),
	CONSTRAINT `purchase_orders_po_number_unique` UNIQUE(`po_number`)
);
--> statement-breakpoint
CREATE TABLE `supplier_returns` (
	`id` varchar(36) NOT NULL,
	`return_number` varchar(50) NOT NULL,
	`supplier_id` varchar(36) NOT NULL,
	`branch_id` varchar(36) NOT NULL,
	`po_id` varchar(36),
	`total_amount` int NOT NULL DEFAULT 0,
	`reason` text,
	`created_at` timestamp NOT NULL DEFAULT (now()),
	CONSTRAINT `supplier_returns_id` PRIMARY KEY(`id`),
	CONSTRAINT `supplier_returns_return_number_unique` UNIQUE(`return_number`)
);
--> statement-breakpoint
CREATE TABLE `suppliers` (
	`id` varchar(36) NOT NULL,
	`name` varchar(255) NOT NULL,
	`phone` varchar(50),
	`address` text,
	`created_at` timestamp NOT NULL DEFAULT (now()),
	CONSTRAINT `suppliers_id` PRIMARY KEY(`id`)
);
--> statement-breakpoint
ALTER TABLE `order_items` ADD `cogs_at_order` int DEFAULT 0 NOT NULL;--> statement-breakpoint
ALTER TABLE `orders` ADD `tax_invoice_number` varchar(50);--> statement-breakpoint
ALTER TABLE `orders` ADD `customer_id` varchar(36);--> statement-breakpoint
ALTER TABLE `activity_logs` ADD CONSTRAINT `activity_logs_staff_id_staff_id_fk` FOREIGN KEY (`staff_id`) REFERENCES `staff`(`id`) ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE `inventory_batches` ADD CONSTRAINT `inventory_batches_inventory_id_inventory_id_fk` FOREIGN KEY (`inventory_id`) REFERENCES `inventory`(`id`) ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE `purchase_orders` ADD CONSTRAINT `purchase_orders_supplier_id_suppliers_id_fk` FOREIGN KEY (`supplier_id`) REFERENCES `suppliers`(`id`) ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE `purchase_orders` ADD CONSTRAINT `purchase_orders_branch_id_branches_id_fk` FOREIGN KEY (`branch_id`) REFERENCES `branches`(`id`) ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE `supplier_returns` ADD CONSTRAINT `supplier_returns_supplier_id_suppliers_id_fk` FOREIGN KEY (`supplier_id`) REFERENCES `suppliers`(`id`) ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE `supplier_returns` ADD CONSTRAINT `supplier_returns_branch_id_branches_id_fk` FOREIGN KEY (`branch_id`) REFERENCES `branches`(`id`) ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE `supplier_returns` ADD CONSTRAINT `supplier_returns_po_id_purchase_orders_id_fk` FOREIGN KEY (`po_id`) REFERENCES `purchase_orders`(`id`) ON DELETE no action ON UPDATE no action;