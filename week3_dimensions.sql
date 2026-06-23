-- =============================================================
-- WEEK 3 - DAY 2: Dimension Tables (Star Schema - Part 1)
-- Project: Multi-Touch Marketing Attribution & ROI Dashboard
-- =============================================================
-- A Star Schema has 2 kinds of tables:
--   FACT table       -> the numbers/measures (spend, clicks, revenue)
--   DIMENSION tables -> the descriptive context (who/what/when/where)
--
-- DAY 2 builds the DIMENSION tables. They answer:
--   dim_channel  -> WHICH marketing channel?
--   dim_campaign -> WHICH campaign (and its details)?
--   dim_date     -> WHEN did it happen?
--
-- Each dimension gets a surrogate key (an INT id) that the
-- fact table (built on Day 3) will point to.
-- Source of data: campaign_performance (loaded on Day 1).
-- =============================================================

USE marketing_analytics;


-- -------------------------------------------------------------
-- DIM 1 - dim_channel
-- One row per marketing channel (Search, Email, Social, ...).
-- -------------------------------------------------------------
DROP TABLE IF EXISTS dim_channel;

CREATE TABLE dim_channel (
    channel_key  INT AUTO_INCREMENT PRIMARY KEY,   -- surrogate key
    channel      VARCHAR(50) NOT NULL UNIQUE        -- business value
);

INSERT INTO dim_channel (channel)
SELECT DISTINCT channel
FROM campaign_performance
WHERE channel IS NOT NULL
ORDER BY channel;

-- Check
SELECT * FROM dim_channel;


-- -------------------------------------------------------------
-- DIM 2 - dim_campaign
-- One row per campaign, with its descriptive attributes.
-- (campaign_id is unique per row in the source data.)
-- -------------------------------------------------------------
DROP TABLE IF EXISTS dim_campaign;

CREATE TABLE dim_campaign (
    campaign_key            INT AUTO_INCREMENT PRIMARY KEY,  -- surrogate key
    campaign_id             VARCHAR(20) NOT NULL UNIQUE,     -- natural key
    channel                 VARCHAR(50),
    start_date              DATE,
    end_date                DATE,
    campaign_duration_days  INT
);

INSERT INTO dim_campaign
    (campaign_id, channel, start_date, end_date, campaign_duration_days)
SELECT DISTINCT
    campaign_id,
    channel,
    start_date,
    end_date,
    DATEDIFF(end_date, start_date) AS campaign_duration_days
FROM campaign_performance
WHERE campaign_id IS NOT NULL;

-- Check
SELECT * FROM dim_campaign LIMIT 20;


-- -------------------------------------------------------------
-- DIM 3 - dim_date
-- One row per calendar date used in the data.
-- date_key is a smart integer in YYYYMMDD form (e.g. 20250413).
-- Built from BOTH start_date and end_date so every date the
-- fact table needs is present.
-- -------------------------------------------------------------
DROP TABLE IF EXISTS dim_date;

CREATE TABLE dim_date (
    date_key      INT PRIMARY KEY,        -- YYYYMMDD surrogate key
    full_date     DATE NOT NULL UNIQUE,
    year          INT,
    quarter       INT,
    month         INT,
    month_name    VARCHAR(20),
    day           INT,
    day_name      VARCHAR(20),
    week_of_year  INT
);

INSERT INTO dim_date
    (date_key, full_date, year, quarter, month, month_name, day, day_name, week_of_year)
SELECT
    CAST(DATE_FORMAT(d, '%Y%m%d') AS UNSIGNED) AS date_key,
    d                                          AS full_date,
    YEAR(d)                                    AS year,
    QUARTER(d)                                 AS quarter,
    MONTH(d)                                   AS month,
    MONTHNAME(d)                               AS month_name,
    DAY(d)                                     AS day,
    DAYNAME(d)                                 AS day_name,
    WEEK(d, 3)                                 AS week_of_year
FROM (
    SELECT DISTINCT start_date AS d FROM campaign_performance WHERE start_date IS NOT NULL
    UNION
    SELECT DISTINCT end_date   AS d FROM campaign_performance WHERE end_date   IS NOT NULL
) AS all_dates
ORDER BY d;

-- Check
SELECT * FROM dim_date ORDER BY full_date LIMIT 20;


-- -------------------------------------------------------------
-- Quick verification of all 3 dimensions
-- -------------------------------------------------------------
SELECT 'dim_channel'  AS dimension, COUNT(*) AS row_count FROM dim_channel
UNION ALL
SELECT 'dim_campaign' AS dimension, COUNT(*) AS row_count FROM dim_campaign
UNION ALL
SELECT 'dim_date'     AS dimension, COUNT(*) AS row_count FROM dim_date;


-- =============================================================
-- NEXT STEP:
--   Day 3 -> fact_campaign_performance (links to these 3 dims
--            via channel_key, campaign_key, date_key)
-- =============================================================
