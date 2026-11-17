-- ============================================================================
-- BookMyShow Ticketing Backend — Sample Data
-- ============================================================================
-- Directly executable on MySQL 8.0+ after running 01_schema.sql
-- ============================================================================

USE bookmyshow;

-- ────────────────────────────────────────────────────────────────────────────
-- CITIES
-- ────────────────────────────────────────────────────────────────────────────

INSERT INTO cities (city_id, city_name, state) VALUES
    (1, 'Mumbai',    'Maharashtra'),
    (2, 'Delhi',     'Delhi'),
    (3, 'Bengaluru', 'Karnataka'),
    (4, 'Hyderabad', 'Telangana'),
    (5, 'Chennai',   'Tamil Nadu');


-- ────────────────────────────────────────────────────────────────────────────
-- THEATRES
-- ────────────────────────────────────────────────────────────────────────────

INSERT INTO theatres (theatre_id, city_id, theatre_name, address, total_screens) VALUES
    (1, 1, 'PVR INOX: Phoenix Palladium',  'Lower Parel, Mumbai 400013',      5),
    (2, 1, 'INOX: R-City',                 'Ghatkopar, Mumbai 400077',        4),
    (3, 2, 'PVR: Select Citywalk',         'Saket, New Delhi 110017',         6),
    (4, 3, 'INOX: Garuda Mall',            'Magrath Road, Bengaluru 560025',  3),
    (5, 4, 'AMB Cinemas',                  'Gachibowli, Hyderabad 500032',    4);


-- ────────────────────────────────────────────────────────────────────────────
-- SCREENS
-- ────────────────────────────────────────────────────────────────────────────

INSERT INTO screens (screen_id, theatre_id, screen_name, screen_number, total_seats) VALUES
    -- PVR Phoenix Palladium (theatre 1)
    (1,  1, 'Screen 1',    1, 150),
    (2,  1, 'Screen 2',    2, 120),
    (3,  1, 'IMAX',        3, 300),
    (4,  1, 'Screen 4',    4, 100),
    (5,  1, 'Gold Class',  5,  40),

    -- INOX R-City (theatre 2)
    (6,  2, 'Screen 1',    1, 180),
    (7,  2, 'Screen 2',    2, 140),
    (8,  2, 'Screen 3',    3, 160),
    (9,  2, 'MX4D',        4,  60),

    -- PVR Select Citywalk (theatre 3)
    (10, 3, 'Screen 1',    1, 200),
    (11, 3, 'Screen 2',    2, 150),
    (12, 3, 'Screen 3',    3, 150);


-- ────────────────────────────────────────────────────────────────────────────
-- SEATS  (generating a subset; in production this is scripted)
-- ────────────────────────────────────────────────────────────────────────────
-- For Screen 1 (screen_id=1, 150 seats): Rows A-J, 15 seats each
-- We'll insert a representative sample across different screens and types.

-- Screen 1 — Row A (Regular)
INSERT INTO seats (seat_id, screen_id, seat_row, seat_number, seat_type) VALUES
    (1,  1, 'A', 1,  'REGULAR'), (2,  1, 'A', 2,  'REGULAR'),
    (3,  1, 'A', 3,  'REGULAR'), (4,  1, 'A', 4,  'REGULAR'),
    (5,  1, 'A', 5,  'REGULAR'), (6,  1, 'A', 6,  'REGULAR'),
    (7,  1, 'A', 7,  'REGULAR'), (8,  1, 'A', 8,  'REGULAR'),
    (9,  1, 'A', 9,  'REGULAR'), (10, 1, 'A', 10, 'REGULAR');

-- Screen 1 — Row B (Regular)
INSERT INTO seats (seat_id, screen_id, seat_row, seat_number, seat_type) VALUES
    (11, 1, 'B', 1,  'REGULAR'), (12, 1, 'B', 2,  'REGULAR'),
    (13, 1, 'B', 3,  'REGULAR'), (14, 1, 'B', 4,  'REGULAR'),
    (15, 1, 'B', 5,  'REGULAR'), (16, 1, 'B', 6,  'REGULAR'),
    (17, 1, 'B', 7,  'REGULAR'), (18, 1, 'B', 8,  'REGULAR'),
    (19, 1, 'B', 9,  'REGULAR'), (20, 1, 'B', 10, 'REGULAR');

-- Screen 1 — Row H (Premium)
INSERT INTO seats (seat_id, screen_id, seat_row, seat_number, seat_type) VALUES
    (21, 1, 'H', 1,  'PREMIUM'), (22, 1, 'H', 2,  'PREMIUM'),
    (23, 1, 'H', 3,  'PREMIUM'), (24, 1, 'H', 4,  'PREMIUM'),
    (25, 1, 'H', 5,  'PREMIUM'), (26, 1, 'H', 6,  'PREMIUM'),
    (27, 1, 'H', 7,  'PREMIUM'), (28, 1, 'H', 8,  'PREMIUM'),
    (29, 1, 'H', 9,  'PREMIUM'), (30, 1, 'H', 10, 'PREMIUM');

-- Screen 1 — Row J (Recliner)
INSERT INTO seats (seat_id, screen_id, seat_row, seat_number, seat_type) VALUES
    (31, 1, 'J', 1,  'RECLINER'), (32, 1, 'J', 2,  'RECLINER'),
    (33, 1, 'J', 3,  'RECLINER'), (34, 1, 'J', 4,  'RECLINER'),
    (35, 1, 'J', 5,  'RECLINER');

-- Screen 3 (IMAX, screen_id=3) — Row A (Regular)
INSERT INTO seats (seat_id, screen_id, seat_row, seat_number, seat_type) VALUES
    (36, 3, 'A', 1,  'REGULAR'), (37, 3, 'A', 2,  'REGULAR'),
    (38, 3, 'A', 3,  'REGULAR'), (39, 3, 'A', 4,  'REGULAR'),
    (40, 3, 'A', 5,  'REGULAR'), (41, 3, 'A', 6,  'REGULAR'),
    (42, 3, 'A', 7,  'REGULAR'), (43, 3, 'A', 8,  'REGULAR'),
    (44, 3, 'A', 9,  'REGULAR'), (45, 3, 'A', 10, 'REGULAR');

-- Screen 5 (Gold Class, screen_id=5) — Row A (Recliner)
INSERT INTO seats (seat_id, screen_id, seat_row, seat_number, seat_type) VALUES
    (46, 5, 'A', 1,  'RECLINER'), (47, 5, 'A', 2,  'RECLINER'),
    (48, 5, 'A', 3,  'RECLINER'), (49, 5, 'A', 4,  'RECLINER'),
    (50, 5, 'A', 5,  'RECLINER');

-- Screen 6 (INOX R-City Screen 1, screen_id=6) — Row A (Regular)
INSERT INTO seats (seat_id, screen_id, seat_row, seat_number, seat_type) VALUES
    (51, 6, 'A', 1,  'REGULAR'), (52, 6, 'A', 2,  'REGULAR'),
    (53, 6, 'A', 3,  'REGULAR'), (54, 6, 'A', 4,  'REGULAR'),
    (55, 6, 'A', 5,  'REGULAR'), (56, 6, 'A', 6,  'REGULAR'),
    (57, 6, 'A', 7,  'REGULAR'), (58, 6, 'A', 8,  'REGULAR'),
    (59, 6, 'A', 9,  'REGULAR'), (60, 6, 'A', 10, 'REGULAR');


-- ────────────────────────────────────────────────────────────────────────────
-- MOVIES
-- ────────────────────────────────────────────────────────────────────────────

INSERT INTO movies (movie_id, title, language, genre, duration_minutes, certificate, release_date) VALUES
    (1, 'Pushpa 2: The Rule',       'Telugu',  'Action, Drama',       180, 'UA', '2026-11-15'),
    (2, 'Singham Again',            'Hindi',   'Action, Thriller',    155, 'UA', '2026-11-01'),
    (3, 'Bhool Bhulaiyaa 3',        'Hindi',   'Horror, Comedy',      150, 'UA', '2026-11-01'),
    (4, 'Amaran',                   'Tamil',   'War, Biography',      165, 'UA', '2026-10-31'),
    (5, 'Lucky Baskhar',            'Telugu',  'Crime, Thriller',     140, 'UA', '2026-10-31'),
    (6, 'Interstellar (Re-release)','English', 'Sci-Fi, Drama',       169, 'UA', '2026-11-10');


-- ────────────────────────────────────────────────────────────────────────────
-- SHOWS  (next 7 days at PVR Phoenix Palladium = theatre_id 1)
-- ────────────────────────────────────────────────────────────────────────────
-- Date: 2026-11-18 (Day 1)

INSERT INTO shows (show_id, movie_id, screen_id, show_date, start_time, end_time, price_regular, price_premium, price_recliner) VALUES
    -- Pushpa 2 on Screen 1
    (1,  1, 1, '2026-11-18', '09:00:00', '12:00:00', 250.00, 350.00, 500.00),
    (2,  1, 1, '2026-11-18', '13:00:00', '16:00:00', 250.00, 350.00, 500.00),
    (3,  1, 1, '2026-11-18', '17:00:00', '20:00:00', 300.00, 400.00, 550.00),
    (4,  1, 1, '2026-11-18', '21:00:00', '23:59:00', 300.00, 400.00, 550.00),

    -- Singham Again on Screen 2
    (5,  2, 2, '2026-11-18', '10:00:00', '12:35:00', 220.00, 320.00, 450.00),
    (6,  2, 2, '2026-11-18', '14:00:00', '16:35:00', 220.00, 320.00, 450.00),
    (7,  2, 2, '2026-11-18', '18:00:00', '20:35:00', 270.00, 370.00, 500.00),
    (8,  2, 2, '2026-11-18', '21:30:00', '23:59:00', 270.00, 370.00, 500.00),

    -- Interstellar on IMAX (Screen 3)
    (9,  6, 3, '2026-11-18', '10:30:00', '13:19:00', 400.00, 500.00, 700.00),
    (10, 6, 3, '2026-11-18', '14:30:00', '17:19:00', 400.00, 500.00, 700.00),
    (11, 6, 3, '2026-11-18', '18:30:00', '21:19:00', 450.00, 550.00, 750.00),

    -- Bhool Bhulaiyaa 3 on Screen 4
    (12, 3, 4, '2026-11-18', '09:30:00', '12:00:00', 200.00, 300.00, 420.00),
    (13, 3, 4, '2026-11-18', '13:30:00', '16:00:00', 200.00, 300.00, 420.00),
    (14, 3, 4, '2026-11-18', '17:30:00', '20:00:00', 250.00, 350.00, 470.00),

    -- Pushpa 2 Gold Class on Screen 5
    (15, 1, 5, '2026-11-18', '11:00:00', '14:00:00', 600.00, 600.00, 600.00),
    (16, 1, 5, '2026-11-18', '19:00:00', '22:00:00', 700.00, 700.00, 700.00);

-- Date: 2026-11-19 (Day 2) — a couple of shows at a different theatre too

INSERT INTO shows (show_id, movie_id, screen_id, show_date, start_time, end_time, price_regular, price_premium, price_recliner) VALUES
    -- Pushpa 2 on Screen 1 (theatre 1)
    (17, 1, 1, '2026-11-19', '09:00:00', '12:00:00', 250.00, 350.00, 500.00),
    (18, 1, 1, '2026-11-19', '13:00:00', '16:00:00', 250.00, 350.00, 500.00),
    (19, 1, 1, '2026-11-19', '21:00:00', '23:59:00', 300.00, 400.00, 550.00),

    -- Singham Again on Screen 2 (theatre 1)
    (20, 2, 2, '2026-11-19', '10:00:00', '12:35:00', 220.00, 320.00, 450.00),
    (21, 2, 2, '2026-11-19', '18:00:00', '20:35:00', 270.00, 370.00, 500.00),

    -- Amaran on Screen 6 (theatre 2 — INOX R-City)
    (22, 4, 6, '2026-11-18', '10:00:00', '12:45:00', 230.00, 330.00, 460.00),
    (23, 4, 6, '2026-11-18', '14:00:00', '16:45:00', 230.00, 330.00, 460.00),
    (24, 4, 6, '2026-11-18', '18:00:00', '20:45:00', 280.00, 380.00, 510.00);


-- ────────────────────────────────────────────────────────────────────────────
-- USERS
-- ────────────────────────────────────────────────────────────────────────────

INSERT INTO users (user_id, full_name, email, phone, password_hash) VALUES
    (1, 'Rahul Sharma',   'rahul.sharma@gmail.com',   '9876543210', '$2b$12$dummyhash1...'),
    (2, 'Priya Patel',    'priya.patel@gmail.com',    '9876543211', '$2b$12$dummyhash2...'),
    (3, 'Arjun Reddy',    'arjun.reddy@gmail.com',    '9876543212', '$2b$12$dummyhash3...'),
    (4, 'Sneha Nair',     'sneha.nair@gmail.com',     '9876543213', '$2b$12$dummyhash4...'),
    (5, 'Vikram Singh',   'vikram.singh@gmail.com',   '9876543214', '$2b$12$dummyhash5...');


-- ────────────────────────────────────────────────────────────────────────────
-- SHOW_SEATS  (for show_id=1, using seats 1-35 from screen 1)
-- ────────────────────────────────────────────────────────────────────────────
-- Demonstrating different statuses for the first show

INSERT INTO show_seats (show_seat_id, show_id, seat_id, seat_status, locked_until, locked_by, booking_id, version) VALUES
    -- Row A: mix of AVAILABLE, LOCKED, BOOKED
    (1,  1, 1,  'AVAILABLE', NULL,                       NULL, NULL, 0),
    (2,  1, 2,  'AVAILABLE', NULL,                       NULL, NULL, 0),
    (3,  1, 3,  'LOCKED',    '2026-11-18 09:05:00',      1,    NULL, 1),
    (4,  1, 4,  'LOCKED',    '2026-11-18 09:05:00',      1,    NULL, 1),
    (5,  1, 5,  'AVAILABLE', NULL,                       NULL, NULL, 0),
    (6,  1, 6,  'AVAILABLE', NULL,                       NULL, NULL, 0),
    (7,  1, 7,  'AVAILABLE', NULL,                       NULL, NULL, 0),
    (8,  1, 8,  'AVAILABLE', NULL,                       NULL, NULL, 0),
    (9,  1, 9,  'AVAILABLE', NULL,                       NULL, NULL, 0),
    (10, 1, 10, 'AVAILABLE', NULL,                       NULL, NULL, 0),

    -- Row B: all available
    (11, 1, 11, 'AVAILABLE', NULL, NULL, NULL, 0),
    (12, 1, 12, 'AVAILABLE', NULL, NULL, NULL, 0),
    (13, 1, 13, 'AVAILABLE', NULL, NULL, NULL, 0),
    (14, 1, 14, 'AVAILABLE', NULL, NULL, NULL, 0),
    (15, 1, 15, 'AVAILABLE', NULL, NULL, NULL, 0),
    (16, 1, 16, 'AVAILABLE', NULL, NULL, NULL, 0),
    (17, 1, 17, 'AVAILABLE', NULL, NULL, NULL, 0),
    (18, 1, 18, 'AVAILABLE', NULL, NULL, NULL, 0),
    (19, 1, 19, 'AVAILABLE', NULL, NULL, NULL, 0),
    (20, 1, 20, 'AVAILABLE', NULL, NULL, NULL, 0),

    -- Row H (Premium): some booked
    (21, 1, 21, 'AVAILABLE', NULL, NULL, NULL, 0),
    (22, 1, 22, 'AVAILABLE', NULL, NULL, NULL, 0),
    (23, 1, 23, 'AVAILABLE', NULL, NULL, NULL, 0),
    (24, 1, 24, 'AVAILABLE', NULL, NULL, NULL, 0),
    (25, 1, 25, 'AVAILABLE', NULL, NULL, NULL, 0),
    (26, 1, 26, 'AVAILABLE', NULL, NULL, NULL, 0),
    (27, 1, 27, 'AVAILABLE', NULL, NULL, NULL, 0),
    (28, 1, 28, 'AVAILABLE', NULL, NULL, NULL, 0),
    (29, 1, 29, 'AVAILABLE', NULL, NULL, NULL, 0),
    (30, 1, 30, 'AVAILABLE', NULL, NULL, NULL, 0),

    -- Row J (Recliner)
    (31, 1, 31, 'AVAILABLE', NULL, NULL, NULL, 0),
    (32, 1, 32, 'AVAILABLE', NULL, NULL, NULL, 0),
    (33, 1, 33, 'AVAILABLE', NULL, NULL, NULL, 0),
    (34, 1, 34, 'AVAILABLE', NULL, NULL, NULL, 0),
    (35, 1, 35, 'AVAILABLE', NULL, NULL, NULL, 0);


-- ────────────────────────────────────────────────────────────────────────────
-- BOOKINGS  (sample confirmed booking)
-- ────────────────────────────────────────────────────────────────────────────

INSERT INTO bookings (booking_id, user_id, show_id, num_seats, total_amount, booking_status, booked_at) VALUES
    (1, 2, 5, 3, 660.00, 'CONFIRMED', '2026-11-17 14:30:00'),
    (2, 3, 9, 2, 800.00, 'CONFIRMED', '2026-11-17 15:00:00'),
    (3, 4, 1, 2, 500.00, 'PENDING',    NULL);


-- ────────────────────────────────────────────────────────────────────────────
-- PAYMENTS  (idempotent — note the unique idempotency_key)
-- ────────────────────────────────────────────────────────────────────────────

INSERT INTO payments (payment_id, booking_id, idempotency_key, amount, currency, payment_status, payment_method, paid_at) VALUES
    (1, 1, 'razorpay_evt_001_abc123', 660.00, 'INR', 'SUCCESS', 'UPI',  '2026-11-17 14:30:05'),
    (2, 2, 'razorpay_evt_002_def456', 800.00, 'INR', 'SUCCESS', 'CARD', '2026-11-17 15:00:12');
