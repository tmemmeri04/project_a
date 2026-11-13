# Codex handoff — November 12, 2026

## Start here

Read this file, `ANALYSIS_PLAN.md`, `README.md`, and
`reports/question_2_methods.md` before changing anything. The Markdown plan is
authoritative; `ANALYSIS_PLAN.html` is an older rendered snapshot.

The user is learning R and normally writes their own analysis code. Tutor and
review neutrally, explain specific errors, and give small hints. Do not write or
rewrite analysis code unless explicitly requested. Preserve descriptive names
and the user's chosen skewness formula. The latest request authorized the
depth-specific histograms and AD diagnostics in script 09. The user then
explicitly requested very simple Question 3 code in script 05: pairwise matched
seasonal/all-year t-tests, with p-values as the only numeric table output.
Keep subsequent teaching question-led and code readable; do not add complexity
or additional analyses without a request.

## Resume on the other computer

In that computer's existing project checkout, with local work committed first:

```sh
git switch main
git pull --ff-only origin main
Rscript --vanilla scripts/000_runtime.R
```

If Git reports local changes or divergent history, inspect those changes before
integrating; do not reset or overwrite them. The checkout path may differ between
machines. Required R packages are `here`, `readr`, `dplyr`, `tidyr`, `ggplot2`,
`knitr`, and `nortest`. The runner preflight checks all of these packages.
No package lockfile exists.

Scripts share objects through the runner. Source it in a fresh session to refresh
everything; `Rscript` exits after running, so use `source("scripts/000_runtime.R")`
in an interactive R session when inspecting resulting objects.

Processed CSVs are tracked. Generated tables/figures, including archived outputs,
are ignored by Git and do not transfer to the other machine. Run the pipeline to
recreate active outputs. The archived matching scripts transfer as reference code;
the separate historical sensitivity outputs are not part of this Git sync.

## Current direction

- NC1–NC3; keep CTD/Winkler and top/bottom separate. Failure is DO <= 5 mg/L.
- Preserve raw data. Exclude negative measurement rows from long data, retain
  missing DO and recorded zeros, and use positive values only for log diagnostics.
- Summer is June 21–September 20; winter is December 21–March 20, inclusive.
- Question 2 is settled: same-day/order complete triplets, all seasons pooled,
  without a time filter. The documented 30-minute sensitivity check supports
  numerical robustness but does not establish exact simultaneity. The user has
  finalized these joint probabilities without a time filter. Export names are
  `joint_probabilities.csv` and `.tex`; retain the timing disclaimer when
  presenting results. No time filter or further matching change is pending.
- `scripts/archive/` is reference-only and excluded from the runner. Do not
  reintroduce the complex time-window matcher without an explicit request.

## Latest work and next discussion

The saved script 05 now includes `normality_results` and `lognormality_results`,
using `nortest::ad.test()` across 24 site/measurement/season groups each. These
tables exist in memory and are not exported. Original DO includes zeros; the
logged analysis uses positive observations only. At the code's 0.05 threshold,
10 original-scale groups and 19 logged groups reject normality. Its "Pass" label
means failure to reject, not proof of a normal distribution. Discuss rounded data,
dependence, multiple tests and the different populations before drawing conclusions.

The user decided not to use the single-group gamma check or the expanded
top-water distribution comparison. Both scripts, reports and outputs are now
under `archive/distribution_fits/` in their respective folders, reference-only.
Do not resume those experiments without a new request.

The active Question 1 additions are script 07 (top water) and script 08 (bottom
water): each creates a 20-row empirical probability table and matching plot,
with 12 method-specific, 6 methods-pooled and 2 all-sites-pooled seasonal rows.
Zeros are retained; pooled probabilities use reading counts. Both run after 05.
Both 20-row tables also include `assumed_normal`, using `pnorm()` with the mean
and sample SD of each group's usable readings, including zeros. Pooled groups
are fitted from pooled readings rather than averaged subgroup probabilities.
Script 06 remains an optional zero-free AD comparison and is not in the runner.

Script 09 now replicates original-scale and positive-only log histograms and
AD tests for each depth's 20 groups, plus script-06-style zero-free comparisons.
Histograms use underlying readings, not the 20 probability values. Each has
20 panels with shared x-axis and separate count axes. New tests are diagnostic;
the archived parametric fitting experiments remain unused.

Question 3 code now builds separate NC1-NC2, NC2-NC3 and NC1-NC3 pair datasets,
reusing date/order matching but requiring only the two relevant readings.
Missing existing Season values are labeled Spring/Fall. `t_test_mean_diff`
has 12 rows (9 seasonal, then 3 all-year) and 4 method/depth p-value columns.
`paired_site_t_tests.csv` and `.tex` are exported. Tests are two-sided and
unadjusted; All year pools all sampled years. Question 2's triple matching
and numerical results are unchanged. See `reports/question_3_methods.md`.

Question 4 now defines average change per day as the later-minus-earlier DO
difference divided by elapsed calendar days, using consecutive complete
three-site matches separately within each method/depth. The user's `daily_changes`
and `corr_coeff_btwn_sites` calculate rates and Pearson r. All seasons are pooled.
At the user's request, script 05 now
exports `daily_change_regressions` as PNG/PDF: three site-pair columns and four
method/depth rows, with descriptive lm lines and no confidence bands.

Next: interpret the site comparisons/correlations and assemble presentation tables
when requested. The formal report and dependence-adjusted inference remain
unfinished. Long sampling gaps smooth the interval rates; neither r nor the lm
lines address temporal dependence.

## Sync validation

Checked November 12 in a fresh R process:

The complete reproducible check is `Rscript --vanilla scripts/validate_workflow.R`.
It passed on this checkout. See `reports/WORKFLOW_VALIDATION.md` for coverage,
package versions, environment warnings and validation limits. All 15 PNG figures
were visually inspected; generated LaTeX table fragments were not compiled.

- PASS: full runner completes, including both Anderson-Darling tables.
- PASS: filtered 2,224 rows; long 8,895 rows with valid dates; one negative
  excluded, 2,424 missing DO, 6,471 usable DO, 41 zeros retained.
- PASS: 24 seasonal probability groups; count identities and confidence interval
  bounds hold; each Anderson-Darling table has 24 finite p-values.
- PASS: complete joint-event counts remain 506, 508, 562, 570 for CTD bottom,
  CTD top, Winkler bottom, Winkler top respectively.
- PASS: runner completes with scripts 07 and 08; both depth-specific tables have
  20 rows. Bottom pooled usable/failure counts match long data: summer 1,555/1,320;
  winter 260/6. Confidence intervals contain their estimates; bottom plot inspected.
- PASS: script 09 completes in the full runner. Each depth has 20 original and
  20 positive-log AD results with finite p-values, plus 15 zero-free comparison
  rows. Histogram counts match the probability tables and positive-only test
  counts. All four new 20-panel histograms were visually inspected.
- PASS: Question 3 table has 12 rows and 48 finite p-values. Independent matching
  reconstruction and one-sample t-tests of differences agree with all paired
  tests. Minimum seasonal group sizes are 34-35 pairs; finalized Question 2
  numerical results remain identical.
- PASS: all 40 depth-specific normal estimates agree with their raw pooled groups;
  all 12 Pearson correlations and interval rates agree with independent calculations.
- PASS: all 17 CSV tables and the matched-event CSV round-trip correctly; 17 LaTeX
  fragments and 15 PNG/PDF pairs are generated. Raw data is unchanged.

These checks establish reproducible execution and key invariants, not final
scientific validation. Consult `ANALYSIS_PLAN.md` for assumptions and remaining work.
