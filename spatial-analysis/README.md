# Kansas DS/AI spatial analyses

This folder contains two reproducible, county-level analyses written in R.

1. **Analysis 1 — Access shadows:** estimates physical accessibility to DS/AI
   education with a multiscale enhanced two-step floating catchment area
   (E2SFCA) model, then compares physical access with broadband access.
2. **Analysis 2 — Expansion-site optimization:** screens one-to-five-county
   expansion sequences under population-reach and equity-priority objectives.

Both analyses are descriptive planning tools. They do not estimate enrollment,
capacity, travel time, feasibility, causal effects, or funded recommendations.

## Reproduce

From this directory, install the required packages once:

```r
install.packages(c(
  "dplyr", "ggplot2", "gt", "janitor", "purrr", "readr", "scales",
  "sf", "targets", "testthat", "tibble", "tidyr", "tidyverse", "units"
))
```

Run the pipeline and tests:

```r
targets::tar_make()
testthat::test_dir("tests/testthat")
```

Render the source reports with Quarto:

```bash
quarto render access-shadow.qmd
quarto render expansion-site-optimization.qmd
```

Rendered HTML, generated figures and tables, and the `targets` cache are
intentionally excluded from version control. They can be regenerated locally.

## Project structure

- `dataset7.csv`: source county-level Atlas data; never modified by the pipeline.
- `R/read-data.R`: input validation and county-geometry joins.
- `R/accessibility.R`: Analysis 1 distance kernels, E2SFCA estimates, and access-shadow classification.
- `R/optimization.R`: Analysis 2 population and equity optimization.
- `R/maps.R` and `R/optimization-map.R`: maps and output helpers.
- `_targets.R`: reproducible dependency graph for Analyses 1–2.
- `access-shadow.qmd`: Analysis 1 report source.
- `expansion-site-optimization.qmd`: Analysis 2 report source.
- `tests/testthat/`: data-integrity and analytical tests.

## Core assumptions

- Distances use Kansas county representative points projected to EPSG:5070;
  they are not road travel times.
- Analysis 1 evaluates 50, 100, and 150 km catchments with a Gaussian
  distance-decay parameter of 3.
- Analysis 2 uses a 100 km catchment, equal-strength hypothetical hubs, and a
  deterministic greedy search over counties without an observed program.
- The equity objective gives transparent 1–3 priority multipliers based on
  poverty, broadband disadvantage, and lower bachelor's-degree attainment.
