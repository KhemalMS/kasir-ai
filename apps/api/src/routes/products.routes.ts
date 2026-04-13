import { Router, Request, Response } from 'express';
import { productsService } from '../services/products.service.js';

const router = Router();

router.get('/', async (req: Request, res: Response) => {
    const products = await productsService.findAll({
        categoryId: req.query.categoryId as string,
        search: req.query.search as string,
        includeInactive: req.query.includeInactive === 'true',
    });
    res.json(products);
});

router.get('/:id', async (req: Request<{ id: string }>, res: Response) => {
    const product = await productsService.findById(req.params.id);
    if (!product) { res.status(404).json({ error: 'Product not found' }); return; }
    res.json(product);
});

router.post('/', async (req: Request, res: Response) => {
    const product = await productsService.create(req.body);
    res.status(201).json(product);
});

router.put('/:id', async (req: Request<{ id: string }>, res: Response) => {
    const product = await productsService.update(req.params.id, req.body);
    if (!product) { res.status(404).json({ error: 'Product not found' }); return; }
    res.json(product);
});

router.delete('/:id', async (req: Request<{ id: string }>, res: Response) => {
    try {
        const result = await productsService.delete(req.params.id);
        if (!result) { res.status(404).json({ error: 'Product not found' }); return; }
        if ((result as any).softDeleted) {
            res.json({ message: 'Produk dinonaktifkan karena sudah pernah digunakan dalam pesanan' });
        } else {
            res.json({ message: 'Product deleted' });
        }
    } catch (e: any) {
        res.status(500).json({ error: 'Gagal menghapus produk', details: e?.message });
    }
});

// Variants
router.get('/:id/variants', async (req: Request<{ id: string }>, res: Response) => {
    const variants = await productsService.getVariants(req.params.id);
    res.json(variants);
});

router.post('/:id/variants', async (req: Request<{ id: string }>, res: Response) => {
    const variant = await productsService.addVariant({
        ...req.body,
        productId: req.params.id,
    });
    res.status(201).json(variant);
});

router.put('/:id/variants/:variantId', async (req: Request<{ id: string; variantId: string }>, res: Response) => {
    const variant = await productsService.updateVariant(req.params.variantId, req.body);
    if (!variant) { res.status(404).json({ error: 'Variant not found' }); return; }
    res.json(variant);
});

router.delete('/:id/variants/:variantId', async (req: Request<{ id: string; variantId: string }>, res: Response) => {
    const variant = await productsService.deleteVariant(req.params.variantId);
    if (!variant) { res.status(404).json({ error: 'Variant not found' }); return; }
    res.json({ message: 'Variant deleted' });
});

// Ingredients
router.post('/:id/ingredients', async (req: Request<{ id: string }>, res: Response) => {
    const ingredient = await productsService.addIngredient({
        ...req.body,
        productId: req.params.id,
    });
    res.status(201).json(ingredient);
});

router.delete('/:id/ingredients/:ingredientId', async (req: Request<{ id: string; ingredientId: string }>, res: Response) => {
    const ingredient = await productsService.removeIngredient(req.params.ingredientId);
    if (!ingredient) { res.status(404).json({ error: 'Ingredient link not found' }); return; }
    res.json({ message: 'Ingredient unlinked' });
});

// Branch availability
router.put('/:id/branches', async (req: Request<{ id: string }>, res: Response) => {
    const result = await productsService.updateBranchAvailability(req.params.id, req.body.branches);
    res.json(result);
});

export default router;
