import 'dotenv/config';

import { neon, neonConfig } from '@neondatabase/serverless';
import { drizzle } from 'drizzle-orm/neon-http';

// Configuration for Neon Local when running in development with Docker
if (process.env.NODE_ENV === 'development' && process.env.DATABASE_URL.includes('neon-local')) {
  // Configure for Neon Local proxy
  neonConfig.fetchEndpoint = 'http://neon-local:5432/sql';
  neonConfig.useSecureWebSocket = false;
  neonConfig.poolQueryViaFetch = true;
}

const sql = neon(process.env.DATABASE_URL);

const db = drizzle(sql);

export { sql, db };
