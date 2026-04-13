import { Router, Request, Response } from 'express';
import { branchesService } from '../services/branches.service.js';

const router = Router();

router.get('/', async (_req: Request, res: Response) => {
    const branches = await branchesService.findAll();
    res.json(branches);
});

router.get('/:id', async (req: Request<{ id: string }>, res: Response) => {
    const branch = await branchesService.findById(req.params.id);
    if (!branch) { res.status(404).json({ error: 'Branch not found' }); return; }
    res.json(branch);
});

router.post('/', async (req: Request, res: Response) => {
    const branch = await branchesService.create(req.body);
    res.status(201).json(branch);
});

router.put('/:id', async (req: Request<{ id: string }>, res: Response) => {
    const branch = await branchesService.update(req.params.id, req.body);
    if (!branch) { res.status(404).json({ error: 'Branch not found' }); return; }
    res.json(branch);
});

router.delete('/:id', async (req: Request<{ id: string }>, res: Response) => {
    const branch = await branchesService.delete(req.params.id);
    if (!branch) { res.status(404).json({ error: 'Branch not found' }); return; }
    res.json({ message: 'Branch deleted' });
});

export default router;
