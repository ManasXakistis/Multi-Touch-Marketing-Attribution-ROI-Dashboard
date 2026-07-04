-- ============================================================
-- 03: Ads Performance KPIs — Correctly Weighted
-- ------------------------------------------------------------
-- IMPORTANT FIX vs. original script:
-- AVG(CTR) and AVG(CPC) across rows give every row equal weight
-- regardless of impression/click volume — a small test campaign
-- and a 10M-impression campaign would count the same. Real CTR/CPC
-- must be ratios of totals:
--     weighted CTR = SUM(clicks)      / SUM(impressions)
--     weighted CPC = SUM(ad_spend)    / SUM(clicks)
--     CPM          = SUM(ad_spend)    / SUM(impressions) * 1000
-- ============================================================

USE marketing_analytics;

-- 3.1 Overall KPIs
SELECT
    COUNT(*)                                                         AS total_records,
    ROUND(SUM(ad_spend), 2)                                          AS total_spend,
    ROUND(SUM(clicks) / NULLIF(SUM(impressions), 0) * 100, 4)        AS weighted_ctr_pct,
    ROUND(SUM(ad_spend) / NULLIF(SUM(clicks), 0), 2)                 AS weighted_cpc,
    ROUND(SUM(ad_spend) / NULLIF(SUM(impressions), 0) * 1000, 2)     AS cpm
FROM ads_performance;

-- 3.2 KPIs by Platform
SELECT
    platform,
    COUNT(*)                                                         AS total_records,
    ROUND(SUM(ad_spend), 2)                                          AS total_spend,
    ROUND(SUM(clicks) / NULLIF(SUM(impressions), 0) * 100, 4)        AS weighted_ctr_pct,
    ROUND(SUM(ad_spend) / NULLIF(SUM(clicks), 0), 2)                 AS weighted_cpc,
    ROUND(SUM(ad_spend) / NULLIF(SUM(impressions), 0) * 1000, 2)     AS cpm
FROM ads_performance
GROUP BY platform
ORDER BY total_spend DESC;

-- 3.3 KPIs by Campaign Type
SELECT
    campaign_type,
    COUNT(*)                                                         AS total_records,
    ROUND(SUM(ad_spend), 2)                                          AS total_spend,
    ROUND(SUM(clicks) / NULLIF(SUM(impressions), 0) * 100, 4)        AS weighted_ctr_pct,
    ROUND(SUM(ad_spend) / NULLIF(SUM(clicks), 0), 2)                 AS weighted_cpc,
    ROUND(SUM(ad_spend) / NULLIF(SUM(impressions), 0) * 1000, 2)     AS cpm
FROM ads_performance
GROUP BY campaign_type
ORDER BY weighted_ctr_pct DESC;

-- 3.4 KPIs by Industry
SELECT
    industry,
    COUNT(*)                                                         AS total_records,
    ROUND(SUM(ad_spend), 2)                                          AS total_spend,
    ROUND(SUM(clicks) / NULLIF(SUM(impressions), 0) * 100, 4)        AS weighted_ctr_pct,
    ROUND(SUM(ad_spend) / NULLIF(SUM(clicks), 0), 2)                 AS weighted_cpc,
    ROUND(SUM(ad_spend) / NULLIF(SUM(impressions), 0) * 1000, 2)     AS cpm
FROM ads_performance
GROUP BY industry
ORDER BY total_spend DESC;

-- 3.5 KPIs by Country
SELECT
    country,
    COUNT(*)                                                         AS total_records,
    ROUND(SUM(ad_spend), 2)                                          AS total_spend,
    ROUND(SUM(clicks) / NULLIF(SUM(impressions), 0) * 100, 4)        AS weighted_ctr_pct,
    ROUND(SUM(ad_spend) / NULLIF(SUM(clicks), 0), 2)                 AS weighted_cpc,
    ROUND(SUM(ad_spend) / NULLIF(SUM(impressions), 0) * 1000, 2)     AS cpm
FROM ads_performance
GROUP BY country
ORDER BY total_spend DESC;

-- 3.6 KPIs by Month
SELECT
    DATE_FORMAT(ad_date, '%Y-%m')                                    AS month,
    ROUND(SUM(ad_spend), 2)                                          AS total_spend,
    ROUND(SUM(clicks) / NULLIF(SUM(impressions), 0) * 100, 4)        AS weighted_ctr_pct,
    ROUND(SUM(ad_spend) / NULLIF(SUM(clicks), 0), 2)                 AS weighted_cpc,
    ROUND(SUM(ad_spend) / NULLIF(SUM(impressions), 0) * 1000, 2)     AS cpm
FROM ads_performance
GROUP BY month
ORDER BY month;

-- 3.7 Platform x Industry breakdown
SELECT
    platform, industry,
    ROUND(SUM(ad_spend), 2)                                          AS total_spend,
    ROUND(SUM(clicks) / NULLIF(SUM(impressions), 0) * 100, 4)        AS weighted_ctr_pct,
    ROUND(SUM(ad_spend) / NULLIF(SUM(clicks), 0), 2)                 AS weighted_cpc
FROM ads_performance
GROUP BY platform, industry
ORDER BY platform, total_spend DESC;

-- 3.8 Best Platform + Campaign Type combinations (min volume filter added —
-- without it, a combination with 2 impressions and 1 lucky click can top the list)
SELECT
    platform, campaign_type,
    SUM(impressions)                                                 AS total_impressions,
    ROUND(SUM(ad_spend), 2)                                          AS total_spend,
    ROUND(SUM(clicks) / NULLIF(SUM(impressions), 0) * 100, 4)        AS weighted_ctr_pct,
    ROUND(SUM(ad_spend) / NULLIF(SUM(clicks), 0), 2)                 AS weighted_cpc
FROM ads_performance
GROUP BY platform, campaign_type
HAVING SUM(impressions) >= 1000
ORDER BY weighted_ctr_pct DESC
LIMIT 20;

-- ============================================================
-- Benchmark view — corrected to weighted ratios
-- ============================================================
CREATE OR REPLACE VIEW vw_ads_benchmark AS
SELECT
    platform, industry, country,
    ROUND(SUM(clicks) / NULLIF(SUM(impressions), 0) * 100, 4)        AS benchmark_ctr_pct,
    ROUND(SUM(ad_spend) / NULLIF(SUM(clicks), 0), 2)                 AS benchmark_cpc,
    ROUND(SUM(ad_spend) / NULLIF(SUM(impressions), 0) * 1000, 2)     AS benchmark_cpm,
    ROUND(SUM(ad_spend), 2)                                          AS total_spend
FROM ads_performance
GROUP BY platform, industry, country;

SELECT * FROM vw_ads_benchmark ORDER BY platform, industry LIMIT 20;
