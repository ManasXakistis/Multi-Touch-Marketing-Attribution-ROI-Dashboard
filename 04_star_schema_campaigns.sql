-- ============================================================
-- 04: Star Schema for the Campaign Performance Mart
-- ------------------------------------------------------------
-- NOTE on scope: this mart is built from `campaign_performance`
-- (channel grain, funnel + revenue metrics: leads, conversions,
-- revenue). It is intentionally a SEPARATE data mart from
-- `ads_performance` (platform/industry/country grain, engagement
-- metrics only: impressions, clicks, CTR, CPC). The two source
-- CSVs don't share a join key, so treat these as two dashboards,
-- not one unified schema, unless a real campaign<->platform
-- mapping is added upstream.
--
-- GRAIN CAVEAT: fact_campaign_performance carries one row per
-- campaign_id, keyed to its start_date. Monthly/quarterly trend
-- views therefore reflect "campaigns bucketed by start month,"
-- not true daily spend distribution across each campaign's
-- start_date -> end_date window. If daily-level trending is
-- needed, spend/revenue must be apportioned across the campaign's
-- date range before loading the fact table.
-- ============================================================

USE marketing_analytics;

-- ---------- dim_channel ----------
DROP TABLE IF EXISTS dim_channel;

CREATE TABLE dim_channel (
    channel_key INT AUTO_INCREMENT PRIMARY KEY,
    channel VARCHAR(50) NOT NULL UNIQUE
);

INSERT INTO dim_channel (channel)
SELECT DISTINCT channel
FROM campaign_performance
WHERE channel IS NOT NULL
ORDER BY channel;

-- ---------- dim_campaign ----------
DROP TABLE IF EXISTS dim_campaign;

CREATE TABLE dim_campaign (
    campaign_key INT AUTO_INCREMENT PRIMARY KEY,
    campaign_id VARCHAR(20) NOT NULL UNIQUE,
    channel VARCHAR(50),
    start_date DATE,
    end_date DATE,
    campaign_duration_days INT
);

INSERT INTO dim_campaign
    (campaign_id, channel, start_date, end_date, campaign_duration_days)
SELECT DISTINCT
    campaign_id, channel, start_date, end_date,
    DATEDIFF(end_date, start_date) AS campaign_duration_days
FROM campaign_performance
WHERE campaign_id IS NOT NULL;

-- ---------- dim_date ----------
DROP TABLE IF EXISTS dim_date;

CREATE TABLE dim_date (
    date_key INT PRIMARY KEY,
    full_date DATE NOT NULL UNIQUE,
    year INT,
    quarter INT,
    month INT,
    month_name VARCHAR(20),
    day INT,
    day_name VARCHAR(20),
    week_of_year INT
);

INSERT INTO dim_date
    (date_key, full_date, year, quarter, month, month_name, day, day_name, week_of_year)
SELECT
    CAST(DATE_FORMAT(d, '%Y%m%d') AS UNSIGNED),
    d, YEAR(d), QUARTER(d), MONTH(d), MONTHNAME(d), DAY(d), DAYNAME(d), WEEK(d, 3)
FROM (
    SELECT DISTINCT start_date AS d FROM campaign_performance WHERE start_date IS NOT NULL
    UNION
    SELECT DISTINCT end_date   AS d FROM campaign_performance WHERE end_date IS NOT NULL
) AS all_dates
ORDER BY d;

-- ---------- fact_campaign_performance ----------
DROP TABLE IF EXISTS fact_campaign_performance;

CREATE TABLE fact_campaign_performance (
    fact_id INT AUTO_INCREMENT PRIMARY KEY,
    campaign_key INT NOT NULL,
    channel_key INT NOT NULL,
    date_key INT NOT NULL,
    impressions INT,
    clicks INT,
    leads INT,
    conversions INT,
    cost_usd DECIMAL(12,2),
    revenue_usd DECIMAL(12,2),
    CONSTRAINT fk_fact_campaign FOREIGN KEY (campaign_key) REFERENCES dim_campaign(campaign_key),
    CONSTRAINT fk_fact_channel  FOREIGN KEY (channel_key)  REFERENCES dim_channel(channel_key),
    CONSTRAINT fk_fact_date     FOREIGN KEY (date_key)     REFERENCES dim_date(date_key)
    -- InnoDB automatically indexes FK columns; no extra index needed here.
);

INSERT INTO fact_campaign_performance
    (campaign_key, channel_key, date_key,
     impressions, clicks, leads, conversions, cost_usd, revenue_usd)
SELECT
    dc.campaign_key, ch.channel_key, dd.date_key,
    cp.impressions, cp.clicks, cp.leads, cp.conversions, cp.cost_usd, cp.revenue_usd
FROM campaign_performance cp
JOIN dim_campaign dc ON cp.campaign_id = dc.campaign_id
JOIN dim_channel ch  ON cp.channel     = ch.channel
JOIN dim_date dd     ON cp.start_date  = dd.full_date;

-- ---------- Load reconciliation (should match; flags silent join drops) ----------
SELECT
    (SELECT COUNT(*) FROM campaign_performance)         AS source_rows,
    (SELECT COUNT(*) FROM fact_campaign_performance)    AS fact_rows,
    (SELECT COUNT(*) FROM campaign_performance) -
    (SELECT COUNT(*) FROM fact_campaign_performance)    AS rows_dropped_by_join;

-- ============================================================
-- BI Views
-- ============================================================

CREATE OR REPLACE VIEW vw_campaign_star AS
SELECT
    f.fact_id, dc.campaign_id, ch.channel,
    dd.full_date, dd.year, dd.quarter, dd.month, dd.month_name,
    f.impressions, f.clicks, f.leads, f.conversions, f.cost_usd, f.revenue_usd
FROM fact_campaign_performance f
JOIN dim_campaign dc ON f.campaign_key = dc.campaign_key
JOIN dim_channel ch  ON f.channel_key  = ch.channel_key
JOIN dim_date dd     ON f.date_key     = dd.date_key;

CREATE OR REPLACE VIEW vw_kpi_overall AS
SELECT
    ROUND(SUM(cost_usd), 2)                                    AS total_spend,
    ROUND(SUM(cost_usd) / NULLIF(SUM(clicks), 0), 2)           AS cpc,
    ROUND(SUM(cost_usd) / NULLIF(SUM(conversions), 0), 2)      AS cac,
    ROUND(SUM(revenue_usd) / NULLIF(SUM(cost_usd), 0), 2)      AS roas
FROM fact_campaign_performance;

CREATE OR REPLACE VIEW vw_kpi_by_channel AS
SELECT
    ch.channel,
    ROUND(SUM(f.cost_usd), 2)                                  AS total_spend,
    ROUND(SUM(f.cost_usd) / NULLIF(SUM(f.clicks), 0), 2)       AS cpc,
    ROUND(SUM(f.cost_usd) / NULLIF(SUM(f.conversions), 0), 2)  AS cac,
    ROUND(SUM(f.revenue_usd) / NULLIF(SUM(f.cost_usd), 0), 2)  AS roas
FROM fact_campaign_performance f
JOIN dim_channel ch ON f.channel_key = ch.channel_key
GROUP BY ch.channel;

-- FIX: original view returned one row per fact_id (i.e. per campaign,
-- since grain is one fact row per campaign) but didn't aggregate, which
-- silently breaks the moment a campaign has more than one fact row.
-- Explicit GROUP BY makes this a true per-campaign summary regardless
-- of grain changes upstream.
CREATE OR REPLACE VIEW vw_kpi_by_campaign AS
SELECT
    dc.campaign_id, ch.channel,
    ROUND(SUM(f.cost_usd), 2)                                  AS total_spend,
    ROUND(SUM(f.cost_usd) / NULLIF(SUM(f.clicks), 0), 2)       AS cpc,
    ROUND(SUM(f.cost_usd) / NULLIF(SUM(f.conversions), 0), 2)  AS cac,
    ROUND(SUM(f.revenue_usd) / NULLIF(SUM(f.cost_usd), 0), 2)  AS roas
FROM fact_campaign_performance f
JOIN dim_campaign dc ON f.campaign_key = dc.campaign_key
JOIN dim_channel ch  ON f.channel_key  = ch.channel_key
GROUP BY dc.campaign_id, ch.channel;

CREATE OR REPLACE VIEW vw_kpi_monthly AS
SELECT
    dd.year, dd.month, dd.month_name,
    ROUND(SUM(f.cost_usd), 2)                                  AS total_spend,
    ROUND(SUM(f.cost_usd) / NULLIF(SUM(f.clicks), 0), 2)       AS cpc,
    ROUND(SUM(f.cost_usd) / NULLIF(SUM(f.conversions), 0), 2)  AS cac,
    ROUND(SUM(f.revenue_usd) / NULLIF(SUM(f.cost_usd), 0), 2)  AS roas
FROM fact_campaign_performance f
JOIN dim_date dd ON f.date_key = dd.date_key
GROUP BY dd.year, dd.month, dd.month_name;

SELECT * FROM vw_kpi_overall;
SELECT * FROM vw_kpi_by_channel ORDER BY roas DESC;
SELECT * FROM vw_kpi_monthly ORDER BY year, month;
SELECT * FROM vw_kpi_by_campaign ORDER BY roas DESC LIMIT 20;
