import { AppDataSource } from './data-source';

async function migrate(): Promise<void> {
  await AppDataSource.initialize();

  try {
    const migrations = await AppDataSource.runMigrations({
      transaction: 'all',
    });

    const names = migrations.map((migration) => migration.name);
    process.stdout.write(
      names.length === 0
        ? 'Database is already up to date.\n'
        : `Applied migrations: ${names.join(', ')}\n`,
    );
  } finally {
    await AppDataSource.destroy();
  }
}

void migrate();
