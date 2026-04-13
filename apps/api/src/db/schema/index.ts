// Auth schemas (Better-Auth)
export { user, session, account, verification } from './auth';

// Table schemas
export { branches } from './branches';
export { categories } from './categories';
export { products } from './products';
export { productVariants } from './productVariants';
export { productBranches } from './productBranches';
export { productIngredients } from './productIngredients';
export { inventory } from './inventory';
export { staff } from './staff';
export { shifts } from './shifts';
export { orders } from './orders';
export { orderItems } from './orderItems';
export { payments } from './payments';
export { expenses } from './expenses';
export { settings } from './settings';
export { paymentMethods } from './paymentMethods';
export { taxes } from './taxes';
export { stockAdjustments } from './stockAdjustments';

// Relations
export {
    branchesRelations,
    categoriesRelations,
    productsRelations,
    productVariantsRelations,
    productBranchesRelations,
    inventoryRelations,
    productIngredientsRelations,
    staffRelations,
    shiftsRelations,
    ordersRelations,
    orderItemsRelations,
    paymentsRelations,
    expensesRelations,
    stockAdjustmentsRelations,
} from './relations';
