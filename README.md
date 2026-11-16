# Newtown Creek Dissolved Oxygen Analysis

Analysis of NC1, NC2 and NC3, with CTD/Winkler and top/bottom measurements
kept separate. See [ANALYSIS_PLAN.md](ANALYSIS_PLAN.md) for current decisions,
validated status and remaining assignment questions. For another computer or a
new Codex session, start with [CODEX_CONTEXT.md](CODEX_CONTEXT.md).

For a step-by-step explanation of all four questions, see
[the analysis procedure](reports/ANALYSIS_PROCEDURE.md).

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
Install missing packages with `install.packages()`; the runner reports missing
ones, including `nortest`. Packages are not installed automatically, and versions are not
currently locked with `renv`.

To rebuild and validate the workflow, run
`Rscript --vanilla scripts/validate_workflow.R`. This checks raw-data
traceability, counts, probabilities, paired tests, correlations, diagnostics
and exports. See [the validation record](reports/WORKFLOW_VALIDATION.md).

## Active workflow

The runner sources these scripts in order:

| Script | Purpose |
|---|---|
| `00_functions.R` | User-defined skewness and table/figure export helpers |
| `01_create_filtered_data.r` | Select sites, parse source dates, assign seasons |
| `02_wide_long_converter.r` | Reshape; remove negative DO; preserve original time text |
| `03_data_sumarrizer.r` | Summaries and data-quality exports |
| `04_table_creator.R` | Seasonal distribution diagnostics and exploratory time plots |
| `05_probability_analyzers.R` | Seasonal probabilities/intervals, finalized joint probabilities, and seasonal/all-year paired site t-tests |
| `07_top_water_probabilities.R` | Top-water empirical probabilities: 12 method-specific, 6 methods-pooled, 2 all-sites-pooled rows, plus plot |
| `08_bottom_water_probabilities.R` | Matching 20-row bottom-water probability table and plot |
| `09_depth_distribution_diagnostics.R` | Histograms and original/log-scale AD tests for both depth-specific 20-group tables; zero-free comparisons |

Scripts share objects through this ordered run. Run the runner to refresh all
objects after editing; previously loaded R objects do not update themselves.

## Files and outputs

- `data/raw/`: unchanged source snapshot, `Harbor_Water_Quality_20260929.csv`.
- `data/processed/`: regenerated **plain-text CSV**, not RDS. The filtered file
  preserves selected source readings. The long file excludes negative DO rows
  and retains original time text; excluded measurements have a separate log.
- `outputs/tables/`: eighteen tables, each exported as CSV and a LaTeX table fragment.
  `daily_change_correlations` presents Q4 Pearson r values by depth, method,
  and site pair; its LaTeX version displays three decimal places.
  These include seasonal, condensed and 2025 summaries, seasonal probabilities,
  data-quality counts, negative-reading/time audits, and finalized joint results.
  `matched_observations_date_order.csv` additionally lists the current triplets.
  Depth-specific outputs are `top_seasonal_probabilities` and
  `bottom_seasonal_probabilities`; methods/sites are pooled by reading counts.
  Both depth-specific tables also include `assumed_normal`, calculated with
  `pnorm()` using each group's mean and sample SD, recomputed from pooled
  readings where applicable. Their probability plots show empirical estimates.
  At each depth, `*_normality_results` and `*_lognormality_results` contain
  20 groups each; `*_distribution_test_comparison` retains only zero-free groups.
  `paired_site_t_tests` has 12 rows: winter, summer and spring/fall for each of
  three site pairs, then three all-year rows. Its four numeric columns are raw
  two-sided paired t-test p-values, keeping methods/depths separate. Pairwise
  matching requires only the two sites being compared. See
  [Question 3 methods](reports/question_3_methods.md) for assumptions.
- `outputs/tables/archive/`: earlier date/order exports and superseded 30/60-minute
  matching results, retained for reference.
- `outputs/figures/`: nineteen named figures, each exported as PNG and PDF.
  Four distribution diagnostics separate site, method/depth and season; three
  time plots are explicitly exploratory; one shows seasonal probabilities with CIs.
  Two additional figures show the depth-specific 20-row probability tables.
  Four more show original and positive-only log histograms for those groupings:
  `top_grouped_histograms`, `top_grouped_positive_log_histograms`, and the
  corresponding `bottom_*` figures. Each has 20 panels, shared x-axis and
  separate count axes so pooled and smaller groups are both readable.
  `top_combined_methods_histograms` and `bottom_combined_methods_histograms`
  show only pooled CTD/Winkler readings: eight panels each for the three sites
  and all sites combined, separated by Summer/Winter. Zeros are retained.
  `all_sites_combined_histograms` shows four panels: top/bottom by Winter/Summer,
  with both methods and all sites pooled in each panel.
  `joint_probabilities` shows Q2's two joint events in separate panels, with
  CTD/Winkler on the x-axis and top/bottom estimates with 95% Clopper-Pearson
  intervals. These intervals assume independent matched events with a common
  event probability; temporal dependence is not modeled.
  `daily_change_regressions` shows the three site-pair regressions in columns
  and four method/depth combinations in rows, using average changes per elapsed day.
- `outputs/figures/archive/`: older manual figure exports, retained for reference.
- `scripts/archive/`: unused historical code, excluded from the runner.
  The rejected gamma check and top-water distribution-fit comparison, including
  their reports and outputs, are under each folder's `archive/distribution_fits/`.
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
Final joint results are exported as `outputs/tables/joint_probabilities.csv`
and `.tex`; the caption retains the timing qualification. No time filter is planned.
The more complex matcher and its checks are reference-only under
`scripts/archive/time_window_matching/`.

Script 05 now computes seasonal Anderson-Darling results for original DO and
positive-only logged DO in memory; these original 24-group tables are not exported.
The requested simple paired site comparisons now also run in script 05.
Interpretation of these tests, correlations of daily changes, and the report
remain future work.

Source: [NYC Open Data Harbor Water Quality](https://data.cityofnewyork.us/Environment/Harbor-Water-Quality/5uug-f49n/about_data).
