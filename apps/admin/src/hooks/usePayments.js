import { useQuery } from '@tanstack/react-query';
import { paymentsService } from '../services/payments.service';

export function usePayments() {
    return useQuery({
        queryKey: ['payments'],
        queryFn: paymentsService.getAll,
    });
}

export function usePaymentsByOrder(orderId) {
    return useQuery({
        queryKey: ['payments', orderId],
        queryFn: () => paymentsService.getByOrderId(orderId),
        enabled: !!orderId,
    });
}
