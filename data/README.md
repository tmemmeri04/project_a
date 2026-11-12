# Data directories

- `raw/`: source snapshot as downloaded; never edited by the pipeline.
- `processed/`: regenerated plain-text CSV files, read with CSV readers.
- `reference/`: assignment brief; reference-only.

`filtered_data.csv` preserves selected NC1-NC3 source observations and season
labels. `long_data.csv` excludes negative measurement rows entirely but retains
missing values and zeros. There are no duplicate DO or negative-value flag columns.
Excluded readings remain in the raw/filtered data and in the separate
`outputs/tables/invalid_oxygen_readings.csv` log. `Sample.Time.raw` retains original
text for missing-time review. Zeros remain usable on the original scale.

`summarized_data.csv` contains the 24 seasonal site/method/depth summaries.
The same table and other report exports are under `outputs/tables/`.
See the root README and ANALYSIS_PLAN for the runner, decisions and limitations.

Source: https://data.cityofnewyork.us/Environment/Harbor-Water-Quality/5uug-f49n/about_data
