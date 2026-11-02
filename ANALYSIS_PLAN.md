# Harbor Dissolved Oxygen Analysis Plan

## Goal

Analyze dissolved oxygen at locations NC1, NC2, and NC3 using four measurements:

- CTD top
- CTD bottom
- Winkler top
- Winkler bottom

For each requested grouping, report the histogram, sample size, missing-value count, mean, standard deviation, and skewness. Later, add statistical models and produce an automated LaTeX report.

## Working approach

The user writes the R code. Codex acts as a tutor by explaining concepts, reviewing the user's code and output, and giving incremental hints. Codex should not edit or rewrite the R analysis unless explicitly asked.

## Project organization

- `data/raw/` contains the source dataset exactly as downloaded.
- `data/processed/` contains derived datasets created from the raw data.
- The active workflow runs in this order:
  1. `scripts/01_create_filtered_data.r` selects locations and measurement columns from the raw data.
  2. `scripts/02_wide_long_converter.r` loads the filtered data, converts types, and reshapes it to long format.
  3. `scripts/03_data_sumarrizer.r` loads the long data and creates `summarized_data`.
- `scripts/archive/` contains reference code that is not part of the active workflow.
- `scripts/99_as_yet_unsused_sorting_scripts.r` contains unused location-splitting and seasonal code. It is outside the active workflow but has not yet been moved into the archive.
- `outputs/figures/` and `outputs/tables/` are for generated results.
- `reports/` is reserved for the later Quarto or LaTeX report.
- Run project code from the project root, whether using VS Code or opening `Project_A.Rproj` in RStudio.

## Current status

Validated on November 2, 2026, using the saved scripts and local data:

- `filtered_data.csv` contains 2,224 rows for NC1, NC2, and NC3 with four dissolved-oxygen measurement columns. It matches the current raw-data selection after normalizing date formatting and numeric types.
- Script 02 converts the Winkler columns to numeric and `Sample.Date` to `Date` before reshaping.
- `long_data` contains 8,896 rows, all four expected measurement labels, numeric `Dissolved_Oxygen`, and no missing dates. The saved long-data object matches the current transformation.
- Each measurement has 741 rows at NC1, 741 at NC2, and 742 at NC3.
- Script 03 runs successfully and creates `summarized_data` with 12 rows containing total rows, missing rows, usable rows, mean, median, and standard deviation. The missing comma has been fixed.
- Missing-value counts per location/measurement group range from 229 to 233 for CTD and 168 to 178 for Winkler.
- `summarized_data` exists in the R session but is not yet exported. It remains grouped by `Sampling.Location` after `summarise()`.
- Skewness, faceted histograms, broader summaries, reporting, and modeling have not yet been implemented.

## Workflow issues still to resolve

- Script 01's `write_csv()` call is commented out. The existing filtered file is valid, but running scripts 01–03 does not yet recreate all derived data from scratch.
- The saved scripts currently use `saveRDS()` and `readRDS()` for `data/processed/long_data.csv`. Its contents are RDS binary data despite the `.csv` extension. Align the filename and reader/writer: use `.rds` for R objects, or a CSV writer/reader for readable text. If choosing CSV, restore date types when loading it.
- `README.md` still references the nonexistent `scripts/01_prepare_data.R`; update it to describe the three-script workflow.
- Move the unused script 99 into `scripts/archive/` when organizing reference code; do not include it in the active run sequence.

## Analysis stages and progress

1. Reshape the filtered data from wide to long form - **implemented and validated**.
   - Sampling location and date are retained.
   - `Measurement` identifies the four measurement types.
   - `Dissolved_Oxygen` is numeric and `Sample.Date` is a `Date`.
   - The validated output contains 8,896 rows (2,224 input rows times four measurements).
   - The output filename/format mismatch remains a workflow issue, as documented above.

2. Create the 12 primary summaries - **existing statistics implemented and validated; skewness pending**.
   - Group by location and measurement.
   - Three locations times four measurements should produce 12 groups.
   - Calculate total count, usable count, missing count, mean, median, standard deviation, and skewness.
   - Total, missing, and usable counts, mean, median, and standard deviation are already calculated in the 12-row `summarized_data` object.
   - Export the completed summary to `outputs/tables/`.
   - Choose and document a skewness definition before adding it.

3. Create the 12 primary histograms - **not started**.
   - Use one 3-by-4 faceted figure: location by measurement.
   - Use consistent bin boundaries and axis scales when comparisons require them.

4. Create broader summaries - **not started**.
   - Each measurement across all locations: 4 results.
   - Each location across all measurements: 3 results.
   - All locations and measurements combined: 1 result.
   - Together with the primary summaries, this produces 20 summary rows.

5. Build the reporting workflow - **not started**.
   - Keep data preparation, summaries, figures, and reporting as separate stages.
   - Use knitr or Quarto to insert results and figures into a reproducible LaTeX/PDF report.
   - Build the report only after the summary table and histogram figure are verified.

6. Add modeling and prediction - **not started**.
   - First decide whether the goal is distribution fitting or prediction.
   - For prediction, clearly identify the response and predictors.
   - Start with models suitable for continuous dissolved-oxygen measurements and validate them with diagnostics and out-of-sample testing.
   - Export model definitions, estimates, diagnostics, and prediction results to the report.

## Statistical decisions to document

- Specify the skewness formula or package, including bias correction.
- Always report sample sizes and missing-value counts. In the current filtered data, CTD measurements have more missing values than Winkler measurements.
- Treat CTD/Winkler and top/bottom as different measurement types unless there is a scientific reason to pool them.
- Recognize that measurements from the same sampling event may be paired rather than independent.
- Before pooling methods, decide whether to average within each sampling event or treat every available measurement as a separate observation.
- Poisson models are generally for count responses and are not a natural choice for continuous dissolved-oxygen values. A Gaussian model is a more reasonable initial candidate, subject to diagnostic checks.
- Account for dates, seasonality, and repeated sampling when designing prediction tests; avoid relying only on a random train/test split if future-date prediction is the goal.

## Immediate next step

1. Align the long-data filename with its actual format and keep scripts 02 and 03 consistent.
2. Make the filtered-data export reproducible from script 01, then verify the full workflow from a fresh R session.
3. Choose and document the skewness definition, then add it to the existing summary.
4. Export the completed 12-row summary to `outputs/tables/`.
5. Build the 3-by-4 histogram grid with deliberate bin boundaries and axis scales.

Update the README and archive placement alongside these workflow changes. Recheck row counts, types, and missing-value counts when changing the data format or preparation steps.
