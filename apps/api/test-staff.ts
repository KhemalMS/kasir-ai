import { staffService } from './src/services/staff.service.js';
staffService.findAll().then(console.log).catch(console.error).finally(() => process.exit(0));
