import { apiClient } from '../lib/api-client';

export const branchesService = {
    getAll: () => apiClient.get('/branches'),
    getById: (id) => apiClient.get(`/branches/${id}`),
    create: (data) => apiClient.post('/branches', data),
    update: (id, data) => apiClient.put(`/branches/${id}`, data),
    delete: (id) => apiClient.delete(`/branches/${id}`),
};
