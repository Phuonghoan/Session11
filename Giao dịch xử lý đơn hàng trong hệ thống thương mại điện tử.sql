-- Tạo bảng
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(100),
    stock INT,
    price NUMERIC(10,2)
);

CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_name VARCHAR(100),
    total_amount NUMERIC(10,2),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id INT REFERENCES orders(order_id),
    product_id INT REFERENCES products(product_id),
    quantity INT,
    subtotal NUMERIC(10,2)
);

-- Dữ liệu mẫu
INSERT INTO products (product_name, stock, price) VALUES
('Laptop', 10, 15000000),
('Mouse', 5, 300000),
('Keyboard', 8, 800000);

-- =========================================
-- 1) TRANSACTION đặt hàng cho "Nguyen Van A"
--    mua:
--    product_id = 1, quantity = 2
--    product_id = 2, quantity = 1
-- =========================================
BEGIN;

-- Kiểm tra tồn kho
DO $$
BEGIN
    IF (SELECT stock FROM products WHERE product_id = 1) < 2 THEN
        RAISE EXCEPTION 'Khong du hang cho product_id = 1';
    END IF;

    IF (SELECT stock FROM products WHERE product_id = 2) < 1 THEN
        RAISE EXCEPTION 'Khong du hang cho product_id = 2';
    END IF;
END $$;

-- Tạo đơn hàng
INSERT INTO orders (customer_name, total_amount)
VALUES ('Nguyen Van A', 0);

-- Thêm chi tiết đơn hàng
INSERT INTO order_items (order_id, product_id, quantity, subtotal)
VALUES
(
    currval(pg_get_serial_sequence('orders', 'order_id')),
    1,
    2,
    2 * (SELECT price FROM products WHERE product_id = 1)
),
(
    currval(pg_get_serial_sequence('orders', 'order_id')),
    2,
    1,
    1 * (SELECT price FROM products WHERE product_id = 2)
);

-- Giảm tồn kho
UPDATE products
SET stock = stock - 2
WHERE product_id = 1;

UPDATE products
SET stock = stock - 1
WHERE product_id = 2;

-- Cập nhật total_amount
UPDATE orders
SET total_amount = (
    SELECT SUM(subtotal)
    FROM order_items
    WHERE order_id = currval(pg_get_serial_sequence('orders', 'order_id'))
)
WHERE order_id = currval(pg_get_serial_sequence('orders', 'order_id'));

COMMIT;

-- Kiểm tra kết quả
SELECT * FROM products;
SELECT * FROM orders;
SELECT * FROM order_items;

-- =========================================
-- 2) MÔ PHỎNG LỖI CÓ TRANSACTION
--    Giảm tồn kho sản phẩm 2 xuống 0 rồi thử đặt hàng lại
-- =========================================
UPDATE products
SET stock = 0
WHERE product_id = 2;

BEGIN;

DO $$
BEGIN
    IF (SELECT stock FROM products WHERE product_id = 1) < 2 THEN
        RAISE EXCEPTION 'Khong du hang cho product_id = 1';
    END IF;

    IF (SELECT stock FROM products WHERE product_id = 2) < 1 THEN
        RAISE EXCEPTION 'Khong du hang cho product_id = 2';
    END IF;
END $$;

INSERT INTO orders (customer_name, total_amount)
VALUES ('Nguyen Van A', 0);

INSERT INTO order_items (order_id, product_id, quantity, subtotal)
VALUES
(
    currval(pg_get_serial_sequence('orders', 'order_id')),
    1,
    2,
    2 * (SELECT price FROM products WHERE product_id = 1)
),
(
    currval(pg_get_serial_sequence('orders', 'order_id')),
    2,
    1,
    1 * (SELECT price FROM products WHERE product_id = 2)
);

UPDATE products
SET stock = stock - 2
WHERE product_id = 1;

UPDATE products
SET stock = stock - 1
WHERE product_id = 2;

UPDATE orders
SET total_amount = (
    SELECT SUM(subtotal)
    FROM order_items
    WHERE order_id = currval(pg_get_serial_sequence('orders', 'order_id'))
)
WHERE order_id = currval(pg_get_serial_sequence('orders', 'order_id'));

ROLLBACK;

-- Kiểm tra sau rollback
SELECT * FROM products;
SELECT * FROM orders;
SELECT * FROM order_items;

-- =========================================
-- MÔ PHỎNG KHI KHÔNG CÓ TRANSACTION
-- =========================================

-- reset stock để test
UPDATE products SET stock = 10 WHERE product_id = 1;
UPDATE products SET stock = 0  WHERE product_id = 2;

-- Tạo đơn hàng trước
INSERT INTO orders (customer_name, total_amount)
VALUES ('Nguyen Van A - no transaction', 0);

-- Thêm dòng đầu tiên
INSERT INTO order_items (order_id, product_id, quantity, subtotal)
VALUES
(
    currval(pg_get_serial_sequence('orders', 'order_id')),
    1,
    2,
    2 * (SELECT price FROM products WHERE product_id = 1)
);

-- Giảm tồn kho product 1
UPDATE products
SET stock = stock - 2
WHERE product_id = 1;

-- Dòng thứ 2 bị lỗi logic vì product 2 hết hàng
-- nên ta giả lập kiểu kiểm tra thủ công:
DO $$
BEGIN
    IF (SELECT stock FROM products WHERE product_id = 2) < 1 THEN
        RAISE EXCEPTION 'Khong du hang cho product_id = 2';
    END IF;
END $$;

-- Kiểm tra kết quả:
-- sẽ thấy dữ liệu trước lỗi đã ghi rồi vì không có transaction bao bọc
SELECT * FROM products;
SELECT * FROM orders;
SELECT * FROM order_items;