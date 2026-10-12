-- English category names. A few categories have no translation and ~600 products have no category,
-- so fall back to the Portuguese name, then 'unknown'. LEFT JOIN is safe: translation has 1 row per name.
CREATE OR REPLACE TABLE stg_products AS
SELECT
    p.product_id,
    COALESCE(t.product_category_name_english, p.product_category_name, 'unknown') AS category
FROM raw_products p
LEFT JOIN raw_category_translation t USING (product_category_name);
