"""Part D charts. Reads SQL results from report/results/ and saves PNGs to report/charts/."""
from pathlib import Path

import matplotlib
matplotlib.use("Agg")  # render to files, no window needed
import matplotlib.pyplot as plt
import pandas as pd
import seaborn as sns

ROOT = Path(__file__).parent
RES = ROOT / "report" / "results"
OUT = ROOT / "report" / "charts"
OUT.mkdir(parents=True, exist_ok=True)
sns.set_theme(style="whitegrid")
RED, BLUE, ORANGE, GREY = "#d62728", "#1f77b4", "#ff7f0e", "#7f7f7f"


def save(fig, name):
    fig.tight_layout()
    fig.savefig(OUT / f"{name}.png", dpi=150)
    plt.close(fig)
    print(f"saved report/charts/{name}.png")


# 1. North Star vs orders placed, weekly
wk = pd.read_csv(RES / "weekly_metrics.csv", parse_dates=["week"])
fig, ax = plt.subplots(figsize=(10, 4.5))
ax.plot(wk["week"], wk["orders"], color=GREY, label="Orders placed")
ax.plot(wk["week"], wk["happy_deliveries"], color=BLUE, lw=2, label="Happy deliveries (North Star)")
ax.fill_between(wk["week"], wk["happy_deliveries"], wk["orders"], color=RED, alpha=0.12,
                label="Gap: not on time with a 4-5 star review")
ax.set_title("Weekly orders vs Happy Deliveries (North Star), Jan 2017 - Aug 2018")
ax.set_xlabel("Purchase week")
ax.set_ylabel("Orders per week")
ax.legend(loc="upper left")
save(fig, "1_north_star_weekly")

# 2. Review score by delivery timing (Part C Q5)
q5 = pd.read_csv(RES / "q5_delivery_delay_vs_review.csv")
q5 = q5[~q5["delay_bucket"].str.contains("ALL")]
labels = q5["delay_bucket"].str[3:]                      # drop the "1. " sort prefix
colors = [RED if "Late" in b else BLUE for b in q5["delay_bucket"]]
fig, ax = plt.subplots(figsize=(10, 4.5))
bars = ax.bar(labels, q5["avg_review_score"], color=colors)
for bar, pct in zip(bars, q5["pct_1_or_2_star"]):
    ax.text(bar.get_x() + bar.get_width() / 2, bar.get_height() + 0.08,
            f"{pct:.0f}% gave 1-2 stars", ha="center", fontsize=9)
ax.set_ylim(0, 5)
ax.set_title("Arriving early earns nothing extra; arriving late destroys the review")
ax.set_xlabel("Delivery vs promised date")
ax.set_ylabel("Average review score (1-5)")
save(fig, "2_review_by_delivery_timing")

# 3. Where late orders lose time
j = pd.read_csv(RES / "i2_late_order_journey.csv").set_index("delivery").loc[["on time / early", "late"]]
fig, ax = plt.subplots(figsize=(10, 3.5))
ax.barh(j.index, j["avg_days_to_handover"], color=ORANGE, label="Seller: purchase -> handover to carrier")
ax.barh(j.index, j["avg_days_in_transit"], left=j["avg_days_to_handover"], color=GREY,
        label="Carrier: handover -> customer")
for i, (h, t) in enumerate(zip(j["avg_days_to_handover"], j["avg_days_in_transit"])):
    ax.text(h / 2, i, f"{h:.0f}d", va="center", ha="center", color="white", fontweight="bold")
    ax.text(h + t / 2, i, f"{t:.0f}d", va="center", ha="center", color="white", fontweight="bold")
ax.set_title("Late orders lose most of their time with the carrier, not the seller")
ax.set_xlabel("Average days")
ax.legend(loc="lower right")
save(fig, "3_late_order_journey")

# 4. Late rate by state vs national average
st = pd.read_csv(RES / "i3_late_rate_by_state.csv").sort_values("late_rate_pct")
national = 100 * j.loc["late", "orders"] / j["orders"].sum()
colors = [RED if r > national else BLUE for r in st["late_rate_pct"]]
fig, ax = plt.subplots(figsize=(8, 6))
ax.barh(st["customer_state"], st["late_rate_pct"], color=colors)
ax.axvline(national, ls="--", color="black", lw=1, label=f"National average ({national:.1f}%)")
ax.set_title("Late-delivery rate by customer state (states with 500+ orders)")
ax.set_xlabel("% of delivered orders that arrived late")
ax.set_ylabel("Customer state")
ax.legend(loc="lower right")
save(fig, "4_late_rate_by_state")
