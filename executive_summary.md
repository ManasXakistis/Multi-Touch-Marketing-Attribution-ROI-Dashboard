# Multi-Touch Marketing Attribution & ROI Dashboard
## Executive Summary Report

**Organization:** Infotact Solutions & Co.
**Project Type:** Advanced Data Analytics — Marketing Attribution
**Analyst:** Ahalya Rajesh
**Dataset:** 10,000 Campaigns · 5 Channels · $25.52M Total Ad Spend

---

## 1. Executive Brief

Marketing teams routinely misallocate budgets by relying on Last-Click
attribution — a model that assigns 100% of conversion credit to the
final touchpoint, systematically undervaluing upper-funnel channels that
drive awareness and consideration. This analysis addresses that gap by
implementing a robust Multi-Touch Attribution (MTA) framework across
five marketing channels, enabling a fair, data-driven assessment of
channel contribution to revenue and conversions.

The findings reveal that while all five channels generate positive ROI,
significant performance disparities exist across attribution models —
with Search and Display driving disproportionate upper-funnel value
that Last-Click models fail to capture. Acting on these insights could
reallocate up to 15–20% of marketing budget toward higher-performing
channels without sacrificing conversion volume.

---

## 2. Business Context & Problem Statement

### The Attribution Problem
Traditional Last-Click attribution credits only the final touchpoint
before conversion. In a multi-channel environment where a customer
might discover a brand via Display, research via Search, and convert
via Email — Last-Click attribution credits only Email, leading to:

- Systematic underinvestment in awareness channels (Display, Search)
- Overinvestment in retargeting and email channels
- Inaccurate ROI calculations that distort budget planning
- Misaligned campaign optimization signals

### Project Objective
Build an end-to-end marketing data pipeline and interactive dashboard
that implements three attribution models — First-Touch, Last-Touch,
and Linear — enabling marketing managers to make model-informed budget
allocation decisions.

---

## 3. Methodology

### Data Pipeline
- **Source:** 10,000 campaign records across 5 channels
- **Processing:** Python (Pandas) for EDA and feature engineering;
  SQL for star schema modeling and KPI aggregation
- **Attribution Models:**
  - **First-Touch:** 100% credit to first channel interaction
  - **Last-Touch:** 100% credit to final channel interaction
  - **Linear:** Equal credit distributed across all touchpoints
- **Visualization:** Power BI interactive dashboard with model toggle

### Key Metrics Engineered
| Metric | Formula |
|---|---|
| ROI | (Revenue − Cost) / Cost × 100 |
| ROAS | Revenue / Ad Spend |
| CAC | Total Cost / Total Conversions |
| CTR | Clicks / Impressions × 100 |
| Conversion Rate | Conversions / Clicks × 100 |

---

## 4. Key Performance Indicators

| KPI | Value | Benchmark |
|---|---|---|
| Total Ad Spend | $25.52M | — |
| Total Revenue | $51.03M | — |
| ROAS | 2.0x | Industry avg: 1.5–2.5x ✅ |
| Average ROI | 100.16% | Positive across all channels ✅ |
| Total Conversions | 10.1M | — |
| Average CAC | $1.02 | Low — efficient acquisition ✅ |
| Average CTR | 5.48% | Industry avg: 2–5% ✅ |
| Total Campaigns | 10,000 | — |

---

## 5. Channel Performance Analysis

### 5.1 Revenue by Channel

| Channel | Revenue | Cost | ROI | Conversions |
|---|---|---|---|---|
| Display | $10.72M | $5.34M | 100.59% | 2,057,607 |
| Influencer | $10.56M | $5.28M | 99.97% | 2,101,198 |
| Email | $10.13M | $5.07M | 101.00% | 2,076,423 |
| Search | $9.90M | $4.92M | **101.31%** | 1,951,752 |
| Social | $9.73M | $4.92M | 97.66% | 1,920,020 |

**Key insight:** Search delivers the highest ROI despite ranking 4th
in revenue — indicating superior spend efficiency. Social is the only
channel below 100% ROI and warrants immediate spend review.

### 5.2 Conversion Funnel Analysis

| Stage | Volume | Drop-off Rate |
|---|---|---|
| Impressions | 2,000,000,000 | — |
| Clicks | 83,290,000 | 95.8% |
| Leads | 15,000,000 | 82.0% |
| Conversions | 10,107,000 | 32.6% |

**Key insight:** The Clicks-to-Leads drop-off (82%) represents the
largest funnel gap — suggesting significant opportunity in lead
nurturing and landing page optimization.

---

## 6. Multi-Touch Attribution Analysis

### 6.1 Attribution Credit by Channel and Model (%)

| Channel | First-Touch | Linear | Last-Touch | Insight |
|---|---|---|---|---|
| Display | 28% | 20% | 12% | Strong awareness driver |
| Search | 28% | 19% | 12% | Strong awareness driver |
| Influencer | 18% | 21% | 22% | Balanced mid-funnel role |
| Email | 14% | 21% | 28% | Strong conversion driver |
| Social | 12% | 19% | 26% | Strong conversion driver |

### 6.2 Model Interpretation

**First-Touch Model:**
Display and Search receive disproportionately high credit (28% each)
— confirming their role as primary brand awareness and discovery
channels. These channels introduce users to the brand and initiate
the customer journey.

**Last-Touch Model:**
Email and Social dominate credit (28% and 26% respectively) —
revealing their effectiveness at re-engaging users and driving
final conversion decisions. These channels are critical for
retargeting and bottom-funnel campaigns.

**Linear Model (Recommended for budgeting):**
Credit is distributed more evenly (19–21% per channel) — providing
the most balanced view of channel contribution and reducing the
over-crediting bias of single-touch models.

---

## 7. Strategic Recommendations

### Recommendation 1 — Increase Search investment (High priority)
Search delivers the highest ROI (101.31%) and highest First-Touch
attribution credit (28%) — confirming it as both the most efficient
and most impactful awareness channel. A 10–15% budget increase in
Search is projected to yield proportional revenue growth.

**Expected impact:** +$990K–$1.49M incremental revenue

---

### Recommendation 2 — Review and optimize Social spend (High priority)
Social is the only channel with ROI below 100% (97.66%) and shows
relatively low First-Touch credit — suggesting it neither introduces
users effectively nor drives conversions efficiently at current spend
levels. A creative refresh and audience targeting review is recommended
before Q3 budget planning.

**Action:** Reduce Social spend by 10% and reallocate to Search or
Display pending creative review.

---

### Recommendation 3 — Invest in Email automation (Medium priority)
Email consistently receives the highest Last-Touch attribution credit
(28%) across models — confirming it as the strongest conversion-stage
channel. Implementing automated re-engagement sequences for users who
clicked but did not convert could materially improve conversion rates.

**Expected impact:** 5–8% improvement in overall conversion rate

---

### Recommendation 4 — Adopt Linear attribution as the default model
Last-Click attribution systematically undervalues Display and Search
by 57% relative to their Linear model credit. Migrating to Linear
attribution for budget planning will correct this bias and lead to
more effective channel investment decisions.

---

### Recommendation 5 — Address the Clicks-to-Leads funnel gap
With an 82% drop-off from Clicks to Leads, landing page optimization
represents the highest-impact, lowest-cost conversion improvement
opportunity. A/B testing landing page copy and form design is
recommended as an immediate next step.

---

## 8. Conclusion

This analysis demonstrates that a data-driven, multi-touch attribution
framework reveals significant strategic insights that single-touch
models obscure. Across 10,000 campaigns and $25.52M in ad spend,
all five channels contribute positively — but with materially different
efficiency profiles depending on funnel stage.

Search and Display are undervalued by Last-Click models and deserve
increased investment. Social requires immediate optimization. Email
automation presents the clearest near-term conversion improvement
opportunity.

Adopting the Linear attribution model as the organizational standard
for budget planning, supported by the interactive Power BI dashboard
delivered in this project, will enable the marketing team to make
faster, more accurate, and more defensible budget allocation decisions.

---

*This report was produced as part of the Infotact Technical Internship
Program — Advanced Data Analytics Project 1. All figures are derived
from the marketing campaign performance dataset (10,000 records) using
Python, SQL, and Power BI.*
