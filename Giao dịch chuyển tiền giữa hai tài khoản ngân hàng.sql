-- Tạo bảng và dữ liệu mẫu
CREATE TABLE accounts (
    account_id SERIAL PRIMARY KEY,
    owner_name VARCHAR(100),
    balance NUMERIC(10,2)
);

INSERT INTO accounts (owner_name, balance)
VALUES ('A', 500.00), ('B', 300.00);

-- 1) Giao dịch chuyển tiền hợp lệ
BEGIN;

UPDATE accounts
SET balance = balance - 100.00
WHERE owner_name = 'A';

UPDATE accounts
SET balance = balance + 100.00
WHERE owner_name = 'B';

COMMIT;

-- Kiểm tra số dư mới
SELECT * FROM accounts;

-- 2) Mô phỏng lỗi và rollback
BEGIN;

UPDATE accounts
SET balance = balance - 100.00
WHERE owner_name = 'A';

-- Sai account_id người nhận
UPDATE accounts
SET balance = balance + 100.00
WHERE account_id = 9999;

-- phát hiện lỗi logic: không có tài khoản nhận
ROLLBACK;

-- Kiểm tra lại số dư, đảm bảo không đổi
SELECT * FROM accounts;