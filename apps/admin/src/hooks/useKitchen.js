import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { kitchenService } from '../services/kitchen.service';

export function useKitchenTickets(status) {
    return useQuery({
        queryKey: ['kitchen', 'tickets', status],
        queryFn: () => kitchenService.getTickets(status),
        refetchInterval: 10000, // Auto-refresh every 10 seconds for KDS
    });
}

export function useUpdateTicketStatus() {
    const queryClient = useQueryClient();
    return useMutation({
        mutationFn: ({ orderId, status }) => kitchenService.updateTicketStatus(orderId, status),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['kitchen'] });
            queryClient.invalidateQueries({ queryKey: ['orders'] });
        },
    });
}
