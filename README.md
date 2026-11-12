# Newtown Creek Dissolved Oxygen Analysis

Analysis of NC1, NC2 and NC3, with CTD/Winkler and top/bottom measurements
kept separate. See [ANALYSIS_PLAN.md](ANALYSIS_PLAN.md) for current decisions,
validated status and remaining assignment questions. For another computer or a
new Codex session, start with [CODEX_CONTEXT.md](CODEX_CONTEXT.md).

## Run the current workflow

Run from the project root in a fresh R session:

```r
source("scripts/000_runtime.R")
```

Or from a terminal in the project root:

```sh
Rscript --vanilla scripts/000_runtime.R
```

Required packages: `here`, `readr`, `dplyr`, `tidyr`, `ggplot2`, `knitr`, `nortest`.
Install missing packages with `install.packages()`; the runner reports any missing
ones, except that its current preflight list omits `nortest`; install that package
too for script 05. Packages are not installed automatically, and versions are not
currently locked with `renv`.

## Active workflow

The runner sources these scripts in order:

| Script | Purpose |
|---|---|
| `00_functions.R` | User-defined skewness and table/figure export helpers |
| `01_create_filtered_data.r` | Select sites, parse source dates, assign seasons |
| `02_wide_long_converter.r` | Reshape; remove negative DO; preserve original time text |
| `03_data_sumarrizer.r` | Summaries and data-quality exports |
| `04_table_creator.R` | Seasonal distribution diagnostics and exploratory time plots |
| `05_probability_analyzers.R` | Seasonal probabilities/intervals and empirical same-day joint probabilities |

Scripts share objects through this ordered run. Run the runner to refresh all
objects after editing; previously loaded R objects do not update themselves.

## Files and outputs

- `data/raw/`: unchanged source snapshot, `Harbor_Water_Quality_20260929.csv`.
- `data/processed/`: regenerated **plain-text CSV**, not RDS. The filtered file
  preserves selected source readings. The long file excludes negative DO rows
  and retains original time text; excluded measurements have a separate log.
- `outputs/tables/`: eight tables, each exported as CSV and a LaTeX table fragment.
  These include seasonal, condensed and 2025 summaries, seasonal probabilities,
  data-quality counts, negative-reading/time audits, and provisional joint results.
  `matched_observations_date_order.csv` additionally lists the current triplets.
- `outputs/tables/archive/`: earlier date/order exports and superseded 30/60-minute
  matching results, retained for reference.
- `outputs/figures/`: eight named figures, each exported as PNG and PDF.
  Four distribution diagnostics separate site, method/depth and season; three
  time plots are explicitly exploratory; one shows seasonal probabilities with CIs.
- `outputs/figures/archive/`: older manual figure exports, retained for reference.
- `scripts/archive/`: unused historical code, excluded from the runner.
- `reports/`: reserved for the report; no report document is implemented yet.

Generated outputs are ignored by Git. Running the pipeline recreates current
outputs and overwrites the three processed CSV files. Raw data is never rewritten.

For LaTeX, include a fragment with `\input{outputs/tables/seasonal_probabilities.tex}`
when compiling from the project root. Fragments include captions and floats;
wide diagnostic tables may need landscape layout or resizing in your report.
Numeric CSV files retain precision; LaTeX display values are rounded.

## Data policy

Negative DO measurements are removed entirely from long data before analysis.
Original readings remain in raw/filtered data and in the separate
`outputs/tables/invalid_oxygen_readings.csv` exclusion log. No duplicate DO or
negative-value flag columns are added to long data. Summary totals describe
retained rows: total = missing + usable.
Recorded zeros are retained, including in the DO <= 5 mg/L event. Log diagnostics
use positive observations only, without adding a constant. Unknown or malformed
times remain missing and are listed for review.

Summer is June 21-September 20 inclusive; winter is December 21-March 20 inclusive.
Spring/fall observations remain in long data and full-year exploratory results.

Question 2's empirical method is finalized using the original date/order approach:
number each site's readings within a date and measurement, pair matching numbers,
and keep complete DO triplets. Results pool all seasons. No time filter is used;
unknown times are not explicitly excluded. A separate 30-minute sensitivity check
changed probabilities by less than one percentage point. Same-day matching is an
approximation to simultaneous conditions; this numerical stability does not prove
exact simultaneity. See [the method and results](reports/question_2_methods.md).
Existing provisional export names/captions retain that timing qualification.
The more complex matcher and its checks are reference-only under
`scripts/archive/time_window_matching/`.

Script 05 now computes seasonal Anderson-Darling results for original DO and
positive-only logged DO in memory; these tables are not yet exported. Mean
comparisons, correlations of daily changes, interpretation of distribution tests,
and the report remain future work.

Source: [NYC Open Data Harbor Water Quality](https://data.cityofnewyork.us/Environment/Harbor-Water-Quality/5uug-f49n/about_data).
