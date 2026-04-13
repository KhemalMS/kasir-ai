import { useQuery } from '@tanstack/react-query';
import { reportsService } from '../services/reports.service';

export function useDailySummary(date, branchId) {
    return useQuery({
        queryKey: ['reports', 'daily', date, branchId],
        queryFn: () => reportsService.getDailySummary(date, branchId),
    });
}

export function useReportSummary(branchId) {
    return useQuery({
        queryKey: ['reports', 'summary', branchId],
        queryFn: () => reportsService.getSummary(branchId),
    });
}

export function useTopProducts(limit = 10, branchId) {
    return useQuery({
        queryKey: ['reports', 'top-products', limit, branchId],
        queryFn: () => reportsService.getTopProducts(limit, branchId),
    });
}

export function useRevenueChart(days = 7, branchId) {
    return useQuery({
        queryKey: ['reports', 'revenue-chart', days, branchId],
        queryFn: () => reportsService.getRevenueChart(days, branchId),
    });
}

export function useCriticalStock(branchId) {
    return useQuery({
        queryKey: ['reports', 'critical-stock', branchId],
        queryFn: () => reportsService.getCriticalStock(branchId),
    });
}
