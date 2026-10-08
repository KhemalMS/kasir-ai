import { Router, Request, Response } from 'express';
import { AppError, asyncHandler } from '../middleware/errorHandler.js';
import { customersService } from '../services/customers.service.js';

const router = Router();

// GET /api/customers?search=
router.get('/', asyncHandler(async (req: Request, res: Response) => {
    const search = req.query.search as string | undefined;
    const data = await customersService.getAllCustomers(search);
    res.json(data);
}));

// GET /api/customers/:id
router.get('/:id', asyncHandler(async (req: Request, res: Response) => {
    const data = await customersService.getCustomerById(req.params.id as string);
    if (!data) throw AppError.notFound('Customer tidak ditemukan');
    res.json(data);
}));

// POST /api/customers
router.post('/', asyncHandler(async (req: Request, res: Response) => {
    try {
        const data = await customersService.createCustomer(req.body);
        res.status(201).json(data);
    } catch (err: any) {
        if (err?.code === 'ER_DUP_ENTRY') {
            throw AppError.conflict('Data customer sudah ada (duplikat)');
        }
        if (err instanceof AppError) throw err;
        throw err;
    }
}));

// PUT /api/customers/:id
router.put('/:id', asyncHandler(async (req: Request, res: Response) => {
    try {
        const data = await customersService.updateCustomer(req.params.id as string, req.body);
        res.json(data);
    } catch (err: any) {
        if (err?.code === 'ER_DUP_ENTRY') {
            throw AppError.conflict('Data customer sudah ada (duplikat)');
        }
        if (err instanceof AppError) throw err;
        throw err;
    }
}));

export default router;
