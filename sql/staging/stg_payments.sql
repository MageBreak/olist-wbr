-- One row per payment. An order can be split across vouchers, cards, installments.
CREATE OR REPLACE TABLE stg_payments AS
SELECT
    order_id,
    CAST(payment_sequential   AS INTEGER)       AS payment_sequential,
    payment_type,
    CAST(payment_installments AS INTEGER)       AS installments,
    CAST(payment_value        AS DECIMAL(12,2)) AS payment_value
FROM raw_payments;
