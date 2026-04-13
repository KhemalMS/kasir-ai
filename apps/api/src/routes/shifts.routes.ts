import { Router, Request, Response, NextFunction } from 'express';
import { shiftsService } from '../services/shifts.service.js';

const router = Router();

router.get('/', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const shifts = await shiftsService.findAll({
            branchId: req.query.branchId as string,
            staffId: req.query.staffId as string,
        });
        res.json(shifts);
    } catch (e) { next(e); }
});

router.get('/current', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const staffId = req.query.staffId as string;
        if (!staffId) { res.status(400).json({ error: 'staffId is required' }); return; }
        const shift = await shiftsService.findCurrent(staffId);
        res.json(shift);
    } catch (e) { next(e); }
});

router.post('/start', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const shift = await shiftsService.start(req.body);
        res.status(201).json(shift);
    } catch (e) { next(e); }
});

router.post('/:id/close', async (req: Request<{ id: string }>, res: Response, next: NextFunction) => {
    try {
        const shift = await shiftsService.close(req.params.id, req.body.endingCash);
        res.json(shift);
    } catch (e) { next(e); }
});

router.get('/:id/summary', async (req: Request<{ id: string }>, res: Response, next: NextFunction) => {
    try {
        const summary = await shiftsService.getSummary(req.params.id);
        if (!summary) { res.status(404).json({ error: 'Shift not found' }); return; }
        res.json(summary);
    } catch (e) { next(e); }
});

export default router;
