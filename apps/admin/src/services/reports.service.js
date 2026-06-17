import { apiClient } from '../lib/api-client';

const buildQs = (params) => {
    const p = new URLSearchParams();
    Object.entries(params).forEach(([k, v]) => { if (v != null && v !== '') p.set(k, v); });
    return p.toString() ? `?${p.toString()}` : '';
};

export const reportsService = {
    getDailySummary: (date, branchId) =>
        apiClient.get(`/reports/daily${buildQs({ date, branchId })}`),

    getSummary: (branchId) =>
        apiClient.get(`/reports/summary${buildQs({ branchId })}`),

    getTopProducts: (limit = 10, branchId) =>
        apiClient.get(`/reports/top-products${buildQs({ limit, branchId })}`),

    getRevenueChart: (days = 7, branchId) =>
        apiClient.get(`/reports/revenue-chart${buildQs({ days, branchId })}`),

    getCriticalStock: (branchId) =>
        apiClient.get(`/reports/critical-stock${buildQs({ branchId })}`),

    getProfitLoss: (start, end, branchId) =>
        apiClient.get(`/reports/profit-loss${buildQs({ start, end, branchId })}`),

    getCashFlow: (start, end, branchId) =>
        apiClient.get(`/reports/cash-flow${buildQs({ start, end, branchId })}`),

    getExpenseSummary: (start, end, branchId) =>
        apiClient.get(`/reports/expense-summary${buildQs({ start, end, branchId })}`),

    getExpenseReport: (start, end, branchId) =>
        apiClient.get(`/reports/expense-report${buildQs({ start, end, branchId })}`),

    getDailySales: (start, end, branchId) =>
        apiClient.get(`/reports/daily-sales${buildQs({ start, end, branchId })}`),

    getShiftReport: (start, end, branchId) =>
        apiClient.get(`/reports/shift-report${buildQs({ start, end, branchId })}`),
};
