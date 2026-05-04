-- Tạo bảng và dữ liệu mẫu
CREATE TABLE flights (
    flight_id SERIAL PRIMARY KEY,
    flight_name VARCHAR(100),
    available_seats INT
);

CREATE TABLE bookings (
    booking_id SERIAL PRIMARY KEY,
    flight_id INT REFERENCES flights(flight_id),
    customer_name VARCHAR(100)
);

INSERT INTO flights (flight_name, available_seats)
VALUES ('VN123', 3), ('VN456', 2);

-- 1) Transaction đặt vé thành công
BEGIN;

UPDATE flights
SET available_seats = available_seats - 1
WHERE flight_name = 'VN123';

INSERT INTO bookings (flight_id, customer_name)
SELECT flight_id, 'Nguyen Van A'
FROM flights
WHERE flight_name = 'VN123';

COMMIT;

-- Kiểm tra lại dữ liệu
SELECT * FROM flights;
SELECT * FROM bookings;

-- 2) Mô phỏng lỗi và ROLLBACK
BEGIN;

UPDATE flights
SET available_seats = available_seats - 1
WHERE flight_name = 'VN123';

-- nhập sai flight_id để gây lỗi khóa ngoại
INSERT INTO bookings (flight_id, customer_name)
VALUES (9999, 'Tran Van B');

ROLLBACK;

-- Kiểm tra lại dữ liệu, số ghế không đổi sau rollback
SELECT * FROM flights;
SELECT * FROM bookings;