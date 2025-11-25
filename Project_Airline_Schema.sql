-- Create and use DB
CREATE DATABASE IF NOT EXISTS AirlineDB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE AirlineDB;

-- Ensure InnoDB for FK & transactions
CREATE TABLE IF NOT EXISTS Airports (
    airport_id INT AUTO_INCREMENT PRIMARY KEY,
    airport_code VARCHAR(10) UNIQUE NOT NULL,
    airport_name VARCHAR(150) NOT NULL,
    city VARCHAR(80),
    country VARCHAR(80),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS Flights (
    flight_id INT AUTO_INCREMENT PRIMARY KEY,
    flight_number VARCHAR(12) NOT NULL UNIQUE,
    origin_id INT NOT NULL,
    destination_id INT NOT NULL,
    departure_time DATETIME NOT NULL,
    arrival_time DATETIME NOT NULL,
    total_seats INT NOT NULL,
    available_seats INT NOT NULL,
    base_price DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    status ENUM('SCHEDULED','DELAYED','CANCELLED') DEFAULT 'SCHEDULED',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (origin_id) REFERENCES Airports(airport_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (destination_id) REFERENCES Airports(airport_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CHECK (total_seats >= 0),
    CHECK (available_seats >= 0)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS Customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(120) NOT NULL,
    email VARCHAR(120) UNIQUE,
    phone VARCHAR(20),
    nationality VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS Seats (
    seat_id INT AUTO_INCREMENT PRIMARY KEY,
    flight_id INT NOT NULL,
    seat_number VARCHAR(6) NOT NULL,
    class ENUM('ECONOMY','PREMIUM_ECONOMY','BUSINESS','FIRST') DEFAULT 'ECONOMY',
    is_booked BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (flight_id) REFERENCES Flights(flight_id) ON DELETE CASCADE ON UPDATE CASCADE,
    UNIQUE KEY ux_flight_seat (flight_id, seat_number)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS Bookings (
    booking_id INT AUTO_INCREMENT PRIMARY KEY,
    flight_id INT NOT NULL,
    customer_id INT NOT NULL,
    booking_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    seat_number VARCHAR(6),
    price_paid DECIMAL(10,2) DEFAULT 0.00,
    status ENUM('CONFIRMED','CANCELLED') DEFAULT 'CONFIRMED',
    payment_id INT,
    FOREIGN KEY (flight_id) REFERENCES Flights(flight_id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS Payments (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    booking_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    payment_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    payment_mode ENUM('UPI','CARD','NETBANKING','CASH') DEFAULT 'CARD',
    transaction_ref VARCHAR(100),
    FOREIGN KEY (booking_id) REFERENCES Bookings(booking_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Indexes for faster lookups
CREATE INDEX idx_flight_times ON Flights(departure_time, arrival_time);
CREATE INDEX idx_bookings_flight ON Bookings(flight_id);
CREATE INDEX idx_seats_flight ON Seats(flight_id);

-- Airports (small set)
INSERT INTO Airports (airport_code, airport_name, city, country) VALUES
('DEL','Indira Gandhi Intl','New Delhi','India'),
('BLR','Kempegowda Intl','Bengaluru','India'),
('BOM','Chhatrapati Shivaji Intl','Mumbai','India'),
('MAA','Chennai Intl','Chennai','India'),
('DXB','Dubai Intl','Dubai','UAE'),
('SIN','Changi','Singapore','Singapore');

-- Flights: We'll add several flights across dates
INSERT INTO Flights (flight_number, origin_id, destination_id, departure_time, arrival_time, total_seats, available_seats, base_price)
VALUES
('AI101', 1, 2, '2025-11-10 06:00:00', '2025-11-10 08:00:00', 180, 180, 5000.00),
('AI102', 2, 1, '2025-11-10 09:00:00', '2025-11-10 11:00:00', 180, 180, 4800.00),
('AI201', 1, 3, '2025-11-11 07:30:00', '2025-11-11 09:30:00', 150, 150, 4500.00),
('AI301', 3, 4, '2025-11-12 18:00:00', '2025-11-12 19:30:00', 120, 120, 3200.00),
('AI401', 1, 5, '2025-11-13 02:00:00', '2025-11-13 05:00:00', 250, 250, 15000.00),
('AI501', 4, 6, '2025-11-14 23:55:00', '2025-11-15 06:00:00', 200, 200, 18000.00);

-- Customers
INSERT INTO Customers (full_name, email, phone, nationality) VALUES
('Rahul Kumar','rahul.kumar@example.com','+919876543210','India'),
('Priya Sharma','priya.sharma@example.com','+919812345678','India'),
('John Doe','john.doe@example.com','+971501234567','UAE'),
('Ling Tan','ling.tan@example.com','+6591234567','Singapore');

-- Seats generation helper: create seat rows for each flight
-- We'll create rows like 1A,1B,... 30 rows * 6 seats = 180 for flights with 180 seats
-- For simplicity we distribute seat numbers: rows 1..(total_seats/6), seat letters A-F
DELIMITER $$
CREATE PROCEDURE generate_seats_for_all_flights()
BEGIN
  DECLARE f_id INT;
  DECLARE t_seats INT;
  DECLARE row_s INT;
  DECLARE r INT;
  DECLARE letters CHAR(6) DEFAULT 'ABCDEF';
  DECLARE idx INT;
  DECLARE seat_label VARCHAR(6);

  DECLARE cur CURSOR FOR SELECT flight_id, total_seats FROM Flights;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET f_id = NULL;

  OPEN cur;
  read_loop: LOOP
    FETCH cur INTO f_id, t_seats;
    IF f_id IS NULL THEN
      LEAVE read_loop;
    END IF;
    SET row_s = CEIL(t_seats / 6);
    SET r = 1;
    WHILE r <= row_s DO
      SET idx = 1;
      WHILE idx <= 6 DO
        SET seat_label = CONCAT(r, SUBSTRING(letters, idx, 1));
        -- avoid inserting more seats than total_seats
        IF ((r-1)*6 + idx) <= t_seats THEN
          INSERT IGNORE INTO Seats (flight_id, seat_number, class, is_booked) VALUES (f_id, seat_label, 'ECONOMY', FALSE);
        END IF;
        SET idx = idx + 1;
      END WHILE;
      SET r = r + 1;
    END WHILE;
  END LOOP;
  CLOSE cur;
END$$
DELIMITER ;

-- Run the seat generator
CALL generate_seats_for_all_flights();

-- Drop the generator to keep schema clean 
DROP PROCEDURE IF EXISTS generate_seats_for_all_flights;

SELECT f.flight_id, f.flight_number, COUNT(s.seat_id) AS seat_count
FROM Flights f LEFT JOIN Seats s USING(flight_id)
GROUP BY f.flight_id, f.flight_number;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_make_booking$$
CREATE PROCEDURE sp_make_booking(
    IN p_flight_id INT,
    IN p_customer_id INT,
    IN p_desired_seat VARCHAR(6),        -- pass NULL for auto-assign
    IN p_payment_amount DECIMAL(10,2),
    IN p_payment_mode VARCHAR(20),
    OUT p_booking_id INT,
    OUT p_error_msg VARCHAR(255)
)
main_block: BEGIN
  DECLARE v_avail INT;
  DECLARE v_seat VARCHAR(6);
  DECLARE v_payment_id INT;

  SET p_booking_id = NULL;
  SET p_error_msg = NULL;

  START TRANSACTION;

  -- Lock the flight row
  SELECT available_seats INTO v_avail
  FROM Flights
  WHERE flight_id = p_flight_id
  FOR UPDATE;

  IF v_avail IS NULL THEN
    SET p_error_msg = 'Flight not found';
    ROLLBACK;
    LEAVE main_block;
  END IF;

  IF v_avail <= 0 THEN
    SET p_error_msg = 'No seats available';
    ROLLBACK;
    LEAVE main_block;
  END IF;

  -- If user provided seat, try to book it
  IF p_desired_seat IS NOT NULL AND TRIM(p_desired_seat) <> '' THEN
    -- Check seat exists and not booked
    IF (SELECT COUNT(*) 
        FROM Seats 
        WHERE flight_id = p_flight_id 
          AND seat_number = p_desired_seat 
          AND is_booked = FALSE) = 1 THEN
      SET v_seat = p_desired_seat;
      UPDATE Seats 
      SET is_booked = TRUE 
      WHERE flight_id = p_flight_id AND seat_number = v_seat;
    ELSE
      SET p_error_msg = CONCAT('Requested seat ', p_desired_seat, ' not available');
      ROLLBACK;
      LEAVE main_block;
    END IF;
  ELSE
    -- Auto-assign lowest-numbered free seat
    SELECT seat_number INTO v_seat
    FROM Seats
    WHERE flight_id = p_flight_id AND is_booked = FALSE
    ORDER BY seat_number ASC
    LIMIT 1;

    IF v_seat IS NULL THEN
      SET p_error_msg = 'No free seat found';
      ROLLBACK;
      LEAVE main_block;
    END IF;

    UPDATE Seats 
    SET is_booked = TRUE 
    WHERE flight_id = p_flight_id AND seat_number = v_seat;
  END IF;

  -- Create booking
  INSERT INTO Bookings (flight_id, customer_id, seat_number, price_paid, status)
  VALUES (p_flight_id, p_customer_id, v_seat, p_payment_amount, 'CONFIRMED');

  SET p_booking_id = LAST_INSERT_ID();

  -- Payment record
  INSERT INTO Payments (booking_id, amount, payment_mode, transaction_ref)
  VALUES (p_booking_id, p_payment_amount, p_payment_mode, CONCAT('TXN', UNIX_TIMESTAMP()));

  SET v_payment_id = LAST_INSERT_ID();

  -- Link payment to booking
  UPDATE Bookings 
  SET payment_id = v_payment_id 
  WHERE booking_id = p_booking_id;

  -- Decrement available seats
  UPDATE Flights 
  SET available_seats = available_seats - 1
  WHERE flight_id = p_flight_id;

  COMMIT;

END main_block$$
DELIMITER ;

SET @booking_id = 0;
SET @err = '';

CALL sp_make_booking(1, 1, NULL, 5000.00, 'CARD', @booking_id, @err);
SELECT @booking_id AS booking_id, @err AS error_message;

SELECT * FROM Bookings WHERE booking_id = @booking_id;
SELECT * FROM Payments WHERE booking_id = @booking_id;
SELECT flight_number, available_seats FROM Flights WHERE flight_id = 1;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_cancel_booking$$
CREATE PROCEDURE sp_cancel_booking(
    IN p_booking_id INT,
    OUT p_msg VARCHAR(255)
)
main_block: BEGIN
  DECLARE v_flight INT;
  DECLARE v_seat VARCHAR(6);
  DECLARE v_status ENUM('CONFIRMED','CANCELLED');

  SET p_msg = NULL;
  START TRANSACTION;

  -- Lock the booking row
  SELECT flight_id, seat_number, status
  INTO v_flight, v_seat, v_status
  FROM Bookings
  WHERE booking_id = p_booking_id
  FOR UPDATE;

  -- Check if booking exists
  IF v_flight IS NULL THEN
    SET p_msg = 'Booking not found';
    ROLLBACK;
    LEAVE main_block;
  END IF;

  -- Already cancelled
  IF v_status = 'CANCELLED' THEN
    SET p_msg = 'Booking already cancelled';
    ROLLBACK;
    LEAVE main_block;
  END IF;

  -- Mark booking cancelled
  UPDATE Bookings
  SET status = 'CANCELLED'
  WHERE booking_id = p_booking_id;

  -- Free seat
  UPDATE Seats
  SET is_booked = FALSE
  WHERE flight_id = v_flight AND seat_number = v_seat;

  -- Increase available seats
  UPDATE Flights
  SET available_seats = available_seats + 1
  WHERE flight_id = v_flight;

  COMMIT;

  SET p_msg = 'Cancelled successfully';

END main_block$$
DELIMITER ;

-- When a booking is inserted as CONFIRMED, mark seat booked and decrement available_seats
DELIMITER $$
DROP TRIGGER IF EXISTS trg_booking_after_insert$$
CREATE TRIGGER trg_booking_after_insert
AFTER INSERT ON Bookings
FOR EACH ROW
BEGIN
  IF NEW.status = 'CONFIRMED' THEN
    UPDATE Seats SET is_booked = TRUE
      WHERE flight_id = NEW.flight_id AND seat_number = NEW.seat_number;
    UPDATE Flights SET available_seats = available_seats - 1 WHERE flight_id = NEW.flight_id;
  END IF;
END$$
DELIMITER ;

-- When booking is updated to CANCELLED, free seat and increment available seats
DELIMITER $$
DROP TRIGGER IF EXISTS trg_booking_after_update$$
CREATE TRIGGER trg_booking_after_update
AFTER UPDATE ON Bookings
FOR EACH ROW
BEGIN
  IF OLD.status = 'CONFIRMED' AND NEW.status = 'CANCELLED' THEN
    UPDATE Seats SET is_booked = FALSE WHERE flight_id = NEW.flight_id AND seat_number = NEW.seat_number;
    UPDATE Flights SET available_seats = available_seats + 1 WHERE flight_id = NEW.flight_id;
  END IF;
END$$
DELIMITER ;

-- Simple flight search by origin, destination, date (date only)
SELECT f.flight_id, f.flight_number, a1.city AS origin_city, a2.city AS dest_city,
       f.departure_time, f.arrival_time, f.available_seats, f.base_price
FROM Flights f
JOIN Airports a1 ON f.origin_id = a1.airport_id
JOIN Airports a2 ON f.destination_id = a2.airport_id
WHERE a1.city = 'New Delhi' AND a2.city = 'Bengaluru' 
  AND DATE(f.departure_time) = '2025-11-10';

CREATE OR REPLACE VIEW vw_daily_bookings AS
SELECT DATE(booking_date) AS book_date,
       COUNT(*) AS total_bookings,
       SUM(price_paid) AS total_revenue
FROM Bookings
WHERE status = 'CONFIRMED'
GROUP BY DATE(booking_date)
ORDER BY book_date;

SELECT * FROM vw_daily_bookings;

CREATE OR REPLACE VIEW vw_flight_load AS
SELECT f.flight_id, f.flight_number,
       f.total_seats,
       f.available_seats,
       ( (f.total_seats - f.available_seats) / f.total_seats ) * 100 AS load_factor_percent
FROM Flights f;

SELECT * FROM vw_flight_load ORDER BY load_factor_percent DESC;

SELECT a1.city AS origin, a2.city AS destination, SUM(b.price_paid) AS revenue
FROM Bookings b
JOIN Flights f ON b.flight_id = f.flight_id
JOIN Airports a1 ON f.origin_id = a1.airport_id
JOIN Airports a2 ON f.destination_id = a2.airport_id
WHERE b.status = 'CONFIRMED'
GROUP BY f.origin_id, f.destination_id
ORDER BY revenue DESC
LIMIT 10;

SELECT b.booking_id, c.full_name, c.email, b.seat_number, b.price_paid, b.booking_date
FROM Bookings b
JOIN Customers c ON b.customer_id = c.customer_id
WHERE b.flight_id = 1
ORDER BY b.booking_date;

-- Replace city names if different
SELECT f.flight_id, f.flight_number, f.departure_time, f.available_seats
FROM Flights f JOIN Airports a1 ON f.origin_id = a1.airport_id JOIN Airports a2 ON f.destination_id = a2.airport_id
WHERE a1.city = 'New Delhi' AND a2.city = 'Bengaluru';

SET @booking_id = 0;
SET @err = '';
CALL sp_make_booking(1, 2, NULL, 5000.00, 'CARD', @booking_id, @err);
SELECT @booking_id AS booking_id, @err AS error;

-- verify
SELECT b.*, c.full_name FROM Bookings b JOIN Customers c ON b.customer_id = c.customer_id WHERE b.booking_id = @booking_id;
SELECT f.flight_id, f.flight_number, f.available_seats FROM Flights f WHERE f.flight_id = 1;
SELECT * FROM Seats WHERE flight_id = 1 AND seat_number = (SELECT seat_number FROM Bookings WHERE booking_id = @booking_id);

SET @msg = '';
CALL sp_cancel_booking(@booking_id, @msg);
SELECT @msg;

-- verify seat freed and available_seats incremented
SELECT * FROM Bookings WHERE booking_id = @booking_id;
SELECT f.flight_id, f.available_seats FROM Flights f WHERE f.flight_id = 1;
SELECT s.* FROM Seats s WHERE s.flight_id = 1 AND s.seat_number = (SELECT seat_number FROM Bookings WHERE booking_id = @booking_id);

