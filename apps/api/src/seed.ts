import 'dotenv/config';
import { db } from './db/index.js';
import { categories } from './db/schema/categories.js';
import { products } from './db/schema/products.js';
import { v4 as uuidv4 } from 'uuid';

async function seed() {
    console.log('🌱 Seeding products...\n');

    // Delete existing products (fresh start)
    await db.delete(products);
    console.log('🗑️  Cleared existing products');

    // Get or create categories
    let cats = await db.select().from(categories);
    if (cats.length === 0) {
        await db.insert(categories).values([
            { id: uuidv4(), name: 'Makanan' },
            { id: uuidv4(), name: 'Minuman' },
            { id: uuidv4(), name: 'Snack' },
        ]);
        cats = await db.select().from(categories);
    }

    const catMap: Record<string, string> = {};
    for (const c of cats) catMap[c.name] = c.id;
    console.log(`✅ Categories: ${cats.map(c => c.name).join(', ')}`);

    const catM = catMap['Makanan'] || cats[0].id;
    const catD = catMap['Minuman'] || cats[0].id;
    const catS = catMap['Snack'] || cats[0].id;

    const productData = [
        { name: 'Nasi Goreng Spesial', price: 25000, categoryId: catM },
        { name: 'Mie Goreng', price: 20000, categoryId: catM },
        { name: 'Ayam Bakar', price: 30000, categoryId: catM },
        { name: 'Nasi Ayam Geprek', price: 22000, categoryId: catM },
        { name: 'Sate Ayam 10 Tusuk', price: 28000, categoryId: catM },
        { name: 'Es Teh Manis', price: 5000, categoryId: catD },
        { name: 'Es Jeruk', price: 8000, categoryId: catD },
        { name: 'Kopi Susu', price: 15000, categoryId: catD },
        { name: 'Air Mineral', price: 4000, categoryId: catD },
        { name: 'Jus Alpukat', price: 12000, categoryId: catD },
        { name: 'Kentang Goreng', price: 15000, categoryId: catS },
        { name: 'Pisang Goreng', price: 10000, categoryId: catS },
        { name: 'Tahu Crispy', price: 8000, categoryId: catS },
        { name: 'Roti Bakar', price: 12000, categoryId: catS },
    ];

    await db.insert(products).values(
        productData.map(p => ({ ...p, id: uuidv4(), isActive: true }))
    );

    console.log(`✅ Products: ${productData.length} items added\n`);
    for (const p of productData) {
        console.log(`   ${p.name.padEnd(22)} Rp ${p.price.toLocaleString('id-ID')}`);
    }
    console.log('\n🎉 Seed complete!');
    process.exit(0);
}

seed().catch(err => { console.error('❌ Error:', err); process.exit(1); });
