import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { shiftsService } from '../services/shifts.service';

export function useShifts(filters) {
    return useQuery({
        queryKey: ['shifts', filters],
        queryFn: () => shiftsService.getAll(filters),
    });
}

export function useCurrentShift(staffId) {
    return useQuery({
        queryKey: ['shifts', 'current', staffId],
        queryFn: () => shiftsService.getCurrent(staffId),
        enabled: !!staffId,
    });
}

export function useShiftSummary(shiftId) {
    return useQuery({
        queryKey: ['shifts', shiftId, 'summary'],
        queryFn: () => shiftsService.getSummary(shiftId),
        enabled: !!shiftId,
    });
}

export function useStartShift() {
    const queryClient = useQueryClient();
    return useMutation({
        mutationFn: shiftsService.start,
        onSuccess: () => queryClient.invalidateQueries({ queryKey: ['shifts'] }),
    });
}

export function useCloseShift() {
    const queryClient = useQueryClient();
    return useMutation({
        mutationFn: ({ id, endingCash }) => shiftsService.close(id, endingCash),
        onSuccess: () => queryClient.invalidateQueries({ queryKey: ['shifts'] }),
    });
}
