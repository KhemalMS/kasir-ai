/**
 * Reset passwords using @noble/hashes/scrypt — EXACTLY the same as better-auth uses.
 * better-auth password format: hex_salt:hex_hash
 * Parameters: N=16384, r=16, p=1, dkLen=64
 */
import 'dotenv/config';
import { db } from './db/index.js';
import { account } from './db/schema/auth.js';
import { eq } from 'drizzle-orm';
import { scryptAsync } from '@noble/hashes/scrypt.js';

// Hex encode helper (same as better-auth uses)
function hexEncode(bytes: Uint8Array): string {
    return Array.from(bytes).map(b => b.toString(16).padStart(2, '0')).join('');
}

// Exact same config as better-auth's @better-auth/utils/password.mjs
const SCRYPT_CONFIG = { N: 16384, r: 16, p: 1, dkLen: 64 };

async function hashPasswordLikeBetterAuth(password: string): Promise<string> {
    const saltBytes = new Uint8Array(16);
    // Use Node.js crypto.getRandomValues equivalent
    for (let i = 0; i < 16; i++) saltBytes[i] = Math.floor(Math.random() * 256);
    const salt = hexEncode(saltBytes);
    const key = await scryptAsync(password.normalize('NFKC'), salt, {
        N: SCRYPT_CONFIG.N,
        r: SCRYPT_CONFIG.r,
        p: SCRYPT_CONFIG.p,
        dkLen: SCRYPT_CONFIG.dkLen,
        maxmem: 128 * SCRYPT_CONFIG.N * SCRYPT_CONFIG.r * 2,
    });
    return `${salt}:${hexEncode(key)}`;
}

async function resetPasswords() {
    console.log('🔑 Kasir-AI Password Reset — Using better-auth compatible scrypt\n');

    const resetList = [
        { userId: 'MwxfAu9d0zL5TiLh5Zdh1gK1sjxtVWVo', email: 'admin@kasir.ai',      password: 'admin123' },
        { userId: 'y2jKdsFcuUQ0vtTIEehgwLQnTPHYhz9z', email: 'dapur@kasir.ai',      password: 'dapur123' },
        { userId: 'wb4y4RDwUudZpmffi0NXB0Pg7VUKwtMJ', email: 'kasir@kasir-ai.com',  password: 'kasir123' },
    ];

    for (const entry of resetList) {
        const hashedPw = await hashPasswordLikeBetterAuth(entry.password);
        await db
            .update(account)
            .set({ password: hashedPw, updatedAt: new Date() })
            .where(eq(account.userId, entry.userId));
        console.log(`✅ ${entry.email} → password direset ke '${entry.password}'`);
    }

    console.log('\n🎉 Selesai! Login dengan:');
    console.log('   admin@kasir.ai       → admin123');
    console.log('   kasir@kasir-ai.com   → kasir123');
    console.log('   dapur@kasir.ai       → dapur123');
    process.exit(0);
}

resetPasswords().catch((err) => {
    console.error('❌ Error:', err);
    process.exit(1);
});
