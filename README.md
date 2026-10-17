# Harbor Dissolved Oxygen Analysis

This project analyzes dissolved oxygen measurements at NYC Harbor sampling
locations NC1, NC2, and NC3. See `ANALYSIS_PLAN.md` for the scientific goal,
current progress, and next analysis steps.

## Project layout

```text
project_a/
|-- data/
|   |-- raw/          # Source data, unchanged
|   `-- processed/    # Data derived from the source data
|-- scripts/
|   |-- 01_prepare_data.R
|   `-- archive/      # Reference code outside the active workflow
|-- outputs/
|   |-- figures/      # Generated plots (not committed by default)
|   `-- tables/       # Generated tables (not committed by default)
|-- reports/          # Future Quarto/LaTeX report
|-- ANALYSIS_PLAN.md
`-- Project_A.Rproj
```

## Working with the project

1. Open `Project_A.Rproj` in RStudio. This makes the repository root the
   working directory.
2. Open `scripts/01_prepare_data.R` and run it from a fresh R session.
3. Use paths relative to the project root, built with `file.path()`. Do not use
   `setwd()` or machine-specific absolute paths in project code.
4. Treat files under `data/raw/` as read-only. Write derived data to
   `data/processed/`, figures to `outputs/figures/`, and tables to
   `outputs/tables/`.

## Path and dependency packages

The project currently uses base R project-relative paths, so it has no new
path-package dependency. If scripts later need to run reliably from nested
directories or during report rendering, add the `here` package and use
`here::i_am()` plus `here::here()`. The lower-level `rprojroot` package is most
useful when custom root-detection rules are needed; this project does not need
that complexity yet.

For reproducible package versions, initialize `renv` once the current script
runs cleanly from a fresh session. Commit `renv.lock`, `.Rprofile`,
`renv/activate.R`, and `renv/settings.json`; do not commit the project package
library.

## Data provenance

The raw data comes from the NYC Open Data Harbor Water Quality dataset:
https://data.cityofnewyork.us/Environment/Harbor-Water-Quality/5uug-f49n/about_data

The current raw snapshot is `data/raw/Harbor_Water_Quality_20260929.csv`.
