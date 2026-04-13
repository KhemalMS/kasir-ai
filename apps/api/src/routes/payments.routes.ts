import { Router, Request, Response } from 'express';
import { paymentsService } from '../services/payments.service.js';

const router = Router();

router.get('/', async (_req: Request, res: Response) => {
    const payments = await paymentsService.findAll();
    res.json(payments);
});

router.get('/:orderId', async (req: Request<{ orderId: string }>, res: Response) => {
    const payments = await paymentsService.findByOrderId(req.params.orderId);
    res.json(payments);
});

export default router;
