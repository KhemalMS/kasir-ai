import { Router, Request, Response } from 'express';
import { expensesService } from '../services/expenses.service.js';

const router = Router();

router.get('/', async (req: Request, res: Response) => {
    const expenses = await expensesService.findAll({
        branchId: req.query.branchId as string,
        category: req.query.category as string,
        status: req.query.status as string,
        startDate: req.query.startDate ? new Date(req.query.startDate as string) : undefined,
        endDate: req.query.endDate ? new Date(req.query.endDate as string) : undefined,
    });
    res.json(expenses);
});

router.get('/:id', async (req: Request<{ id: string }>, res: Response) => {
    const expense = await expensesService.findById(req.params.id);
    if (!expense) { res.status(404).json({ error: 'Expense not found' }); return; }
    res.json(expense);
});

router.post('/', async (req: Request, res: Response) => {
    const expense = await expensesService.create(req.body);
    res.status(201).json(expense);
});

router.put('/:id', async (req: Request<{ id: string }>, res: Response) => {
    const expense = await expensesService.update(req.params.id, req.body);
    if (!expense) { res.status(404).json({ error: 'Expense not found' }); return; }
    res.json(expense);
});

router.put('/:id/approve', async (req: Request<{ id: string }>, res: Response) => {
    const expense = await expensesService.approve(req.params.id, req.body.status);
    res.json(expense);
});

router.delete('/:id', async (req: Request<{ id: string }>, res: Response) => {
    const expense = await expensesService.delete(req.params.id);
    if (!expense) { res.status(404).json({ error: 'Expense not found' }); return; }
    res.json({ message: 'Expense deleted' });
});

export default router;
