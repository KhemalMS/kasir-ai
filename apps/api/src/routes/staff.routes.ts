import { Router, Request, Response, NextFunction } from 'express';
import { staffService } from '../services/staff.service.js';

const router = Router();

router.get('/', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const staff = await staffService.findAll({
            branchId: req.query.branchId as string,
            role: req.query.role as string,
            search: req.query.search as string,
        });
        res.json(staff);
    } catch (e) { next(e); }
});

// Get staff by user ID (for Flutter auth flow)
router.get('/by-user/:userId', async (req: Request<{ userId: string }>, res: Response, next: NextFunction) => {
    try {
        const member = await staffService.findByUserId(req.params.userId);
        if (!member) { res.status(404).json({ error: 'Staff not found for this user' }); return; }
        res.json(member);
    } catch (e) { next(e); }
});

router.get('/:id', async (req: Request<{ id: string }>, res: Response, next: NextFunction) => {
    try {
        const member = await staffService.findById(req.params.id);
        if (!member) { res.status(404).json({ error: 'Staff not found' }); return; }
        res.json(member);
    } catch (e) { next(e); }
});

router.post('/', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const member = await staffService.create(req.body);
        res.status(201).json(member);
    } catch (e) { next(e); }
});

router.put('/:id', async (req: Request<{ id: string }>, res: Response, next: NextFunction) => {
    try {
        const member = await staffService.update(req.params.id, req.body);
        if (!member) { res.status(404).json({ error: 'Staff not found' }); return; }
        res.json(member);
    } catch (e) { next(e); }
});

router.delete('/:id', async (req: Request<{ id: string }>, res: Response, next: NextFunction) => {
    try {
        const member = await staffService.delete(req.params.id);
        if (!member) { res.status(404).json({ error: 'Staff not found' }); return; }
        res.json({ message: 'Staff deleted' });
    } catch (e) { next(e); }
});

export default router;
