import { db } from '../db/index.js';
import { inventory } from '../db/schema/inventory.js';
import { productIngredients } from '../db/schema/productIngredients.js';
import { stockAdjustments } from '../db/schema/stockAdjustments.js';
import { products } from '../db/schema/products.js';
import { eq, and, like, sql, lte, desc, isNull } from 'drizzle-orm';
import { v4 as uuidv4 } from 'uuid';
import { productVariants } from '../db/schema/productVariants.js';

export const inventoryService = {
    // ─── CRUD ────────────────────────────────────────────────────
    async findAll(filters?: { branchId?: string; categoryId?: string; search?: string }) {
        const conditions = [];
        if (filters?.branchId) conditions.push(eq(inventory.branchId, filters.branchId));
        if (filters?.categoryId) conditions.push(eq(inventory.categoryId, filters.categoryId));
        if (filters?.search) conditions.push(like(inventory.name, `%${filters.search}%`));

        if (conditions.length > 0) {
            return db.select().from(inventory).where(and(...conditions));
        }
        return db.select().from(inventory);
    },

    async findById(id: string) {
        const [item] = await db.select().from(inventory).where(eq(inventory.id, id));
        return item || null;
    },

    async create(data: typeof inventory.$inferInsert) {
        const id = data.id || uuidv4();
        await db.insert(inventory).values({ ...data, id });
        return this.findById(id);
    },

    async update(id: string, data: Partial<typeof inventory.$inferInsert>) {
        await db
            .update(inventory)
            .set({ ...data, updatedAt: new Date() })
            .where(eq(inventory.id, id));
        return this.findById(id);
    },

    async delete(id: string) {
        const item = await this.findById(id);
        await db.delete(inventory).where(eq(inventory.id, id));
        return item;
    },

    // ─── Alerts ──────────────────────────────────────────────────
    async getAlerts() {
        return db
            .select()
            .from(inventory)
            .where(
                lte(inventory.quantity, sql`${inventory.reorderThreshold}`)
            );
    },

    // ─── Stock Adjustment ────────────────────────────────────────
    async adjustStock(inventoryId: string, staffId: string | null, quantity: number, type: string, reason?: string) {
        return db.transaction(async (tx) => {
            // Log the adjustment
            await tx.insert(stockAdjustments).values({
                id: uuidv4(),
                inventoryId,
                staffId,
                type,
                quantity: String(quantity),
                reason: reason || null,
            });

            // Update inventory quantity
            if (type === 'IN') {
                await tx.update(inventory)
                    .set({ quantity: sql`${inventory.quantity} + ${quantity}`, updatedAt: new Date() })
                    .where(eq(inventory.id, inventoryId));
            } else if (type === 'OUT' || type === 'ORDER') {
                await tx.update(inventory)
                    .set({ quantity: sql`GREATEST(${inventory.quantity} - ${quantity}, 0)`, updatedAt: new Date() })
                    .where(eq(inventory.id, inventoryId));
            } else if (type === 'ADJUSTMENT') {
                await tx.update(inventory)
                    .set({ quantity: String(quantity), updatedAt: new Date() })
                    .where(eq(inventory.id, inventoryId));
            }

            return this.findById(inventoryId);
        });
    },

    async getAdjustmentLog(inventoryId?: string) {
        const sa = stockAdjustments;
        const inv = inventory;

        const baseQuery = db
            .select({
                id: sa.id,
                inventoryId: sa.inventoryId,
                inventoryName: inv.name,
                staffId: sa.staffId,
                type: sa.type,
                quantity: sa.quantity,
                reason: sa.reason,
                createdAt: sa.createdAt,
            })
            .from(sa)
            .leftJoin(inv, eq(sa.inventoryId, inv.id))
            .orderBy(desc(sa.createdAt));

        if (inventoryId) {
            return baseQuery.where(eq(sa.inventoryId, inventoryId));
        }
        return baseQuery;
    },

    // ─── Recipes (Product Ingredients) ───────────────────────────
    async getRecipe(productId: string, variantId?: string | null) {
        const pi = productIngredients;
        const inv = inventory;

        const conditions = [eq(pi.productId, productId)];
        if (variantId) {
            conditions.push(eq(pi.variantId, variantId));
        } else {
            conditions.push(isNull(pi.variantId));
        }

        return db
            .select({
                id: pi.id,
                productId: pi.productId,
                variantId: pi.variantId,
                inventoryId: pi.inventoryId,
                quantityUsed: pi.quantityUsed,
                inventoryName: inv.name,
                inventoryUnit: inv.unit,
                inventoryStock: inv.quantity,
            })
            .from(pi)
            .leftJoin(inv, eq(pi.inventoryId, inv.id))
            .where(and(...conditions));
    },

    async getAllRecipes() {
        const pi = productIngredients;
        const inv = inventory;
        const prod = products;
        const pv = productVariants;

        return db
            .select({
                id: pi.id,
                productId: pi.productId,
                productName: prod.name,
                variantId: pi.variantId,
                variantName: pv.name,
                inventoryId: pi.inventoryId,
                inventoryName: inv.name,
                inventoryUnit: inv.unit,
                quantityUsed: pi.quantityUsed,
            })
            .from(pi)
            .leftJoin(inv, eq(pi.inventoryId, inv.id))
            .leftJoin(prod, eq(pi.productId, prod.id))
            .leftJoin(pv, eq(pi.variantId, pv.id));
    },

    async setRecipe(productId: string, ingredients: { inventoryId: string; quantityUsed: number }[], variantId?: string | null) {
        return db.transaction(async (tx) => {
            // Delete existing recipe for this product+variant combo
            if (variantId) {
                await tx.delete(productIngredients).where(
                    and(eq(productIngredients.productId, productId), eq(productIngredients.variantId, variantId))
                );
            } else {
                await tx.delete(productIngredients).where(
                    and(eq(productIngredients.productId, productId), isNull(productIngredients.variantId))
                );
            }

            // Insert new recipe
            if (ingredients.length > 0) {
                await tx.insert(productIngredients).values(
                    ingredients.map((ing) => ({
                        id: uuidv4(),
                        productId,
                        variantId: variantId || null,
                        inventoryId: ing.inventoryId,
                        quantityUsed: String(ing.quantityUsed),
                    }))
                );
            }

            return this.getRecipe(productId, variantId);
        });
    },

    // ─── Auto-deduct on Order ────────────────────────────────────
    async deductForOrder(items: { productId: string; variantId?: string | null; quantity: number }[], staffId?: string) {
        for (const item of items) {
            // Try variant-specific recipe first, then fall back to base product recipe
            let recipe = item.variantId
                ? await this.getRecipe(item.productId, item.variantId)
                : [];
            if (recipe.length === 0) {
                recipe = await this.getRecipe(item.productId, null);
            }
            for (const ingredient of recipe) {
                const deductQty = Number(ingredient.quantityUsed) * item.quantity;
                if (deductQty > 0) {
                    await this.adjustStock(
                        ingredient.inventoryId,
                        staffId || null,
                        deductQty,
                        'ORDER',
                        `Order: ${item.productId}${item.variantId ? ` (variant: ${item.variantId})` : ''} x${item.quantity}`
                    );
                }
            }
        }
    },
};
