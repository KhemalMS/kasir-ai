import 'dotenv/config';
import { db } from '../db/index.js';
import { staff } from '../db/schema/index.js';
import bcrypt from 'bcryptjs';

async function seedPin() {
    try {
        console.log('Seeding PIN for staff...');
        const pin = '1234';
        const hashedPin = await bcrypt.hash(pin, 10);
        
        const result = await db.update(staff).set({
            pinCode: hashedPin,
            pinAttempts: 0,
            pinLockedUntil: null,
        });
        
        console.log(`Successfully updated ${result[0].affectedRows} staff member(s) with PIN ${pin}`);
        process.exit(0);
    } catch (error) {
        console.error('Failed to seed PIN:', error);
        process.exit(1);
    }
}

seedPin();
