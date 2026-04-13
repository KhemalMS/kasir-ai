import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { staffService } from '../services/staff.service';

export function useStaff(filters) {
    return useQuery({
        queryKey: ['staff', filters],
        queryFn: () => staffService.getAll(filters),
    });
}

export function useStaffMember(id) {
    return useQuery({
        queryKey: ['staff', id],
        queryFn: () => staffService.getById(id),
        enabled: !!id,
    });
}

export function useCreateStaff() {
    const queryClient = useQueryClient();
    return useMutation({
        mutationFn: staffService.create,
        onSuccess: () => queryClient.invalidateQueries({ queryKey: ['staff'] }),
    });
}

export function useUpdateStaff() {
    const queryClient = useQueryClient();
    return useMutation({
        mutationFn: ({ id, data }) => staffService.update(id, data),
        onSuccess: () => queryClient.invalidateQueries({ queryKey: ['staff'] }),
    });
}

export function useDeleteStaff() {
    const queryClient = useQueryClient();
    return useMutation({
        mutationFn: staffService.delete,
        onSuccess: () => queryClient.invalidateQueries({ queryKey: ['staff'] }),
    });
}
