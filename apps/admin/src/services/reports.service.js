import { apiClient } from '../lib/api-client';

export const reportsService = {
    getDailySummary: (date, branchId) => {
        const params = new URLSearchParams();
        if (date) params.set('date', date);
        if (branchId) params.set('branchId', branchId);
        const qs = params.toString();
        return apiClient.get(`/reports/daily${qs ? `?${qs}` : ''}`);
    },
    getSummary: (branchId) => {
        const qs = branchId ? `?branchId=${branchId}` : '';
        return apiClient.get(`/reports/summary${qs}`);
    },
    getTopProducts: (limit = 10, branchId) => {
        const params = new URLSearchParams();
        params.set('limit', limit.toString());
        if (branchId) params.set('branchId', branchId);
        return apiClient.get(`/reports/top-products?${params}`);
    },
    getRevenueChart: (days = 7, branchId) => {
        const params = new URLSearchParams();
        params.set('days', days.toString());
        if (branchId) params.set('branchId', branchId);
        return apiClient.get(`/reports/revenue-chart?${params}`);
    },
    getCriticalStock: (branchId) => {
        const qs = branchId ? `?branchId=${branchId}` : '';
        return apiClient.get(`/reports/critical-stock${qs}`);
    },
};
