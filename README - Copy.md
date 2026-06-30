# Multi-Touch Attribution Modeling

This notebook engineers touchpoint-level features and applies three attribution
models to the marketing campaign performance dataset.

## What it does

1. **Feature engineering** — builds journey-level features per user:
   - `touch_order`: sequence number of each touchpoint
   - `path_length`: total touchpoints in the user's journey
   - `is_first_touch` / `is_last_touch`: journey boundary flags
   - `days_since_first_touch`: recency within the journey

2. **Attribution models** — distributes conversion credit across touchpoints:
   - **First-Touch**: 100% credit to the first touchpoint
   - **Last-Touch**: 100% credit to the last touchpoint
   - **Linear**: credit split evenly across all touchpoints in the path

3. **Validation** — confirms credit sums to 1.0 per converting user per model.

4. **Export** — writes two CSVs for Power BI:
   - `attribution_results.csv` (row-level, for drill-down)
   - `channel_attribution_summary.csv` (pre-aggregated, primary dashboard source)

## Before running

Update `DATA_PATH` in section 1 to point to the cleaned campaign performance CSV,
and confirm column names match your schema (`user_id`, `touchpoint_date`,
`channel`, `campaign_id`, `converted`).

## Next step

Join `channel_attribution_summary.csv` with ad spend to compute attributed ROI
per channel per model.
