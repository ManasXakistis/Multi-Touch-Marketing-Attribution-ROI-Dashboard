-- ============================================================
-- 01: Ads Performance Mart — Staged, Idempotent Load
-- Grain: one row per (date, platform, campaign_type, industry, country)
-- Source: global_ads_performance_dataset-selected-columns.csv
-- ============================================================

CREATE DATABASE IF NOT EXISTS marketing_analytics;
USE marketing_analytics;

-- One-time server setting — run manually by a DBA, not as part of a
-- repeatable ETL script. Left here only as documentation.
-- SET GLOBAL local_infile = 1;

-- ---------- Staging table (raw landing zone) ----------
DROP TABLE IF EXISTS stg_ads_performance;

CREATE TABLE stg_ads_performance (
    raw_date        VARCHAR(20),
    platform        VARCHAR(50),
    campaign_type   VARCHAR(50),
    industry        VARCHAR(50),
    country         VARCHAR(50),
    impressions     INT,
    clicks          INT,
    CTR             DECIMAL(8,4),
    CPC             DECIMAL(8,2),
    ad_spend        DECIMAL(12,2)
);

-- NOTE: replace the path below with your local file location before running.
-- Keeping it as a variable-style placeholder documents intent without
-- hardcoding one analyst's machine into version control.
LOAD DATA LOCAL INFILE 'C:\Users\DELL\OneDrive\Desktop\Multi-Touch-Marketing-Attribution-ROI-Dashboard\Multi-Touch-Marketing-Attribution-ROI-Dashboard\global_ads_performance_dataset-selected-columns.csv'
INTO TABLE stg_ads_performance
FIELDS TERMINATED BY ','
LINES  TERMINATED BY '\n'
IGNORE 1 ROWS
(raw_date, platform, campaign_type, industry, country,
 impressions, clicks, CTR, CPC, ad_spend);

-- ---------- Target (analytics) table ----------
CREATE TABLE IF NOT EXISTS ads_performance (
    id             INT AUTO_INCREMENT PRIMARY KEY,
    ad_date        DATE NOT NULL,
    platform       VARCHAR(50) NOT NULL,
    campaign_type  VARCHAR(50),
    industry       VARCHAR(50),
    country        VARCHAR(50),
    impressions    INT,
    clicks         INT,
    CTR            DECIMAL(8,4),
    CPC            DECIMAL(8,2),
    ad_spend       DECIMAL(12,2),
    loaded_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Full-refresh pattern: truncate + reload keeps the table idempotent.
-- If this ever needs to become incremental, switch to an
-- INSERT ... ON DUPLICATE KEY UPDATE against a real natural key.
TRUNCATE TABLE ads_performance;

INSERT INTO ads_performance
    (ad_date, platform, campaign_type, industry, country,
     impressions, clicks, CTR, CPC, ad_spend)
SELECT
    STR_TO_DATE(raw_date, '%Y-%m-%d'),
    platform, campaign_type, industry, country,
    impressions, clicks, CTR, CPC, ad_spend
FROM stg_ads_performance
WHERE raw_date IS NOT NULL;

-- ---------- Indexes for the query patterns actually used downstream ----------
CREATE INDEX idx_ads_platform  ON ads_performance (platform);
CREATE INDEX idx_ads_industry  ON ads_performance (industry);
CREATE INDEX idx_ads_country   ON ads_performance (country);
CREATE INDEX idx_ads_date      ON ads_performance (ad_date);
CREATE INDEX idx_ads_ptype     ON ads_performance (platform, campaign_type);

-- ---------- Load sanity check ----------
SELECT
    (SELECT COUNT(*) FROM stg_ads_performance) AS staged_rows,
    (SELECT COUNT(*) FROM ads_performance)     AS loaded_rows;
