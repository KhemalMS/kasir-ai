import { drizzle } from 'drizzle-orm/mysql2';
import mysql from 'mysql2/promise';
import 'dotenv/config';
import * as schema from './schema/index.js';

const pool = mysql.createPool({
    uri: process.env.DATABASE_URL!,
    connectionLimit: 20,
    waitForConnections: true,
    queueLimit: 100,
    enableKeepAlive: true,
    keepAliveInitialDelay: 0,
});

export const db = drizzle(pool, { schema, mode: 'default' });
export type Database = typeof db;
