import { apiClient } from '../lib/api-client';

export const inventoryService = {
    getAll: (filters = {}) => {
        const params = new URLSearchParams();
        if (filters.branchId) params.set('branchId', filters.branchId);
        if (filters.categoryId) params.set('categoryId', filters.categoryId);
        if (filters.search) params.set('search', filters.search);
        const qs = params.toString();
        return apiClient.get(`/inventory${qs ? `?${qs}` : ''}`);
    },
    getById: (id) => apiClient.get(`/inventory/${id}`),
    getAlerts: () => apiClient.get('/inventory/alerts'),
    create: (data) => apiClient.post('/inventory', data),
    update: (id, data) => apiClient.put(`/inventory/${id}`, data),
    delete: (id) => apiClient.delete(`/inventory/${id}`),
};
