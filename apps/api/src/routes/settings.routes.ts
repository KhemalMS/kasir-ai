import { Router, Request, Response } from 'express';
import { settingsService } from '../services/settings.service.js';

const router = Router();

// General settings
router.get('/', async (_req: Request, res: Response) => {
    const settings = await settingsService.findAll();
    res.json(settings);
});

router.get('/group/:group', async (req: Request<{ group: string }>, res: Response) => {
    const settings = await settingsService.findByGroup(req.params.group);
    res.json(settings);
});

router.put('/', async (req: Request, res: Response) => {
    const results = await settingsService.bulkUpdate(req.body.settings);
    res.json(results);
});

// Payment methods
router.get('/payment-methods', async (_req: Request, res: Response) => {
    const methods = await settingsService.getPaymentMethods();
    res.json(methods);
});

router.post('/payment-methods', async (req: Request, res: Response) => {
    const method = await settingsService.createPaymentMethod(req.body);
    res.status(201).json(method);
});

router.put('/payment-methods/:id', async (req: Request<{ id: string }>, res: Response) => {
    const method = await settingsService.updatePaymentMethod(req.params.id, req.body);
    if (!method) { res.status(404).json({ error: 'Payment method not found' }); return; }
    res.json(method);
});

router.delete('/payment-methods/:id', async (req: Request<{ id: string }>, res: Response) => {
    const method = await settingsService.deletePaymentMethod(req.params.id);
    if (!method) { res.status(404).json({ error: 'Payment method not found' }); return; }
    res.json({ message: 'Payment method deleted' });
});

// Taxes
router.get('/taxes', async (_req: Request, res: Response) => {
    const taxes = await settingsService.getTaxes();
    res.json(taxes);
});

router.post('/taxes', async (req: Request, res: Response) => {
    const tax = await settingsService.createTax(req.body);
    res.status(201).json(tax);
});

router.put('/taxes/:id', async (req: Request<{ id: string }>, res: Response) => {
    const tax = await settingsService.updateTax(req.params.id, req.body);
    if (!tax) { res.status(404).json({ error: 'Tax not found' }); return; }
    res.json(tax);
});

router.delete('/taxes/:id', async (req: Request<{ id: string }>, res: Response) => {
    const tax = await settingsService.deleteTax(req.params.id);
    if (!tax) { res.status(404).json({ error: 'Tax not found' }); return; }
    res.json({ message: 'Tax deleted' });
});

export default router;
