library(testthat)

project_root <- normalizePath(testthat::test_path("..", ".."))

source(file.path(project_root, "R", "read-data.R"))
source(file.path(project_root, "R", "accessibility.R"))
source(file.path(project_root, "R", "optimization.R"))

atlas <- read_atlas(file.path(project_root, "dataset7.csv"))
all_pairs <- build_all_county_pairs(atlas)

test_that("all-county distance matrix is complete", {
  expect_equal(nrow(all_pairs), 105L^2)
  expect_equal(dplyr::n_distinct(all_pairs$site_county), 105L)
  expect_equal(dplyr::n_distinct(all_pairs$demand_county), 105L)
  expect_true(all(all_pairs$distance_km >= 0))
})

test_that("expansion recommendations are valid", {
  recommendations <- run_expansion_optimization(
    all_pairs,
    atlas,
    max_sites = 5
  )

  expect_equal(nrow(recommendations), 10L)
  expect_setequal(
    unique(recommendations$strategy),
    c("Population reach", "Equity priority")
  )
  expect_equal(
    dplyr::n_distinct(
      recommendations$selected_county[
        recommendations$strategy == "Population reach"
      ]
    ),
    5L
  )
  expect_equal(
    dplyr::n_distinct(
      recommendations$selected_county[
        recommendations$strategy == "Equity priority"
      ]
    ),
    5L
  )
  expect_true(all(recommendations$objective_gain > 0))
  expect_false(any(
    recommendations$selected_county %in%
      atlas$county_name[atlas$has_programs == 1L]
  ))
})
