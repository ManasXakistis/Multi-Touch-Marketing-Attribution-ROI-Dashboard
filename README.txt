# Notebooks

Run the notebooks in the following order:

## 1. `attribution_modeling.ipynb`
Builds touchpoint-level features and applies three attribution 
models to distribute conversion credit across channels.

- Input: simulated touchpoint data
- Output: channel_attribution_summary.csv
- Models: First-Touch, Last-Touch, Linear

## 2. `channel_roi_analysis.ipynb`
Joins attribution output with ad spend data to calculate 
ROI per channel per attribution model.

- Input: channel_attribution_summary.csv
- Output: channel_roi_summary.csv
