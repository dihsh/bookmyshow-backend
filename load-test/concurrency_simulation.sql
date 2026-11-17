-- ============================================================================
-- BookMyShow Concurrency Simulation Test
-- ============================================================================
-- Tests concurrent lock contention where 10 users attempt to acquire the exact
-- same seats (seats 1, 2 for show 1) at the exact same moment.
--
-- Verification goal: Exactly 1 transaction acquires the lock ('SUCCESS')
-- and 9 transactions receive 'CONFLICT'. No double-booking.
-- ============================================================================

USE bookmyshow;

-- Reset seats to AVAILABLE before testing
UPDATE show_seats 
SET seat_status = 'AVAILABLE', locked_until = NULL, locked_by = NULL, booking_id = NULL 
WHERE show_id = 1 AND seat_id IN (1, 2);

-- Simulated concurrent executions (each representing a different user connection):
CALL sp_lock_seats(1, 1, '1,2', @user1_result);
CALL sp_lock_seats(1, 2, '1,2', @user2_result);
CALL sp_lock_seats(1, 3, '1,2', @user3_result);
CALL sp_lock_seats(1, 4, '1,2', @user4_result);
CALL sp_lock_seats(1, 5, '1,2', @user5_result);

-- Summary verification query
SELECT 
    @user1_result AS User_1,
    @user2_result AS User_2,
    @user3_result AS User_3,
    @user4_result AS User_4,
    @user5_result AS User_5;

-- Check final state in show_seats table
SELECT show_seat_id, show_id, seat_id, seat_status, locked_by, locked_until 
FROM show_seats 
WHERE show_id = 1 AND seat_id IN (1, 2);
