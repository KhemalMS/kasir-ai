import { apiClient } from '../lib/api-client';

export const shiftsService = {
    getAll: (filters = {}) => {
        const params = new URLSearchParams();
        if (filters.branchId) params.set('branchId', filters.branchId);
        if (filters.staffId) params.set('staffId', filters.staffId);
        const qs = params.toString();
        return apiClient.get(`/shifts${qs ? `?${qs}` : ''}`);
    },
    getCurrent: (staffId) => apiClient.get(`/shifts/current?staffId=${staffId}`),
    start: (data) => apiClient.post('/shifts/start', data),
    close: (id, endingCash) => apiClient.post(`/shifts/${id}/close`, { endingCash }),
    getSummary: (id) => apiClient.get(`/shifts/${id}/summary`),
};
