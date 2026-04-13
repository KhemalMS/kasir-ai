import { apiClient } from '../lib/api-client';

export const staffService = {
    getAll: (filters = {}) => {
        const params = new URLSearchParams();
        if (filters.branchId) params.set('branchId', filters.branchId);
        if (filters.role) params.set('role', filters.role);
        if (filters.search) params.set('search', filters.search);
        const qs = params.toString();
        return apiClient.get(`/staff${qs ? `?${qs}` : ''}`);
    },
    getById: (id) => apiClient.get(`/staff/${id}`),
    create: (data) => apiClient.post('/staff', data),
    update: (id, data) => apiClient.put(`/staff/${id}`, data),
    delete: (id) => apiClient.delete(`/staff/${id}`),
};
