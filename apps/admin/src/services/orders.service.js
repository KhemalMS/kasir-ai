import { apiClient } from '../lib/api-client';

export const ordersService = {
    getAll: (filters = {}) => {
        const params = new URLSearchParams();
        if (filters.branchId) params.set('branchId', filters.branchId);
        if (filters.status) params.set('status', filters.status);
        if (filters.startDate) params.set('startDate', filters.startDate);
        if (filters.endDate) params.set('endDate', filters.endDate);
        const qs = params.toString();
        return apiClient.get(`/orders${qs ? `?${qs}` : ''}`);
    },
    getById: (id) => apiClient.get(`/orders/${id}`),
    getSaved: (shiftId) => apiClient.get(`/orders/saved?shiftId=${shiftId}`),
    create: (data) => apiClient.post('/orders', data),
    updateStatus: (id, status) => apiClient.put(`/orders/${id}/status`, { status }),
};
