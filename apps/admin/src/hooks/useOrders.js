import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { ordersService } from '../services/orders.service';

export function useOrders(filters) {
    return useQuery({
        queryKey: ['orders', filters],
        queryFn: () => ordersService.getAll(filters),
    });
}

export function useOrder(id) {
    return useQuery({
        queryKey: ['orders', id],
        queryFn: () => ordersService.getById(id),
        enabled: !!id,
    });
}

export function useSavedOrders(shiftId) {
    return useQuery({
        queryKey: ['orders', 'saved', shiftId],
        queryFn: () => ordersService.getSaved(shiftId),
        enabled: !!shiftId,
    });
}

export function useCreateOrder() {
    const queryClient = useQueryClient();
    return useMutation({
        mutationFn: ordersService.create,
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['orders'] });
            queryClient.invalidateQueries({ queryKey: ['reports'] });
            queryClient.invalidateQueries({ queryKey: ['inventory'] });
        },
    });
}

export function useUpdateOrderStatus() {
    const queryClient = useQueryClient();
    return useMutation({
        mutationFn: ({ id, status }) => ordersService.updateStatus(id, status),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['orders'] });
            queryClient.invalidateQueries({ queryKey: ['kitchen'] });
        },
    });
}
