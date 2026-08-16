-- ============================================================
-- Week 3 | Global Ads Performance — Table, Load & KPI Queries
-- Project: Multi-Touch Marketing Attribution & ROI Dashboard
-- Dataset: global_ads_performance_dataset-selected-columns.csv
-- ============================================================

USE marketing_analytics;

-- ============================================================
-- STEP 1: Create Ads Performance Table
-- ============================================================

DROP TABLE IF EXISTS ads_performance;

CREATE TABLE ads_performance (
    id             INT AUTO_INCREMENT PRIMARY KEY,
    ad_date        DATE,
    platform       VARCHAR(50),
    campaign_type  VARCHAR(50),
    industry       VARCHAR(50),
    country        VARCHAR(50),
    impressions    INT,
    clicks         INT,
    CTR            DECIMAL(8, 4),
    CPC            DECIMAL(8, 2),
    ad_spend       DECIMAL(12, 2)
);


-- ============================================================
-- STEP 2: Load CSV Data
-- ============================================================

SET GLOBAL local_infile = 1;

LOAD DATA LOCAL INFILE './data/global_ads_performance_dataset-selected-columns.csv'
INTO TABLE ads_performance
FIELDS TERMINATED BY ','
LINES  TERMINATED BY '\n'
IGNORE 1 ROWS
(
    @ad_date, platform, campaign_type, industry, country,
    impressions, clicks, CTR, CPC, ad_spend
)
SET ad_date = STR_TO_DATE(@ad_date, '%Y-%m-%d');

-- Verify load
SELECT COUNT(*) AS total_rows_loaded FROM ads_performance;
SELECT * FROM ads_performance LIMIT 5;


-- ============================================================
-- STEP 3: KPI Queries
-- ============================================================

-- KPI formulas:
-- CTR  = Clicks / Impressions (already in dataset)
-- CPC  = Ad Spend / Clicks (already in dataset)
-- CPM  = (Ad Spend / Impressions) * 1000 -> cost per 1000 impressions
-- Total Spend = SUM(ad_spend)
-- NULLIF(...,0) -> guards against divide-by-zero errors


-- 3.1 Overall KPIs across all platforms
SELECT
    COUNT(*)                                                        AS total_records,
    ROUND(SUM(ad_spend), 2)                                        AS total_spend,
    ROUND(AVG(CTR) * 100, 4)                                       AS avg_ctr_pct,
    ROUND(AVG(CPC), 2)                                             AS avg_cpc,
    ROUND((SUM(ad_spend) / NULLIF(SUM(impressions), 0)) * 1000, 2) AS cpm
FROM ads_performance;


-- 3.2 KPIs by Platform
SELECT
    platform,
    COUNT(*)                                                        AS total_records,
    ROUND(SUM(ad_spend), 2)                                        AS total_spend,
    ROUND(AVG(CTR) * 100, 4)                                       AS avg_ctr_pct,
    ROUND(AVG(CPC), 2)                                             AS avg_cpc,
    ROUND((SUM(ad_spend) / NULLIF(SUM(impressions), 0)) * 1000, 2) AS cpm
FROM ads_performance
GROUP BY platform
ORDER BY total_spend DESC;


-- 3.3 KPIs by Campaign Type
SELECT
    campaign_type,
    COUNT(*)                                                        AS total_records,
    ROUND(SUM(ad_spend), 2)                                        AS total_spend,
    ROUND(AVG(CTR) * 100, 4)                                       AS avg_ctr_pct,
    ROUND(AVG(CPC), 2)                                             AS avg_cpc,
    ROUND((SUM(ad_spend) / NULLIF(SUM(impressions), 0)) * 1000, 2) AS cpm
FROM ads_performance
GROUP BY campaign_type
ORDER BY avg_ctr_pct DESC;


-- 3.4 KPIs by Industry
SELECT
    industry,
    COUNT(*)                                                        AS total_records,
    ROUND(SUM(ad_spend), 2)                                        AS total_spend,
    ROUND(AVG(CTR) * 100, 4)                                       AS avg_ctr_pct,
    ROUND(AVG(CPC), 2)                                             AS avg_cpc,
    ROUND((SUM(ad_spend) / NULLIF(SUM(impressions), 0)) * 1000, 2) AS cpm
FROM ads_performance
GROUP BY industry
ORDER BY total_spend DESC;


-- 3.5 KPIs by Country
SELECT
    country,
    COUNT(*)                                                        AS total_records,
    ROUND(SUM(ad_spend), 2)                                        AS total_spend,
    ROUND(AVG(CTR) * 100, 4)                                       AS avg_ctr_pct,
    ROUND(AVG(CPC), 2)                                             AS avg_cpc,
    ROUND((SUM(ad_spend) / NULLIF(SUM(impressions), 0)) * 1000, 2) AS cpm
FROM ads_performance
GROUP BY country
ORDER BY total_spend DESC;


-- 3.6 KPIs by Month
SELECT
    DATE_FORMAT(ad_date, '%Y-%m')                                   AS month,
    ROUND(SUM(ad_spend), 2)                                        AS total_spend,
    ROUND(AVG(CTR) * 100, 4)                                       AS avg_ctr_pct,
    ROUND(AVG(CPC), 2)                                             AS avg_cpc,
    ROUND((SUM(ad_spend) / NULLIF(SUM(impressions), 0)) * 1000, 2) AS cpm
FROM ads_performance
GROUP BY month
ORDER BY month;


-- 3.7 Platform x Industry breakdown
SELECT
    platform,
    industry,
    ROUND(SUM(ad_spend), 2)   AS total_spend,
    ROUND(AVG(CTR) * 100, 4)  AS avg_ctr_pct,
    ROUND(AVG(CPC), 2)        AS avg_cpc
FROM ads_performance
GROUP BY platform, industry
ORDER BY platform, total_spend DESC;


-- 3.8 Best performing Platform + Campaign Type combinations
SELECT
    platform,
    campaign_type,
    ROUND(SUM(ad_spend), 2)   AS total_spend,
    ROUND(AVG(CTR) * 100, 4)  AS avg_ctr_pct,
    ROUND(AVG(CPC), 2)        AS avg_cpc
FROM ads_performance
GROUP BY platform, campaign_type
ORDER BY avg_ctr_pct DESC
LIMIT 20;


-- ============================================================
-- STEP 4: Benchmark View (for Dashboard comparison)
-- ============================================================

-- This view gives global benchmark KPIs per platform
-- Used to compare campaign_performance dataset against industry averages

CREATE OR REPLACE VIEW vw_ads_benchmark AS
SELECT
    platform,
    industry,
    country,
    ROUND(AVG(CTR) * 100, 4)                                       AS benchmark_ctr_pct,
    ROUND(AVG(CPC), 2)                                             AS benchmark_cpc,
    ROUND((SUM(ad_spend) / NULLIF(SUM(impressions), 0)) * 1000, 2) AS benchmark_cpm,
    ROUND(SUM(ad_spend), 2)                                        AS total_spend
FROM ads_performance
GROUP BY platform, industry, country;

-- Preview benchmark view
SELECT * FROM vw_ads_benchmark ORDER BY platform, industry LIMIT 20;
