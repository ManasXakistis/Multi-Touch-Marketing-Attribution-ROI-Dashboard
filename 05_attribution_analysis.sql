-- ============================================================
-- 05: Multi-Touch Attribution & Window-Function Analysis
-- ------------------------------------------------------------
-- FIX: every window function below is ordered by `date` alone.
-- When two touchpoints share a date (common at real volume),
-- MySQL does not guarantee a stable order, so journey_step /
-- rank can flip between runs and your attribution numbers stop
-- being reproducible. Every ORDER BY now includes `id` as a
-- deterministic tiebreaker.
--
-- MODELING NOTE: these models attribute *ad_spend itself* across
-- a journey's touchpoints (a budget-normalized "touchpoint
-- importance" view), not conversion credit — this dataset has no
-- conversion/revenue field at the ad_campaigns grain to attribute
-- instead. If you get access to conversion data at this grain,
-- swap `ad_spend` for `conversions` or `revenue` in the weight
-- calculations below to get classic MTA credit-assignment output.
-- ============================================================

USE marketing_analytics;

-- ---------- Journey step (deterministic) ----------
-- (uses the ads_performance table from 01_load_ads_performance.sql;
--  swap in `ad_campaigns` if you're running against the week2 table)
WITH journey AS (
    SELECT
        id, industry, platform, campaign_type, ad_spend, ad_date,
        ROW_NUMBER() OVER (PARTITION BY industry ORDER BY ad_date ASC, id ASC) AS journey_step,
        COUNT(*) OVER (PARTITION BY industry) AS total_steps
    FROM ads_performance
)
SELECT * FROM journey ORDER BY industry, journey_step LIMIT 50;

-- ---------- First-click attribution ----------
WITH journey AS (
    SELECT
        id, industry, platform, campaign_type, ad_spend, ad_date,
        ROW_NUMBER() OVER (PARTITION BY industry ORDER BY ad_date ASC, id ASC) AS journey_step
    FROM ads_performance
)
SELECT
    industry, platform, campaign_type, ad_date, journey_step, ad_spend,
    CASE WHEN journey_step = 1 THEN 1.0 ELSE 0.0 END AS first_click_weight,
    CASE WHEN journey_step = 1 THEN ad_spend ELSE 0.0 END AS attributed_spend_first_click
FROM journey
ORDER BY industry, journey_step;

-- ---------- Last-click attribution ----------
WITH journey AS (
    SELECT
        id, industry, platform, campaign_type, ad_spend, ad_date,
        ROW_NUMBER() OVER (PARTITION BY industry ORDER BY ad_date ASC, id ASC) AS journey_step,
        COUNT(*) OVER (PARTITION BY industry) AS total_steps
    FROM ads_performance
)
SELECT
    industry, platform, campaign_type, ad_date, journey_step, ad_spend,
    CASE WHEN journey_step = total_steps THEN 1.0 ELSE 0.0 END AS last_click_weight,
    CASE WHEN journey_step = total_steps THEN ad_spend ELSE 0.0 END AS attributed_spend_last_click
FROM journey
ORDER BY industry, journey_step;

-- ---------- Linear attribution ----------
WITH journey AS (
    SELECT
        id, industry, platform, campaign_type, ad_spend, ad_date,
        ROW_NUMBER() OVER (PARTITION BY industry ORDER BY ad_date ASC, id ASC) AS journey_step,
        COUNT(*) OVER (PARTITION BY industry) AS total_steps
    FROM ads_performance
)
SELECT
    industry, platform, campaign_type, ad_date, journey_step, total_steps, ad_spend,
    ROUND(1.0 / total_steps, 6) AS linear_weight,
    ROUND(ad_spend / total_steps, 4) AS attributed_spend_linear
FROM journey
ORDER BY industry, journey_step;

-- ---------- Time-decay attribution (half-life = 1 step) ----------
WITH journey AS (
    SELECT
        id, industry, platform, campaign_type, ad_spend, ad_date,
        ROW_NUMBER() OVER (PARTITION BY industry ORDER BY ad_date ASC, id ASC) AS journey_step,
        COUNT(*) OVER (PARTITION BY industry) AS total_steps
    FROM ads_performance
),
raw_weights AS (
    SELECT *, POWER(0.5, total_steps - journey_step) AS raw_weight FROM journey
),
weight_sums AS (
    SELECT industry, SUM(raw_weight) AS sum_weights FROM raw_weights GROUP BY industry
)
SELECT
    r.industry, r.platform, r.campaign_type, r.ad_date, r.journey_step, r.ad_spend,
    ROUND(r.raw_weight / w.sum_weights, 6) AS time_decay_weight,
    ROUND(r.ad_spend * r.raw_weight / w.sum_weights, 4) AS attributed_spend_time_decay
FROM raw_weights r
JOIN weight_sums w ON r.industry = w.industry
ORDER BY r.industry, r.journey_step;

-- ---------- Position-based (U-shaped: 40/20/40) attribution ----------
WITH journey AS (
    SELECT
        id, industry, platform, campaign_type, ad_spend, ad_date,
        ROW_NUMBER() OVER (PARTITION BY industry ORDER BY ad_date ASC, id ASC) AS journey_step,
        COUNT(*) OVER (PARTITION BY industry) AS total_steps
    FROM ads_performance
)
SELECT
    industry, platform, campaign_type, ad_date, journey_step, ad_spend,
    ROUND(CASE
        WHEN total_steps = 1 THEN 1.0
        WHEN journey_step = 1 THEN 0.40
        WHEN journey_step = total_steps THEN 0.40
        ELSE 0.20 / NULLIF(total_steps - 2, 0)
    END, 6) AS position_weight,
    ROUND(ad_spend * CASE
        WHEN total_steps = 1 THEN 1.0
        WHEN journey_step = 1 THEN 0.40
        WHEN journey_step = total_steps THEN 0.40
        ELSE 0.20 / NULLIF(total_steps - 2, 0)
    END, 4) AS attributed_spend_position
FROM journey
ORDER BY industry, journey_step;

-- ---------- Model comparison, by platform ----------
WITH journey AS (
    SELECT platform, industry, ad_spend, ad_date, id,
           ROW_NUMBER() OVER (PARTITION BY industry ORDER BY ad_date ASC, id ASC) AS journey_step,
           COUNT(*) OVER (PARTITION BY industry) AS total_steps
    FROM ads_performance
),
raw_weights AS (
    SELECT *, POWER(0.5, total_steps - journey_step) AS raw_td_weight FROM journey
),
td_sums AS (
    SELECT industry, SUM(raw_td_weight) AS sum_td FROM raw_weights GROUP BY industry
)
SELECT
    r.platform,
    ROUND(SUM(CASE WHEN r.journey_step = 1 THEN r.ad_spend ELSE 0 END), 2) AS first_click_spend,
    ROUND(SUM(r.ad_spend / r.total_steps), 2) AS linear_spend,
    ROUND(SUM(r.ad_spend * r.raw_td_weight / t.sum_td), 2) AS time_decay_spend
FROM raw_weights r
JOIN td_sums t ON r.industry = t.industry
GROUP BY r.platform
ORDER BY linear_spend DESC;

-- ---------- Outlier detection: z-score by platform ----------
WITH stats AS (
    SELECT platform, AVG(ad_spend) AS mean_spend, STDDEV_POP(ad_spend) AS std_spend
    FROM ads_performance
    GROUP BY platform
)
SELECT
    a.id, a.ad_date, a.platform, a.ad_spend,
    ROUND(s.mean_spend, 2) AS platform_mean,
    ROUND(s.std_spend, 2) AS platform_std,
    ROUND((a.ad_spend - s.mean_spend) / NULLIF(s.std_spend, 0), 4) AS z_score
FROM ads_performance a
JOIN stats s ON a.platform = s.platform
WHERE (a.ad_spend - s.mean_spend) > 2 * s.std_spend
ORDER BY z_score DESC;
