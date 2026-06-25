-- ============================================================
-- Week 3 | Base Queries & KPI Analysis
-- Project: Multi-Touch Marketing Attribution & ROI Dashboard
-- ============================================================

CREATE DATABASE IF NOT EXISTS marketing_analytics;
USE marketing_analytics;

DROP TABLE IF EXISTS campaign_performance;

CREATE TABLE campaign_performance (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    campaign_id   VARCHAR(20),
    start_date    DATE,
    end_date      DATE,
    channel       VARCHAR(50),
    impressions   INT,
    clicks        INT,
    leads         INT,
    conversions   INT,
    cost_usd      DECIMAL(12,2),
    revenue_usd   DECIMAL(12,2),
    roi           DECIMAL(8,4)
);

SET GLOBAL local_infile = 1;

LOAD DATA LOCAL INFILE './data/marketing_campaign_performance_10000.csv'
INTO TABLE campaign_performance
FIELDS TERMINATED BY ','
LINES  TERMINATED BY '\n'
IGNORE 1 ROWS
(campaign_id, @start_date, @end_date, channel,
 impressions, clicks, leads, conversions,
 cost_usd, revenue_usd, roi)
SET start_date = STR_TO_DATE(@start_date, '%d-%m-%Y'),
    end_date   = STR_TO_DATE(@end_date,   '%d-%m-%Y');


SELECT COUNT(*) AS total_rows_loaded FROM campaign_performance;


-- ============================================================
-- KPI CALCULATIONS
-- ============================================================

-- KPI formulas:
-- Total Spend = SUM(cost) -> total money spent on ads
-- CPC = SUM(cost) / SUM(clicks) -> cost per click
-- CAC = SUM(cost) / SUM(conversions) -> cost to acquire 1 customer
-- ROAS = SUM(revenue) / SUM(cost) -> revenue earned per $1 spent
-- NULLIF(...,0) -> guards against divide-by-zero errors.


-- 1. Overall KPIs
SELECT
    ROUND(SUM(cost_usd), 2) AS total_spend,
    ROUND(SUM(cost_usd) / NULLIF(SUM(clicks), 0), 2) AS cpc,
    ROUND(SUM(cost_usd) / NULLIF(SUM(conversions), 0), 2) AS cac,
    ROUND(SUM(revenue_usd) / NULLIF(SUM(cost_usd), 0), 2) AS roas
FROM campaign_performance;


-- 2. KPIs by Channel
SELECT
    channel,
    ROUND(SUM(cost_usd), 2) AS total_spend,
    ROUND(SUM(cost_usd) / NULLIF(SUM(clicks), 0), 2) AS cpc,
    ROUND(SUM(cost_usd) / NULLIF(SUM(conversions), 0), 2) AS cac,
    ROUND(SUM(revenue_usd) / NULLIF(SUM(cost_usd), 0), 2) AS roas
FROM campaign_performance
GROUP BY channel
ORDER BY roas DESC;


-- 3. KPIs by Campaign (Top 50 by ROAS)
SELECT
    campaign_id,
    channel,
    ROUND(cost_usd, 2) AS total_spend,
    ROUND(cost_usd / NULLIF(clicks, 0), 2) AS cpc,
    ROUND(cost_usd / NULLIF(conversions, 0), 2) AS cac,
    ROUND(revenue_usd / NULLIF(cost_usd, 0), 2) AS roas
FROM campaign_performance
ORDER BY roas DESC
LIMIT 50;


-- 4. KPIs by Month
SELECT
    DATE_FORMAT(start_date, '%Y-%m') AS month,
    ROUND(SUM(cost_usd), 2) AS total_spend,
    ROUND(SUM(cost_usd) / NULLIF(SUM(clicks), 0), 2) AS cpc,
    ROUND(SUM(cost_usd) / NULLIF(SUM(conversions), 0), 2) AS cac,
    ROUND(SUM(revenue_usd) / NULLIF(SUM(cost_usd), 0), 2) AS roas
FROM campaign_performance
GROUP BY month
ORDER BY month;
