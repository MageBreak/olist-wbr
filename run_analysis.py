"""Run every Part C query in sql/analysis/ and save results to report/results/<name>.csv.
The answers are computed 100% in SQL; Python only saves the output for the report and charts."""
from pathlib import Path

import duckdb

ROOT = Path(__file__).parent
OUT = ROOT / "report" / "results"
OUT.mkdir(parents=True, exist_ok=True)

con = duckdb.connect(str(ROOT / "olist.duckdb"), read_only=True)
for f in sorted((ROOT / "sql" / "analysis").glob("*.sql")):
    df = con.execute(f.read_text()).df()
    df.to_csv(OUT / f"{f.stem}.csv", index=False)
    print(f"\n=== {f.stem}  ({len(df)} rows -> report/results/{f.stem}.csv) ===")
    print(df.head(12).to_string(index=False))
con.close()
