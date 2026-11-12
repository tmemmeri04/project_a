# Codex handoff — November 12, 2026

## Start here

Read this file, `ANALYSIS_PLAN.md`, `README.md`, and
`reports/question_2_methods.md` before changing anything. The Markdown plan is
authoritative; `ANALYSIS_PLAN.html` is an older rendered snapshot.

The user is learning R and normally writes their own analysis code. Tutor and
review neutrally, explain specific errors, and give small hints. Do not write or
rewrite analysis code unless explicitly requested. Preserve descriptive names
and the user's chosen skewness formula. This sync request authorizes committing
the saved changes and updating handoff documentation, not new scientific choices.

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
`knitr`, and `nortest`. The current runner preflight omits `nortest`, although
script 05 requires it. No package lockfile exists.

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
  numerical robustness but does not establish exact simultaneity. Existing
  provisional output names reflect that limitation.
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

Next: help the user review these tests and interpret the results. Site mean
comparisons, daily-change correlations and the report remain unfinished. Daily
changes need an explicit definition because consecutive sampled dates need not
be consecutive calendar days.

## Sync validation

Checked November 12 in a fresh R process:

- PASS: full runner completes, including both Anderson-Darling tables.
- PASS: filtered 2,224 rows; long 8,895 rows with valid dates; one negative
  excluded, 2,424 missing DO, 6,471 usable DO, 41 zeros retained.
- PASS: 24 seasonal probability groups; count identities and confidence interval
  bounds hold; each Anderson-Darling table has 24 finite p-values.
- PASS: complete joint-event counts remain 506, 508, 562, 570 for CTD bottom,
  CTD top, Winkler bottom, Winkler top respectively.

These checks establish reproducible execution and key invariants, not final
scientific validation. Consult `ANALYSIS_PLAN.md` for assumptions and remaining work.
