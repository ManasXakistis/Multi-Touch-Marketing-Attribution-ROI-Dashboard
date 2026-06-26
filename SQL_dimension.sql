USE marketing_analytics;

DROP TABLE IF EXISTS dim_channel;

CREATE TABLE dim_channel (
    channel_key INT AUTO_INCREMENT PRIMARY KEY,
    channel VARCHAR(50) NOT NULL UNIQUE
);

INSERT INTO dim_channel (channel)
SELECT DISTINCT channel
FROM campaign_performance
WHERE channel IS NOT NULL
ORDER BY channel;

SELECT * FROM dim_channel;

DROP TABLE IF EXISTS dim_campaign;

CREATE TABLE dim_campaign (
    campaign_key INT AUTO_INCREMENT PRIMARY KEY,
    campaign_id VARCHAR(20) NOT NULL UNIQUE,
    channel VARCHAR(50),
    start_date DATE,
    end_date DATE,
    campaign_duration_days INT
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

SELECT * FROM dim_campaign LIMIT 20;

DROP TABLE IF EXISTS dim_date;

CREATE TABLE dim_date (
    date_key INT PRIMARY KEY,
    full_date DATE NOT NULL UNIQUE,
    year INT,
    quarter INT,
    month INT,
    month_name VARCHAR(20),
    day INT,
    day_name VARCHAR(20),
    week_of_year INT
);

INSERT INTO dim_date
    (date_key, full_date, year, quarter, month, month_name, day, day_name, week_of_year)
SELECT
    CAST(DATE_FORMAT(d, '%Y%m%d') AS UNSIGNED) AS date_key,
    d AS full_date,
    YEAR(d) AS year,
    QUARTER(d) AS quarter,
    MONTH(d) AS month,
    MONTHNAME(d) AS month_name,
    DAY(d) AS day,
    DAYNAME(d) AS day_name,
    WEEK(d, 3) AS week_of_year
FROM (
    SELECT DISTINCT start_date AS d FROM campaign_performance WHERE start_date IS NOT NULL
    UNION
    SELECT DISTINCT end_date AS d FROM campaign_performance WHERE end_date IS NOT NULL
) AS all_dates
ORDER BY d;

SELECT * FROM dim_date ORDER BY full_date LIMIT 20;

SELECT 'dim_channel' AS dimension, COUNT(*) AS row_count FROM dim_channel
UNION ALL
SELECT 'dim_campaign' AS dimension, COUNT(*) AS row_count FROM dim_campaign
UNION ALL
SELECT 'dim_date' AS dimension, COUNT(*) AS row_count FROM dim_date;
