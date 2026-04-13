import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { branchesService } from '../services/branches.service';

export function useBranches() {
    return useQuery({
        queryKey: ['branches'],
        queryFn: branchesService.getAll,
    });
}

export function useBranch(id) {
    return useQuery({
        queryKey: ['branches', id],
        queryFn: () => branchesService.getById(id),
        enabled: !!id,
    });
}

export function useCreateBranch() {
    const queryClient = useQueryClient();
    return useMutation({
        mutationFn: branchesService.create,
        onSuccess: () => queryClient.invalidateQueries({ queryKey: ['branches'] }),
    });
}

export function useUpdateBranch() {
    const queryClient = useQueryClient();
    return useMutation({
        mutationFn: ({ id, data }) => branchesService.update(id, data),
        onSuccess: () => queryClient.invalidateQueries({ queryKey: ['branches'] }),
    });
}

export function useDeleteBranch() {
    const queryClient = useQueryClient();
    return useMutation({
        mutationFn: branchesService.delete,
        onSuccess: () => queryClient.invalidateQueries({ queryKey: ['branches'] }),
    });
}
