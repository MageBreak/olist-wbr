"""Olist ELT pipeline: raw CSVs -> raw_* tables -> stg_* -> DQ checks -> mart."""
import logging
import sys
from pathlib import Path

import duckdb

ROOT = Path(__file__).parent
RAW_DIR = ROOT / "data" / "raw"
DB_PATH = ROOT / "olist.duckdb"
SQL_DIR = ROOT / "sql"

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(message)s",
    handlers=[logging.StreamHandler(), logging.FileHandler(ROOT / "pipeline.log")],
)
log = logging.getLogger("olist")

# table name -> (csv file, columns the rest of the pipeline depends on)
SOURCES = {
    "orders": ("olist_orders_dataset.csv",
               ["order_id", "customer_id", "order_status", "order_purchase_timestamp",
                "order_delivered_customer_date", "order_estimated_delivery_date"]),
    "order_items": ("olist_order_items_dataset.csv",
                    ["order_id", "order_item_id", "product_id", "seller_id", "price", "freight_value"]),
    "payments": ("olist_order_payments_dataset.csv",
                 ["order_id", "payment_sequential", "payment_type", "payment_value"]),
    "reviews": ("olist_order_reviews_dataset.csv",
                ["review_id", "order_id", "review_score", "review_creation_date"]),
    "customers": ("olist_customers_dataset.csv",
                  ["customer_id", "customer_unique_id", "customer_state"]),
    "sellers": ("olist_sellers_dataset.csv", ["seller_id", "seller_state"]),
    "products": ("olist_products_dataset.csv", ["product_id", "product_category_name"]),
    "category_translation": ("product_category_name_translation.csv",
                             ["product_category_name", "product_category_name_english"]),
    "geolocation": ("olist_geolocation_dataset.csv", ["geolocation_zip_code_prefix"]),
}


def load_raw(con):
    """Load every CSV as-is (all text). CREATE OR REPLACE makes reruns idempotent."""
    for table, (fname, expected_cols) in SOURCES.items():
        path = RAW_DIR / fname
        if not path.exists():
            raise FileNotFoundError(
                f"Missing source file: {path}. Download the Olist dataset into data/raw/ (see README)."
            )

        con.execute(f"""
            CREATE OR REPLACE TABLE raw_{table} AS
            SELECT * FROM read_csv('{path}', header = true, all_varchar = true)
        """)

        cols = {c.lstrip("\ufeff") for c, *_ in con.execute(f"DESCRIBE raw_{table}").fetchall()}
        missing = set(expected_cols) - cols
        if missing:
            raise ValueError(f"{fname} is missing expected column(s): {sorted(missing)}")

        n = con.execute(f"SELECT COUNT(*) FROM raw_{table}").fetchone()[0]
        log.info("raw_%-22s %10s rows", table, f"{n:,}")


def run_sql_folder(con, folder):
    """Run every .sql file in sql/<folder>/ in name order. Each file builds the table it's named after."""
    files = sorted((SQL_DIR / folder).glob("*.sql"))
    if not files:
        raise FileNotFoundError(f"No .sql files found in sql/{folder}/")
    for f in files:
        try:
            con.execute(f.read_text())
        except duckdb.Error as e:
            raise RuntimeError(f"SQL failed in {f.name}: {e}") from e
        n = con.execute(f"SELECT COUNT(*) FROM {f.stem}").fetchone()[0]
        log.info("%-26s %10s rows", f.stem, f"{n:,}")


def main():
    log.info("=== Pipeline start ===")
    con = duckdb.connect(str(DB_PATH))
    try:
        log.info("Step 1/4: load raw tables")
        load_raw(con)
        log.info("Step 2/4: build staging tables")
        run_sql_folder(con, "staging")
        log.info("=== Pipeline finished OK ===")
    except Exception as e:
        log.error("PIPELINE FAILED: %s", e)
        sys.exit(1)  # non-zero exit = Airflow/cron know it failed
    finally:
        con.close()


if __name__ == "__main__":
    main()
