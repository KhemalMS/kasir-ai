import { relations } from 'drizzle-orm';
import { branches } from './branches';
import { categories } from './categories';
import { products } from './products';
import { productVariants } from './productVariants';
import { productBranches } from './productBranches';
import { productIngredients } from './productIngredients';
import { inventory } from './inventory';
import { staff } from './staff';
import { shifts } from './shifts';
import { orders } from './orders';
import { orderItems } from './orderItems';
import { payments } from './payments';
import { expenses } from './expenses';
import { stockAdjustments } from './stockAdjustments';

// ── Branch Relations ───────────────────────────────────────────
export const branchesRelations = relations(branches, ({ many }) => ({
    staff: many(staff),
    inventory: many(inventory),
    orders: many(orders),
    expenses: many(expenses),
    shifts: many(shifts),
    productBranches: many(productBranches),
}));

// ── Category Relations ─────────────────────────────────────────
export const categoriesRelations = relations(categories, ({ many }) => ({
    products: many(products),
    inventory: many(inventory),
}));

// ── Product Relations ──────────────────────────────────────────
export const productsRelations = relations(products, ({ one, many }) => ({
    category: one(categories, {
        fields: [products.categoryId],
        references: [categories.id],
    }),
    variants: many(productVariants),
    ingredients: many(productIngredients),
    branches: many(productBranches),
    orderItems: many(orderItems),
}));

// ── Product Variant Relations ──────────────────────────────────
export const productVariantsRelations = relations(productVariants, ({ one }) => ({
    product: one(products, {
        fields: [productVariants.productId],
        references: [products.id],
    }),
}));

// ── Product Branch Relations ───────────────────────────────────
export const productBranchesRelations = relations(productBranches, ({ one }) => ({
    product: one(products, {
        fields: [productBranches.productId],
        references: [products.id],
    }),
    branch: one(branches, {
        fields: [productBranches.branchId],
        references: [branches.id],
    }),
}));

// ── Inventory Relations ────────────────────────────────────────
export const inventoryRelations = relations(inventory, ({ one, many }) => ({
    category: one(categories, {
        fields: [inventory.categoryId],
        references: [categories.id],
    }),
    branch: one(branches, {
        fields: [inventory.branchId],
        references: [branches.id],
    }),
    productIngredients: many(productIngredients),
}));

// ── Product Ingredient Relations ───────────────────────────────
export const productIngredientsRelations = relations(productIngredients, ({ one }) => ({
    product: one(products, {
        fields: [productIngredients.productId],
        references: [products.id],
    }),
    inventoryItem: one(inventory, {
        fields: [productIngredients.inventoryId],
        references: [inventory.id],
    }),
}));

// ── Staff Relations ────────────────────────────────────────────
export const staffRelations = relations(staff, ({ one, many }) => ({
    branch: one(branches, {
        fields: [staff.branchId],
        references: [branches.id],
    }),
    orders: many(orders),
    shifts: many(shifts),
    expenses: many(expenses),
}));

// ── Shift Relations ────────────────────────────────────────────
export const shiftsRelations = relations(shifts, ({ one, many }) => ({
    staff: one(staff, {
        fields: [shifts.staffId],
        references: [staff.id],
    }),
    branch: one(branches, {
        fields: [shifts.branchId],
        references: [branches.id],
    }),
    orders: many(orders),
    expenses: many(expenses),
}));

// ── Order Relations ────────────────────────────────────────────
export const ordersRelations = relations(orders, ({ one, many }) => ({
    staff: one(staff, {
        fields: [orders.staffId],
        references: [staff.id],
    }),
    branch: one(branches, {
        fields: [orders.branchId],
        references: [branches.id],
    }),
    shift: one(shifts, {
        fields: [orders.shiftId],
        references: [shifts.id],
    }),
    items: many(orderItems),
    payments: many(payments),
}));

// ── Order Item Relations ───────────────────────────────────────
export const orderItemsRelations = relations(orderItems, ({ one }) => ({
    order: one(orders, {
        fields: [orderItems.orderId],
        references: [orders.id],
    }),
    product: one(products, {
        fields: [orderItems.productId],
        references: [products.id],
    }),
    variant: one(productVariants, {
        fields: [orderItems.variantId],
        references: [productVariants.id],
    }),
}));

// ── Payment Relations ──────────────────────────────────────────
export const paymentsRelations = relations(payments, ({ one }) => ({
    order: one(orders, {
        fields: [payments.orderId],
        references: [orders.id],
    }),
}));

// ── Expense Relations ──────────────────────────────────────────
export const expensesRelations = relations(expenses, ({ one }) => ({
    staff: one(staff, {
        fields: [expenses.staffId],
        references: [staff.id],
    }),
    branch: one(branches, {
        fields: [expenses.branchId],
        references: [branches.id],
    }),
    shift: one(shifts, {
        fields: [expenses.shiftId],
        references: [shifts.id],
    }),
}));

// ── Stock Adjustment Relations ─────────────────────────────────
export const stockAdjustmentsRelations = relations(stockAdjustments, ({ one }) => ({
    inventoryItem: one(inventory, {
        fields: [stockAdjustments.inventoryId],
        references: [inventory.id],
    }),
    staff: one(staff, {
        fields: [stockAdjustments.staffId],
        references: [staff.id],
    }),
}));
