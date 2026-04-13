import { db } from '../db/index.js';
import { orders } from '../db/schema/orders.js';
import { orderItems } from '../db/schema/orderItems.js';
import { payments } from '../db/schema/payments.js';
import { products } from '../db/schema/products.js';
import { eq, and, desc, between } from 'drizzle-orm';
import { AppError } from '../middleware/errorHandler.js';
import { inventoryService } from './inventory.service.js';
import { v4 as uuidv4 } from 'uuid';

interface CreateOrderInput {
    orderNumber: string;
    staffId: string;
    branchId: string;
    shiftId?: string;
    orderType: string;
    tableNumber?: string;
    subtotal: number;
    taxAmount: number;
    serviceAmount: number;
    discountAmount?: number;
    totalAmount: number;
    notes?: string;
    items: {
        productId: string;
        variantId?: string;
        quantity: number;
        price?: number;
        priceAtOrder?: number;
        variantPriceAtOrder?: number;
        notes?: string;
    }[];
    paymentMethods: {
        method: string;
        amount: number;
        reference?: string;
    }[];
}

export const ordersService = {
    async findAll(filters?: {
        branchId?: string;
        status?: string;
        shiftId?: string;
        startDate?: Date;
        endDate?: Date;
    }) {
        const conditions = [];
        if (filters?.branchId) conditions.push(eq(orders.branchId, filters.branchId));
        if (filters?.status) conditions.push(eq(orders.status, filters.status));
        if (filters?.shiftId) conditions.push(eq(orders.shiftId, filters.shiftId));
        if (filters?.startDate && filters?.endDate) {
            conditions.push(between(orders.createdAt, filters.startDate, filters.endDate));
        }

        const query = conditions.length > 0 ? and(...conditions) : undefined;
        return db
            .select()
            .from(orders)
            .where(query)
            .orderBy(desc(orders.createdAt));
    },

    async findById(id: string) {
        const [order] = await db
            .select()
            .from(orders)
            .where(eq(orders.id, id));
        if (!order) return null;

        const rawItems = await db
            .select({
                id: orderItems.id,
                orderId: orderItems.orderId,
                productId: orderItems.productId,
                variantId: orderItems.variantId,
                quantity: orderItems.quantity,
                priceAtOrder: orderItems.priceAtOrder,
                variantPriceAtOrder: orderItems.variantPriceAtOrder,
                notes: orderItems.notes,
                createdAt: orderItems.createdAt,
                productName: products.name,
            })
            .from(orderItems)
            .leftJoin(products, eq(orderItems.productId, products.id))
            .where(eq(orderItems.orderId, id));

        const orderPayments = await db
            .select()
            .from(payments)
            .where(eq(payments.orderId, id));

        return { ...order, items: rawItems, payments: orderPayments };
    },

    async create(input: CreateOrderInput) {
        return db.transaction(async (tx) => {
            // 1. Create order
            const orderId = uuidv4();
            await tx
                .insert(orders)
                .values({
                    id: orderId,
                    orderNumber: input.orderNumber,
                    staffId: input.staffId,
                    branchId: input.branchId,
                    shiftId: input.shiftId,
                    orderType: input.orderType,
                    tableNumber: input.tableNumber,
                    subtotal: input.subtotal,
                    taxAmount: input.taxAmount,
                    serviceAmount: input.serviceAmount,
                    discountAmount: input.discountAmount || 0,
                    totalAmount: input.totalAmount,
                    notes: input.notes,
                    status: 'Sukses',
                });

            // 2. Create order items
            if (input.items.length > 0) {
                await tx.insert(orderItems).values(
                    input.items.map((item) => ({
                        id: uuidv4(),
                        orderId,
                        productId: item.productId,
                        variantId: item.variantId,
                        quantity: item.quantity,
                        priceAtOrder: item.priceAtOrder || (item as any).price || 0,
                        variantPriceAtOrder: item.variantPriceAtOrder || 0,
                        notes: item.notes,
                    }))
                );
            }

            // 3. Create payments
            if (input.paymentMethods.length > 0) {
                await tx.insert(payments).values(
                    input.paymentMethods.map((pm) => ({
                        id: uuidv4(),
                        orderId,
                        method: pm.method,
                        amount: pm.amount,
                        reference: pm.reference,
                    }))
                );
            }

            const [order] = await tx.select().from(orders).where(eq(orders.id, orderId));

            // 4. Auto-deduct raw materials based on recipes
            try {
                await inventoryService.deductForOrder(
                    input.items.map(i => ({ productId: i.productId, variantId: (i as any).variantId || null, quantity: i.quantity })),
                    input.staffId
                );
            } catch (e) {
                console.warn('Inventory deduction warning:', e);
            }

            return order;
        });
    },

    async updateStatus(id: string, status: string) {
        await db
            .update(orders)
            .set({ status, updatedAt: new Date() })
            .where(eq(orders.id, id));
        const [order] = await db.select().from(orders).where(eq(orders.id, id));
        if (!order) throw new AppError('Order not found', 404);
        return order;
    },

    async getSavedOrders(shiftId: string) {
        return db
            .select()
            .from(orders)
            .where(and(eq(orders.shiftId, shiftId), eq(orders.status, 'Pending')))
            .orderBy(desc(orders.createdAt));
    },

    async delete(id: string) {
        const [order] = await db.select().from(orders).where(eq(orders.id, id));
        if (!order) throw new AppError('Order not found', 404);

        await db.transaction(async (tx) => {
            // Delete related records first (order_items, payments)
            await tx.delete(orderItems).where(eq(orderItems.orderId, id));
            await tx.delete(payments).where(eq(payments.orderId, id));
            await tx.delete(orders).where(eq(orders.id, id));
        });

        return order;
    },
};
