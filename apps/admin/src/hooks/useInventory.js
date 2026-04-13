import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { inventoryService } from '../services/inventory.service';

export function useInventory(filters) {
    return useQuery({
        queryKey: ['inventory', filters],
        queryFn: () => inventoryService.getAll(filters),
    });
}

export function useInventoryItem(id) {
    return useQuery({
        queryKey: ['inventory', id],
        queryFn: () => inventoryService.getById(id),
        enabled: !!id,
    });
}

export function useInventoryAlerts() {
    return useQuery({
        queryKey: ['inventory', 'alerts'],
        queryFn: inventoryService.getAlerts,
    });
}

export function useCreateInventoryItem() {
    const queryClient = useQueryClient();
    return useMutation({
        mutationFn: inventoryService.create,
        onSuccess: () => queryClient.invalidateQueries({ queryKey: ['inventory'] }),
    });
}

export function useUpdateInventoryItem() {
    const queryClient = useQueryClient();
    return useMutation({
        mutationFn: ({ id, data }) => inventoryService.update(id, data),
        onSuccess: () => queryClient.invalidateQueries({ queryKey: ['inventory'] }),
    });
}

export function useDeleteInventoryItem() {
    const queryClient = useQueryClient();
    return useMutation({
        mutationFn: inventoryService.delete,
        onSuccess: () => queryClient.invalidateQueries({ queryKey: ['inventory'] }),
    });
}
