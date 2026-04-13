import { Router, Request, Response } from 'express';
import { categoriesService } from '../services/categories.service.js';

const router = Router();

router.get('/', async (_req: Request, res: Response) => {
    const categories = await categoriesService.findAll();
    res.json(categories);
});

router.post('/', async (req: Request, res: Response) => {
    const category = await categoriesService.create(req.body);
    res.status(201).json(category);
});

router.put('/:id', async (req: Request<{ id: string }>, res: Response) => {
    const category = await categoriesService.update(req.params.id, req.body);
    if (!category) { res.status(404).json({ error: 'Category not found' }); return; }
    res.json(category);
});

router.delete('/:id', async (req: Request<{ id: string }>, res: Response) => {
    const category = await categoriesService.delete(req.params.id);
    if (!category) { res.status(404).json({ error: 'Category not found' }); return; }
    res.json({ message: 'Category deleted' });
});

export default router;
