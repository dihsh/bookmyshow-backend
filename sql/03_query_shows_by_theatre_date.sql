-- ============================================================================
-- BookMyShow — P2: List all shows on a given date at a given theatre
-- ============================================================================
-- Displays every show running at a theatre on a particular date, grouped by
-- movie, with show timings, screen info, and pricing.
--
-- Parameters (replace before execution):
--   @theatre_id  →  1          (PVR INOX: Phoenix Palladium)
--   @show_date   →  '2026-11-18'
-- ============================================================================

USE bookmyshow;

-- ────────────────────────────────────────────────────────────────────────────
-- QUERY: All shows at a given theatre on a given date
-- ────────────────────────────────────────────────────────────────────────────
-- Uses the covering index idx_show_date_screen on shows(show_date, screen_id)
-- and joins through screens to filter by theatre_id.
-- Results are ordered by movie title then start_time for a natural UI layout.

SET @theatre_id = 1;
SET @show_date  = '2026-11-18';

SELECT
    m.title                                            AS movie_title,
    m.language,
    m.genre,
    m.certificate,
    CONCAT(FLOOR(m.duration_minutes / 60), 'h ',
           MOD(m.duration_minutes, 60), 'm')           AS duration,
    sc.screen_name,
    sh.show_id,
    sh.start_time,
    sh.end_time,
    sh.price_regular,
    sh.price_premium,
    sh.price_recliner,
    -- Seat availability summary (sub-query for each show)
    (SELECT COUNT(*) FROM show_seats ss
     WHERE ss.show_id = sh.show_id
       AND ss.seat_status = 'AVAILABLE')               AS available_seats,
    (SELECT COUNT(*) FROM show_seats ss
     WHERE ss.show_id = sh.show_id)                    AS total_seats
FROM
    shows sh
    INNER JOIN screens sc ON sh.screen_id = sc.screen_id
    INNER JOIN movies  m  ON sh.movie_id  = m.movie_id
WHERE
    sc.theatre_id = @theatre_id
    AND sh.show_date = @show_date
ORDER BY
    m.title ASC,
    sh.start_time ASC;


-- ============================================================================
-- EXPECTED OUTPUT (with seed data, theatre_id=1, date=2026-11-18):
-- ============================================================================
-- +---------------------------+---------+------------------+------+----------+-----------+---------+-----------+----------+-------+-------+---------+-------+-------+
-- | movie_title               | language| genre            | cert | duration | screen    | show_id | start     | end      | reg   | prem  | recl    | avail | total |
-- +---------------------------+---------+------------------+------+----------+-----------+---------+-----------+----------+-------+-------+---------+-------+-------+
-- | Bhool Bhulaiyaa 3         | Hindi   | Horror, Comedy   | UA   | 2h 30m   | Screen 4  | 12      | 09:30:00  | 12:00:00 | 200   | 300   | 420     |   0   |   0   |
-- | Bhool Bhulaiyaa 3         | Hindi   | Horror, Comedy   | UA   | 2h 30m   | Screen 4  | 13      | 13:30:00  | 16:00:00 | 200   | 300   | 420     |   0   |   0   |
-- | Bhool Bhulaiyaa 3         | Hindi   | Horror, Comedy   | UA   | 2h 30m   | Screen 4  | 14      | 17:30:00  | 20:00:00 | 250   | 350   | 470     |   0   |   0   |
-- | Interstellar (Re-release) | English | Sci-Fi, Drama    | UA   | 2h 49m   | IMAX      | 9       | 10:30:00  | 13:19:00 | 400   | 500   | 700     |   0   |   0   |
-- | Interstellar (Re-release) | English | Sci-Fi, Drama    | UA   | 2h 49m   | IMAX      | 10      | 14:30:00  | 17:19:00 | 400   | 500   | 700     |   0   |   0   |
-- | Interstellar (Re-release) | English | Sci-Fi, Drama    | UA   | 2h 49m   | IMAX      | 11      | 18:30:00  | 21:19:00 | 450   | 550   | 750     |   0   |   0   |
-- | Pushpa 2: The Rule        | Telugu  | Action, Drama    | UA   | 3h 0m    | Screen 1  | 1       | 09:00:00  | 12:00:00 | 250   | 350   | 500     |  33   |  35   |
-- | Pushpa 2: The Rule        | Telugu  | Action, Drama    | UA   | 3h 0m    | Gold Class| 15      | 11:00:00  | 14:00:00 | 600   | 600   | 600     |   0   |   0   |
-- | Pushpa 2: The Rule        | Telugu  | Action, Drama    | UA   | 3h 0m    | Screen 1  | 2       | 13:00:00  | 16:00:00 | 250   | 350   | 500     |   0   |   0   |
-- | Pushpa 2: The Rule        | Telugu  | Action, Drama    | UA   | 3h 0m    | Screen 1  | 3       | 17:00:00  | 20:00:00 | 300   | 400   | 550     |   0   |   0   |
-- | Pushpa 2: The Rule        | Telugu  | Action, Drama    | UA   | 3h 0m    | Gold Class| 16      | 19:00:00  | 22:00:00 | 700   | 700   | 700     |   0   |   0   |
-- | Pushpa 2: The Rule        | Telugu  | Action, Drama    | UA   | 3h 0m    | Screen 1  | 4       | 21:00:00  | 23:59:00 | 300   | 400   | 550     |   0   |   0   |
-- | Singham Again             | Hindi   | Action, Thriller | UA   | 2h 35m   | Screen 2  | 5       | 10:00:00  | 12:35:00 | 220   | 320   | 450     |   0   |   0   |
-- | Singham Again             | Hindi   | Action, Thriller | UA   | 2h 35m   | Screen 2  | 6       | 14:00:00  | 16:35:00 | 220   | 320   | 450     |   0   |   0   |
-- | Singham Again             | Hindi   | Action, Thriller | UA   | 2h 35m   | Screen 2  | 7       | 18:00:00  | 20:35:00 | 270   | 370   | 500     |   0   |   0   |
-- | Singham Again             | Hindi   | Action, Thriller | UA   | 2h 35m   | Screen 2  | 8       | 21:30:00  | 23:59:00 | 270   | 370   | 500     |   0   |   0   |
-- +---------------------------+---------+------------------+------+----------+-----------+---------+-----------+----------+-------+-------+---------+-------+-------+
-- Note: available_seats=0 for shows without show_seats rows seeded (only show 1 has them).
