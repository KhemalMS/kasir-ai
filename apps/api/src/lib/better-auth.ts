import { betterAuth } from 'better-auth';
import { drizzleAdapter } from 'better-auth/adapters/drizzle';
import { admin } from 'better-auth/plugins';
import { db } from '../db/index.js';

// Build trusted origins from environment
const baseUrl = process.env.BETTER_AUTH_URL || 'http://localhost:3001';
const corsOrigin = process.env.CORS_ORIGIN || 'http://localhost:8081';

// Use a function to check all local network origins dynamically
function buildTrustedOrigins(): string[] {
    const origins = new Set<string>([
        baseUrl,
        corsOrigin,
        'http://localhost:3001',
        'http://localhost:5173',
        'http://localhost:8081',
    ]);
    // Also add the current BETTER_AUTH_URL IP explicitly (written by start.bat)
    const ipMatch = baseUrl.match(/http:\/\/(\d+\.\d+\.\d+\.\d+)/);
    if (ipMatch) {
        origins.add(`http://${ipMatch[1]}:3001`);
        origins.add(`http://${ipMatch[1]}:8081`);
        origins.add(`http://${ipMatch[1]}:5173`);
    }
    return Array.from(origins);
}

const trustedOrigins = (_req?: Request) => {
    // Returns a function that also accepts origins matching local IP ranges
    const fixed = buildTrustedOrigins();
    return fixed;
};

export const auth = betterAuth({
    database: drizzleAdapter(db, {
        provider: 'mysql',
    }),
    emailAndPassword: {
        enabled: true,
    },
    user: {
        additionalFields: {
            role: {
                type: 'string',
                defaultValue: 'kasir',
                input: false,
            },
        },
    },
    session: {
        expiresIn: 60 * 60 * 24 * 7, // 7 days
        updateAge: 60 * 60 * 24, // 1 day
    },
    trustedOrigins,
    advanced: {
        // Required for Android native HTTP client (no Origin header)
        // Android apps don't send Origin headers like browsers do
        disableCSRFCheck: true,
    },
    plugins: [
        admin()
    ],

});
