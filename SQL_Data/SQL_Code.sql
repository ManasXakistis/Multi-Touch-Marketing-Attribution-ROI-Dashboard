-- =============================================================
-- WEEK 2: Advanced SQL & Attribution Logic
-- Dataset: ad_campaigns (date, platform, campaign_type,
--          industry, country, impressions, clicks, CTR, CPC,
--          ad_spend)
-- =============================================================

-- -------------------------------------------------------------
-- STEP 0 – Table Setup & Data Load
-- -------------------------------------------------------------

CREATE DATABASE IF NOT EXISTS marketing_analytics;
USE marketing_analytics;

DROP TABLE IF EXISTS ad_campaigns;

CREATE TABLE ad_campaigns (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    date          DATE,
    platform      VARCHAR(50),
    campaign_type VARCHAR(50),
    industry      VARCHAR(50),
    country       VARCHAR(50),
    impressions   INT,
    clicks        INT,
    CTR           DECIMAL(6,4),
    CPC           DECIMAL(8,2),
    ad_spend      DECIMAL(10,2)
);

-- Load CSV (tab-delimited, skip header row)
SET GLOBAL local_infile = 1;
SHOW VARIABLES LIKE 'local_infile';

LOAD DATA LOCAL INFILE 'C:\Users\Atul\OneDrive\Desktop\Infotact Projects\Multi-Touch-Marketing-Attribution-ROI-Dashboard\SQL_Data\Dataset.csv'
INTO TABLE ad_campaigns
FIELDS TERMINATED BY '\t'
LINES  TERMINATED BY '\n'
IGNORE 1 ROWS
(date, platform, campaign_type, industry, country,
 impressions, clicks, CTR, CPC, ad_spend);


-- =============================================================
-- SECTION 1: Window Functions — Sequencing the User Journey
-- =============================================================

-- Q1. Rank each campaign row per platform by date (chronological
--     sequencing — akin to ordering touchpoints in a user journey).
--     ROW_NUMBER assigns a unique, deterministic ordinal per partition.

SELECT
    id,
    date,
    platform,
    campaign_type,
    industry,
    ad_spend,
    ROW_NUMBER() OVER (
        PARTITION BY platform
        ORDER BY date ASC
    ) AS journey_step
FROM ad_campaigns;


-- Q2. Rank campaigns within each platform by ad_spend (highest first).
--     RANK() yields tied positions; DENSE_RANK() closes the gaps.

SELECT
    platform,
    campaign_type,
    ad_spend,
    RANK()       OVER (PARTITION BY platform ORDER BY ad_spend DESC) AS spend_rank,
    DENSE_RANK() OVER (PARTITION BY platform ORDER BY ad_spend DESC) AS spend_dense_rank
FROM ad_campaigns;


-- Q3. Running (cumulative) ad spend per platform ordered by date.
--     Reveals how budget accrued over time for each channel.

SELECT
    date,
    platform,
    ad_spend,
    SUM(ad_spend) OVER (
        PARTITION BY platform
        ORDER BY date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_spend
FROM ad_campaigns
ORDER BY platform, date;


-- Q4. 7-day moving average of clicks per platform.
--     Smooths out day-to-day volatility — a canonical time-series idiom.

SELECT
    date,
    platform,
    clicks,
    ROUND(
        AVG(clicks) OVER (
            PARTITION BY platform
            ORDER BY date
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ), 2
    ) AS clicks_7day_avg
FROM ad_campaigns
ORDER BY platform, date;


-- Q5. Lag & Lead — compare each row's ad_spend with the previous
--     and next row within the same platform (period-over-period delta).

SELECT
    date,
    platform,
    ad_spend,
    LAG(ad_spend,  1, 0) OVER (PARTITION BY platform ORDER BY date) AS prev_spend,
    LEAD(ad_spend, 1, 0) OVER (PARTITION BY platform ORDER BY date) AS next_spend,
    ROUND(ad_spend - LAG(ad_spend, 1, 0)
          OVER (PARTITION BY platform ORDER BY date), 2)             AS spend_delta
FROM ad_campaigns
ORDER BY platform, date;


-- Q6. NTILE — segment campaigns into 4 spend quartiles per platform.
--     Useful for identifying high-performing vs. underperforming tiers.

SELECT
    id,
    platform,
    ad_spend,
    NTILE(4) OVER (
        PARTITION BY platform
        ORDER BY ad_spend DESC
    ) AS spend_quartile   -- 1 = top quartile, 4 = bottom
FROM ad_campaigns;


-- Q7. PERCENT_RANK & CUME_DIST of CTR within each campaign type.
--     Shows where each row stands relative to its cohort.

SELECT
    campaign_type,
    platform,
    CTR,
    ROUND(PERCENT_RANK() OVER (
        PARTITION BY campaign_type ORDER BY CTR
    ), 4) AS ctr_percent_rank,
    ROUND(CUME_DIST() OVER (
        PARTITION BY campaign_type ORDER BY CTR
    ), 4) AS ctr_cume_dist
FROM ad_campaigns
ORDER BY campaign_type, CTR DESC;


-- Q8. First & Last touchpoint per industry using FIRST_VALUE / LAST_VALUE.
--     Pinpoints the entry and exit channels for each industry's journey.

SELECT
    industry,
    date,
    platform,
    FIRST_VALUE(platform) OVER (
        PARTITION BY industry
        ORDER BY date
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS first_channel,
    LAST_VALUE(platform) OVER (
        PARTITION BY industry
        ORDER BY date
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS last_channel
FROM ad_campaigns;


-- =============================================================
-- SECTION 2: Attribution Modelling
-- =============================================================

-- Attribution distributes conversion credit across touchpoints.
-- Here, each row = one touchpoint (platform exposure) per industry.
-- We sequence touchpoints chronologically, then apply weights.


-- ---------------------------------------------------------------
-- Q9. FIRST-CLICK ATTRIBUTION
-- The entire conversion credit goes to the first touchpoint.
-- Weight = 1 for journey_step = 1, else 0.
-- ---------------------------------------------------------------

WITH journey AS (
    SELECT
        id,
        industry,
        platform,
        campaign_type,
        ad_spend,
        date,
        ROW_NUMBER() OVER (
            PARTITION BY industry
            ORDER BY date ASC
        ) AS journey_step
    FROM ad_campaigns
),
total_touchpoints AS (
    SELECT industry, COUNT(*) AS total_steps
    FROM journey
    GROUP BY industry
)
SELECT
    j.industry,
    j.platform,
    j.campaign_type,
    j.date,
    j.journey_step,
    j.ad_spend,
    CASE
        WHEN j.journey_step = 1 THEN 1.0
        ELSE 0.0
    END AS first_click_weight,
    CASE
        WHEN j.journey_step = 1 THEN j.ad_spend
        ELSE 0.0
    END AS attributed_spend_first_click
FROM journey j
JOIN total_touchpoints t ON j.industry = t.industry
ORDER BY j.industry, j.journey_step;


-- ---------------------------------------------------------------
-- Q10. LAST-CLICK ATTRIBUTION
-- Full credit to the final touchpoint — favoured by platforms
-- that measure direct-response conversions.
-- ---------------------------------------------------------------

WITH journey AS (
    SELECT
        id,
        industry,
        platform,
        campaign_type,
        ad_spend,
        date,
        ROW_NUMBER() OVER (
            PARTITION BY industry ORDER BY date ASC
        ) AS journey_step,
        COUNT(*)     OVER (
            PARTITION BY industry
        ) AS total_steps
    FROM ad_campaigns
)
SELECT
    industry,
    platform,
    campaign_type,
    date,
    journey_step,
    ad_spend,
    CASE
        WHEN journey_step = total_steps THEN 1.0
        ELSE 0.0
    END AS last_click_weight,
    CASE
        WHEN journey_step = total_steps THEN ad_spend
        ELSE 0.0
    END AS attributed_spend_last_click
FROM journey
ORDER BY industry, journey_step;


-- ---------------------------------------------------------------
-- Q11. LINEAR ATTRIBUTION
-- Credit is distributed equally across ALL touchpoints.
-- Weight per touchpoint = 1 / total_touchpoints_in_journey
-- ---------------------------------------------------------------

WITH journey AS (
    SELECT
        id,
        industry,
        platform,
        campaign_type,
        ad_spend,
        date,
        ROW_NUMBER() OVER (
            PARTITION BY industry ORDER BY date ASC
        ) AS journey_step,
        COUNT(*)     OVER (
            PARTITION BY industry
        ) AS total_steps
    FROM ad_campaigns
)
SELECT
    industry,
    platform,
    campaign_type,
    date,
    journey_step,
    total_steps,
    ad_spend,
    ROUND(1.0 / total_steps, 6)              AS linear_weight,
    ROUND(ad_spend / total_steps, 4)         AS attributed_spend_linear
FROM journey
ORDER BY industry, journey_step;


-- ---------------------------------------------------------------
-- Q12. TIME-DECAY ATTRIBUTION
-- More recent touchpoints receive exponentially more credit.
-- Decay factor λ = 0.5 per step from the last touchpoint.
-- weight_i = λ^(total_steps - journey_step)
-- Weights are then normalised to sum to 1.
-- ---------------------------------------------------------------

WITH journey AS (
    SELECT
        id,
        industry,
        platform,
        campaign_type,
        ad_spend,
        date,
        ROW_NUMBER() OVER (
            PARTITION BY industry ORDER BY date ASC
        ) AS journey_step,
        COUNT(*)     OVER (
            PARTITION BY industry
        ) AS total_steps
    FROM ad_campaigns
),
raw_weights AS (
    SELECT
        *,
        POWER(0.5, total_steps - journey_step) AS raw_weight
    FROM journey
),
weight_sums AS (
    SELECT industry, SUM(raw_weight) AS sum_weights
    FROM raw_weights
    GROUP BY industry
)
SELECT
    r.industry,
    r.platform,
    r.campaign_type,
    r.date,
    r.journey_step,
    r.ad_spend,
    ROUND(r.raw_weight / w.sum_weights, 6)              AS time_decay_weight,
    ROUND(r.ad_spend * r.raw_weight / w.sum_weights, 4) AS attributed_spend_time_decay
FROM raw_weights r
JOIN weight_sums w ON r.industry = w.industry
ORDER BY r.industry, r.journey_step;


-- ---------------------------------------------------------------
-- Q13. POSITION-BASED (U-SHAPED) ATTRIBUTION
-- 40 % credit to first touch, 40 % to last touch,
-- remaining 20 % split linearly among middle touchpoints.
-- This model valorises both discovery and conversion channels.
-- ---------------------------------------------------------------

WITH journey AS (
    SELECT
        id,
        industry,
        platform,
        campaign_type,
        ad_spend,
        date,
        ROW_NUMBER() OVER (
            PARTITION BY industry ORDER BY date ASC
        ) AS journey_step,
        COUNT(*)     OVER (
            PARTITION BY industry
        ) AS total_steps
    FROM ad_campaigns
)
SELECT
    industry,
    platform,
    campaign_type,
    date,
    journey_step,
    ad_spend,
    ROUND(
        CASE
            WHEN total_steps = 1 THEN 1.0                          -- sole touchpoint gets 100 %
            WHEN journey_step = 1             THEN 0.40
            WHEN journey_step = total_steps   THEN 0.40
            ELSE 0.20 / NULLIF(total_steps - 2, 0)                -- middle steps share 20 %
        END, 6
    ) AS position_weight,
    ROUND(
        ad_spend * CASE
            WHEN total_steps = 1              THEN 1.0
            WHEN journey_step = 1             THEN 0.40
            WHEN journey_step = total_steps   THEN 0.40
            ELSE 0.20 / NULLIF(total_steps - 2, 0)
        END, 4
    ) AS attributed_spend_position
FROM journey
ORDER BY industry, journey_step;


-- =============================================================
-- SECTION 3: Aggregated Attribution Reports
-- =============================================================

-- Q14. Total attributed spend per platform under LINEAR model —
--      lets you compare cross-channel efficiency apples-to-apples.

WITH journey AS (
    SELECT
        platform,
        industry,
        ad_spend,
        COUNT(*) OVER (PARTITION BY industry) AS total_steps
    FROM ad_campaigns
)
SELECT
    platform,
    ROUND(SUM(ad_spend / total_steps), 2) AS total_linear_attributed_spend,
    COUNT(*)                               AS touchpoint_count
FROM journey
GROUP BY platform
ORDER BY total_linear_attributed_spend DESC;


-- Q15. First-click channel share per industry —
--      which platform initiates the most journeys per sector?

WITH journey AS (
    SELECT
        industry,
        platform,
        ROW_NUMBER() OVER (
            PARTITION BY industry ORDER BY date ASC
        ) AS journey_step
    FROM ad_campaigns
)
SELECT
    industry,
    platform AS first_click_channel,
    COUNT(*) AS first_touch_count
FROM journey
WHERE journey_step = 1
GROUP BY industry, platform
ORDER BY industry, first_touch_count DESC;


-- Q16. Side-by-side comparison: First-Click vs Linear vs Time-Decay
--      attributed spend per platform — an executive-level pivot.

WITH journey AS (
    SELECT
        platform,
        industry,
        ad_spend,
        date,
        ROW_NUMBER() OVER (
            PARTITION BY industry ORDER BY date ASC
        ) AS journey_step,
        COUNT(*) OVER (PARTITION BY industry) AS total_steps
    FROM ad_campaigns
),
raw_weights AS (
    SELECT *,
        POWER(0.5, total_steps - journey_step) AS raw_td_weight
    FROM journey
),
td_sums AS (
    SELECT industry, SUM(raw_td_weight) AS sum_td
    FROM raw_weights GROUP BY industry
)
SELECT
    r.platform,
    -- First-Click
    ROUND(SUM(
        CASE WHEN r.journey_step = 1 THEN r.ad_spend ELSE 0 END
    ), 2) AS first_click_spend,
    -- Linear
    ROUND(SUM(r.ad_spend / r.total_steps), 2) AS linear_spend,
    -- Time-Decay
    ROUND(SUM(r.ad_spend * r.raw_td_weight / t.sum_td), 2) AS time_decay_spend
FROM raw_weights r
JOIN td_sums t ON r.industry = t.industry
GROUP BY r.platform
ORDER BY linear_spend DESC;


-- Q17. CTR performance percentile per country using window functions —
--      surfaces geo-specific outliers.

SELECT
    country,
    platform,
    campaign_type,
    ROUND(AVG(CTR), 4)  AS avg_ctr,
    ROUND(PERCENT_RANK() OVER (
        PARTITION BY country
        ORDER BY AVG(CTR)
    ), 4)               AS ctr_percentile_in_country
FROM ad_campaigns
GROUP BY country, platform, campaign_type
ORDER BY country, ctr_percentile_in_country DESC;


-- Q18. Month-over-month ad spend growth per platform.
--      Uses LAG across monthly aggregates inside a CTE.

WITH monthly AS (
    SELECT
        DATE_FORMAT(date, '%Y-%m') AS month,
        platform,
        SUM(ad_spend)              AS monthly_spend
    FROM ad_campaigns
    GROUP BY month, platform
)
SELECT
    month,
    platform,
    monthly_spend,
    LAG(monthly_spend) OVER (
        PARTITION BY platform ORDER BY month
    )                                                          AS prev_month_spend,
    ROUND(
        (monthly_spend - LAG(monthly_spend) OVER (
            PARTITION BY platform ORDER BY month)
        ) / NULLIF(LAG(monthly_spend) OVER (
            PARTITION BY platform ORDER BY month), 0) * 100
    , 2)                                                       AS mom_growth_pct
FROM monthly
ORDER BY platform, month;


-- Q19. Top-3 campaigns by ad_spend within each industry
--      using ROW_NUMBER() to avoid over-counting ties.

WITH ranked AS (
    SELECT
        industry,
        platform,
        campaign_type,
        country,
        ad_spend,
        ROW_NUMBER() OVER (
            PARTITION BY industry
            ORDER BY ad_spend DESC
        ) AS spend_rank
    FROM ad_campaigns
)
SELECT *
FROM ranked
WHERE spend_rank <= 3
ORDER BY industry, spend_rank;


-- Q20. Detect anomalous spikes: rows where ad_spend exceeds
--      2 standard deviations above the platform mean —
--      a rudimentary but effective outlier-detection heuristic.

WITH stats AS (
    SELECT
        platform,
        AVG(ad_spend)                       AS mean_spend,
        STDDEV_POP(ad_spend)                AS std_spend
    FROM ad_campaigns
    GROUP BY platform
)
SELECT
    a.id,
    a.date,
    a.platform,
    a.ad_spend,
    ROUND(s.mean_spend, 2)                  AS platform_mean,
    ROUND(s.std_spend, 2)                   AS platform_std,
    ROUND((a.ad_spend - s.mean_spend)
          / NULLIF(s.std_spend, 0), 4)      AS z_score
FROM ad_campaigns a
JOIN stats s ON a.platform = s.platform
WHERE (a.ad_spend - s.mean_spend) > 2 * s.std_spend
ORDER BY z_score DESC;