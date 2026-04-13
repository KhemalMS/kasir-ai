import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { expensesService } from '../services/expenses.service';

export function useExpenses(filters) {
    return useQuery({
        queryKey: ['expenses', filters],
        queryFn: () => expensesService.getAll(filters),
    });
}

export function useExpense(id) {
    return useQuery({
        queryKey: ['expenses', id],
        queryFn: () => expensesService.getById(id),
        enabled: !!id,
    });
}

export function useCreateExpense() {
    const queryClient = useQueryClient();
    return useMutation({
        mutationFn: expensesService.create,
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['expenses'] });
            queryClient.invalidateQueries({ queryKey: ['reports'] });
        },
    });
}

export function useUpdateExpense() {
    const queryClient = useQueryClient();
    return useMutation({
        mutationFn: ({ id, data }) => expensesService.update(id, data),
        onSuccess: () => queryClient.invalidateQueries({ queryKey: ['expenses'] }),
    });
}

export function useApproveExpense() {
    const queryClient = useQueryClient();
    return useMutation({
        mutationFn: ({ id, status }) => expensesService.approve(id, status),
        onSuccess: () => queryClient.invalidateQueries({ queryKey: ['expenses'] }),
    });
}

export function useDeleteExpense() {
    const queryClient = useQueryClient();
    return useMutation({
        mutationFn: expensesService.delete,
        onSuccess: () => queryClient.invalidateQueries({ queryKey: ['expenses'] }),
    });
}
