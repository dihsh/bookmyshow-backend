# BookMyShow — Ticketing Backend (Database Design)

A BookMyShow-scale ticketing backend schema with seat-level locking, timed holds, idempotent payment processing, and concurrency-safe booking flows. All SQL is directly executable on **MySQL 8.0+**.

---

## Table of Contents

1. [Entity-Relationship Diagram](#1-entity-relationship-diagram)
2. [Entity List & Attributes](#2-entity-list--attributes)
3. [Normalization Proof (1NF → BCNF)](#3-normalization-proof-1nf--bcnf)
4. [Concurrency & Locking Strategy](#4-concurrency--locking-strategy)
5. [P1 — Schema DDL & Sample Data](#5-p1--schema-ddl--sample-data)
6. [P2 — Shows at a Theatre on a Date](#6-p2--shows-at-a-theatre-on-a-date)
7. [Index Strategy](#7-index-strategy)
8. [How to Run](#8-how-to-run)

---

## 1. Entity-Relationship Diagram

```
┌──────────┐       ┌───────────┐       ┌──────────┐       ┌────────┐
│  cities  │1────M│  theatres  │1────M│  screens  │1────M│  seats  │
│          │       │            │       │           │       │        │
│ city_id  │       │ theatre_id │       │ screen_id │       │seat_id │
│ city_name│       │ city_id FK │       │theatre_id │       │screen_id│
│ state    │       │ name       │       │ name      │       │seat_row│
└──────────┘       │ address    │       │ number    │       │seat_num│
                   │ screens    │       │ seats     │       │type    │
                   └────────────┘       └─────┬─────┘       └───┬────┘
                                              │1                 │1
                                              │                  │
                                        ┌─────┴─────┐           │
                   ┌──────────┐    M    │   shows    │           │
                   │  movies  │────────│            │           │
                   │          │         │ show_id    │           │
                   │ movie_id │         │ movie_id FK│           │
                   │ title    │         │ screen_id  │           │
                   │ language │         │ show_date  │           │
                   │ genre    │         │ start_time │           │
                   │ duration │         │ end_time   │           │
                   │ cert     │         │ prices     │           │
                   └──────────┘         └─────┬──────┘           │
                                              │1                 │
                                              │                  │
                                        ┌─────┴──────────────────┴───┐
                                        │       show_seats           │
                                        │  (Concurrency Hot Table)   │
                                        │                            │
                                        │ show_seat_id  PK           │
                                        │ show_id       FK → shows   │
                                        │ seat_id       FK → seats   │
                                        │ seat_status   ENUM         │
                                        │ locked_until  TIMESTAMP    │
                                        │ locked_by     FK → users   │
                                        │ booking_id    FK → bookings│
                                        │ version       INT          │
                                        └────────┬───────────────────┘
                                                 │
                              ┌───────────┐      │       ┌────────────┐
                              │   users   │      │       │  payments  │
                              │           │      │       │            │
                              │ user_id   │──────┘       │payment_id  │
                              │ name      │              │booking_id  │
                              │ email     │              │idempotency │
                              │ phone     │              │  _key (UQ) │
                              │ pwd_hash  │              │amount      │
                              └─────┬─────┘              │status      │
                                    │                    │method      │
                                    │1                   │gateway_resp│
                                    │                    └──────┬─────┘
                              ┌─────┴──────┐                    │
                              │  bookings  │1───────────────────┘
                              │            │
                              │booking_id  │
                              │user_id  FK │
                              │show_id  FK │
                              │num_seats   │
                              │total_amount│
                              │status      │
                              │booked_at   │
                              └────────────┘
```

---

## 2. Entity List & Attributes

### 2.1 cities
| Column     | Type         | Constraints          |
|------------|-------------|----------------------|
| city_id    | INT (PK)    | AUTO_INCREMENT       |
| city_name  | VARCHAR(100)| NOT NULL             |
| state      | VARCHAR(100)| NOT NULL             |
| created_at | TIMESTAMP   | DEFAULT NOW()        |
| updated_at | TIMESTAMP   | ON UPDATE NOW()      |

### 2.2 theatres
| Column        | Type         | Constraints               |
|---------------|-------------|---------------------------|
| theatre_id    | INT (PK)    | AUTO_INCREMENT            |
| city_id       | INT (FK)    | → cities.city_id          |
| theatre_name  | VARCHAR(200)| NOT NULL                  |
| address       | VARCHAR(500)| NOT NULL                  |
| total_screens | SMALLINT    | DEFAULT 1                 |
| created_at    | TIMESTAMP   | DEFAULT NOW()             |
| updated_at    | TIMESTAMP   | ON UPDATE NOW()           |

### 2.3 screens
| Column        | Type         | Constraints                       |
|---------------|-------------|-----------------------------------|
| screen_id     | INT (PK)    | AUTO_INCREMENT                    |
| theatre_id    | INT (FK)    | → theatres.theatre_id             |
| screen_name   | VARCHAR(50) | NOT NULL (e.g. "IMAX")            |
| screen_number | SMALLINT    | UNIQUE within theatre             |
| total_seats   | SMALLINT    | NOT NULL                          |
| created_at    | TIMESTAMP   | DEFAULT NOW()                     |
| updated_at    | TIMESTAMP   | ON UPDATE NOW()                   |

### 2.4 seats
| Column      | Type            | Constraints                        |
|-------------|----------------|------------------------------------|
| seat_id     | INT (PK)       | AUTO_INCREMENT                     |
| screen_id   | INT (FK)       | → screens.screen_id                |
| seat_row    | CHAR(2)        | NOT NULL (e.g. "A", "B")           |
| seat_number | SMALLINT       | NOT NULL                           |
| seat_type   | ENUM           | REGULAR, PREMIUM, RECLINER         |
| created_at  | TIMESTAMP      | DEFAULT NOW()                      |

### 2.5 movies
| Column           | Type         | Constraints               |
|------------------|-------------|---------------------------|
| movie_id         | INT (PK)    | AUTO_INCREMENT            |
| title            | VARCHAR(300)| NOT NULL                  |
| language         | VARCHAR(50) | NOT NULL                  |
| genre            | VARCHAR(100)| NOT NULL                  |
| duration_minutes | SMALLINT    | NOT NULL                  |
| certificate      | ENUM        | U, UA, A, S              |
| release_date     | DATE        | NOT NULL                  |
| poster_url       | VARCHAR(500)| NULL                      |
| created_at       | TIMESTAMP   | DEFAULT NOW()             |
| updated_at       | TIMESTAMP   | ON UPDATE NOW()           |

### 2.6 shows
| Column         | Type          | Constraints                        |
|----------------|--------------|-----------------------------------|
| show_id        | INT (PK)     | AUTO_INCREMENT                     |
| movie_id       | INT (FK)     | → movies.movie_id                  |
| screen_id      | INT (FK)     | → screens.screen_id                |
| show_date      | DATE         | NOT NULL                           |
| start_time     | TIME         | NOT NULL                           |
| end_time       | TIME         | NOT NULL                           |
| price_regular  | DECIMAL(8,2) | NOT NULL                           |
| price_premium  | DECIMAL(8,2) | NOT NULL                           |
| price_recliner | DECIMAL(8,2) | NOT NULL                           |
| created_at     | TIMESTAMP    | DEFAULT NOW()                      |
| updated_at     | TIMESTAMP    | ON UPDATE NOW()                    |

**Unique Key**: `(screen_id, show_date, start_time)` — prevents overlapping shows.

### 2.7 users
| Column        | Type         | Constraints          |
|---------------|-------------|----------------------|
| user_id       | INT (PK)    | AUTO_INCREMENT       |
| full_name     | VARCHAR(200)| NOT NULL             |
| email         | VARCHAR(254)| UNIQUE, NOT NULL     |
| phone         | VARCHAR(15) | UNIQUE, NOT NULL     |
| password_hash | VARCHAR(255)| NOT NULL             |
| created_at    | TIMESTAMP   | DEFAULT NOW()        |
| updated_at    | TIMESTAMP   | ON UPDATE NOW()      |

### 2.8 show_seats ⚡ (Concurrency Hot Table)
| Column       | Type         | Constraints                                |
|--------------|-------------|-------------------------------------------|
| show_seat_id | BIGINT (PK) | AUTO_INCREMENT                             |
| show_id      | INT (FK)    | → shows.show_id                            |
| seat_id      | INT (FK)    | → seats.seat_id                            |
| seat_status  | ENUM        | AVAILABLE, LOCKED, BOOKED                  |
| locked_until | TIMESTAMP   | NULL — set when LOCKED                     |
| locked_by    | INT (FK)    | → users.user_id — who holds the lock       |
| booking_id   | BIGINT (FK) | → bookings.booking_id — set after payment  |
| version      | INT         | Optimistic locking counter                 |
| created_at   | TIMESTAMP   | DEFAULT NOW()                              |
| updated_at   | TIMESTAMP   | ON UPDATE NOW()                            |

**Unique Key**: `(show_id, seat_id)` — each seat appears at most once per show.

### 2.9 bookings
| Column         | Type          | Constraints                       |
|----------------|--------------|----------------------------------|
| booking_id     | BIGINT (PK)  | AUTO_INCREMENT                    |
| user_id        | INT (FK)     | → users.user_id                   |
| show_id        | INT (FK)     | → shows.show_id                   |
| num_seats      | SMALLINT     | NOT NULL                          |
| total_amount   | DECIMAL(10,2)| NOT NULL                          |
| booking_status | ENUM         | PENDING, CONFIRMED, CANCELLED, EXPIRED |
| booked_at      | TIMESTAMP    | NULL — set on CONFIRMED           |
| created_at     | TIMESTAMP    | DEFAULT NOW()                     |
| updated_at     | TIMESTAMP    | ON UPDATE NOW()                   |

### 2.10 payments
| Column          | Type          | Constraints                        |
|-----------------|--------------|-----------------------------------|
| payment_id      | BIGINT (PK)  | AUTO_INCREMENT                     |
| booking_id      | BIGINT (FK)  | → bookings.booking_id              |
| idempotency_key | VARCHAR(128) | **UNIQUE** — gateway's txn ID      |
| amount          | DECIMAL(10,2)| NOT NULL                           |
| currency        | CHAR(3)      | DEFAULT 'INR'                      |
| payment_status  | ENUM         | INITIATED, SUCCESS, FAILED, REFUNDED |
| payment_method  | VARCHAR(50)  | UPI, CARD, NET_BANKING, WALLET     |
| gateway_response| JSON         | Raw gateway payload                |
| paid_at         | TIMESTAMP    | NULL — set on SUCCESS              |
| created_at      | TIMESTAMP    | DEFAULT NOW()                      |
| updated_at      | TIMESTAMP    | ON UPDATE NOW()                    |

---

## 3. Normalization Proof (1NF → BCNF)

### 1NF (First Normal Form) ✅
- All columns contain **atomic values** (no arrays, no repeating groups).
- Each table has a **primary key**.
- No multi-valued attributes: genre is stored as a single string (not a separate table, acceptable for display-only data).

### 2NF (Second Normal Form) ✅
- Every non-key attribute is **fully functionally dependent** on the entire primary key.
- `show_seats` has composite candidate key `(show_id, seat_id)`:
  - `seat_status`, `locked_until`, `locked_by` all depend on the specific seat in a specific show (the full key), not on `show_id` alone or `seat_id` alone.
- No table has a composite PK with partial dependencies.

### 3NF (Third Normal Form) ✅
- No **transitive dependencies**: every non-key attribute depends directly on the PK, not through another non-key attribute.
- Example: In `theatres`, `city_name` is NOT stored — it's accessed via `city_id` FK → `cities` table. No denormalization.
- In `shows`, prices depend on `show_id` (the screening), not derived from `movie_id`.

### BCNF (Boyce-Codd Normal Form) ✅
- For every **functional dependency** X → Y, X is a **superkey**.
- `shows`: `{screen_id, show_date, start_time}` → all other attributes. This candidate key is enforced via UNIQUE constraint. The surrogate PK `show_id` is also a superkey.
- `show_seats`: `{show_id, seat_id}` → all other attributes. Enforced via UNIQUE constraint. `show_seat_id` (surrogate PK) is also a superkey.
- No FD exists where a non-superkey determines another attribute.

---

## 4. Concurrency & Locking Strategy

### 4.1 Pessimistic Locking (Primary Strategy)

```sql
-- Step 1: Acquire exclusive row locks
SELECT * FROM show_seats
WHERE show_id = ? AND seat_id IN (?, ?, ?)
  AND seat_status = 'AVAILABLE'
FOR UPDATE;
-- InnoDB now holds X-locks on these rows.
-- Any other transaction trying to lock the same rows will BLOCK.

-- Step 2: If all available → mark as LOCKED
UPDATE show_seats
SET seat_status = 'LOCKED', locked_until = NOW() + INTERVAL 5 MINUTE, ...
WHERE ...;

COMMIT;  -- releases the locks
```

**Why pessimistic?** In a hot-seat scenario (e.g., first-day-first-show of a blockbuster), many users compete for the same few seats. Pessimistic locking guarantees **no double-booking** because:
- Only one transaction holds the lock at a time.
- If seats are already locked/booked, the transaction immediately returns `CONFLICT`.

### 4.2 Optimistic Locking (Fallback for Reads)

The `version` column in `show_seats` supports optimistic concurrency for read-heavy paths (e.g., refreshing the seat map):

```sql
UPDATE show_seats
SET seat_status = 'LOCKED', version = version + 1
WHERE show_id = ? AND seat_id = ? AND version = ?;
-- If affected_rows = 0, another transaction modified it → retry.
```

### 4.3 Timed Holds (5-Minute Window)

```
User selects seats → seats LOCKED for 5 min → user pays → seats BOOKED
                                                └→ timer expires → seats AVAILABLE
```

- `locked_until` column stores the expiry timestamp.
- A **MySQL Event** runs every 30 seconds: `CALL sp_release_expired_holds()`.
- In production, **Redis** `EXPIRE` keys provide sub-second precision:
  - On lock: `SET seat_lock:{show_id}:{seat_id} {user_id} EX 300`
  - On expire: Redis keyspace notification triggers seat release.

### 4.4 Idempotent Payment Webhooks

Payment gateways (Razorpay, Stripe) may retry webhooks. We handle this via:

1. **UNIQUE constraint** on `payments.idempotency_key` (the gateway's event ID).
2. Before processing: check if `idempotency_key` exists → if yes, return `ALREADY_PROCESSED`.
3. This guarantees **exactly-once** seat confirmation per payment event.

### 4.5 Concurrency Guarantees Summary

| Scenario | Protection | Mechanism |
|---|---|---|
| Two users select the same seat | No double-lock | `SELECT … FOR UPDATE` (row-level X-lock) |
| User doesn't pay in time | Seats released | `locked_until` + scheduled cleanup event |
| Payment webhook sent twice | Processed once | `UNIQUE idempotency_key` check |
| Read seat map during booking | Consistent view | `version` column + optimistic retry |
| DB crash during booking | Atomic rollback | InnoDB transactions |

---

## 5. P1 — Schema DDL & Sample Data

### SQL Files

| File | Purpose |
|------|---------|
| [`sql/01_schema.sql`](sql/01_schema.sql) | CREATE TABLE statements for all 10 entities |
| [`sql/02_seed_data.sql`](sql/02_seed_data.sql) | INSERT sample rows (cities, theatres, movies, shows, seats, users, bookings, payments) |
| [`sql/04_concurrency_procedures.sql`](sql/04_concurrency_procedures.sql) | Stored procedures for seat locking, hold release, and idempotent payment processing |
| [`sql/05_indexes.sql`](sql/05_indexes.sql) | Additional performance indexes |

### Sample Data Summary

| Table      | Rows | Highlights |
|------------|------|------------|
| cities     | 5    | Mumbai, Delhi, Bengaluru, Hyderabad, Chennai |
| theatres   | 5    | PVR, INOX, AMB across cities |
| screens    | 12   | Includes IMAX, MX4D, Gold Class |
| seats      | 60   | Regular, Premium, Recliner types |
| movies     | 6    | Pushpa 2, Singham Again, Interstellar, etc. |
| shows      | 24   | 7 days of shows across theatres |
| users      | 5    | Sample user accounts |
| show_seats | 35   | Mix of AVAILABLE, LOCKED, BOOKED |
| bookings   | 3    | CONFIRMED and PENDING examples |
| payments   | 2    | Successful payments with idempotency keys |

---

## 6. P2 — Shows at a Theatre on a Date

**File**: [`sql/03_query_shows_by_theatre_date.sql`](sql/03_query_shows_by_theatre_date.sql)

```sql
SET @theatre_id = 1;        -- PVR INOX: Phoenix Palladium
SET @show_date  = '2026-11-18';

SELECT
    m.title           AS movie_title,
    m.language,
    m.genre,
    m.certificate,
    CONCAT(FLOOR(m.duration_minutes / 60), 'h ',
           MOD(m.duration_minutes, 60), 'm')  AS duration,
    sc.screen_name,
    sh.show_id,
    sh.start_time,
    sh.end_time,
    sh.price_regular,
    sh.price_premium,
    sh.price_recliner,
    (SELECT COUNT(*) FROM show_seats ss
     WHERE ss.show_id = sh.show_id AND ss.seat_status = 'AVAILABLE') AS available_seats,
    (SELECT COUNT(*) FROM show_seats ss
     WHERE ss.show_id = sh.show_id) AS total_seats
FROM shows sh
    INNER JOIN screens sc ON sh.screen_id = sc.screen_id
    INNER JOIN movies  m  ON sh.movie_id  = m.movie_id
WHERE sc.theatre_id = @theatre_id
  AND sh.show_date  = @show_date
ORDER BY m.title ASC, sh.start_time ASC;
```

This query:
- Joins `shows → screens` to filter by theatre.
- Joins `shows → movies` to get movie details.
- Sub-queries count available and total seats per show.
- Uses the **covering index** `idx_show_date_screen` for fast lookups.
- Orders by movie title and then start time, matching the BookMyShow UI layout.

---

## 7. Index Strategy

| Index | Table | Columns | Purpose |
|-------|-------|---------|---------|
| `uk_screen_date_time` | shows | (screen_id, show_date, start_time) | Prevent overlapping shows |
| `idx_show_date_screen` | shows | (show_date, screen_id) | P2 query: shows by date + theatre |
| `idx_shows_date_screen_movie` | shows | (show_date, screen_id, movie_id, start_time) | Covering index for P2 |
| `uk_show_seat` | show_seats | (show_id, seat_id) | One row per seat per show |
| `idx_ss_show_status` | show_seats | (show_id, seat_status) | Seat map loading |
| `idx_ss_locked_until` | show_seats | (seat_status, locked_until) | Expired hold cleanup |
| `uk_idempotency` | payments | (idempotency_key) | Exactly-once webhook processing |
| `idx_bookings_user_status` | bookings | (user_id, booking_status) | User booking history |

---

## 8. How to Run & Test on Your Laptop

### Prerequisites

- **MySQL 8.0+** installed and running
  - Download: https://dev.mysql.com/downloads/installer/
  - During installation, set a root password (you'll need it below)

### Step-by-Step Setup

#### Step 1: Verify MySQL is running

```bash
# Windows (PowerShell)
mysql --version

# If MySQL isn't in PATH, use the full path:
# "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql" --version
```

#### Step 2: Clone the repo

```bash
git clone https://github.com/dihsh/bookmyshow-backend.git
cd bookmyshow-backend
```

#### Step 3: Create the database and tables (P1)

```bash
mysql -u root -p < sql/01_schema.sql
```

You'll be prompted for your MySQL root password. This creates the `bookmyshow` database and all 10 tables.

#### Step 4: Load sample data

```bash
mysql -u root -p < sql/02_seed_data.sql
```

Inserts cities, theatres, screens, seats, movies, shows, users, bookings, and payments.

#### Step 5: Create stored procedures (concurrency logic)

```bash
mysql -u root -p < sql/04_concurrency_procedures.sql
```

Creates the seat-locking, hold-release, and idempotent payment webhook procedures.

#### Step 6: Add performance indexes

```bash
mysql -u root -p < sql/05_indexes.sql
```

#### Step 7: Run the P2 query (shows at a theatre on a date)

```bash
mysql -u root -p < sql/03_query_shows_by_theatre_date.sql
```

This lists all shows at **PVR INOX: Phoenix Palladium** (theatre_id=1) on **2026-11-18**, grouped by movie with show timings, screen names, prices, and seat availability.

### Testing the Concurrency Features

#### Test 1: Seat Locking

Open a MySQL shell and run:

```sql
USE bookmyshow;

-- Lock seats A3 and A4 (seat_id 3,4) for show 1, by user 1
CALL sp_lock_seats(1, 1, '3,4', @result);
SELECT @result;
-- Expected: 'SUCCESS'

-- Try locking the same seats again (simulating a second user)
CALL sp_lock_seats(1, 2, '3,4', @result);
SELECT @result;
-- Expected: 'CONFLICT' — seats are already locked!
```

#### Test 2: Concurrent Access (open two MySQL terminals)

**Terminal 1:**
```sql
USE bookmyshow;
START TRANSACTION;
SELECT * FROM show_seats WHERE show_id = 1 AND seat_id IN (11, 12) FOR UPDATE;
-- Holds the lock... don't commit yet
```

**Terminal 2:**
```sql
USE bookmyshow;
START TRANSACTION;
SELECT * FROM show_seats WHERE show_id = 1 AND seat_id IN (11, 12) FOR UPDATE;
-- This will BLOCK and wait until Terminal 1 commits or rolls back!
```

**Terminal 1:**
```sql
COMMIT;  -- Now Terminal 2 unblocks
```

#### Test 3: Idempotent Payment Processing

```sql
USE bookmyshow;

-- First webhook call
CALL sp_process_payment_webhook(3, 'razorpay_evt_003_xyz789', 500.00, 'UPI', 'SUCCESS', '{"status":"ok"}', @result);
SELECT @result;
-- Expected: 'PAYMENT_SUCCESS'

-- Same webhook arrives again (gateway retry)
CALL sp_process_payment_webhook(3, 'razorpay_evt_003_xyz789', 500.00, 'UPI', 'SUCCESS', '{"status":"ok"}', @result);
SELECT @result;
-- Expected: 'ALREADY_PROCESSED' — idempotent!
```

#### Test 4: Expired Hold Release

```sql
USE bookmyshow;

-- Enable the event scheduler
SET GLOBAL event_scheduler = ON;

-- Check current locked seats
SELECT seat_id, seat_status, locked_until FROM show_seats WHERE seat_status = 'LOCKED';

-- Manually run the cleanup (or wait 30s for the event)
CALL sp_release_expired_holds();

-- Check again — expired locks should be released
SELECT seat_id, seat_status, locked_until FROM show_seats WHERE seat_status = 'LOCKED';
```

#### Test 5: Verify the P2 Query with Different Parameters

```sql
USE bookmyshow;

-- Shows at INOX R-City (theatre_id=2) on 2026-11-18
SET @theatre_id = 2;
SET @show_date = '2026-11-18';

SELECT m.title, sc.screen_name, sh.start_time, sh.end_time, sh.price_regular
FROM shows sh
    INNER JOIN screens sc ON sh.screen_id = sc.screen_id
    INNER JOIN movies  m  ON sh.movie_id  = m.movie_id
WHERE sc.theatre_id = @theatre_id AND sh.show_date = @show_date
ORDER BY m.title, sh.start_time;
```

### Quick Verification Checklist

| # | Test | Expected Result | ✓ |
|---|------|-----------------|---|
| 1 | `SELECT COUNT(*) FROM cities;` | 5 | |
| 2 | `SELECT COUNT(*) FROM theatres;` | 5 | |
| 3 | `SELECT COUNT(*) FROM shows;` | 24 | |
| 4 | `SELECT COUNT(*) FROM show_seats;` | 35 | |
| 5 | P2 query returns shows grouped by movie | 16 rows for theatre 1, date 2026-11-18 | |
| 6 | `sp_lock_seats` returns SUCCESS for available seats | 'SUCCESS' | |
| 7 | `sp_lock_seats` returns CONFLICT for locked seats | 'CONFLICT' | |
| 8 | Duplicate webhook returns ALREADY_PROCESSED | 'ALREADY_PROCESSED' | |

---

## Author

Built as a system design exercise demonstrating database design for high-concurrency ticketing systems.

## License

MIT
