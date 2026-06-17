import { useQuery } from '@tanstack/react-query';
import { reportsService } from '../services/reports.service';

const STALE = 60_000; // 1 minute

export function useDailySummary(date, branchId) {
    return useQuery({
        queryKey: ['reports', 'daily', date, branchId],
        queryFn: () => reportsService.getDailySummary(date, branchId),
        staleTime: STALE,
    });
}

export function useReportSummary(branchId) {
    return useQuery({
        queryKey: ['reports', 'summary', branchId],
        queryFn: () => reportsService.getSummary(branchId),
        staleTime: STALE,
    });
}

export function useTopProducts(limit = 10, branchId) {
    return useQuery({
        queryKey: ['reports', 'top-products', limit, branchId],
        queryFn: () => reportsService.getTopProducts(limit, branchId),
        staleTime: STALE,
    });
}

export function useRevenueChart(days = 7, branchId) {
    return useQuery({
        queryKey: ['reports', 'revenue-chart', days, branchId],
        queryFn: () => reportsService.getRevenueChart(days, branchId),
        staleTime: STALE,
    });
}

export function useCriticalStock(branchId) {
    return useQuery({
        queryKey: ['reports', 'critical-stock', branchId],
        queryFn: () => reportsService.getCriticalStock(branchId),
        staleTime: STALE,
    });
}

export function useProfitLoss(start, end, branchId) {
    return useQuery({
        queryKey: ['reports', 'profit-loss', start, end, branchId],
        queryFn: () => reportsService.getProfitLoss(start, end, branchId),
        staleTime: STALE,
        enabled: !!start && !!end,
    });
}

export function useCashFlow(start, end, branchId) {
    return useQuery({
        queryKey: ['reports', 'cash-flow', start, end, branchId],
        queryFn: () => reportsService.getCashFlow(start, end, branchId),
        staleTime: STALE,
        enabled: !!start && !!end,
    });
}

export function useExpenseSummary(start, end, branchId) {
    return useQuery({
        queryKey: ['reports', 'expense-summary', start, end, branchId],
        queryFn: () => reportsService.getExpenseSummary(start, end, branchId),
        staleTime: STALE,
        enabled: !!start && !!end,
    });
}

export function useExpenseReport(start, end, branchId) {
    return useQuery({
        queryKey: ['reports', 'expense-report', start, end, branchId],
        queryFn: () => reportsService.getExpenseReport(start, end, branchId),
        staleTime: STALE,
        enabled: !!start && !!end,
    });
}

export function useDailySalesReport(start, end, branchId) {
    return useQuery({
        queryKey: ['reports', 'daily-sales', start, end, branchId],
        queryFn: () => reportsService.getDailySales(start, end, branchId),
        staleTime: STALE,
        enabled: !!start && !!end,
    });
}
