import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { settingsService } from '../services/settings.service';

// General settings
export function useSettings() {
    return useQuery({
        queryKey: ['settings'],
        queryFn: settingsService.getAll,
    });
}

export function useSettingsByGroup(group) {
    return useQuery({
        queryKey: ['settings', group],
        queryFn: () => settingsService.getByGroup(group),
        enabled: !!group,
    });
}

export function useUpdateSettings() {
    const queryClient = useQueryClient();
    return useMutation({
        mutationFn: settingsService.bulkUpdate,
        onSuccess: () => queryClient.invalidateQueries({ queryKey: ['settings'] }),
    });
}

// Payment methods
export function usePaymentMethods() {
    return useQuery({
        queryKey: ['settings', 'payment-methods'],
        queryFn: settingsService.getPaymentMethods,
    });
}

export function useCreatePaymentMethod() {
    const queryClient = useQueryClient();
    return useMutation({
        mutationFn: settingsService.createPaymentMethod,
        onSuccess: () => queryClient.invalidateQueries({ queryKey: ['settings', 'payment-methods'] }),
    });
}

export function useUpdatePaymentMethod() {
    const queryClient = useQueryClient();
    return useMutation({
        mutationFn: ({ id, data }) => settingsService.updatePaymentMethod(id, data),
        onSuccess: () => queryClient.invalidateQueries({ queryKey: ['settings', 'payment-methods'] }),
    });
}

export function useDeletePaymentMethod() {
    const queryClient = useQueryClient();
    return useMutation({
        mutationFn: settingsService.deletePaymentMethod,
        onSuccess: () => queryClient.invalidateQueries({ queryKey: ['settings', 'payment-methods'] }),
    });
}

// Taxes
export function useTaxes() {
    return useQuery({
        queryKey: ['settings', 'taxes'],
        queryFn: settingsService.getTaxes,
    });
}

export function useCreateTax() {
    const queryClient = useQueryClient();
    return useMutation({
        mutationFn: settingsService.createTax,
        onSuccess: () => queryClient.invalidateQueries({ queryKey: ['settings', 'taxes'] }),
    });
}

export function useUpdateTax() {
    const queryClient = useQueryClient();
    return useMutation({
        mutationFn: ({ id, data }) => settingsService.updateTax(id, data),
        onSuccess: () => queryClient.invalidateQueries({ queryKey: ['settings', 'taxes'] }),
    });
}

export function useDeleteTax() {
    const queryClient = useQueryClient();
    return useMutation({
        mutationFn: settingsService.deleteTax,
        onSuccess: () => queryClient.invalidateQueries({ queryKey: ['settings', 'taxes'] }),
    });
}
