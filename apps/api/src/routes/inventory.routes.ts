import { Router, Request, Response } from 'express';
import { inventoryService } from '../services/inventory.service.js';

const router = Router();

// ─── CRUD ────────────────────────────────────────────────────────
router.get('/', async (req: Request, res: Response) => {
    const items = await inventoryService.findAll({
        branchId: req.query.branchId as string,
        categoryId: req.query.categoryId as string,
        search: req.query.search as string,
    });
    res.json(items);
});

router.get('/alerts', async (_req: Request, res: Response) => {
    const alerts = await inventoryService.getAlerts();
    res.json(alerts);
});

router.get('/:id', async (req: Request<{ id: string }>, res: Response) => {
    const item = await inventoryService.findById(req.params.id);
    if (!item) { res.status(404).json({ error: 'Inventory item not found' }); return; }
    res.json(item);
});

router.post('/', async (req: Request, res: Response) => {
    const item = await inventoryService.create(req.body);
    res.status(201).json(item);
});

router.put('/:id', async (req: Request<{ id: string }>, res: Response) => {
    const item = await inventoryService.update(req.params.id, req.body);
    if (!item) { res.status(404).json({ error: 'Inventory item not found' }); return; }
    res.json(item);
});

router.delete('/:id', async (req: Request<{ id: string }>, res: Response) => {
    const item = await inventoryService.delete(req.params.id);
    if (!item) { res.status(404).json({ error: 'Inventory item not found' }); return; }
    res.json({ message: 'Inventory item deleted' });
});

// ─── Stock Adjustments ───────────────────────────────────────────
router.post('/:id/adjust', async (req: Request<{ id: string }>, res: Response) => {
    const { quantity, type, reason, staffId } = req.body;
    if (!quantity || !type) {
        res.status(400).json({ error: 'quantity and type are required' });
        return;
    }
    const item = await inventoryService.adjustStock(req.params.id, staffId || null, Number(quantity), type, reason);
    res.json(item);
});

router.get('/adjustments/log', async (req: Request, res: Response) => {
    const inventoryId = req.query.inventoryId as string | undefined;
    const log = await inventoryService.getAdjustmentLog(inventoryId);
    res.json(log);
});

// ─── Recipes ─────────────────────────────────────────────────────
router.get('/recipes/all', async (_req: Request, res: Response) => {
    const recipes = await inventoryService.getAllRecipes();
    res.json(recipes);
});

router.get('/recipes/:productId', async (req: Request<{ productId: string }>, res: Response) => {
    const variantId = req.query.variantId as string | undefined;
    const recipe = await inventoryService.getRecipe(req.params.productId, variantId || null);
    res.json(recipe);
});

router.post('/recipes/:productId', async (req: Request<{ productId: string }>, res: Response) => {
    const { ingredients, variantId } = req.body;
    if (!Array.isArray(ingredients)) {
        res.status(400).json({ error: 'ingredients array is required' });
        return;
    }
    const recipe = await inventoryService.setRecipe(req.params.productId, ingredients, variantId || null);
    res.json(recipe);
});

export default router;
