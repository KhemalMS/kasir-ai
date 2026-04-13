import { Router, Request, Response, NextFunction } from 'express';
import { kitchenService } from '../services/kitchen.service.js';

const router = Router();

router.get('/tickets', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const status = req.query.status as string | undefined;
        const tickets = await kitchenService.getActiveTickets(status);
        res.json(tickets);
    } catch (e) { next(e); }
});

router.put('/tickets/:orderId/status', async (req: Request<{ orderId: string }>, res: Response, next: NextFunction) => {
    try {
        const order = await kitchenService.updateTicketStatus(req.params.orderId, req.body.status);
        if (!order) { res.status(404).json({ error: 'Order not found' }); return; }
        res.json(order);
    } catch (e) { next(e); }
});

export default router;
