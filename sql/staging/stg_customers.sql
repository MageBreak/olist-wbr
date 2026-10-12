-- customer_id = one per ORDER. customer_unique_id = the actual person. (Part C Q4 depends on this.)
CREATE OR REPLACE TABLE stg_customers AS
SELECT
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix AS zip_prefix,
    customer_city            AS city,
    customer_state           AS state
FROM raw_customers;
