/** Bound each instance's pool; URL controls provider TLS (never disable validation). */
export function databaseConnectionOptions() {
  const max = Number(process.env.DATABASE_POOL_MAX ?? 5);
  if (!Number.isInteger(max) || max < 1 || max > 20) {
    throw new Error('DATABASE_POOL_MAX must be an integer between 1 and 20.');
  }
  return {
    extra: {
      max,
      connectionTimeoutMillis: 5000,
      idleTimeoutMillis: 30000,
      statement_timeout: 15000,
      idle_in_transaction_session_timeout: 15000,
    },
  };
}
