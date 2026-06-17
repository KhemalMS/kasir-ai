import 'dotenv/config';
import { db } from './db/index.js';
import { categories } from './db/schema/categories.js';
import { products } from './db/schema/products.js';
import { settings } from './db/schema/settings.js';
import { branches } from './db/schema/branches.js';
import { staff } from './db/schema/staff.js';
import { user, account } from './db/schema/auth.js';
import { v4 as uuidv4 } from 'uuid';
import { eq } from 'drizzle-orm';
import crypto from 'crypto';

// ── Password hashing compatible with better-auth ──────────────────
// better-auth uses scrypt by default. For seed we use a raw bcrypt-like
// approach via the built-in Node.js crypto scrypt.
async function hashPassword(password: string): Promise<string> {
    const salt = crypto.randomBytes(16).toString('hex');
    const hash = await new Promise<string>((resolve, reject) => {
        crypto.scrypt(password, salt, 64, (err, derivedKey) => {
            if (err) reject(err);
            else resolve(derivedKey.toString('hex'));
        });
    });
    return `${salt}:${hash}`;
}

async function seed() {
    console.log('🌱 Kasir-AI Database Seeder\n');

    // ── 1. Default Branch ──────────────────────────────────────────
    console.log('🏪 [1/4] Seeding branches...');
    let branchId: string;
    const existingBranches = await db.select().from(branches);
    if (existingBranches.length === 0) {
        await db.insert(branches).values({
            name: 'Cabang Utama',
            locationCode: 'PUSAT',
            address: 'Jl. Contoh No. 123',
            status: 'Buka',
        });
        // Re-fetch to get the auto-generated ID
        const [newBranch] = await db.select().from(branches);
        branchId = newBranch.id;
        console.log('   ✅ Cabang Utama dibuat');
    } else {
        branchId = existingBranches[0].id;
        console.log(`   ⏭️  Cabang sudah ada: ${existingBranches[0].name}`);
    }

    // ── 2. Default Users & Staff ───────────────────────────────────
    console.log('\n👥 [2/4] Seeding users & staff...');

    const defaultUsers = [
        { email: 'admin@kasir.ai',  name: 'Admin',       role: 'admin',  staffRole: 'Admin',  password: 'admin123' },
        { email: 'kasir@kasir.ai',  name: 'Kasir Staff', role: 'kasir',  staffRole: 'Kasir',  password: 'kasir123' },
        { email: 'dapur@kasir.ai',  name: 'Dapur Staff', role: 'dapur',  staffRole: 'Dapur',  password: 'dapur123' },
    ];

    for (const u of defaultUsers) {
        const existing = await db.select().from(user).where(eq(user.email, u.email));
        if (existing.length > 0) {
            console.log(`   ⏭️  User ${u.email} sudah ada, dilewati`);
            continue;
        }

        const userId = uuidv4();
        const hashedPw = await hashPassword(u.password);

        // Insert user
        await db.insert(user).values({
            id: userId,
            name: u.name,
            email: u.email,
            emailVerified: true,
            role: u.role,
        });

        // Insert account (email+password provider)
        await db.insert(account).values({
            id: uuidv4(),
            accountId: userId,
            providerId: 'credential',
            userId,
            password: hashedPw,
            createdAt: new Date(),
            updatedAt: new Date(),
        });

        // Insert staff linked to user
        const existingStaff = await db.select().from(staff).where(eq(staff.email, u.email));
        if (existingStaff.length === 0) {
            await db.insert(staff).values({
                id: uuidv4(),
                userId,
                name: u.name,
                email: u.email,
                role: u.staffRole,
                branchId,
                status: 'Aktif',
            });
        }

        console.log(`   ✅ ${u.email} (${u.role}) — password: ${u.password}`);
    }

    // ── 3. Categories & Products ───────────────────────────────────
    console.log('\n📦 [3/4] Seeding products...');

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
    console.log(`   ✅ Kategori: ${cats.map(c => c.name).join(', ')}`);

    const existingProducts = await db.select().from(products);
    if (existingProducts.length === 0) {
        const catM = catMap['Makanan'] || cats[0].id;
        const catD = catMap['Minuman'] || cats[0].id;
        const catS = catMap['Snack'] || cats[0].id;

        const productData = [
            { name: 'Nasi Goreng Spesial',  price: 25000, categoryId: catM },
            { name: 'Mie Goreng',           price: 20000, categoryId: catM },
            { name: 'Ayam Bakar',           price: 30000, categoryId: catM },
            { name: 'Nasi Ayam Geprek',     price: 22000, categoryId: catM },
            { name: 'Sate Ayam 10 Tusuk',   price: 28000, categoryId: catM },
            { name: 'Es Teh Manis',         price: 5000,  categoryId: catD },
            { name: 'Es Jeruk',             price: 8000,  categoryId: catD },
            { name: 'Kopi Susu',            price: 15000, categoryId: catD },
            { name: 'Air Mineral',          price: 4000,  categoryId: catD },
            { name: 'Jus Alpukat',          price: 12000, categoryId: catD },
            { name: 'Kentang Goreng',       price: 15000, categoryId: catS },
            { name: 'Pisang Goreng',        price: 10000, categoryId: catS },
            { name: 'Tahu Crispy',          price: 8000,  categoryId: catS },
            { name: 'Roti Bakar',           price: 12000, categoryId: catS },
        ];

        await db.insert(products).values(
            productData.map(p => ({ ...p, id: uuidv4(), isActive: true }))
        );
        console.log(`   ✅ ${productData.length} produk ditambahkan`);
    } else {
        console.log(`   ⏭️  ${existingProducts.length} produk sudah ada, dilewati`);
    }

    // ── 4. Store Settings ──────────────────────────────────────────
    console.log('\n⚙️  [4/4] Seeding pengaturan toko...');
    const storeDefaults = [
        { key: 'store_name',    value: 'Kasir-AI',          group: 'store' },
        { key: 'store_address', value: 'Jl. Contoh No. 123', group: 'store' },
        { key: 'store_phone',   value: '021-1234567',        group: 'store' },
        { key: 'store_website', value: '',                   group: 'store' },
    ];
    for (const item of storeDefaults) {
        const existing = await db.select().from(settings).where(eq(settings.key, item.key));
        if (existing.length === 0) {
            await db.insert(settings).values({ ...item, id: uuidv4() });
            console.log(`   ✅ ${item.key} = "${item.value}"`);
        } else {
            console.log(`   ⏭️  ${item.key} sudah ada, dilewati`);
        }
    }

    console.log('\n🎉 Seed selesai!');
    console.log('\n📋 Akun default yang tersedia:');
    console.log('   admin@kasir.ai   → password: admin123');
    console.log('   kasir@kasir.ai   → password: kasir123');
    console.log('   dapur@kasir.ai   → password: dapur123');
    console.log('\n⚠️  Ganti password default setelah login pertama!\n');
    process.exit(0);
}

seed().catch(err => { console.error('❌ Error:', err); process.exit(1); });
