-- ============================================================================
-- BookMyShow — Performance Indexes
-- ============================================================================
-- Additional indexes beyond those in the schema, optimized for high-concurrency
-- read and write patterns.
-- ============================================================================

USE bookmyshow;

-- ────────────────────────────────────────────────────────────────────────────
-- Composite index for P2 query: shows by theatre + date
-- The query joins shows → screens → theatres.
-- This covering index lets MySQL resolve the join without hitting the table.
-- ────────────────────────────────────────────────────────────────────────────
-- (Already have idx_show_date_screen in schema; adding a covering variant)

CREATE INDEX idx_shows_date_screen_movie
    ON shows (show_date, screen_id, movie_id, start_time);

-- ────────────────────────────────────────────────────────────────────────────
-- Index for the seat map: quickly load all seats + status for a show
-- ────────────────────────────────────────────────────────────────────────────

CREATE INDEX idx_ss_show_seat_status
    ON show_seats (show_id, seat_id, seat_status);

-- ────────────────────────────────────────────────────────────────────────────
-- Index for expired hold cleanup (used by sp_release_expired_holds)
-- ────────────────────────────────────────────────────────────────────────────
-- (Already have idx_ss_locked_until in schema — this is a note, not a duplicate)

-- ────────────────────────────────────────────────────────────────────────────
-- Index for payment idempotency lookups
-- ────────────────────────────────────────────────────────────────────────────
-- (Already have uk_idempotency unique key on payments.idempotency_key)

-- ────────────────────────────────────────────────────────────────────────────
-- Index for user booking history
-- ────────────────────────────────────────────────────────────────────────────

CREATE INDEX idx_bookings_user_status
    ON bookings (user_id, booking_status);
