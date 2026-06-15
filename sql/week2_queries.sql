
CREATE DATABASE IF NOT EXISTS marketing_analytics;
USE marketing_analytics;

DROP TABLE IF EXISTS ad_campaigns;

CREATE TABLE ad_campaigns (
    id INT AUTO_INCREMENT PRIMARY KEY,
    date DATE,
    platform VARCHAR(50),
    campaign_type VARCHAR(50),
    industry VARCHAR(50),
    country VARCHAR(50),
    impressions INT,
    clicks INT,
    CTR DECIMAL(6,4),
    CPC DECIMAL(8,2),
    ad_spend DECIMAL(10,2)
);

SET GLOBAL local_infile = 1;

LOAD DATA LOCAL INFILE 'C:\Users\DELL\OneDrive\Desktop\Multi-Touch-Marketing-Attribution-ROI-Dashboard\Multi-Touch-Marketing-Attribution-ROI-Dashboard\Data\RAW\global_ads_performance_dataset-selected-columns.csv'
INTO TABLE ad_campaigns
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(date, platform, campaign_type, industry, country,
 impressions, clicks, CTR, CPC, ad_spend);

SELECT COUNT(*) AS total_rows_loaded FROM ad_campaigns;

SELECT
    id, date, platform, campaign_type, industry, ad_spend,
    ROW_NUMBER() OVER (PARTITION BY platform ORDER BY date ASC) AS journey_step
FROM ad_campaigns;

SELECT
    platform, campaign_type, ad_spend,
    RANK() OVER (PARTITION BY platform ORDER BY ad_spend DESC) AS spend_rank,
    DENSE_RANK() OVER (PARTITION BY platform ORDER BY ad_spend DESC) AS spend_dense_rank
FROM ad_campaigns;

SELECT
    date, platform, ad_spend,
    SUM(ad_spend) OVER (
        PARTITION BY platform ORDER BY date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_spend
FROM ad_campaigns
ORDER BY platform, date;

SELECT
    date, platform, clicks,
    ROUND(
        AVG(clicks) OVER (
            PARTITION BY platform ORDER BY date
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ), 2
    ) AS clicks_7day_avg
FROM ad_campaigns
ORDER BY platform, date;

SELECT
    date, platform, ad_spend,
    LAG(ad_spend, 1, 0) OVER (PARTITION BY platform ORDER BY date) AS prev_spend,
    LEAD(ad_spend, 1, 0) OVER (PARTITION BY platform ORDER BY date) AS next_spend,
    ROUND(ad_spend - LAG(ad_spend, 1, 0)
          OVER (PARTITION BY platform ORDER BY date), 2) AS spend_delta
FROM ad_campaigns
ORDER BY platform, date;

SELECT
    id, platform, ad_spend,
    NTILE(4) OVER (PARTITION BY platform ORDER BY ad_spend DESC) AS spend_quartile
FROM ad_campaigns;

SELECT
    campaign_type, platform, CTR,
    ROUND(PERCENT_RANK() OVER (PARTITION BY campaign_type ORDER BY CTR), 4) AS ctr_percent_rank,
    ROUND(CUME_DIST() OVER (PARTITION BY campaign_type ORDER BY CTR), 4) AS ctr_cume_dist
FROM ad_campaigns
ORDER BY campaign_type, CTR DESC;

SELECT
    industry, date, platform,
    FIRST_VALUE(platform) OVER (
        PARTITION BY industry ORDER BY date
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS first_channel,
    LAST_VALUE(platform) OVER (
        PARTITION BY industry ORDER BY date
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS last_channel
FROM ad_campaigns;

WITH journey AS (
    SELECT
        id, industry, platform, campaign_type, ad_spend, date,
        ROW_NUMBER() OVER (PARTITION BY industry ORDER BY date ASC) AS journey_step
    FROM ad_campaigns
),
total_touchpoints AS (
    SELECT industry, COUNT(*) AS total_steps FROM journey GROUP BY industry
)
SELECT
    j.industry, j.platform, j.campaign_type, j.date,
    j.journey_step, j.ad_spend,
    CASE WHEN j.journey_step = 1 THEN 1.0 ELSE 0.0 END AS first_click_weight,
    CASE WHEN j.journey_step = 1 THEN j.ad_spend ELSE 0.0 END AS attributed_spend_first_click
FROM journey j
JOIN total_touchpoints t ON j.industry = t.industry
ORDER BY j.industry, j.journey_step;

WITH journey AS (
    SELECT
        id, industry, platform, campaign_type, ad_spend, date,
        ROW_NUMBER() OVER (PARTITION BY industry ORDER BY date ASC) AS journey_step,
        COUNT(*) OVER (PARTITION BY industry) AS total_steps
    FROM ad_campaigns
)
SELECT
    industry, platform, campaign_type, date, journey_step, ad_spend,
    CASE WHEN journey_step = total_steps THEN 1.0 ELSE 0.0 END AS last_click_weight,
    CASE WHEN journey_step = total_steps THEN ad_spend ELSE 0.0 END AS attributed_spend_last_click
FROM journey
ORDER BY industry, journey_step;

WITH journey AS (
    SELECT
        id, industry, platform, campaign_type, ad_spend, date,
        ROW_NUMBER() OVER (PARTITION BY industry ORDER BY date ASC) AS journey_step,
        COUNT(*) OVER (PARTITION BY industry) AS total_steps
    FROM ad_campaigns
)
SELECT
    industry, platform, campaign_type, date, journey_step, total_steps, ad_spend,
    ROUND(1.0 / total_steps, 6) AS linear_weight,
    ROUND(ad_spend / total_steps, 4) AS attributed_spend_linear
FROM journey
ORDER BY industry, journey_step;

WITH journey AS (
    SELECT
        id, industry, platform, campaign_type, ad_spend, date,
        ROW_NUMBER() OVER (PARTITION BY industry ORDER BY date ASC) AS journey_step,
        COUNT(*) OVER (PARTITION BY industry) AS total_steps
    FROM ad_campaigns
),
raw_weights AS (
    SELECT *, POWER(0.5, total_steps - journey_step) AS raw_weight
    FROM journey
),
weight_sums AS (
    SELECT industry, SUM(raw_weight) AS sum_weights FROM raw_weights GROUP BY industry
)
SELECT
    r.industry, r.platform, r.campaign_type, r.date,
    r.journey_step, r.ad_spend,
    ROUND(r.raw_weight / w.sum_weights, 6) AS time_decay_weight,
    ROUND(r.ad_spend * r.raw_weight / w.sum_weights, 4) AS attributed_spend_time_decay
FROM raw_weights r
JOIN weight_sums w ON r.industry = w.industry
ORDER BY r.industry, r.journey_step;

WITH journey AS (
    SELECT
        id, industry, platform, campaign_type, ad_spend, date,
        ROW_NUMBER() OVER (PARTITION BY industry ORDER BY date ASC) AS journey_step,
        COUNT(*) OVER (PARTITION BY industry) AS total_steps
    FROM ad_campaigns
)
SELECT
    industry, platform, campaign_type, date, journey_step, ad_spend,
    ROUND(
        CASE
            WHEN total_steps = 1 THEN 1.0
            WHEN journey_step = 1 THEN 0.40
            WHEN journey_step = total_steps THEN 0.40
            ELSE 0.20 / NULLIF(total_steps - 2, 0)
        END, 6
    ) AS position_weight,
    ROUND(
        ad_spend * CASE
            WHEN total_steps = 1 THEN 1.0
            WHEN journey_step = 1 THEN 0.40
            WHEN journey_step = total_steps THEN 0.40
            ELSE 0.20 / NULLIF(total_steps - 2, 0)
        END, 4
    ) AS attributed_spend_position
FROM journey
ORDER BY industry, journey_step;

WITH journey AS (
    SELECT platform, industry, ad_spend,
           COUNT(*) OVER (PARTITION BY industry) AS total_steps
    FROM ad_campaigns
)
SELECT
    platform,
    ROUND(SUM(ad_spend / total_steps), 2) AS total_linear_attributed_spend,
    COUNT(*) AS touchpoint_count
FROM journey
GROUP BY platform
ORDER BY total_linear_attributed_spend DESC;

WITH journey AS (
    SELECT industry, platform,
           ROW_NUMBER() OVER (PARTITION BY industry ORDER BY date ASC) AS journey_step
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

WITH journey AS (
    SELECT platform, industry, ad_spend, date,
           ROW_NUMBER() OVER (PARTITION BY industry ORDER BY date ASC) AS journey_step,
           COUNT(*) OVER (PARTITION BY industry) AS total_steps
    FROM ad_campaigns
),
raw_weights AS (
    SELECT *, POWER(0.5, total_steps - journey_step) AS raw_td_weight
    FROM journey
),
td_sums AS (
    SELECT industry, SUM(raw_td_weight) AS sum_td
    FROM raw_weights GROUP BY industry
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

SELECT
    country, platform, campaign_type,
    ROUND(AVG(CTR), 4) AS avg_ctr,
    ROUND(PERCENT_RANK() OVER (
        PARTITION BY country
        ORDER BY AVG(CTR)
    ), 4) AS ctr_percentile_in_country
FROM ad_campaigns
GROUP BY country, platform, campaign_type
ORDER BY country, ctr_percentile_in_country DESC;

WITH monthly AS (
    SELECT
        DATE_FORMAT(date, '%Y-%m') AS month,
        platform,
        SUM(ad_spend) AS monthly_spend
    FROM ad_campaigns
    GROUP BY month, platform
)
SELECT
    month, platform, monthly_spend,
    LAG(monthly_spend) OVER (PARTITION BY platform ORDER BY month) AS prev_month_spend,
    ROUND(
        (monthly_spend - LAG(monthly_spend) OVER (PARTITION BY platform ORDER BY month))
        / NULLIF(LAG(monthly_spend) OVER (PARTITION BY platform ORDER BY month), 0) * 100
    , 2) AS mom_growth_pct
FROM monthly
ORDER BY platform, month;

WITH ranked AS (
    SELECT industry, platform, campaign_type, country, ad_spend,
           ROW_NUMBER() OVER (PARTITION BY industry ORDER BY ad_spend DESC) AS spend_rank
    FROM ad_campaigns
)
SELECT * FROM ranked
WHERE spend_rank <= 3
ORDER BY industry, spend_rank;

WITH stats AS (
    SELECT platform,
           AVG(ad_spend) AS mean_spend,
           STDDEV_POP(ad_spend) AS std_spend
    FROM ad_campaigns
    GROUP BY platform
)
SELECT
    a.id, a.date, a.platform, a.ad_spend,
    ROUND(s.mean_spend, 2) AS platform_mean,
    ROUND(s.std_spend, 2) AS platform_std,
    ROUND((a.ad_spend - s.mean_spend)
          / NULLIF(s.std_spend, 0), 4) AS z_score
FROM ad_campaigns a
JOIN stats s ON a.platform = s.platform
WHERE (a.ad_spend - s.mean_spend) > 2 * s.std_spend
ORDER BY z_score DESC;
