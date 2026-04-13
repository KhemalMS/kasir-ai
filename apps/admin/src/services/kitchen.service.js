import { apiClient } from '../lib/api-client';

export const kitchenService = {
    getTickets: (status) => {
        const qs = status ? `?status=${status}` : '';
        return apiClient.get(`/kitchen/tickets${qs}`);
    },
    updateTicketStatus: (orderId, status) => apiClient.put(`/kitchen/tickets/${orderId}/status`, { status }),
};
