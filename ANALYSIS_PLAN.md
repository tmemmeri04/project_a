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
- `scripts/01_prepare_data.R` contains the active preparation and analysis work.
- `scripts/archive/` contains reference code that is not part of the active workflow.
- `outputs/figures/` and `outputs/tables/` are for generated results.
- `reports/` is reserved for the later Quarto or LaTeX report.
- Run project code from the project root by opening `Project_A.Rproj`.

## Current status

- The data has been filtered to NC1, NC2, and NC3 with four dissolved-oxygen measurement columns.
- Separate location data frames (`nc1_data`, `nc2_data`, and `nc3_data`) have been created, and their dates have been converted to R `Date` values.
- The Winkler columns have been converted to numeric in both the location data frames and `new_fulldata`.
- A `pivot_longer()` transformation has been written to create `long_data` with `Measurement` and `Dissolved_Oxygen` columns.
- A location-by-measurement summary pipeline has been drafted with total rows, missing rows, usable rows, mean, median, and standard deviation.
- The summary block still needs a comma after `total_rows = n()` before it can run.
- `long_data` and the 12-row summary output have not yet been validated from observed R output.
- Skewness, faceted histograms, broader summaries, reporting, and modeling have not yet been implemented.

## Analysis stages and progress

1. Reshape the filtered data from wide to long form - **written; validation pending**.
   - Keep sampling location and date.
   - Create a `Measurement` column identifying the four measurement types.
   - Create a numeric `Dissolved_Oxygen` column containing their values.
   - Verify the result with `str(long_data)` before treating this stage as complete.
   - Confirm whether `Sample.Date` should also be converted in `new_fulldata` or `long_data`; converting dates only in the three location data frames does not change the dates stored in `long_data`.

2. Create the 12 primary summaries - **drafted; not yet run successfully**.
   - Group by location and measurement.
   - Three locations times four measurements should produce 12 groups.
   - Calculate total count, usable count, missing count, mean, median, standard deviation, and skewness.
   - Correct the missing separator in the current `summarise()` call.
   - Assign the verified result to a named object so it can later be plotted or exported.
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
- Always report sample sizes and missing-value counts, especially because Winkler measurements contain more missing data.
- Treat CTD/Winkler and top/bottom as different measurement types unless there is a scientific reason to pool them.
- Recognize that measurements from the same sampling event may be paired rather than independent.
- Before pooling methods, decide whether to average within each sampling event or treat every available measurement as a separate observation.
- Poisson models are generally for count responses and are not a natural choice for continuous dissolved-oxygen values. A Gaussian model is a more reasonable initial candidate, subject to diagnostic checks.
- Account for dates, seasonality, and repeated sampling when designing prediction tests; avoid relying only on a random train/test split if future-date prediction is the goal.

## Immediate next step

Validate the code that is already written before adding more analysis:

1. Add the missing separator after `total_rows = n()` in the summary block.
2. Run through creation of `long_data` and inspect `str(long_data)`.
3. Confirm that the four expected measurement labels exist and `Dissolved_Oxygen` is numeric.
4. Check the date type, missing-value counts, and expected row count of 8,896 (2,224 original rows times four measurements).
5. Run the grouped summary and confirm that it returns exactly 12 rows with plausible statistics.
6. Save that result to a named object; then choose a skewness definition before adding skewness or beginning the histogram grid.
