import { Router, Request, Response } from 'express';
import { z } from 'zod';
import { ordersService } from '../services/orders.service.js';
import { validateBody } from '../middleware/validate.middleware.js';

const router = Router();

// Validation schemas
const createOrderSchema = z.object({
    branchId: z.string().default('default'),
    staffId: z.string().default('unknown'),
    shiftId: z.string().optional().nullable(),
    orderType: z.string().optional().default('dine_in'),
    tableNumber: z.string().optional().nullable(),
    items: z.preprocess(
        (v) => Array.isArray(v) ? v.filter((i: any) => i != null && typeof i === 'object' && i.productId) : v,
        z.array(z.object({
            productId: z.string().min(1),
            quantity: z.preprocess((v) => {
                const n = Number(v);
                return isNaN(n) ? 1 : n;
            }, z.number().int().positive()),
            price: z.preprocess((v) => {
                const n = Number(v);
                return isNaN(n) ? 0 : n;
            }, z.number().nonnegative()),
            notes: z.string().max(500).optional().nullable(),
            variantId: z.string().optional().nullable(),
        })).min(1, 'At least one item is required')
    ),
    status: z.string().optional(),
}).passthrough(); // Allow additional fields

const updateStatusSchema = z.object({
    status: z.enum(['pending', 'preparing', 'ready', 'completed', 'cancelled']),
});

router.get('/', async (req: Request, res: Response) => {
    const orders = await ordersService.findAll({
        branchId: req.query.branchId as string,
        status: req.query.status as string,
        shiftId: req.query.shiftId as string,
        startDate: req.query.startDate ? new Date(req.query.startDate as string) : undefined,
        endDate: req.query.endDate ? new Date(req.query.endDate as string) : undefined,
    });
    res.json(orders);
});

router.get('/saved', async (req: Request, res: Response) => {
    const shiftId = req.query.shiftId as string;
    if (!shiftId) { res.status(400).json({ error: 'shiftId is required' }); return; }
    const orders = await ordersService.getSavedOrders(shiftId);
    res.json(orders);
});

router.get('/:id', async (req: Request<{ id: string }>, res: Response) => {
    const order = await ordersService.findById(req.params.id);
    if (!order) { res.status(404).json({ error: 'Order not found' }); return; }
    res.json(order);
});

router.post('/', validateBody(createOrderSchema), async (req: Request, res: Response) => {
    try {
        const order = await ordersService.create(req.body);
        res.status(201).json(order);
    } catch (err: any) {
        console.error('[Orders] Create error:', err);
        res.status(500).json({ error: err.message || 'Failed to create order' });
    }
});

router.put('/:id/status', validateBody(updateStatusSchema), async (req: Request<{ id: string }>, res: Response) => {
    const order = await ordersService.updateStatus(req.params.id, req.body.status);
    res.json(order);
});

router.delete('/:id', async (req: Request<{ id: string }>, res: Response) => {
    try {
        const order = await ordersService.delete(req.params.id);
        res.json({ message: 'Order deleted', order });
    } catch (err: any) {
        if (err.statusCode === 404) {
            res.status(404).json({ error: 'Order not found' });
        } else {
            res.status(500).json({ error: err.message || 'Failed to delete order' });
        }
    }
});

export default router;
