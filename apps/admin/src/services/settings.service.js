import { apiClient } from '../lib/api-client';

export const settingsService = {
    // General settings
    getAll: () => apiClient.get('/settings'),
    getByGroup: (group) => apiClient.get(`/settings/group/${group}`),
    bulkUpdate: (settings) => apiClient.put('/settings', { settings }),

    // Payment methods
    getPaymentMethods: () => apiClient.get('/settings/payment-methods'),
    createPaymentMethod: (data) => apiClient.post('/settings/payment-methods', data),
    updatePaymentMethod: (id, data) => apiClient.put(`/settings/payment-methods/${id}`, data),
    deletePaymentMethod: (id) => apiClient.delete(`/settings/payment-methods/${id}`),

    // Taxes
    getTaxes: () => apiClient.get('/settings/taxes'),
    createTax: (data) => apiClient.post('/settings/taxes', data),
    updateTax: (id, data) => apiClient.put(`/settings/taxes/${id}`, data),
    deleteTax: (id) => apiClient.delete(`/settings/taxes/${id}`),
};
