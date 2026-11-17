-- ============================================================================
-- BookMyShow — Concurrency & Locking Procedures
-- ============================================================================
-- Demonstrates:
--   1. Pessimistic locking for seat reservation (SELECT … FOR UPDATE)
--   2. Timed hold release (background cleanup)
--   3. Idempotent payment webhook processing
-- ============================================================================

USE bookmyshow;

-- ────────────────────────────────────────────────────────────────────────────
-- PROCEDURE 1: Lock seats for a user (Pessimistic Locking)
-- ────────────────────────────────────────────────────────────────────────────
-- Called when a user selects seats and clicks "Book Now".
-- Acquires exclusive row locks via FOR UPDATE → no other transaction can
-- modify the same rows until this transaction commits or rolls back.
--
-- Hold duration: 5 minutes (300 seconds).  After that, a cleanup job or
-- Redis TTL releases the hold.
--
-- Parameters:
--   p_show_id    INT         — the show
--   p_user_id    INT         — who is locking
--   p_seat_ids   TEXT        — comma-separated seat IDs, e.g. '3,4,5'
--
-- Returns: 'SUCCESS' or 'CONFLICT' via OUT param.

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_lock_seats$$

CREATE PROCEDURE sp_lock_seats(
    IN  p_show_id   INT,
    IN  p_user_id   INT,
    IN  p_seat_ids  TEXT,       -- comma-separated seat IDs
    OUT p_result    VARCHAR(20)
)
BEGIN
    DECLARE v_total_requested INT;
    DECLARE v_available       INT;
    DECLARE v_lock_until      TIMESTAMP;

    SET v_lock_until = TIMESTAMPADD(SECOND, 300, NOW());  -- 5 min hold

    -- Count how many seats the user wants
    SET v_total_requested = (LENGTH(p_seat_ids) - LENGTH(REPLACE(p_seat_ids, ',', '')) + 1);

    START TRANSACTION;

    -- ★ Pessimistic lock: SELECT … FOR UPDATE
    -- Acquires InnoDB row-level exclusive locks on the matching show_seats rows.
    -- Any concurrent transaction trying to lock the same rows will BLOCK here.
    SELECT COUNT(*) INTO v_available
    FROM show_seats
    WHERE show_id = p_show_id
      AND FIND_IN_SET(seat_id, p_seat_ids)
      AND seat_status = 'AVAILABLE'
    FOR UPDATE;

    IF v_available = v_total_requested THEN
        -- All requested seats are available → lock them
        UPDATE show_seats
        SET seat_status  = 'LOCKED',
            locked_until = v_lock_until,
            locked_by    = p_user_id,
            version      = version + 1,
            updated_at   = NOW()
        WHERE show_id = p_show_id
          AND FIND_IN_SET(seat_id, p_seat_ids)
          AND seat_status = 'AVAILABLE';

        SET p_result = 'SUCCESS';
        COMMIT;
    ELSE
        -- Some seats already taken → abort (atomic, no partial locks)
        SET p_result = 'CONFLICT';
        ROLLBACK;
    END IF;
END$$

DELIMITER ;


-- ────────────────────────────────────────────────────────────────────────────
-- PROCEDURE 2: Release expired seat holds
-- ────────────────────────────────────────────────────────────────────────────
-- Should be called periodically by a cron job / scheduled event (every 30s).
-- Also, in a production system, Redis EXPIRE keys trigger this per-seat.

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_release_expired_holds$$

CREATE PROCEDURE sp_release_expired_holds()
BEGIN
    UPDATE show_seats
    SET seat_status  = 'AVAILABLE',
        locked_until = NULL,
        locked_by    = NULL,
        version      = version + 1,
        updated_at   = NOW()
    WHERE seat_status = 'LOCKED'
      AND locked_until < NOW();

    -- Also expire corresponding pending bookings
    UPDATE bookings b
    SET b.booking_status = 'EXPIRED',
        b.updated_at     = NOW()
    WHERE b.booking_status = 'PENDING'
      AND b.created_at < TIMESTAMPADD(MINUTE, -5, NOW())
      AND NOT EXISTS (
          SELECT 1 FROM show_seats ss
          WHERE ss.booking_id = b.booking_id
            AND ss.seat_status = 'BOOKED'
      );
END$$

DELIMITER ;


-- ────────────────────────────────────────────────────────────────────────────
-- PROCEDURE 3: Idempotent payment webhook handler
-- ────────────────────────────────────────────────────────────────────────────
-- The payment gateway may send the same webhook multiple times.
-- We use the idempotency_key (gateway's transaction ID) with a UNIQUE constraint.
-- INSERT … ON DUPLICATE KEY ensures exactly-once processing.

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_process_payment_webhook$$

CREATE PROCEDURE sp_process_payment_webhook(
    IN  p_booking_id       BIGINT,
    IN  p_idempotency_key  VARCHAR(128),
    IN  p_amount           DECIMAL(10,2),
    IN  p_payment_method   VARCHAR(50),
    IN  p_gateway_status   VARCHAR(20),     -- 'SUCCESS' or 'FAILED'
    IN  p_gateway_response JSON,
    OUT p_result           VARCHAR(30)
)
BEGIN
    DECLARE v_existing_id BIGINT DEFAULT NULL;
    DECLARE v_booking_status VARCHAR(20);

    -- Check if this webhook was already processed (idempotency check)
    SELECT payment_id INTO v_existing_id
    FROM payments
    WHERE idempotency_key = p_idempotency_key
    LIMIT 1;

    IF v_existing_id IS NOT NULL THEN
        -- Already processed → no-op (idempotent)
        SET p_result = 'ALREADY_PROCESSED';
    ELSE
        START TRANSACTION;

        -- Verify booking exists and is PENDING
        SELECT booking_status INTO v_booking_status
        FROM bookings
        WHERE booking_id = p_booking_id
        FOR UPDATE;

        IF v_booking_status IS NULL THEN
            SET p_result = 'BOOKING_NOT_FOUND';
            ROLLBACK;
        ELSEIF v_booking_status != 'PENDING' THEN
            SET p_result = 'INVALID_BOOKING_STATUS';
            ROLLBACK;
        ELSE
            -- Insert payment record
            INSERT INTO payments (booking_id, idempotency_key, amount, currency,
                                  payment_status, payment_method, gateway_response, paid_at)
            VALUES (p_booking_id, p_idempotency_key, p_amount, 'INR',
                    p_gateway_status, p_payment_method, p_gateway_response,
                    IF(p_gateway_status = 'SUCCESS', NOW(), NULL));

            IF p_gateway_status = 'SUCCESS' THEN
                -- Confirm the booking
                UPDATE bookings
                SET booking_status = 'CONFIRMED',
                    booked_at      = NOW(),
                    updated_at     = NOW()
                WHERE booking_id = p_booking_id;

                -- Move seats from LOCKED → BOOKED
                UPDATE show_seats
                SET seat_status  = 'BOOKED',
                    locked_until = NULL,
                    booking_id   = p_booking_id,
                    version      = version + 1,
                    updated_at   = NOW()
                WHERE show_id = (SELECT show_id FROM bookings WHERE booking_id = p_booking_id)
                  AND locked_by = (SELECT user_id FROM bookings WHERE booking_id = p_booking_id)
                  AND seat_status = 'LOCKED';

                SET p_result = 'PAYMENT_SUCCESS';
            ELSE
                -- Payment failed → release seats
                UPDATE show_seats
                SET seat_status  = 'AVAILABLE',
                    locked_until = NULL,
                    locked_by    = NULL,
                    booking_id   = NULL,
                    version      = version + 1,
                    updated_at   = NOW()
                WHERE show_id = (SELECT show_id FROM bookings WHERE booking_id = p_booking_id)
                  AND locked_by = (SELECT user_id FROM bookings WHERE booking_id = p_booking_id)
                  AND seat_status = 'LOCKED';

                UPDATE bookings
                SET booking_status = 'CANCELLED',
                    updated_at     = NOW()
                WHERE booking_id = p_booking_id;

                SET p_result = 'PAYMENT_FAILED';
            END IF;

            COMMIT;
        END IF;
    END IF;
END$$

DELIMITER ;


-- ────────────────────────────────────────────────────────────────────────────
-- MySQL Event Scheduler: auto-release expired holds every 30 seconds
-- ────────────────────────────────────────────────────────────────────────────
-- Requires: SET GLOBAL event_scheduler = ON;

DROP EVENT IF EXISTS evt_release_expired_holds;

CREATE EVENT evt_release_expired_holds
ON SCHEDULE EVERY 30 SECOND
DO
    CALL sp_release_expired_holds();
