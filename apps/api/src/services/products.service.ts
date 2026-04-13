import { db } from '../db/index.js';
import { products } from '../db/schema/products.js';
import { categories } from '../db/schema/categories.js';
import { productVariants } from '../db/schema/productVariants.js';
import { productIngredients } from '../db/schema/productIngredients.js';
import { productBranches } from '../db/schema/productBranches.js';
import { eq, like, and } from 'drizzle-orm';
import { v4 as uuidv4 } from 'uuid';

export const productsService = {
    async findAll(filters?: { categoryId?: string; search?: string; includeInactive?: boolean }) {
        const conditions = [];

        // Only filter active unless admin requests all
        if (!filters?.includeInactive) {
            conditions.push(eq(products.isActive, true));
        }

        if (filters?.categoryId) {
            conditions.push(eq(products.categoryId, filters.categoryId));
        }
        if (filters?.search) {
            conditions.push(like(products.name, `%${filters.search}%`));
        }

        const rows = await db
            .select({
                id: products.id,
                name: products.name,
                code: products.code,
                unit: products.unit,
                description: products.description,
                basePrice: products.basePrice,
                markup: products.markup,
                price: products.price,
                originalPrice: products.originalPrice,
                taxInclusive: products.taxInclusive,
                categoryId: products.categoryId,
                category: categories.name,
                imageUrl: products.imageUrl,
                sku: products.sku,
                isAI: products.isAI,
                isActive: products.isActive,
                createdAt: products.createdAt,
                updatedAt: products.updatedAt,
            })
            .from(products)
            .leftJoin(categories, eq(products.categoryId, categories.id))
            .where(conditions.length > 0 ? and(...conditions) : undefined);

        // Fetch variants for all products in one query
        if (rows.length === 0) return rows;
        const productIds = rows.map(r => r.id);
        const allVariants = await db
            .select()
            .from(productVariants)
            .where(eq(productVariants.isActive, true));

        // Group variants by productId
        const variantMap = new Map<string, typeof allVariants>();
        for (const v of allVariants) {
            if (!productIds.includes(v.productId)) continue;
            const list = variantMap.get(v.productId) || [];
            list.push(v);
            variantMap.set(v.productId, list);
        }

        return rows.map(r => ({
            ...r,
            variants: variantMap.get(r.id) || [],
        }));
    },

    async findById(id: string) {
        const [row] = await db
            .select({
                id: products.id,
                name: products.name,
                code: products.code,
                unit: products.unit,
                description: products.description,
                basePrice: products.basePrice,
                markup: products.markup,
                price: products.price,
                originalPrice: products.originalPrice,
                taxInclusive: products.taxInclusive,
                categoryId: products.categoryId,
                category: categories.name,
                imageUrl: products.imageUrl,
                sku: products.sku,
                isAI: products.isAI,
                isActive: products.isActive,
                createdAt: products.createdAt,
                updatedAt: products.updatedAt,
            })
            .from(products)
            .leftJoin(categories, eq(products.categoryId, categories.id))
            .where(eq(products.id, id));
        return row || null;
    },

    async create(data: typeof products.$inferInsert) {
        const id = data.id || uuidv4();
        await db.insert(products).values({ ...data, id });
        return this.findById(id);
    },

    async update(id: string, data: Partial<typeof products.$inferInsert>) {
        await db
            .update(products)
            .set({ ...data, updatedAt: new Date() })
            .where(eq(products.id, id));
        return this.findById(id);
    },

    async delete(id: string) {
        const product = await this.findById(id);
        if (!product) return null;
        try {
            // Try hard delete first
            await db.delete(products).where(eq(products.id, id));
        } catch (e: any) {
            // If foreign key constraint fails, use soft delete
            if (e?.cause?.code === 'ER_ROW_IS_REFERENCED_2' || e?.code === 'ER_ROW_IS_REFERENCED_2') {
                await db.update(products)
                    .set({ isActive: false, updatedAt: new Date() })
                    .where(eq(products.id, id));
                return { ...product, isActive: false, softDeleted: true };
            }
            throw e;
        }
        return product;
    },

    async getVariants(productId: string) {
        return db.select().from(productVariants)
            .where(and(eq(productVariants.productId, productId), eq(productVariants.isActive, true)));
    },

    // Variants
    async addVariant(data: typeof productVariants.$inferInsert) {
        const id = data.id || uuidv4();
        await db.insert(productVariants).values({ ...data, id });
        const [variant] = await db.select().from(productVariants).where(eq(productVariants.id, id));
        return variant;
    },

    async updateVariant(variantId: string, data: Partial<typeof productVariants.$inferInsert>) {
        await db
            .update(productVariants)
            .set(data)
            .where(eq(productVariants.id, variantId));
        const [variant] = await db.select().from(productVariants).where(eq(productVariants.id, variantId));
        return variant;
    },

    async deleteVariant(variantId: string) {
        const [variant] = await db.select().from(productVariants).where(eq(productVariants.id, variantId));
        await db.delete(productVariants).where(eq(productVariants.id, variantId));
        return variant;
    },

    // Ingredients
    async addIngredient(data: typeof productIngredients.$inferInsert) {
        const id = data.id || uuidv4();
        await db.insert(productIngredients).values({ ...data, id });
        const [ingredient] = await db.select().from(productIngredients).where(eq(productIngredients.id, id));
        return ingredient;
    },

    async removeIngredient(ingredientId: string) {
        const [ingredient] = await db.select().from(productIngredients).where(eq(productIngredients.id, ingredientId));
        await db.delete(productIngredients).where(eq(productIngredients.id, ingredientId));
        return ingredient;
    },

    // Branch availability
    async updateBranchAvailability(
        productId: string,
        branchData: { branchId: string; isAvailable: boolean; stock?: number }[]
    ) {
        await db.delete(productBranches).where(eq(productBranches.productId, productId));
        if (branchData.length > 0) {
            const values = branchData.map((b) => ({ ...b, productId, id: uuidv4() }));
            await db.insert(productBranches).values(values);
            return values;
        }
        return [];
    },
};
