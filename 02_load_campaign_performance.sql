-- ============================================================
-- 02: Campaign Performance Mart — Staged, Idempotent Load
-- Grain: one row per campaign (channel, funnel + revenue metrics)
-- Source: marketing_campaign_performance_10000.csv
-- ============================================================

USE marketing_analytics;

DROP TABLE IF EXISTS stg_campaign_performance;

CREATE TABLE stg_campaign_performance (
    campaign_id   VARCHAR(20),
    raw_start     VARCHAR(20),
    raw_end       VARCHAR(20),
    channel       VARCHAR(50),
    impressions   INT,
    clicks        INT,
    leads         INT,
    conversions   INT,
    cost_usd      DECIMAL(12,2),
    revenue_usd   DECIMAL(12,2),
    roi           DECIMAL(8,4)
);

-- Replace with your local file path before running.
LOAD DATA LOCAL INFILE 'C:\Users\DELL\OneDrive\Desktop\Multi-Touch-Marketing-Attribution-ROI-Dashboard\Multi-Touch-Marketing-Attribution-ROI-Dashboard\marketing_campaign_performance_10000.csv'
INTO TABLE stg_campaign_performance
FIELDS TERMINATED BY ','
LINES  TERMINATED BY '\n'
IGNORE 1 ROWS
(campaign_id, raw_start, raw_end, channel,
 impressions, clicks, leads, conversions,
 cost_usd, revenue_usd, roi);

CREATE TABLE IF NOT EXISTS campaign_performance (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    campaign_id   VARCHAR(20) NOT NULL,
    start_date    DATE,
    end_date      DATE,
    channel       VARCHAR(50),
    impressions   INT,
    clicks        INT,
    leads         INT,
    conversions   INT,
    cost_usd      DECIMAL(12,2),
    revenue_usd   DECIMAL(12,2),
    roi           DECIMAL(8,4),
    UNIQUE KEY uq_campaign_id (campaign_id)
);

TRUNCATE TABLE campaign_performance;

INSERT INTO campaign_performance
    (campaign_id, start_date, end_date, channel,
     impressions, clicks, leads, conversions, cost_usd, revenue_usd, roi)
SELECT
    campaign_id,
    STR_TO_DATE(raw_start, '%d-%m-%Y'),
    STR_TO_DATE(raw_end,   '%d-%m-%Y'),
    channel, impressions, clicks, leads, conversions,
    cost_usd, revenue_usd, roi
FROM stg_campaign_performance
WHERE campaign_id IS NOT NULL;

CREATE INDEX idx_camp_channel ON campaign_performance (channel);
CREATE INDEX idx_camp_start   ON campaign_performance (start_date);

-- ---------- Load sanity check ----------
SELECT
    (SELECT COUNT(*) FROM stg_campaign_performance) AS staged_rows,
    (SELECT COUNT(*) FROM campaign_performance)      AS loaded_rows,
    (SELECT COUNT(*) FROM stg_campaign_performance) -
    (SELECT COUNT(DISTINCT campaign_id) FROM stg_campaign_performance) AS duplicate_campaign_ids_dropped;
