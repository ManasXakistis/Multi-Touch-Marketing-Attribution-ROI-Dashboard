# Multi-Touch Marketing Attribution & ROI Dashboard

## Overview

This project analyzes marketing campaign and advertising performance data to understand which channels drive the best returns. It builds an end-to-end analytics pipeline in MySQL — from raw data ingestion and advanced SQL analysis, to KPI calculation and star-schema data modeling, and finally an interactive Power BI dashboard for executive decision-making on marketing budget optimization.

The work is delivered in weekly stages: data ingestion and exploration, advanced SQL analytics, metric calculation and dimensional modeling, and BI dashboarding with executive reporting.

## Datasets Used

**1. Marketing Campaign Performance Dataset**

Used for campaign-level performance, funnel tracking, ROI, CAC, and revenue analysis.

Key columns: `CampaignID`, `StartDate`, `EndDate`, `Channel`, `Impressions`, `Clicks`, `Leads`, `Conversions`, `Cost_USD`, `Revenue_USD`, `ROI`

**2. Global Ads Performance Dataset**

Used for platform, country, industry, campaign type, CTR, CPC, and ad spend analysis.

Key columns: `date`, `platform`, `campaign_type`, `industry`, `country`, `impressions`, `clicks`, `CTR`, `CPC`, `ad_spend`

## Tech Stack

- **Database:** MySQL 8.0
- **Querying / Modeling:** SQL (window functions, aggregations, star schema, views)
- **BI / Visualization:** Power BI Desktop (connected to MySQL via MySQL Connector/NET)
- **Version Control:** Git & GitHub

## Project Structure

| File | Description |
|------|-------------|
| `Data/` | Source data folder |
| `global_ads_performance_dataset-selected-columns.csv` | Global ads dataset |
| `marketing_campaign_performance_10000.csv` | Campaign performance dataset |
| `week2_queries.sql` | Advanced SQL analytics (window functions) on the ads dataset |
| `week3_queries.sql` | Core KPI calculations (Total Spend, CPC, CAC, ROAS) |
| `week3_dimensions.sql` | Dimension tables (`dim_channel`, `dim_campaign`, `dim_date`) |
| `week3_fact_table.sql` | Fact table (`fact_campaign_performance`) with foreign keys |
| `week3_bi_views.sql` | BI-ready reporting views for the dashboard |
| `week4_funnel_view.sql` | Funnel view (`vw_funnel`) feeding the conversion funnel visual |
| `dashboard.pbix` | Power BI dashboard |

## Weekly Progress

### Week 1 — Project Setup & Data Understanding
- Defined the project scope, objectives, and dashboard plan.
- Selected and documented the two source datasets (campaign performance and global ads).
- Established the goal: channel-level ROI analysis and budget optimization.

### Week 2 — Advanced SQL Analytics
- Set up the `marketing_analytics` database and loaded the global ads dataset into the `ad_campaigns` table.
- Wrote advanced SQL using **window functions**:
  - `ROW_NUMBER()` to sequence campaign journey steps per platform.
  - `RANK()` / `DENSE_RANK()` to rank campaigns by ad spend.
  - Running totals of spend with `SUM() OVER (...)`.
  - 7-day moving averages of clicks with windowed `AVG()`.

### Week 3 — Metric Calculation & Data Modeling
- Calculated core marketing KPIs: **Total Spend, CPC, CAC, and ROAS** (overall, per-channel, per-campaign, and monthly).
- Modeled the data into a **star schema** for BI:
  - **Dimensions:** `dim_channel`, `dim_campaign`, `dim_date`.
  - **Fact table:** `fact_campaign_performance` linked to dimensions via surrogate keys and foreign keys.
  - **Reporting views:** `vw_campaign_star`, `vw_kpi_overall`, `vw_kpi_by_channel`, `vw_kpi_by_campaign`, `vw_kpi_monthly`.

### Week 4 — BI Dashboarding & Executive Reporting
- Connected **Power BI Desktop** to the MySQL database.
- Built interactive visuals:
  - **Conversion funnel** — Impressions → Clicks → Leads → Conversions.
  - **ROI scatter plot** — spend vs revenue per campaign, colored by channel.
  - **Channel-comparison bar chart** — spend (and other KPIs) by channel.
- *(In progress)* Dashboard assembly, interactive slicers, and an executive summary translating the data into actionable marketing recommendations.

## Key Metrics (KPIs)

| KPI | Definition |
|-----|------------|
| **Total Spend** | Total advertising cost |
| **CPC** (Cost Per Click) | Total spend ÷ total clicks |
| **CAC** (Customer Acquisition Cost) | Total spend ÷ total conversions |
| **ROAS** (Return on Ad Spend) | Total revenue ÷ total spend |

## How to Run

1. Create the database and load the base data (run `week2_queries.sql` for the ads table; load `campaign_performance` for the campaign data).
2. Run the Week 3 scripts in order: `week3_queries.sql` → `week3_dimensions.sql` → `week3_fact_table.sql` → `week3_bi_views.sql`.
3. Run `week4_funnel_view.sql` to create the funnel view.
4. Open `dashboard.pbix` in Power BI Desktop and refresh the MySQL connection to view the dashboard.

