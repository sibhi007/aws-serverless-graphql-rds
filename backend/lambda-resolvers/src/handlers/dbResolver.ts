import { readFileSync } from 'fs';
import { join } from 'path';
import { SecretsManagerClient, GetSecretValueCommand } from '@aws-sdk/client-secrets-manager';
import { Client } from 'pg';

type DbEvent = { action: 'GET_ITEMS' } | { action: 'CREATE_ITEM'; name: string };

const secrets = new SecretsManagerClient({});
let creds: { username: string; password: string } | undefined;
let tableReady = false;

export function cleanName(input: unknown): string {
  const name = String(input ?? '').trim();
  if (name.length === 0 || name.length > 100) {
    throw new Error('name must be 1-100 characters');
  }
  return name;
}

async function connect(): Promise<Client> {
  if (!creds) {
    const out = await secrets.send(new GetSecretValueCommand({ SecretId: process.env.DB_SECRET_ARN }));
    creds = JSON.parse(out.SecretString ?? '{}');
  }

  const db = new Client({
    host: process.env.DB_HOST,
    port: 5432,
    user: creds!.username,
    password: creds!.password,
    database: process.env.DB_NAME,
    ssl: {
      ca: readFileSync(join(process.env.LAMBDA_TASK_ROOT ?? '.', 'certs/global-bundle.pem')),
      rejectUnauthorized: true,
    },
  });

  await db.connect();
  return db;
}

export const handler = async (event: DbEvent) => {
  const db = await connect();
  try {
    if (!tableReady) {
      await db.query(
        'CREATE TABLE IF NOT EXISTS items (id SERIAL PRIMARY KEY, name VARCHAR(100) NOT NULL, created_at TIMESTAMPTZ DEFAULT now())'
      );
      tableReady = true;
    }

    if (event.action === 'CREATE_ITEM') {
      const res = await db.query(
        'INSERT INTO items (name) VALUES ($1) RETURNING id, name, created_at',
        [cleanName(event.name)]
      );
      return res.rows[0];
    }

    const res = await db.query('SELECT id, name, created_at FROM items ORDER BY id DESC LIMIT 100');
    return res.rows;
  } finally {
    await db.end();
  }
};