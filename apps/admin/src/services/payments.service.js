import { apiClient } from '../lib/api-client';

export const paymentsService = {
    getAll: () => apiClient.get('/payments'),
    getByOrderId: (orderId) => apiClient.get(`/payments/${orderId}`),
};
