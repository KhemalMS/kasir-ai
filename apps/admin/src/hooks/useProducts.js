import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { productsService } from '../services/products.service';

export function useProducts(filters) {
    return useQuery({
        queryKey: ['products', filters],
        queryFn: () => productsService.getAll(filters),
    });
}

export function useProduct(id) {
    return useQuery({
        queryKey: ['products', id],
        queryFn: () => productsService.getById(id),
        enabled: !!id,
    });
}

export function useCreateProduct() {
    const queryClient = useQueryClient();
    return useMutation({
        mutationFn: productsService.create,
        onSuccess: () => queryClient.invalidateQueries({ queryKey: ['products'] }),
    });
}

export function useUpdateProduct() {
    const queryClient = useQueryClient();
    return useMutation({
        mutationFn: ({ id, data }) => productsService.update(id, data),
        onSuccess: () => queryClient.invalidateQueries({ queryKey: ['products'] }),
    });
}

export function useDeleteProduct() {
    const queryClient = useQueryClient();
    return useMutation({
        mutationFn: productsService.delete,
        onSuccess: () => queryClient.invalidateQueries({ queryKey: ['products'] }),
    });
}

export function useAddVariant() {
    const queryClient = useQueryClient();
    return useMutation({
        mutationFn: ({ productId, data }) => productsService.addVariant(productId, data),
        onSuccess: () => queryClient.invalidateQueries({ queryKey: ['products'] }),
    });
}

export function useDeleteVariant() {
    const queryClient = useQueryClient();
    return useMutation({
        mutationFn: ({ productId, variantId }) => productsService.deleteVariant(productId, variantId),
        onSuccess: () => queryClient.invalidateQueries({ queryKey: ['products'] }),
    });
}

export function useAddIngredient() {
    const queryClient = useQueryClient();
    return useMutation({
        mutationFn: ({ productId, data }) => productsService.addIngredient(productId, data),
        onSuccess: () => queryClient.invalidateQueries({ queryKey: ['products'] }),
    });
}

export function useUpdateBranchAvailability() {
    const queryClient = useQueryClient();
    return useMutation({
        mutationFn: ({ productId, branches }) => productsService.updateBranchAvailability(productId, branches),
        onSuccess: () => queryClient.invalidateQueries({ queryKey: ['products'] }),
    });
}
