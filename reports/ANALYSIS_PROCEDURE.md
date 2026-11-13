# Procedure for the Newtown Creek dissolved oxygen analysis

This document describes the procedure used to answer the four project questions
for sampling locations NC1, NC2 and NC3. Dissolved oxygen (DO) is expressed in
mg/L. The analysis uses observed low-oxygen frequencies, paired comparisons of
site means, and descriptive correlations of changes between sampling visits.

The four measurement types are CTD top, CTD bottom, Winkler top and Winkler
bottom. They are analyzed separately except where the two methods are explicitly
pooled within a depth. Top and bottom readings are never pooled together.

## Data preparation

The source is the NYC Open Data Harbor Water Quality dataset, retained locally
as `data/raw/Harbor_Water_Quality_20260929.csv`. The original file is preserved.
Only NC1, NC2 and NC3 records are selected, along with sampling dates, times and
the four DO measurements. Dates are parsed using the source month/day/year format.

The selected data are reshaped into long format, with one row per measurement
type from each sampling record. Negative DO measurements are removed from the
analysis data. Only the affected measurement is removed; other measurements
from that sampling record remain available. Missing DO is retained for quality
counts but excluded from calculations requiring a reading. Recorded zeros are
retained, including when counting low-oxygen events.

Original time text is preserved. Missing or unparseable sampling times remain
missing; replacement times are not invented. Derived data are saved under
`data/processed/`, and excluded negative readings are recorded separately.

The existing seasonal definitions are used throughout:

- **Summer:** June 21 through September 20, inclusive.
- **Winter:** December 21 through March 20, inclusive.
- **Spring/Fall:** all remaining dates. These have a missing seasonal label in
  the original preparation and are relabeled Spring/Fall for Question 3.

## Question 1 Seasonal probabilities of low dissolved oxygen

A low-oxygen event is defined as **DO at or below 5 mg/L**. For each site,
measurement type and season, its empirical probability is calculated as:

\[
\widehat P(DO\leq5)
=\frac{\text{number of usable readings at or below 5 mg/L}}
{\text{number of usable readings}}.
\]

Zeros contribute to both numerator and denominator. Missing readings contribute
to neither. Summer and winter are compared separately.

Separate top-water and bottom-water tables are produced. Each contains 20 rows:

1. Twelve rows for three sites, two methods and two seasons.
2. Six rows combining CTD and Winkler readings within each site and season.
3. Two rows combining both methods and all three sites within each season.

For combined groups, failure counts and usable-reading counts are added before
dividing. The analysis does not average the individual group probabilities.
Consequently, each usable method reading contributes equally to the pooled
estimate, and the result reflects the available mix of methods and sites.

The tables include 95% Clopper-Pearson binomial confidence intervals calculated
with `binom.test()`. Point-and-interval plots display the same estimates.
These intervals assume independent observations with a common event probability
within a group. Paired methods and repeated sampling may violate that assumption.

### Supporting distribution diagnostics

Original-scale histograms and normal Q-Q plots are examined alongside histograms
and Q-Q plots of logged positive DO. Original histograms retain zeros and use
0.5 mg/L bins. Logged histograms exclude zeros and use 0.2 log-unit bins. The
5 mg/L threshold is shown on both scales. The depth-specific grouped histograms
use the same 20 groupings as the probability tables.

Anderson-Darling tests are performed using `nortest::ad.test()` on original DO
and on the natural logarithms of positive readings. Testing normality of logged
positive readings assesses a lognormal model for that positive component only.
It does not assess the recorded zeros. Zero-free comparison tables are also
created so both test labels can be viewed for the same set of observations.

At the 0.05 threshold, Pass means failure to reject normality; it does not prove
normality. The tests are exploratory. No multiple-testing correction is applied,
and rounding and temporal dependence are not explicitly accounted for.
Both the original 24-group probability table
and the depth-specific 20-row tables include empirical probabilities alongside
a plug-in normal estimate in the `assumed_normal` column. This uses
`pnorm(5, mean, sd)`, with the mean and sample SD calculated from that group's
usable DO readings, including zeros. For combined methods or sites, these
parameters are recalculated from all pooled readings; fitted probabilities are
not averaged across subgroups. The normal estimates assume a normal model and
are distinct from the empirical probabilities and their binomial confidence
intervals. The probability plots continue to show the empirical estimates.

## Matching observations across sites

Questions 2 through 4 use date/order matching. Within each sampling date,
measurement type and site, records are sorted by sampling time and numbered
starting at one. Matching date, measurement type and sequence number identify
corresponding readings across sites. Missing DO readings are retained during
numbering and excluded afterward when selecting complete pairs or triplets.
Unknown times sort after known times.

No time-window filter is applied. The matched observations approximate
simultaneous conditions, but readings may have been collected at different times
on the same date. This limitation is retained when presenting results.

## Question 2 Joint low oxygen probabilities

Only matched events with usable DO at all three sites are retained. Calculations
are performed separately for the four measurement types, pooling all seasons
and sampled years.

For each measurement type, the denominator is the number of complete three-site
events. The two numerators count:

- Events where **all three** site readings are at or below 5 mg/L.
- Events where **exactly one** site reading is at or below 5 mg/L and the other
  two readings are above 5 mg/L.

Each count is divided by the same complete-event denominator. These are direct
empirical joint frequencies; individual site probabilities are not multiplied,
and independence between sites is not assumed for these counts.

The results are finalized using the selected same-day/order method. A separate
30-minute sensitivity check was documented previously, but it is not a filter
on the final estimates. The final outputs are `joint_probabilities.csv` and its
LaTeX counterpart. These estimates describe sampled complete occasions, rather
than the proportion of continuous time for which the events occurred.

## Question 3 Paired comparisons of mean dissolved oxygen

Separate matched datasets are created for NC1-NC2, NC2-NC3 and NC1-NC3. Each
comparison requires usable readings only at its two sites. A missing reading
at the third site does not exclude an otherwise complete pair.

For every pair and measurement type, two-sided paired t-tests are performed
separately for winter, summer, spring/fall and all seasons together. The all-year
calculation pools every sampled year; it is not a test for each calendar year.

Each test uses:

```r
t.test(first_site, second_site, paired = TRUE)$p.value
```

The paired differences are first-site DO minus second-site DO. The null
hypothesis is that their population mean is zero. The paired t-statistic is:

\[
t=\frac{\bar d}{s_d/\sqrt n},
\]

where \(\bar d\) is the mean paired difference, \(s_d\) is its sample standard
deviation, and \(n\) is the number of matched pairs.

The output has 12 rows: three seasonal rows per pair followed by three all-year
rows. Four numeric columns contain the p-values for the separate method/depth
combinations. At an unadjusted significance level of 0.05, a p-value below 0.05
indicates evidence against zero mean difference, subject to the assumptions.
A larger p-value does not establish equality or similarity.

Pairing accommodates dependence between sites within an occasion. The standard
test still assumes independence between paired differences across occasions.
Temporal dependence has not been modeled, and the 48 p-values have not been
adjusted for multiple comparisons. The p-value table alone does not show the
direction or practical size of a difference. Comparing seasonal p-values does
not test whether the seasonal mean differences differ from one another.

## Question 4 Correlation of average changes per day

The complete three-site matched observations are sorted by date within each
measurement type. For each site, the change from the previous matched occasion
is divided by the elapsed number of calendar days:

\[
\text{rate}_{s,t}
=\frac{DO_{s,t}-DO_{s,t-1}}{\text{Date}_t-\text{Date}_{t-1}},
\]

where \(s\) identifies the site. The units are mg/L/day. Positive values indicate
increasing DO and negative values indicate decreasing DO. The first observation
in each measurement group has no preceding observation, so its rate is missing.

These are average rates over sampling intervals. They are not direct
measurements of every day's change. All sites use the same start and end dates
for each interval. In the current matched data, intervals are positive, the
median gap is seven days, and some gaps extend for months. Rates over long gaps
smooth fluctuations that may have occurred within the interval.

Pearson correlation coefficients are calculated between the NC1-NC2, NC2-NC3
and NC1-NC3 rate vectors, separately for each method/depth, using:

```r
cor(site_1_change, site_2_change, use = "complete.obs")
```

The output is Pearson **r**, not its square or adjusted R-squared. All seasons
are pooled. Positive correlations indicate that the average rates tend to move
together. They do not establish causation or statistical significance.

Scatterplots show the three site pairs in columns and the four method/depth
combinations in rows. Ordinary linear regression lines with intercepts are
added using `geom_smooth(method = "lm", formula = y ~ x, se = FALSE)`.
The lines are descriptive; confidence bands are not shown. Correlation
confidence intervals and dependence-adjusted significance tests are not part
of the current procedure. Adjacent rates share endpoint readings, and temporal
dependence and unequal interval lengths remain relevant to interpretation.

## Reproducing the analysis

From a fresh R session in the project root, run:

```r
source("scripts/000_runtime.R")
```

The runner loads the shared functions, selects and reshapes the data, generates
summaries and diagnostic plots, performs the Question 1 through 4 calculations,
and produces the additional depth-specific probability tables and diagnostics.
Scripts share objects through this ordered run.

Required packages are `here`, `readr`, `dplyr`, `tidyr`, `ggplot2`, `knitr` and
`nortest`. The runner checks for missing packages. Package versions are not
currently locked. Tables are exported as CSV and LaTeX fragments under
`outputs/tables/`; figures are exported as PNG and PDF under `outputs/figures/`.
Running the workflow refreshes derived files and leaves the raw source unchanged.
The correlation tibble `corr_coeff_btwn_sites` is currently available in memory;
the regression plot is exported as `daily_change_regressions`.

## Source and related methods notes

- [NYC Open Data Harbor Water Quality](https://data.cityofnewyork.us/Environment/Harbor-Water-Quality/5uug-f49n/about_data).
- [Question 2 matching and sensitivity notes](question_2_methods.md).
- [Question 3 paired comparison notes](question_3_methods.md).

The procedure describes the current analysis as of November 12, 2026.
