"""Run every query in sql/analysis (Part C), sql/insights and sql/metrics (Part D).
Saves each result to report/results/<name>.csv. All answers are computed in SQL;
Python only saves the output for the report and charts."""
from pathlib import Path

import duckdb

ROOT = Path(__file__).parent
OUT = ROOT / "report" / "results"
OUT.mkdir(parents=True, exist_ok=True)

con = duckdb.connect(str(ROOT / "olist.duckdb"), read_only=True)
for folder in ["analysis", "insights", "metrics"]:
    for f in sorted((ROOT / "sql" / folder).glob("*.sql")):
        df = con.execute(f.read_text()).df()
        df.to_csv(OUT / f"{f.stem}.csv", index=False)
        print(f"\n=== {folder}/{f.stem}  ({len(df)} rows) ===")
        print(df.head(12).to_string(index=False))
con.close()
