import { db } from '../db/index.js';
import { orders } from '../db/schema/orders.js';
import { orderItems } from '../db/schema/orderItems.js';
import { products } from '../db/schema/products.js';
import { eq, and, desc, not, inArray, gte } from 'drizzle-orm';

export const kitchenService = {
    async getActiveTickets(status?: string) {
        // Only show orders from the last 24 hours
        const oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);

        const conditions = [
            not(eq(orders.status, 'Batal')),
            gte(orders.createdAt, oneDayAgo),
        ];
        if (status) {
            conditions.push(eq(orders.status, status));
        }

        const orderList = await db
            .select()
            .from(orders)
            .where(and(...conditions))
            .orderBy(desc(orders.createdAt))
            .limit(50);

        if (orderList.length === 0) return [];

        // Get items for all orders
        const orderIds = orderList.map(o => o.id);
        const allItems = await db
            .select({
                id: orderItems.id,
                orderId: orderItems.orderId,
                productId: orderItems.productId,
                quantity: orderItems.quantity,
                notes: orderItems.notes,
                productName: products.name,
                productCategory: products.categoryId,
            })
            .from(orderItems)
            .leftJoin(products, eq(orderItems.productId, products.id))
            .where(inArray(orderItems.orderId, orderIds));

        // Group items by orderId
        const itemsByOrder: Record<string, any[]> = {};
        for (const item of allItems) {
            if (!itemsByOrder[item.orderId]) itemsByOrder[item.orderId] = [];
            itemsByOrder[item.orderId].push({
                id: item.id,
                orderId: item.orderId,
                quantity: item.quantity,
                notes: item.notes,
                product: {
                    id: item.productId,
                    name: item.productName,
                },
            });
        }

        // Combine
        return orderList.map(order => ({
            ...order,
            items: itemsByOrder[order.id] || [],
        }));
    },

    async updateTicketStatus(orderId: string, status: string) {
        await db
            .update(orders)
            .set({ status, updatedAt: new Date() })
            .where(eq(orders.id, orderId));
        const [order] = await db.select().from(orders).where(eq(orders.id, orderId));
        return order;
    },
};
