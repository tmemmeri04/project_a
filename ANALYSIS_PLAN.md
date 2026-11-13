# Newtown Creek DO: Current Analysis Plan

## Goal and scope

Analyze NC1-NC3 to address the water-quality assignment questions:

1. Probability of DO <= 5 mg/L at each site in summer versus winter.
2. Probability of all three sites, or exactly one site, failing simultaneously.
3. Whether average DO differs between sites at the 95% confidence level.
4. Whether daily changes in DO are correlated across sites.

Keep CTD/Winkler and top/bottom separate. Distribution fitting can support the
answers; it does not replace the mean comparisons or daily-change analysis.
The brief is `data/reference/Project_enveng264_Fall2026.pdf`.

## Working agreement

The user normally writes analysis code and Codex tutors/reviews. On November 11,
2026, the user explicitly authorized cleanup of invalid-value handling, plots,
exports, and active documentation. Sample matching and the remaining assignment
analyses were initially deferred. After comparing alternatives, the user finalized
the original same-day/order empirical method with its time-window sensitivity
check documented separately. No time filter is applied to the active estimates.
The user has now added Anderson-Darling tests to script 05 for original DO and
positive-only logged DO; those tables remain in memory. The subsequent gamma
check and expanded top-water model comparison were rejected by the user and
archived, including their reports and outputs. The active Question 1 extension
uses empirical probabilities for top and bottom water separately. Further
scientific choices should be discussed.
Historical scripts and manually exported figures are reference-only in archive
folders. The README describes the active runner and dependencies.

## Current decisions

- Preserve raw data unchanged. Regenerate derived data from the source snapshot.
- Parse source dates as month/day/year; processed dates are ISO dates.
- Summer: June 21-September 20 inclusive. Winter: December 21-March 20 inclusive.
  Other dates have missing `Season` and are excluded only from seasonal analyses.
- By explicit user preference, script 02 removes negative measurement rows
  entirely from long data. Remove only the affected method/depth observation,
  not the other measurements from that sampling event. No duplicate DO or
  negative-value flag columns are retained. Original values remain in raw/filtered
  data and the separate `invalid_oxygen_readings` exclusion log.
  Summary totals cover retained rows: total rows = missing rows + usable rows.
  Zeros are counted separately within usable rows.
- Retain recorded zeros as observations, without claiming their exact physical
  interpretation is established. They count toward DO <= 5 mg/L.
- Positive-only log diagnostics explicitly exclude zeros and invalid readings.
  No arbitrary constant is added. Any lognormal conclusion will concern the
  positive component unless a different observation model is justified.
- Preserve original sampling time text in `Sample.Time.raw`. Unparseable times
  stay missing; do not guess what numeric-looking time strings mean.
- Retain the user's existing skewness formula by explicit request:
  `sum((x - mean(x))^3) / ((n - 1) * sd(x)^3)`, where SD is R's sample SD.
  This is dimensionless and is not adjusted Fisher-Pearson skewness. Return NA
  for fewer than two values or undefined/zero SD.
- Probability is count(DO <= 5) / count(usable DO) within the same group.
  Preserve numeric precision in analysis; round presentation values only.
- Report 95% Clopper-Pearson binomial intervals for observed proportions, with
  lower and upper limits retained as numeric columns. These assume independent
  observations with a common probability within the group. Temporal dependence,
  nonstationarity, and missing-data selection remain limitations to evaluate.
- `assumed_normal` is a plug-in fitted normal probability using the same usable
  observations. It is neither a goodness-of-fit p-value nor a confidence interval.
- Condensed summaries pool sites but keep measurement and season separate.
  The 2025 summary pools sites and includes only top-water measurements.

## Question 2: finalized empirical method

The full method, counts, probability estimates, sensitivity comparison and
limitations are documented in [reports/question_2_methods.md](reports/question_2_methods.md).

- Use original same-day/order matching: group by date, measurement and site;
  sort by sampling time; number readings; pair matching numbers across sites;
  retain events with nonmissing DO at every site. Pool all seasons and years.
- No time-window filter is applied. Unknown times are not explicitly excluded.
  Describe these as same-day matched observations approximating simultaneous
  conditions, rather than claiming exact simultaneity.
- Separate 30-minute sensitivity analysis removes 4.5-6.1% of complete events.
  Maximum absolute changes are 0.87 percentage points for all-three failure and
  0.61 percentage points for exactly-one failure. This supports numerical
  robustness on this snapshot, not proof of equivalence or accurate timing.
- The joint probabilities are finalized by user decision, without a time filter.
  Exports are `joint_probabilities.csv` and `.tex`. State the same-day matching
  limitation when presenting results; exact simultaneity is not established.
- Date/order matching plus a 30-minute filter gave the same triplets as the more
  complex matcher. That helper, its checks and alternative exports are archived
  as reference-only. Do not reintroduce it without an explicit request.

## Histogram presentation

- Original-scale seasonal histograms use common 0.5 mg/L bins; positive-only
  log histograms use common 0.2 log-unit bins. All 24 panels retain shared axes.
- Summer is NYC DEP-inspired green (#78BE20) and winter blue (#0072CE).
  These approximate the logo palette rather than verified brand specifications.
  Panels display usable sample sizes, readable
  measurement labels and a dashed reference at DO = 5 mg/L (log(5) on log plots).
- These are presentation changes; observations and statistical results are unchanged.

## Distribution diagnostics: current work

- The gamma and expanded top-water distribution-fit experiments are reference-only
  under `archive/distribution_fits/` in scripts, reports and outputs. The user
  does not plan to use them; do not resume model selection without a new request.
- Scripts 07 and 08 generate separate top- and bottom-water empirical tables and
  plots. Each table has 20 seasonal rows: 12 site/method, 6 site with methods
  pooled, and 2 with sites and methods pooled. Pool counts rather than averaging
  probabilities. Zeros remain; 95% binomial intervals retain the independence caveat.
- Both 20-row tables now also include `assumed_normal`, using `pnorm(5, mean, sd)`
  with each group's usable readings, including zeros. Pooled means and sample SDs
  are recalculated from pooled readings. Plots continue to show empirical estimates.
- Script 09 replicates original and positive-only log histograms and AD tests
  for these 20 groups at each depth. Zero-free comparisons follow script 06.
  Original histograms use 0.5 mg/L bins; logged histograms use 0.2 log-unit bins.
  These new grouped histograms share x-axes but use separate count axes for
  readability across different pooling levels. Original script-04 plots are unchanged.
  All groups reuse the same recorded readings; overlapping groups, dependence,
  rounding and multiple tests limit interpretation. These diagnostics do not
  resume the archived distribution-fitting experiments.

- Visual review of the saved seasonal Q-Q plots suggests original-scale normal
  fits are generally closer to straight lines than logged-data normal fits,
  especially in winter. Some summer groups, particularly CTD top, show substantial
  curvature or tail departures even on the original scale.
- This is a visual assessment, not a finding that normality holds in every group.
  Original-scale plots include zeros; log diagnostics concern positive values only.
- Script 05 now runs `nortest::ad.test()` separately for each site/measurement/season
  on original DO (`normality_results`) and positive-only logged DO
  (`lognormality_results`). Both are in-memory tables with 24 groups, not exports.
  A fresh run on November 12 produced 10 original-scale and 19 log-scale groups
  with p <= 0.05. The code labels these "Fail" and other groups "Pass"; a "Pass"
  means failure to reject normality, not proof of normality. Interpretation must
  account for rounded data, repeated sampling, group sample sizes and multiplicity.

## Validated status: November 12, 2026

- Fresh runner includes scripts 01-05, 07 (top probabilities), 08 (bottom probabilities)
  and 09 (depth-specific distribution diagnostics).
- Filtered data: 2,224 rows; reshaping produces 8,896 measurement rows;
  long data retains 8,895 rows with valid dates after excluding one negative.
- Filtered seasonal counts: summer 1,090; winter 156; other dates 978.
- Across retained long data: 2,424 missing readings and 6,471 usable readings,
  including 41 zeros. The separate exclusion log contains one negative reading.
- Seventeen sampling records lack usable times (68 long rows). Three records
  have malformed numeric-looking times; the other source times are missing.
- Seasonal site summaries and probabilities each contain 24 groups.
  Condensed summary: eight groups; 2025 top-water summary: four groups.
- Four empirical date/order joint-probability rows are generated. Complete
  event counts: CTD bottom 506; CTD top 508; Winkler bottom 562; Winkler top 570.
- Seventeen CSV/LaTeX table pairs, one date/order matched-event CSV and fifteen PNG/PDF
  figure pairs are generated. Previous time-window results are archived.
- Seasonal diagnostics use the same site/method/depth/season grouping as the
  probability analysis. Exploratory time plots use all seasons and are labelled.
- All processed files are plain CSV. `summarized_data.csv` is also exported under
  `outputs/tables/` for reporting. No output is an RDS object under a CSV extension.

## Remaining work, in priority order

1. Use the depth-specific empirical tables and plots for Question 1. Distribution
   fitting is closed for now by user decision; its experiments are archived.
   Question 2's empirical method and timing sensitivity are documented; no matching
   change is pending.
2. Review the requested simple paired t-tests in script 05. Separate site pairs
   use complete two-site date/order matches; the 12-row table has winter,
   summer, spring/fall and all-year results, with four method/depth p-value
   columns. Tests are two-sided and unadjusted; interpretation must address
   repeated measurements and multiple comparisons. This is not a finalized
   inference about site differences. See `reports/question_3_methods.md`.
3. Question 4 now uses average change per elapsed day between consecutive
   complete three-site sampling dates, separately by measurement. The user has
   calculated Pearson r values in `corr_coeff_btwn_sites`.
   Script 05 exports `daily_change_regressions`, with three site-pair columns
   and four method/depth rows. These are descriptive results with all seasons
   pooled; temporal dependence is not modeled and long gaps smooth fluctuations.
   No dependence-adjusted significance claim has been made.
4. If the Anderson-Darling diagnostics are included in the report, document their
   assumptions, the positive-only scope of logged tests, rounding, temporal
   dependence and multiplicity. A normality p-value is not model certainty;
   no further distribution fitting is pending.
5. Write the engineering report with numbered/captioned tables and figures,
   source references, justified assumptions and a code appendix. Choose a compact
   subset of current diagnostics; the export collection is not the final report.
6. Consider package version locking once the analysis choices are settled.

## Verification for changes

Use a fresh R process for a full runner check after pipeline changes. Check
row/date preservation, raw-value traceability, invalid/zero treatment, grouped
count identities, probability/CI bounds, expected exports and representative plot
appearance. Keep final scientific validation separate from successful execution.
