import { Router, Request, Response } from 'express';
import { AppError, asyncHandler } from '../middleware/errorHandler.js';
import { z } from 'zod';
import { validateQuery } from '../middleware/validate.middleware.js';
import { productsService } from '../services/products.service.js';
import { inventoryService } from '../services/inventory.service.js';


const router = Router();

const listQuerySchema = z.object({
    categoryId: z.string().optional(),
    search: z.string().optional(),
    includeInactive: z.preprocess((v) => v === 'true', z.boolean().default(false)),
    limit: z.coerce.number().int().min(1).max(100).default(50),
    offset: z.coerce.number().int().min(0).default(0),
});

router.get('/', validateQuery(listQuerySchema), asyncHandler(async (req: Request, res: Response) => {
    const products = await productsService.findAll({
        categoryId: req.query.categoryId as string | undefined,
        search: req.query.search as string | undefined,
        includeInactive: req.query.includeInactive as unknown as boolean,
        limit: req.query.limit as unknown as number,
        offset: req.query.offset as unknown as number,
    });
    res.json(products);
}));

router.get('/:id', asyncHandler(async (req: Request<{ id: string }>, res: Response) => {
    const product = await productsService.findById(req.params.id);
    if (!product) { throw AppError.notFound(); }
    res.json(product);
}));

router.post('/', asyncHandler(async (req: Request, res: Response) => {
    const product = await productsService.create(req.body);
    res.status(201).json(product);
}));

router.put('/:id', asyncHandler(async (req: Request<{ id: string }>, res: Response) => {
    const product = await productsService.update(req.params.id, req.body);
    if (!product) { throw AppError.notFound(); }
    res.json(product);
}));

router.delete('/:id', asyncHandler(async (req: Request<{ id: string }>, res: Response) => {
    const result = await productsService.delete(req.params.id);
    if (!result) { throw AppError.notFound(); }
    if ((result as any).softDeleted) {
        res.json({ message: 'Produk dinonaktifkan karena sudah pernah digunakan dalam pesanan' });
    } else {
        res.json({ message: 'Product deleted' });
    }
}));

// Variants
router.get('/:id/variants', asyncHandler(async (req: Request<{ id: string }>, res: Response) => {
    const variants = await productsService.getVariants(req.params.id);
    res.json(variants);
}));

router.post('/:id/variants', asyncHandler(async (req: Request<{ id: string }>, res: Response) => {
    const variant = await productsService.addVariant({
        ...req.body,
        productId: req.params.id,
    });
    res.status(201).json(variant);
}));

router.put('/:id/variants/:variantId', asyncHandler(async (req: Request<{ id: string; variantId: string }>, res: Response) => {
    const variant = await productsService.updateVariant(req.params.variantId, req.body);
    if (!variant) { throw AppError.notFound(); }
    res.json(variant);
}));

router.delete('/:id/variants/:variantId', asyncHandler(async (req: Request<{ id: string; variantId: string }>, res: Response) => {
    const variant = await productsService.deleteVariant(req.params.variantId);
    if (!variant) { throw AppError.notFound(); }
    res.json({ message: 'Variant deleted' });
}));

// ─── Ingredients ──────────────────────────────────────────────
// GET /products/recipes/all — all recipes (for admin recipe management page)
router.get('/recipes/all', asyncHandler(async (_req: Request, res: Response) => {
    const recipes = await inventoryService.getAllRecipes();
    res.json(recipes);
}));

// GET /products/:id/recipe — get recipe ingredients for one product (optionally ?variantId=)
router.get('/:id/recipe', asyncHandler(async (req: Request<{ id: string }>, res: Response) => {
    const { variantId } = req.query as { variantId?: string };
    const recipe = await inventoryService.getRecipe(req.params.id, variantId ?? null);
    res.json(recipe);
}));

// POST /products/:id/recipe — set (replace) recipe for a product (optionally with variantId in body)
router.post('/:id/recipe', asyncHandler(async (req: Request<{ id: string }>, res: Response) => {
    const { ingredients, variantId } = req.body as {
        ingredients: { inventoryId: string; quantityUsed: number }[];
        variantId?: string | null;
    };
    if (!Array.isArray(ingredients)) {
        throw AppError.validation('Ingredients harus berupa array');
    }
    const recipe = await inventoryService.setRecipe(req.params.id, ingredients, variantId ?? null);
    res.json(recipe);
}));

router.post('/:id/ingredients', asyncHandler(async (req: Request<{ id: string }>, res: Response) => {
    const ingredient = await productsService.addIngredient({
        ...req.body,
        productId: req.params.id,
    });
    res.status(201).json(ingredient);
}));

router.delete('/:id/ingredients/:ingredientId', asyncHandler(async (req: Request<{ id: string; ingredientId: string }>, res: Response) => {
    const ingredient = await productsService.removeIngredient(req.params.ingredientId);
    if (!ingredient) { throw AppError.notFound(); }
    res.json({ message: 'Ingredient unlinked' });
}));

// Branch availability
router.put('/:id/branches', asyncHandler(async (req: Request<{ id: string }>, res: Response) => {
    const result = await productsService.updateBranchAvailability(req.params.id, req.body.branches);
    res.json(result);
}));

export default router;
