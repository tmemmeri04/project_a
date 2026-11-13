# Question 1: single-group gamma check

## Scope and method

Exploratory comparison of NC3, CTD top, Summer. This was the individual
top-water seasonal group with the highest user-defined sample skewness
(1.9706), selected before fitting. Its 252 usable readings are all positive;
the minimum is 0.95 mg/L. No zeros were discarded for this comparison.

Normal, lognormal and gamma models were fitted by maximum likelihood using
`MASS::fitdistr()` on the same original-scale DO readings. The lognormal
likelihood includes the transformation factor through its density. Each model
has two fitted parameters. AIC comparisons therefore use a common dataset and
measurement scale. The fitted probability is the model CDF at 5 mg/L.

## Results

The empirical probability is 156 / 252 = **61.90%**.

| Model | Fitted P(DO <= 5) | Difference from empirical, percentage points | AIC | Delta AIC | Maximum CDF gap |
|---|---:|---:|---:|---:|---:|
| Normal | 53.81% | -8.10 | 1097.73 | 68.38 | 0.1197 |
| Lognormal | 61.92% | +0.02 | 1029.35 | 0.00 | 0.0534 |
| Gamma | 59.42% | -2.49 | 1030.27 | 0.92 | 0.0648 |

Gamma shape = 5.95894; rate = 1.24211 per mg/L.

Gamma and lognormal improve on normal by both AIC and the descriptive maximum
gap between fitted and empirical CDFs. Lognormal has the lowest AIC, but its
0.92 advantage over gamma provides little separation between these two models.
It also happens to closely match the empirical probability at the target
threshold; this single-threshold agreement does not establish overall fit.
The normal fit assigns about 1.18% probability to negative DO.

## Limits and stopping point

These are in-sample descriptive comparisons, not a formal goodness-of-fit
acceptance test or an assessment of future prediction. The maximum CDF gap is
not a calibrated KS p-value. Repeated sampling, rounding and changes across
years are not modeled. Selection of a highly skewed group means this result
cannot establish the best distribution for the other groups or pooled data.

This completes the requested single-group check. Retain the empirical
20-row top-water table as the primary Question 1 result and this comparison
as a supporting example. No t-distribution column or model estimates for the
other groups were added.

## Reproduction and artifacts

Run `Rscript --vanilla scripts/08_gamma_fit_check.R` from the project root.
This optional script is not included in the main runner.

- `outputs/tables/gamma_fit_check_comparison.csv` and `.tex`
- `outputs/tables/gamma_fit_check_parameters.csv` and `.tex`
- `outputs/figures/gamma_fit_check_cdf.png` and `.pdf`

Generated outputs are ignored by Git; rerun the script to recreate them.

Method reference: [MASS maximum-likelihood distribution fitting](https://www.stat.math.ethz.ch/R-manual/R-devel/library/MASS/html/fitdistr.html).
