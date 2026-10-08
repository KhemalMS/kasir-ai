import { Router, Request, Response } from 'express';
import { AppError, asyncHandler } from '../middleware/errorHandler.js';
import { z } from 'zod';
import { ordersService } from '../services/orders.service.js';
import { validateBody, validateQuery } from '../middleware/validate.middleware.js';

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

const listQuerySchema = z.object({
    branchId: z.string().optional(),
    status: z.string().optional(),
    shiftId: z.string().optional(),
    startDate: z.string().datetime().optional(),
    endDate: z.string().datetime().optional(),
    limit: z.coerce.number().int().min(1).max(100).default(50),
    offset: z.coerce.number().int().min(0).default(0),
});

router.get('/', validateQuery(listQuerySchema), asyncHandler(async (req: Request, res: Response) => {
    const orders = await ordersService.findAll({
        branchId: req.query.branchId as string,
        status: req.query.status as string,
        shiftId: req.query.shiftId as string,
        startDate: req.query.startDate ? new Date(req.query.startDate as string) : undefined,
        endDate: req.query.endDate ? new Date(req.query.endDate as string) : undefined,
        limit: req.query.limit as number | undefined,
        offset: req.query.offset as number | undefined,
    });
    res.json(orders);
}));

router.get('/saved', asyncHandler(async (req: Request, res: Response) => {
    const shiftId = req.query.shiftId as string;
    if (!shiftId) { throw AppError.validation('Shift ID diperlukan'); }
    const orders = await ordersService.getSavedOrders(shiftId);
    res.json(orders);
}));

router.get('/:id', asyncHandler(async (req: Request<{ id: string }>, res: Response) => {
    const order = await ordersService.findById(req.params.id);
    if (!order) { throw AppError.notFound('Order tidak ditemukan'); }
    res.json(order);
}));

router.post('/', validateBody(createOrderSchema), asyncHandler(async (req: Request, res: Response) => {
    const order = await ordersService.create(req.body);
    res.status(201).json(order);
}));

router.put('/:id/status', validateBody(updateStatusSchema), asyncHandler(async (req: Request<{ id: string }>, res: Response) => {
    const order = await ordersService.updateStatus(req.params.id, req.body.status);
    res.json(order);
}));

router.delete('/:id', asyncHandler(async (req: Request<{ id: string }>, res: Response) => {
    const order = await ordersService.delete(req.params.id);
    res.json({ message: 'Order deleted', order });
}));

export default router;
