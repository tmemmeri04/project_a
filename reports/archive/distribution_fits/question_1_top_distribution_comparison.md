# Question 1: distribution comparisons for all 20 top-water groups

## Scope

This extends the single-group gamma check to the same 20 groups used in
`top_seasonal_probabilities`: 12 individual site/method/season groups,
6 site/season groups pooling methods, and 2 seasonal groups pooling methods
and sites. Bottom-water measurements are excluded. Failure is DO <= 5 mg/L.

The analysis uses all usable readings within each group. Missing DO is excluded;
recorded zeros remain in empirical probabilities. Normal, gamma and lognormal
parameters are fitted by maximum likelihood. Fits use original-scale densities,
including the appropriate transformation factor in the lognormal density.

## Recorded zeros and AIC

The user selected a separate-zero model for gamma and lognormal:

`P(DO <= 5) = p0 + (1 - p0) * F_positive(5)`,

where `p0` is the observed fraction of usable readings recorded as zero and
the positive distribution is fitted using readings above zero. Five groups
contain zeros. Both positive-family models use the same separate zero mass;
their mixed log-likelihood includes the zero counts and positive-component
probabilities, with three parameters counted in AIC. Without zeros, ordinary
two-parameter gamma and lognormal fits are used.

Normal is fitted to all usable readings as an ordinary continuous benchmark.
Its AIC is deliberately omitted in the five groups containing zeros: a fully
continuous likelihood is not directly ranked against likelihoods with separate
zero masses. All three AICs are comparable in the 15 zero-free groups. AIC is
compared within each group only, never between different aggregation levels.

Treating recorded zeros as a separate component is an exploratory observation
model; it does not establish that the zeros are physically exact. Rounding or
detection-limit mechanisms could justify different models.

## Main results

| Aggregation | Gamma lowest AIC | Normal lowest AIC | Lognormal lowest AIC |
|---|---:|---:|---:|
| Individual methods: 12 groups | 6 | 5 | 1 |
| Methods pooled: 6 groups | 3 | 3 | 0 |
| Sites and methods pooled: 2 groups | 1 | 1 | 0 |

Of the 15 zero-free groups, normal has the lowest AIC in 9, gamma in 5,
and lognormal in 1. Gamma has lower AIC than lognormal in all five groups
containing zeros. Normal was not in those five AIC comparisons.

Four groups have another eligible model less than 2 AIC units from the minimum:
NC1 CTD top winter, NC1 Winkler top winter, NC2 Winkler top winter, and NC3
CTD top summer. These close comparisons do not support a clear separation.

Summer: gamma has the lowest eligible AIC in 8 of 10 groups, lognormal in 1,
and normal in 1. Winter: normal has the lowest AIC in 8 of 10 groups, gamma
in 2. Groups overlap, so these counts are descriptions, not independent votes.

### Both methods and all sites pooled

| Season | Empirical | Normal | Lognormal | Gamma | Lowest eligible AIC |
|---|---:|---:|---:|---:|---|
| Summer | 63.68% | 57.72% | 64.70% | 63.52% | Gamma |
| Winter | 5.75% | 4.73% | 4.72% | 4.20% | Normal |

The CSV files retain full precision; display values here are rounded.

For the 12 individual-method groups, mean absolute differences from empirical
threshold probabilities are 2.06 percentage points for gamma, 2.57 for lognormal,
and 3.84 for normal. These are in-sample descriptive discrepancies and do not
measure future predictive accuracy. A model's closeness at 5 mg/L is distinct
from its fit across the entire distribution.

## Interpretation and stopping point

The single selected example did not generalize to a universal lognormal winner.
Gamma is a useful candidate for summer groups; normal is often relatively
better in winter. Lowest AIC means relative support among the eligible models,
not proof that a distribution fits adequately. Plots still show departures
from each candidate distribution in some groups.

The maximum fitted-versus-empirical CDF gap is also saved. This calculation
accounts for the jump at zero in the mixed models. It is descriptive, not a
calibrated KS p-value. No new goodness-of-fit hypothesis tests were conducted.

Repeated sampling, paired methods, rounding, missing-data selection and changes
over years are not explicitly modeled. Pooling sites or methods can combine
different populations. The pooled and individual groups reuse observations and
must not be treated as 20 independent replications.

Retain the empirical probabilities as the primary Question 1 estimates and
use these fitted probabilities as a model sensitivity comparison. This completes
the scoped extension; the next assignment task is comparing site means.

## Artifacts and reproduction

Run from the project root:

```r
source("scripts/09_top_water_distribution_fits.R")
```

The optional script reads the processed long data and is not in the main runner.
It leaves the existing empirical table and analysis code unchanged. It creates:

- `top_distribution_probabilities`: 20-row empirical and fitted probability tibble.
- `top_distribution_comparison`: 60 rows containing probabilities, AICs, CDF gaps,
  zero fractions, and negative-tail probabilities.
- `top_distribution_parameters`: fitted location/scale or shape/rate parameters.
- `top_distribution_ranking`: within-group AIC rankings and models within 2 units.

Each table is exported as CSV and LaTeX under `outputs/tables/`. Figures are
`outputs/figures/top_distribution_individual_cdfs` and
`outputs/figures/top_distribution_pooled_cdfs`, each as PNG and PDF.
Generated outputs are ignored by Git; rerun the script to recreate them.

Validation: confirmed 20 groups, 60 finite fitted probabilities, 120 parameter
estimates, unchanged empirical probabilities, raw-data counts for every grouping,
gamma likelihood equations, mixture probabilities, and recomputed comparable AICs.
Both CDF figures were visually inspected.

References: [MASS fitting](https://www.stat.math.ethz.ch/R-manual/R-devel/library/MASS/html/fitdistr.html),
[zero-modified lognormal](https://search.r-project.org/CRAN/refmans/EnvStats/html/ZeroModifiedLognormal.html),
[R AIC documentation](https://stat.ethz.ch/CRAN/web/packages/stats/refman/stats.html#AIC).
