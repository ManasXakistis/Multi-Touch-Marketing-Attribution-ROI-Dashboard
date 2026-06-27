USE marketing_analytics;

CREATE OR REPLACE VIEW vw_funnel AS
SELECT 1 AS stage_order, 'Impressions' AS stage, SUM(impressions) AS value FROM campaign_performance
UNION ALL
SELECT 2 AS stage_order, 'Clicks' AS stage, SUM(clicks) AS value FROM campaign_performance
UNION ALL
SELECT 3 AS stage_order, 'Leads' AS stage, SUM(leads) AS value FROM campaign_performance
UNION ALL
SELECT 4 AS stage_order, 'Conversions' AS stage, SUM(conversions) AS value FROM campaign_performance;

SELECT * FROM vw_funnel ORDER BY stage_order;
