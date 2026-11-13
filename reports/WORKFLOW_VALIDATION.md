# Workflow validation on November 12 2026

The active workflow and optional script 06 passed validation in a fresh R
process. All 15 generated PNG figures were visually inspected. These checks
verify execution, traceability and calculations for the current source snapshot;
they do not remove the statistical limitations documented in the procedure.

## Reproduce the checks

Run from the project root:

```sh
Rscript --vanilla scripts/validate_workflow.R
```

The validator rebuilds the workflow, refreshes derived data and outputs, and
stops on a failed check. Runner output is retained in the ignored file
`outputs/tables/workflow_validation_log.txt`. It does not run archived analyses.

## Verified results

| Area | Checks that passed |
|---|---|
| Source preservation | Raw file checksum unchanged during execution; no Git changes to raw data |
| Data preparation | 2,224 selected records; 8,895 retained long rows; valid dates; one negative excluded; 2,424 missing readings; 6,471 usable readings including 41 zeros |
| Traceability | Site/date selection and all four DO columns agree with raw records; every retained long row reconstructs from the filtered selection |
| Seasons and summaries | Summer 1,090, winter 156, other dates 978; summary dimensions, missing/usable count identities and minimum/mean/maximum bounds |
| Question 1 | Every count, observed probability, normal probability and 95% interval in the 24-row base table and both 20-row depth tables agrees with group readings |
| Question 2 | Matching reconstructs independently; unique event identifiers; complete-event counts 506, 508, 562 and 570; both joint probabilities agree with direct counts |
| Question 3 | Twelve-row table layout; all 48 paired p-values agree with independently reconstructed matches and one-sample tests of paired differences |
| Question 4 | Positive date gaps; one initial missing rate per measurement; all interval rates and 12 Pearson correlations agree with independent calculations; regression plot has 12 panels |
| Diagnostics | Original 24-group tables contain finite AD p-values; all 80 depth-specific AD p-values match direct group tests; both zero-free comparisons have 15 rows; optional script 06 has 20 rows |
| Histograms | Twenty panels per depth-specific figure; original and positive-only histogram counts agree with their corresponding test populations |
| Exports | All 17 CSV tables round-trip to their R objects; matched-event CSV also agrees; 17 nonempty LaTeX fragments; 15 nonempty PNG/PDF pairs with correct file signatures; processed files are plain CSV |
| Visual inspection | All 15 PNG figures inspected for labels, units, panel layout, plotted content and clipping |
| Script syntax | All R scripts, including optional and archived reference scripts, parse successfully |

Raw file SHA256:

```text
B57329FA39401C2F5EB8B9BEA6A7C9E1E025DA28BF521F2C3165056DA8408668
```

## Environment

Validation used R 4.6.1 on Windows with these packages:

| Package | Version |
|---|---|
| here | 1.0.2 |
| readr | 2.2.0 |
| dplyr | 1.2.1 |
| tidyr | 1.3.2 |
| ggplot2 | 4.0.3 |
| knitr | 1.52 |
| nortest | 1.0.4 |

The process reported startup locale warnings and a warning that `here` was built
under R 4.6.2. The workflow completed and all validation assertions passed.
Package versions are recorded here but are not locked by an `renv` file.

LaTeX fragments were generated and checked for table structure, but were not
compiled into a report because no LaTeX engine was available on PATH. The final
report layout still needs its own compilation and visual review.

## Limits and Git scope

Same-day matching remains an approximation to simultaneous conditions. Binomial
intervals and paired t-test inference retain their independence assumptions;
p-values are unadjusted for multiple comparisons. AD tests are exploratory,
and correlations and regression lines are descriptive. Validation did not add
dependence adjustments or change these scientific choices.

The gamma and expanded distribution-fit experiments remain archived. Their
scripts were syntax checked, but their computations were not part of this run.
Generated active and archived outputs are ignored by Git and are recreated by
running the relevant scripts. Active scripts, processed CSV data, methods notes,
archive reference code and the workspace R-diagnostics preference are saved
with the project.
