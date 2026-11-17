-- ============================================================================
-- BookMyShow Ticketing Backend — Schema Definition
-- ============================================================================
-- Target : MySQL 8.0+
-- Normal Forms : 1NF, 2NF, 3NF, BCNF verified
-- Concurrency : Pessimistic seat-level locking via `seat_status` + `locked_until`
-- ============================================================================

CREATE DATABASE IF NOT EXISTS bookmyshow;
USE bookmyshow;

-- ────────────────────────────────────────────────────────────────────────────
-- 1. CITIES
-- ────────────────────────────────────────────────────────────────────────────
-- Each row is uniquely identified by city_id.
-- city_name is a simple atomic attribute → 1NF ✓
-- No partial or transitive dependencies (single-column PK) → 2NF, 3NF, BCNF ✓

CREATE TABLE cities (
    city_id      INT           AUTO_INCREMENT PRIMARY KEY,
    city_name    VARCHAR(100)  NOT NULL,
    state        VARCHAR(100)  NOT NULL,
    created_at   TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    UNIQUE KEY uk_city_state (city_name, state)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ────────────────────────────────────────────────────────────────────────────
-- 2. THEATRES
-- ────────────────────────────────────────────────────────────────────────────
-- Each theatre belongs to exactly one city (FK → cities).
-- total_screens is an attribute of the theatre, not of the city → no transitive dep.
-- 1NF–BCNF ✓

CREATE TABLE theatres (
    theatre_id    INT           AUTO_INCREMENT PRIMARY KEY,
    city_id       INT           NOT NULL,
    theatre_name  VARCHAR(200)  NOT NULL,
    address       VARCHAR(500)  NOT NULL,
    total_screens SMALLINT      NOT NULL DEFAULT 1,
    created_at    TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_theatre_city FOREIGN KEY (city_id) REFERENCES cities(city_id),
    INDEX idx_theatre_city (city_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ────────────────────────────────────────────────────────────────────────────
-- 3. SCREENS
-- ────────────────────────────────────────────────────────────────────────────
-- A screen belongs to exactly one theatre.
-- screen_number is unique within a theatre → composite unique key.
-- 1NF–BCNF ✓

CREATE TABLE screens (
    screen_id      INT           AUTO_INCREMENT PRIMARY KEY,
    theatre_id     INT           NOT NULL,
    screen_name    VARCHAR(50)   NOT NULL,          -- e.g. "Screen 1", "IMAX"
    screen_number  SMALLINT      NOT NULL,
    total_seats    SMALLINT      NOT NULL,
    created_at     TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at     TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_screen_theatre FOREIGN KEY (theatre_id) REFERENCES theatres(theatre_id),
    UNIQUE KEY uk_screen_in_theatre (theatre_id, screen_number),
    INDEX idx_screen_theatre (theatre_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ────────────────────────────────────────────────────────────────────────────
-- 4. SEATS
-- ────────────────────────────────────────────────────────────────────────────
-- Each physical seat belongs to one screen.
-- seat_row + seat_number is unique within a screen.
-- seat_type (REGULAR, PREMIUM, RECLINER) is an attribute of the seat, not derived
-- from any other non-key attribute → BCNF ✓

CREATE TABLE seats (
    seat_id      INT           AUTO_INCREMENT PRIMARY KEY,
    screen_id    INT           NOT NULL,
    seat_row     CHAR(2)       NOT NULL,            -- e.g. "A", "B", "AA"
    seat_number  SMALLINT      NOT NULL,            -- e.g. 1, 2, …
    seat_type    ENUM('REGULAR','PREMIUM','RECLINER') NOT NULL DEFAULT 'REGULAR',
    created_at   TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_seat_screen FOREIGN KEY (screen_id) REFERENCES screens(screen_id),
    UNIQUE KEY uk_seat_in_screen (screen_id, seat_row, seat_number),
    INDEX idx_seat_screen (screen_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ────────────────────────────────────────────────────────────────────────────
-- 5. MOVIES
-- ────────────────────────────────────────────────────────────────────────────
-- Each movie is an independent entity.
-- duration_minutes, language, genre are all functionally dependent only on movie_id.
-- 1NF–BCNF ✓

CREATE TABLE movies (
    movie_id          INT           AUTO_INCREMENT PRIMARY KEY,
    title             VARCHAR(300)  NOT NULL,
    language          VARCHAR(50)   NOT NULL,
    genre             VARCHAR(100)  NOT NULL,
    duration_minutes  SMALLINT      NOT NULL,
    certificate       ENUM('U','UA','A','S') NOT NULL DEFAULT 'UA',
    release_date      DATE          NOT NULL,
    poster_url        VARCHAR(500)  NULL,
    created_at        TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at        TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX idx_movie_release (release_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ────────────────────────────────────────────────────────────────────────────
-- 6. SHOWS  (a specific screening of a movie on a screen at a date+time)
-- ────────────────────────────────────────────────────────────────────────────
-- Composite business key: (screen_id, show_date, start_time).
-- movie_id, price_* depend only on show_id (the PK) → no partial deps.
-- 1NF–BCNF ✓

CREATE TABLE shows (
    show_id           INT           AUTO_INCREMENT PRIMARY KEY,
    movie_id          INT           NOT NULL,
    screen_id         INT           NOT NULL,
    show_date         DATE          NOT NULL,
    start_time        TIME          NOT NULL,
    end_time          TIME          NOT NULL,
    price_regular     DECIMAL(8,2)  NOT NULL,
    price_premium     DECIMAL(8,2)  NOT NULL,
    price_recliner    DECIMAL(8,2)  NOT NULL,
    created_at        TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at        TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_show_movie  FOREIGN KEY (movie_id)  REFERENCES movies(movie_id),
    CONSTRAINT fk_show_screen FOREIGN KEY (screen_id) REFERENCES screens(screen_id),

    -- Prevent two shows overlapping on the same screen+date+time
    UNIQUE KEY uk_screen_date_time (screen_id, show_date, start_time),

    -- ★ Critical index for P2: "all shows at a theatre on a date"
    INDEX idx_show_date_screen (show_date, screen_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ────────────────────────────────────────────────────────────────────────────
-- 7. USERS
-- ────────────────────────────────────────────────────────────────────────────

CREATE TABLE users (
    user_id       INT           AUTO_INCREMENT PRIMARY KEY,
    full_name     VARCHAR(200)  NOT NULL,
    email         VARCHAR(254)  NOT NULL,
    phone         VARCHAR(15)   NOT NULL,
    password_hash VARCHAR(255)  NOT NULL,
    created_at    TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    UNIQUE KEY uk_user_email (email),
    UNIQUE KEY uk_user_phone (phone)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ────────────────────────────────────────────────────────────────────────────
-- 8. SHOW_SEATS  (per-show seat availability — the concurrency hot table)
-- ────────────────────────────────────────────────────────────────────────────
-- One row per seat per show.  This is the entity we lock.
--
-- seat_status lifecycle:
--   AVAILABLE → LOCKED → BOOKED      (happy path)
--   AVAILABLE → LOCKED → AVAILABLE   (hold expired / payment failed)
--
-- locked_until: populated when status = LOCKED.
--   A background job or Redis TTL releases seats whose locked_until < NOW().
--
-- Locking strategy (Pessimistic):
--   SELECT … WHERE show_id = ? AND seat_id = ? FOR UPDATE
--   This acquires an InnoDB row-level exclusive lock.
--   Only one transaction can lock the same seat; others block until commit/rollback.
--
-- version column: enables optimistic-locking fallback for read-heavy paths.
--
-- 1NF–BCNF ✓  (every non-key attribute depends only on the full PK)

CREATE TABLE show_seats (
    show_seat_id   BIGINT        AUTO_INCREMENT PRIMARY KEY,
    show_id        INT           NOT NULL,
    seat_id        INT           NOT NULL,
    seat_status    ENUM('AVAILABLE','LOCKED','BOOKED') NOT NULL DEFAULT 'AVAILABLE',
    locked_until   TIMESTAMP     NULL DEFAULT NULL,
    locked_by      INT           NULL DEFAULT NULL,       -- user_id who holds the lock
    booking_id     BIGINT        NULL DEFAULT NULL,       -- set after payment confirmed
    version        INT           NOT NULL DEFAULT 0,      -- optimistic locking counter
    created_at     TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at     TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_ss_show FOREIGN KEY (show_id) REFERENCES shows(show_id),
    CONSTRAINT fk_ss_seat FOREIGN KEY (seat_id) REFERENCES seats(seat_id),
    CONSTRAINT fk_ss_user FOREIGN KEY (locked_by) REFERENCES users(user_id),

    -- Each seat appears at most once per show
    UNIQUE KEY uk_show_seat (show_id, seat_id),

    -- Fast lookup for "all seats of a show" (the seat map)
    INDEX idx_ss_show_status (show_id, seat_status),

    -- Background job: find expired locks efficiently
    INDEX idx_ss_locked_until (seat_status, locked_until)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ────────────────────────────────────────────────────────────────────────────
-- 9. BOOKINGS
-- ────────────────────────────────────────────────────────────────────────────

CREATE TABLE bookings (
    booking_id      BIGINT        AUTO_INCREMENT PRIMARY KEY,
    user_id         INT           NOT NULL,
    show_id         INT           NOT NULL,
    num_seats       SMALLINT      NOT NULL,
    total_amount    DECIMAL(10,2) NOT NULL,
    booking_status  ENUM('PENDING','CONFIRMED','CANCELLED','EXPIRED') NOT NULL DEFAULT 'PENDING',
    booked_at       TIMESTAMP     NULL DEFAULT NULL,
    created_at      TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_booking_user FOREIGN KEY (user_id) REFERENCES users(user_id),
    CONSTRAINT fk_booking_show FOREIGN KEY (show_id) REFERENCES shows(show_id),
    INDEX idx_booking_user (user_id),
    INDEX idx_booking_show (show_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Now add the FK from show_seats → bookings (deferred because bookings didn't exist yet)
ALTER TABLE show_seats
    ADD CONSTRAINT fk_ss_booking FOREIGN KEY (booking_id) REFERENCES bookings(booking_id);


-- ────────────────────────────────────────────────────────────────────────────
-- 10. PAYMENTS  (idempotent webhook handling)
-- ────────────────────────────────────────────────────────────────────────────
-- idempotency_key: the payment gateway's unique transaction/event ID.
--   Before processing a webhook, we:
--     INSERT … ON DUPLICATE KEY UPDATE (no-op if same key exists)
--   This guarantees exactly-once processing even if the gateway retries.
--
-- 1NF–BCNF ✓

CREATE TABLE payments (
    payment_id       BIGINT         AUTO_INCREMENT PRIMARY KEY,
    booking_id       BIGINT         NOT NULL,
    idempotency_key  VARCHAR(128)   NOT NULL,          -- gateway's unique txn ID
    amount           DECIMAL(10,2)  NOT NULL,
    currency         CHAR(3)        NOT NULL DEFAULT 'INR',
    payment_status   ENUM('INITIATED','SUCCESS','FAILED','REFUNDED') NOT NULL DEFAULT 'INITIATED',
    payment_method   VARCHAR(50)    NULL,              -- UPI, CARD, NET_BANKING, WALLET
    gateway_response JSON           NULL,              -- raw response from gateway
    paid_at          TIMESTAMP      NULL DEFAULT NULL,
    created_at       TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at       TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_payment_booking FOREIGN KEY (booking_id) REFERENCES bookings(booking_id),

    -- ★ Idempotency: each gateway event processed at most once
    UNIQUE KEY uk_idempotency (idempotency_key),
    INDEX idx_payment_booking (booking_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
