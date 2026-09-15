library(testthat)

project_root <- normalizePath(testthat::test_path("..", ".."))

source(file.path(project_root, "R", "read-data.R"))
source(file.path(project_root, "R", "accessibility.R"))

atlas <- read_atlas(file.path(project_root, "dataset7.csv"))
county_geometry <- read_county_geometry(
  file.path(
    project_root,
    "..",
    "frontend",
    "public",
    "kansas-counties.geojson"
  )
)
pairs <- build_county_pairs(atlas)
accessibility <- calculate_accessibility_scenarios(pairs)
classified <- classify_access_shadow(accessibility, atlas)

test_that("atlas audit is exact", {
  expect_equal(nrow(atlas), 105L)
  expect_equal(dplyr::n_distinct(atlas$county_name), 105L)
  expect_equal(sum(atlas$has_programs == 1L), 17L)
  expect_equal(sum(atlas$online_impact_score > 0), 8L)
  expect_equal(sum(atlas$broadband_coverage_missing), 1L)
  expect_equal(sum(!atlas$low_income_digital_access_valid), 105L)
})

test_that("county-provider matrix is complete", {
  expect_equal(nrow(pairs), 105L * 17L)
  expect_true(all(pairs$distance_km >= 0))
  expect_equal(dplyr::n_distinct(pairs$demand_county), 105L)
  expect_equal(dplyr::n_distinct(pairs$provider_county), 17L)
})

test_that("county geometry joins one-to-one", {
  spatial_atlas <- join_county_geometry(county_geometry, atlas)
  expect_s3_class(spatial_atlas, "sf")
  expect_equal(nrow(spatial_atlas), 105L)
  expect_false(anyNA(spatial_atlas$county_population))
})

test_that("all scenarios produce valid county estimates", {
  expect_equal(nrow(accessibility), 105L * 3L)
  expect_equal(sort(unique(accessibility$catchment_km)), c(50, 100, 150))
  expect_true(all(accessibility$physical_access_per_100k >= 0))
  expect_false(anyNA(accessibility$physical_access_per_100k))
})

test_that("E2SFCA distributes all provider supply", {
  validation <- validate_accessibility(accessibility, atlas)
  expect_true(all(validation$supply_conserved))
  expect_true(all(validation$all_access_nonnegative))
  expect_equal(validation$county_rows, rep(105L, 3L))
})

test_that("access-shadow classification is complete", {
  expect_false(anyNA(classified$access_type))
  expect_true(all(classified$access_shadow %in% c(TRUE, FALSE)))
  expect_equal(nrow(classified), 315L)
  expect_gt(
    sum(classified$catchment_km == 50 & classified$access_shadow),
    0L
  )
})
