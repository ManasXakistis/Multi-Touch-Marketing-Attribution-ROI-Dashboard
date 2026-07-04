# Business Logic and KPI Definitions (Revised)

## Scope: Two Data Marts

This project draws on two source datasets that do **not** share a join key, so they are modeled as two separate marts rather than one unified schema:

1. **Ads Performance mart** (`ads_performance`) — grain: one row per (date, platform, campaign_type, industry, country). Engagement metrics only: impressions, clicks, CTR, CPC, ad spend. No conversions or revenue at this grain.
2. **Campaign Performance mart** (`campaign_performance` → star schema) — grain: one row per campaign, keyed to channel. Funnel and revenue metrics: leads, conversions, cost, revenue.

Any dashboard combining "platform-level engagement" and "campaign-level ROAS" in one view is combining two different grains and should say so explicitly.

## KPI Definitions

### Total Spend
`SUM(ad_spend)` / `SUM(cost_usd)`. Baseline against which every efficiency ratio is calculated.

### Click-Through Rate (CTR) — Ads Performance mart
**Correct formula:** `SUM(clicks) / SUM(impressions)`, not `AVG(CTR)` across rows.
Averaging the per-row CTR gives a campaign with 50 impressions the same weight as one with 5,000,000 — it distorts the metric toward small, noisy campaigns. Always aggregate the numerator and denominator separately, then divide.

### Cost Per Click (CPC)
**Correct formula:** `SUM(ad_spend) / SUM(clicks)` (same weighting logic as CTR above), not `AVG(CPC)`.

### Cost Per Mille (CPM)
`(SUM(ad_spend) / SUM(impressions)) * 1000`.

### Customer Acquisition Cost (CAC) — Campaign Performance mart
`SUM(cost_usd) / SUM(conversions)`.

### Return on Ad Spend (ROAS) — Campaign Performance mart
`SUM(revenue_usd) / SUM(cost_usd)`.

### `NULLIF(x, 0)`
Used throughout to guard against divide-by-zero when a segment has zero clicks/impressions/spend.

## Star Schema Design (Campaign Performance mart only)

### Fact Table: `fact_campaign_performance`
Grain: **one row per campaign**, keyed to `start_date`. This is a deliberate simplification, not a daily time series — `dim_date` supports day-level granularity, but nothing currently apportions a campaign's spend/revenue across its `start_date`–`end_date` window. Monthly trend views therefore reflect "campaigns bucketed by start month." If true daily trending is needed later, spend must be distributed (e.g., evenly or by an activity curve) across each campaign's date range before loading the fact table.

- `fact_id` (PK), `campaign_key` (FK), `channel_key` (FK), `date_key` (FK)
- `impressions`, `clicks`, `leads`, `conversions`, `cost_usd`, `revenue_usd`

### Dimensions implemented: `dim_date`, `dim_campaign`, `dim_channel`
**Not implemented:** `dim_platform`, `dim_country`, `dim_industry` — the campaign-performance source data has no platform/country/industry fields to hang these on. Those attributes exist only in the separate Ads Performance mart. If a future data source links campaign_id to platform/country/industry, this schema can be extended with a proper `dim_platform` and a bridge, as originally sketched — but it isn't buildable from the current CSVs.

## Data Flow

1. **Ingestion:** raw CSVs land in `stg_*` staging tables via `LOAD DATA LOCAL INFILE` (file path is environment-specific — never hardcode a personal machine path into a checked-in script).
2. **Validation:** `06_data_quality_checks.sql` runs after every load — checks for clicks > impressions, negative values, null keys, duplicate campaign IDs, and source-vs-recomputed CTR/CPC drift.
3. **Load:** staging → target tables via truncate-and-reload, making reruns idempotent (no duplicate accumulation from re-running the pipeline).
4. **Dimensional modeling:** `campaign_performance` → `dim_date` / `dim_campaign` / `dim_channel` / `fact_campaign_performance`.
5. **KPI calculation:** weighted-ratio formulas defined above, applied at the view layer (`vw_kpi_*`).
6. **BI layer:** views feed Power BI / Tableau.

## Known Limitations (carried forward intentionally, not silently fixed)

- Attribution models (first-click, last-click, linear, time-decay, position-based) attribute **ad spend itself** across a journey's touchpoints — a budget-normalized "touchpoint importance" measure — because the Ads Performance mart has no conversion/revenue field to attribute instead. This is not classic conversion-credit MTA; label charts accordingly.
- `fact_campaign_performance` is single-grain-per-campaign; see Star Schema section above.
- The two marts cannot currently be joined into one cross-platform-and-revenue view without new source data linking campaign_id to platform/country/industry.
