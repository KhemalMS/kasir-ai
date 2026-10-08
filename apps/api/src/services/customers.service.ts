import { db } from '../db/index.js';
import { customers, orders } from '../db/schema/index.js';
import { eq, and, like, or, sql, desc } from 'drizzle-orm';
import { v4 as uuidv4 } from 'uuid';

interface CreateCustomerInput {
    name: string;
    phone?: string;
    email?: string;
    birthdate?: string;
}

interface UpdateCustomerInput {
    name?: string;
    phone?: string;
    email?: string;
    birthdate?: string;
}

function computeTier(points: number): string {
    if (points >= 5000) return 'Gold';
    if (points >= 1000) return 'Silver';
    return 'Bronze';
}

export const customersService = {
    async getAllCustomers(search?: string) {
        // Subquery: order count & total spent per customer
        const stats = db
            .select({
                customerId: orders.customerId,
                orderCount: sql<number>`COUNT(${orders.id})`.as('order_count'),
                totalSpent: sql<number>`COALESCE(SUM(${orders.totalAmount}), 0)`.as('total_spent'),
                lastOrderAt: sql<string>`MAX(${orders.createdAt})`.as('last_order_at'),
            })
            .from(orders)
            .where(eq(orders.status, 'Sukses'))
            .groupBy(orders.customerId)
            .as('stats');

        const query = db
            .select({
                id: customers.id,
                name: customers.name,
                phone: customers.phone,
                email: customers.email,
                birthdate: customers.birthdate,
                points: customers.points,
                tier: customers.tier,
                createdAt: customers.createdAt,
                orderCount: stats.orderCount,
                totalSpent: stats.totalSpent,
                lastOrderAt: stats.lastOrderAt,
            })
            .from(customers)
            .leftJoin(stats, eq(customers.id, stats.customerId))
            .orderBy(desc(customers.createdAt));

        const results = await (search
            ? query.where(or(
                like(customers.name, `%${search}%`),
                like(customers.phone, `%${search}%`),
              ))
            : query);

        return results.map(r => ({
            ...r,
            orderCount: Number(r.orderCount ?? 0),
            totalSpent: Number(r.totalSpent ?? 0),
        }));
    },

    async getCustomerById(id: string) {
        const [customer] = await db
            .select()
            .from(customers)
            .where(eq(customers.id, id));

        if (!customer) return null;

        const recentOrders = await db
            .select({
                id: orders.id,
                orderNumber: orders.orderNumber,
                totalAmount: orders.totalAmount,
                status: orders.status,
                createdAt: orders.createdAt,
            })
            .from(orders)
            .where(and(eq(orders.customerId, id), eq(orders.status, 'Sukses')))
            .orderBy(desc(orders.createdAt))
            .limit(10);

        return { ...customer, recentOrders };
    },

    async createCustomer(data: CreateCustomerInput) {
        const id = uuidv4();
        await db.insert(customers).values({
            id,
            name: data.name,
            phone: data.phone,
            email: data.email,
            birthdate: data.birthdate as any,
            points: 0,
            tier: 'Bronze',
        });
        const [customer] = await db.select().from(customers).where(eq(customers.id, id));
        return customer;
    },

    async updateCustomer(id: string, data: UpdateCustomerInput) {
        await db.update(customers).set({
            ...data,
            birthdate: data.birthdate as any,
            updatedAt: new Date(),
        }).where(eq(customers.id, id));
        const [customer] = await db.select().from(customers).where(eq(customers.id, id));
        return customer;
    },

    async addPoints(customerId: string, totalAmount: number) {
        const newPoints = Math.floor(totalAmount / 10000);
        if (newPoints <= 0) return;

        // Fetch current points and add new ones atomically
        const [current] = await db
            .select({ points: customers.points })
            .from(customers)
            .where(eq(customers.id, customerId));

        if (!current) return;

        const updatedPoints = current.points + newPoints;
        const newTier = computeTier(updatedPoints);

        await db.update(customers).set({
            points: updatedPoints,
            tier: newTier,
            updatedAt: new Date(),
        }).where(eq(customers.id, customerId));
    },
};
