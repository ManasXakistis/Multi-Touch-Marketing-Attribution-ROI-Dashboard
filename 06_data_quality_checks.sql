-- ============================================================
-- 06: Data Quality Checks
-- Run after every load, before trusting downstream KPI/BI views.
-- Every check should return 0 rows / 0 count in a healthy load.
-- ============================================================

USE marketing_analytics;

-- ---------- ads_performance ----------

-- Impossible engagement: more clicks than impressions
SELECT COUNT(*) AS bad_click_rows
FROM ads_performance
WHERE clicks > impressions;

-- Negative values that shouldn't exist
SELECT COUNT(*) AS negative_value_rows
FROM ads_performance
WHERE impressions < 0 OR clicks < 0 OR ad_spend < 0;

-- Nulls in required dimensions
SELECT COUNT(*) AS null_dimension_rows
FROM ads_performance
WHERE ad_date IS NULL OR platform IS NULL;

-- Source CTR/CPC vs. recomputed values — flags upstream data errors
SELECT id, ad_date, platform, CTR AS source_ctr,
       ROUND(clicks / NULLIF(impressions, 0), 4) AS recomputed_ctr,
       CPC AS source_cpc,
       ROUND(ad_spend / NULLIF(clicks, 0), 2) AS recomputed_cpc
FROM ads_performance
WHERE ABS(CTR - clicks / NULLIF(impressions, 0)) > 0.001
   OR ABS(CPC - ad_spend / NULLIF(clicks, 0)) > 0.01
LIMIT 100;

-- ---------- campaign_performance ----------

SELECT COUNT(*) AS bad_click_rows
FROM campaign_performance
WHERE clicks > impressions;

SELECT COUNT(*) AS negative_value_rows
FROM campaign_performance
WHERE impressions < 0 OR clicks < 0 OR cost_usd < 0 OR revenue_usd < 0;

SELECT COUNT(*) AS end_before_start_rows
FROM campaign_performance
WHERE end_date < start_date;

SELECT campaign_id, COUNT(*) AS dupe_count
FROM campaign_performance
GROUP BY campaign_id
HAVING COUNT(*) > 1;

-- ---------- Star schema referential integrity ----------

-- Rows dropped by the fact-table load's INNER JOINs (should be investigated,
-- not just tolerated, if > 0)
SELECT
    (SELECT COUNT(*) FROM campaign_performance) AS source_rows,
    (SELECT COUNT(*) FROM fact_campaign_performance) AS fact_rows;

-- Orphaned campaign_ids that failed to match dim_campaign / dim_channel / dim_date
SELECT cp.campaign_id
FROM campaign_performance cp
LEFT JOIN dim_campaign dc ON cp.campaign_id = dc.campaign_id
LEFT JOIN dim_channel ch  ON cp.channel = ch.channel
LEFT JOIN dim_date dd     ON cp.start_date = dd.full_date
WHERE dc.campaign_key IS NULL OR ch.channel_key IS NULL OR dd.date_key IS NULL;
