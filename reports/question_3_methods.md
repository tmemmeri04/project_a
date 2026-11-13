# Question 3: simple paired comparisons of site means

The user requested readable code and a compact table of `t.test()$p.value`.
The implementation is in `scripts/05_probability_analyzers.R`, using the existing
`time_filtered_long_data` date/order numbering from Question 2.

For each measurement type and sampling date, readings at each site are sorted
by recorded time and assigned a sampling-round number. Matching date and round
numbers form site pairs. No time filter is applied, so same-day matching is an
approximation to simultaneous conditions. Unusable times retain the existing
sorting behavior. Zeros are retained, and negative readings have already been
excluded by script 02.

NC1-NC2, NC2-NC3 and NC1-NC3 are constructed separately. Each comparison requires
only its two nonmissing DO readings; a missing third-site reading does not
exclude the pair. Question 2 still uses complete three-site events unchanged.

Seasonal tests use the existing Summer and Winter labels. Missing Season labels
are called Spring/Fall, without changing date rules. Each pair has three
seasonal rows. Three final All year rows pool all seasons across all sampled
years; they are not separate tests for each calendar year.

Each group uses `t.test(first_site, second_site, paired = TRUE)$p.value`:
a two-sided test of zero mean paired difference. The output tibble is
`t_test_mean_diff`, with Pair, Season, CTD_bottom, CTD_top, Winkler_bottom and
Winkler_top columns. Only p-values are included as numeric output. It is
exported as `outputs/tables/paired_site_t_tests.csv` and `.tex`.

The 48 p-values are unadjusted for multiple testing. Paired t inference assumes
independence between matched occasions and a suitable sampling distribution
for their mean difference. Dependence over time, missingness and approximate
matching remain limitations. Normality of each site's marginal observations
is not itself the paired-test assumption; the differences matter. P-values
alone do not give the direction or size of a difference. Comparing seasonal
p-values does not test whether the seasonal mean differences differ.

These tests implement the requested simple workflow; interpretation and any
additional inference remain to be discussed with the user.
