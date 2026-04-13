import { betterAuth } from 'better-auth';
import { drizzleAdapter } from 'better-auth/adapters/drizzle';
import { db } from '../db/index.js';

// Build trusted origins from environment
const baseUrl = process.env.BETTER_AUTH_URL || 'http://localhost:3001';
const corsOrigin = process.env.CORS_ORIGIN || 'http://localhost:5173';

const trustedOrigins = [
    baseUrl,
    corsOrigin,
    'http://localhost:3001',
    'http://localhost:8081',
];

// Add local network IPs if BETTER_AUTH_URL uses one
const ipMatch = baseUrl.match(/http:\/\/(\d+\.\d+\.\d+\.\d+)/);
if (ipMatch) {
    trustedOrigins.push(`http://${ipMatch[1]}:3001`);
    trustedOrigins.push(`http://${ipMatch[1]}:8081`);
}

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
});
