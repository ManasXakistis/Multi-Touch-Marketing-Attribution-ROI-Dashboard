USE marketing_analytics;

DROP TABLE IF EXISTS fact_campaign_performance;

CREATE TABLE fact_campaign_performance (
    fact_id INT AUTO_INCREMENT PRIMARY KEY,
    campaign_key INT NOT NULL,
    channel_key INT NOT NULL,
    date_key INT NOT NULL,
    impressions INT,
    clicks INT,
    leads INT,
    conversions INT,
    cost_usd DECIMAL(12,2),
    revenue_usd DECIMAL(12,2),
    CONSTRAINT fk_fact_campaign FOREIGN KEY (campaign_key) REFERENCES dim_campaign(campaign_key),
    CONSTRAINT fk_fact_channel FOREIGN KEY (channel_key) REFERENCES dim_channel(channel_key),
    CONSTRAINT fk_fact_date FOREIGN KEY (date_key) REFERENCES dim_date(date_key)
);

INSERT INTO fact_campaign_performance
    (campaign_key, channel_key, date_key,
     impressions, clicks, leads, conversions, cost_usd, revenue_usd)
SELECT
    dc.campaign_key,
    ch.channel_key,
    dd.date_key,
    cp.impressions,
    cp.clicks,
    cp.leads,
    cp.conversions,
    cp.cost_usd,
    cp.revenue_usd
FROM campaign_performance cp
JOIN dim_campaign dc ON cp.campaign_id = dc.campaign_id
JOIN dim_channel ch ON cp.channel = ch.channel
JOIN dim_date dd ON cp.start_date = dd.full_date;

SELECT COUNT(*) AS fact_rows FROM fact_campaign_performance;
SELECT COUNT(*) AS source_rows FROM campaign_performance;

SELECT * FROM fact_campaign_performance LIMIT 10;

SELECT
    f.fact_id,
    dc.campaign_id,
    ch.channel,
    dd.full_date,
    dd.year,
    dd.month_name,
    f.impressions,
    f.clicks,
    f.conversions,
    f.cost_usd,
    f.revenue_usd
FROM fact_campaign_performance f
JOIN dim_campaign dc ON f.campaign_key = dc.campaign_key
JOIN dim_channel ch ON f.channel_key = ch.channel_key
JOIN dim_date dd ON f.date_key = dd.date_key
LIMIT 20;

SELECT
    ch.channel,
    ROUND(SUM(f.cost_usd), 2) AS total_spend,
    ROUND(SUM(f.cost_usd) / NULLIF(SUM(f.clicks), 0), 2) AS cpc,
    ROUND(SUM(f.cost_usd) / NULLIF(SUM(f.conversions), 0), 2) AS cac,
    ROUND(SUM(f.revenue_usd) / NULLIF(SUM(f.cost_usd), 0), 2) AS roas
FROM fact_campaign_performance f
JOIN dim_channel ch ON f.channel_key = ch.channel_key
GROUP BY ch.channel
ORDER BY roas DESC;

