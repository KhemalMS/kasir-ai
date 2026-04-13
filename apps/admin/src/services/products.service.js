import { apiClient } from '../lib/api-client';

export const productsService = {
    getAll: (filters = {}) => {
        const params = new URLSearchParams();
        if (filters.categoryId) params.set('categoryId', filters.categoryId);
        if (filters.search) params.set('search', filters.search);
        const qs = params.toString();
        return apiClient.get(`/products${qs ? `?${qs}` : ''}`);
    },
    getById: (id) => apiClient.get(`/products/${id}`),
    create: (data) => apiClient.post('/products', data),
    update: (id, data) => apiClient.put(`/products/${id}`, data),
    delete: (id) => apiClient.delete(`/products/${id}`),

    // Variants
    addVariant: (productId, data) => apiClient.post(`/products/${productId}/variants`, data),
    updateVariant: (productId, variantId, data) => apiClient.put(`/products/${productId}/variants/${variantId}`, data),
    deleteVariant: (productId, variantId) => apiClient.delete(`/products/${productId}/variants/${variantId}`),

    // Ingredients
    addIngredient: (productId, data) => apiClient.post(`/products/${productId}/ingredients`, data),
    removeIngredient: (productId, ingredientId) => apiClient.delete(`/products/${productId}/ingredients/${ingredientId}`),

    // Branch availability
    updateBranchAvailability: (productId, branches) => apiClient.put(`/products/${productId}/branches`, { branches }),

    // Image upload
    uploadImage: async (file) => {
        const formData = new FormData();
        formData.append('image', file);
        return apiClient.upload('/upload', formData);
    },
};
