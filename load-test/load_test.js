/**
 * BookMyShow High-Concurrency Load Test
 * 
 * Simulates N concurrent users attempting to lock the same seats simultaneously.
 * Proves pessimistic row-level locking guarantees zero double-booking under load.
 * 
 * Usage:
 *   npm install mysql2
 *   node load-test/load_test.js
 */

const mysql = require('mysql2/promise');

const DB_CONFIG = {
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: 'bookmyshow',
  waitForConnections: true,
  connectionLimit: 50
};

const CONCURRENT_USERS = 50;
const SHOW_ID = 1;
const TARGET_SEATS = '5,6'; // seats to contend for

async function simulateUserBooking(userId, pool) {
  const connection = await pool.getConnection();
  try {
    const [result] = await connection.query('CALL sp_lock_seats(?, ?, ?, @result); SELECT @result AS status;', [
      SHOW_ID,
      userId,
      TARGET_SEATS
    ]);
    const status = result[1][0].status;
    return { userId, status };
  } catch (err) {
    return { userId, status: 'ERROR', error: err.message };
  } finally {
    connection.release();
  }
}

async function runLoadTest() {
  console.log('====================================================');
  console.log(`Starting Load Test: ${CONCURRENT_USERS} concurrent requests for seats ${TARGET_SEATS}`);
  console.log('====================================================');

  const pool = mysql.createPool(DB_CONFIG);

  try {
    // Reset seats first
    await pool.query(
      `UPDATE show_seats 
       SET seat_status = 'AVAILABLE', locked_until = NULL, locked_by = NULL 
       WHERE show_id = ? AND FIND_IN_SET(seat_id, ?)`,
      [SHOW_ID, TARGET_SEATS]
    );

    const startTime = Date.now();
    const tasks = [];

    for (let i = 1; i <= CONCURRENT_USERS; i++) {
      tasks.push(simulateUserBooking(i, pool));
    }

    const results = await Promise.all(tasks);
    const durationMs = Date.now() - startTime;

    const successes = results.filter(r => r.status === 'SUCCESS');
    const conflicts = results.filter(r => r.status === 'CONFLICT');
    const errors = results.filter(r => r.status === 'ERROR');

    console.log(`\nTest completed in ${durationMs}ms`);
    console.log(`- SUCCESS   : ${successes.length} (Expected: 1)`);
    console.log(`- CONFLICT  : ${conflicts.length} (Expected: ${CONCURRENT_USERS - 1})`);
    console.log(`- ERRORS    : ${errors.length}`);

    if (successes.length === 1 && conflicts.length === CONCURRENT_USERS - 1) {
      console.log('\n✅ PASS: Exact 1 user acquired lock. Zero double-booking occurred.');
    } else {
      console.error('\n❌ FAIL: Race condition detected!');
    }
  } finally {
    await pool.end();
  }
}

if (require.main === module) {
  runLoadTest().catch(console.error);
}
