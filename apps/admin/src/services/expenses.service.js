import { apiClient } from '../lib/api-client';

export const expensesService = {
    getAll: (filters = {}) => {
        const params = new URLSearchParams();
        if (filters.branchId) params.set('branchId', filters.branchId);
        if (filters.category) params.set('category', filters.category);
        if (filters.status) params.set('status', filters.status);
        if (filters.startDate) params.set('startDate', filters.startDate);
        if (filters.endDate) params.set('endDate', filters.endDate);
        const qs = params.toString();
        return apiClient.get(`/expenses${qs ? `?${qs}` : ''}`);
    },
    getById: (id) => apiClient.get(`/expenses/${id}`),
    create: (data) => apiClient.post('/expenses', data),
    update: (id, data) => apiClient.put(`/expenses/${id}`, data),
    approve: (id, status) => apiClient.put(`/expenses/${id}/approve`, { status }),
    delete: (id) => apiClient.delete(`/expenses/${id}`),
};
