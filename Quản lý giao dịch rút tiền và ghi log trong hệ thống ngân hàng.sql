-- Tạo bảng
CREATE TABLE accounts (
    account_id SERIAL PRIMARY KEY,
    customer_name VARCHAR(100),
    balance NUMERIC(12,2)
);

CREATE TABLE transactions (
    trans_id SERIAL PRIMARY KEY,
    account_id INT REFERENCES accounts(account_id),
    amount NUMERIC(12,2),
    trans_type VARCHAR(20), -- 'WITHDRAW' hoặc 'DEPOSIT'
    created_at TIMESTAMP DEFAULT NOW()
);

-- Dữ liệu mẫu
INSERT INTO accounts (customer_name, balance) VALUES
('Nguyen Van A', 1000.00),
('Tran Thi B', 500.00);

-- =========================================
-- 1) TRANSACTION rút tiền thành công
-- =========================================
BEGIN;

-- Kiểm tra số dư
DO $$
BEGIN
    IF (SELECT balance FROM accounts WHERE account_id = 1) < 200 THEN
        RAISE EXCEPTION 'So du khong du';
    END IF;
END $$;

-- Trừ số dư
UPDATE accounts
SET balance = balance - 200
WHERE account_id = 1;

-- Ghi log giao dịch
INSERT INTO transactions (account_id, amount, trans_type)
VALUES (1, 200, 'WITHDRAW');

COMMIT;

-- Kiểm tra kết quả
SELECT * FROM accounts;
SELECT * FROM transactions;

-- =========================================
-- 2) MÔ PHỎNG LỖI và ROLLBACK
--    lỗi khi ghi log: sai account_id trong transactions
-- =========================================
BEGIN;

-- Kiểm tra số dư
DO $$
BEGIN
    IF (SELECT balance FROM accounts WHERE account_id = 1) < 100 THEN
        RAISE EXCEPTION 'So du khong du';
    END IF;
END $$;

-- Trừ số dư
UPDATE accounts
SET balance = balance - 100
WHERE account_id = 1;

-- Ghi log lỗi (account_id không tồn tại -> lỗi khóa ngoại)
INSERT INTO transactions (account_id, amount, trans_type)
VALUES (9999, 100, 'WITHDRAW');

ROLLBACK;

-- Kiểm tra lại: số dư không đổi sau rollback
SELECT * FROM accounts;
SELECT * FROM transactions;

-- =========================================
-- 3) Chạy nhiều lần để kiểm tra tính toàn vẹn dữ liệu
-- =========================================

-- Lần 1
BEGIN;
DO $$
BEGIN
    IF (SELECT balance FROM accounts WHERE account_id = 2) < 50 THEN
        RAISE EXCEPTION 'So du khong du';
    END IF;
END $$;

UPDATE accounts
SET balance = balance - 50
WHERE account_id = 2;

INSERT INTO transactions (account_id, amount, trans_type)
VALUES (2, 50, 'WITHDRAW');
COMMIT;

-- Lần 2
BEGIN;
DO $$
BEGIN
    IF (SELECT balance FROM accounts WHERE account_id = 2) < 70 THEN
        RAISE EXCEPTION 'So du khong du';
    END IF;
END $$;

UPDATE accounts
SET balance = balance - 70
WHERE account_id = 2;

INSERT INTO transactions (account_id, amount, trans_type)
VALUES (2, 70, 'WITHDRAW');
COMMIT;

-- Kiểm tra tính toàn vẹn:
-- mỗi dòng log trong transactions phải tương ứng với thay đổi balance
SELECT * FROM accounts;
SELECT * FROM transactions ORDER BY trans_id;