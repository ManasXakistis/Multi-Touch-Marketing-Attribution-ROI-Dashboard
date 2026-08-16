USE marketing_analytics;

CREATE OR REPLACE VIEW vw_campaign_star AS
SELECT
    f.fact_id,
    dc.campaign_id,
    ch.channel,
    dd.full_date,
    dd.year,
    dd.quarter,
    dd.month,
    dd.month_name,
    f.impressions,
    f.clicks,
    f.leads,
    f.conversions,
    f.cost_usd,
    f.revenue_usd
FROM fact_campaign_performance f
JOIN dim_campaign dc ON f.campaign_key = dc.campaign_key
JOIN dim_channel ch ON f.channel_key = ch.channel_key
JOIN dim_date dd ON f.date_key = dd.date_key;

CREATE OR REPLACE VIEW vw_kpi_overall AS
SELECT
    ROUND(SUM(cost_usd), 2) AS total_spend,
    ROUND(SUM(cost_usd) / NULLIF(SUM(clicks), 0), 2) AS cpc,
    ROUND(SUM(cost_usd) / NULLIF(SUM(conversions), 0), 2) AS cac,
    ROUND(SUM(revenue_usd) / NULLIF(SUM(cost_usd), 0), 2) AS roas
FROM fact_campaign_performance;

CREATE OR REPLACE VIEW vw_kpi_by_channel AS
SELECT
    ch.channel,
    ROUND(SUM(f.cost_usd), 2) AS total_spend,
    ROUND(SUM(f.cost_usd) / NULLIF(SUM(f.clicks), 0), 2) AS cpc,
    ROUND(SUM(f.cost_usd) / NULLIF(SUM(f.conversions), 0), 2) AS cac,
    ROUND(SUM(f.revenue_usd) / NULLIF(SUM(f.cost_usd), 0), 2) AS roas
FROM fact_campaign_performance f
JOIN dim_channel ch ON f.channel_key = ch.channel_key
GROUP BY ch.channel;

CREATE OR REPLACE VIEW vw_kpi_by_campaign AS
SELECT
    dc.campaign_id,
    ch.channel,
    ROUND(f.cost_usd, 2) AS total_spend,
    ROUND(f.cost_usd / NULLIF(f.clicks, 0), 2) AS cpc,
    ROUND(f.cost_usd / NULLIF(f.conversions, 0), 2) AS cac,
    ROUND(f.revenue_usd / NULLIF(f.cost_usd, 0), 2) AS roas
FROM fact_campaign_performance f
JOIN dim_campaign dc ON f.campaign_key = dc.campaign_key
JOIN dim_channel ch ON f.channel_key = ch.channel_key;

CREATE OR REPLACE VIEW vw_kpi_monthly AS
SELECT
    dd.year,
    dd.month,
    dd.month_name,
    ROUND(SUM(f.cost_usd), 2) AS total_spend,
    ROUND(SUM(f.cost_usd) / NULLIF(SUM(f.clicks), 0), 2) AS cpc,
    ROUND(SUM(f.cost_usd) / NULLIF(SUM(f.conversions), 0), 2) AS cac,
    ROUND(SUM(f.revenue_usd) / NULLIF(SUM(f.cost_usd), 0), 2) AS roas
FROM fact_campaign_performance f
JOIN dim_date dd ON f.date_key = dd.date_key
GROUP BY dd.year, dd.month, dd.month_name;

SELECT * FROM vw_kpi_overall;
SELECT * FROM vw_kpi_by_channel ORDER BY roas DESC;
SELECT * FROM vw_kpi_monthly ORDER BY year, month;
SELECT * FROM vw_kpi_by_campaign ORDER BY roas DESC LIMIT 20;
SELECT * FROM vw_campaign_star LIMIT 20;
