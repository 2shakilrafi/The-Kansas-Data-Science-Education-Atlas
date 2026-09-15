read_atlas <- function(path) {
  required_columns <- c(
    "county_name",
    "county_population",
    "county_latitude",
    "county_longitude",
    "online_impact_score",
    "total_program_impact_score",
    "broadband_access_index",
    "avg_broadband_coverage_pct",
    "poverty_rate",
    "young_adult_bachelors_plus_rate",
    "four_year_colleges",
    "low_income_digital_access_rate",
    "has_programs"
  )

  atlas <- readr::read_csv(path, show_col_types = FALSE) |>
    janitor::clean_names()

  missing_columns <- setdiff(required_columns, names(atlas))
  if (length(missing_columns) > 0L) {
    stop(
      "Dataset is missing required columns: ",
      paste(missing_columns, collapse = ", "),
      call. = FALSE
    )
  }

  atlas <- atlas |>
    dplyr::mutate(
      broadband_coverage_missing = avg_broadband_coverage_pct == -1,
      avg_broadband_coverage_pct = dplyr::na_if(
        avg_broadband_coverage_pct,
        -1
      ),
      low_income_digital_access_valid = dplyr::between(
        low_income_digital_access_rate,
        0,
        1
      )
    )

  if (nrow(atlas) != 105L) {
    stop("Expected 105 Kansas counties; found ", nrow(atlas), ".", call. = FALSE)
  }
  if (dplyr::n_distinct(atlas$county_name) != 105L) {
    stop("County names are not unique.", call. = FALSE)
  }
  if (anyNA(atlas$county_latitude) || anyNA(atlas$county_longitude)) {
    stop("County coordinates contain missing values.", call. = FALSE)
  }
  if (!all(atlas$has_programs %in% c(0L, 1L))) {
    stop("has_programs must contain only 0 and 1.", call. = FALSE)
  }
  if (!all(atlas$has_programs == as.integer(atlas$total_program_impact_score > 0))) {
    stop("has_programs is inconsistent with total_program_impact_score.", call. = FALSE)
  }

  atlas
}

read_county_geometry <- function(path) {
  geometry <- sf::st_read(path, quiet = TRUE) |>
    dplyr::transmute(
      geoid = paste0(STATE, COUNTY),
      county_name = paste(NAME, LSAD),
      geometry
    )

  if (nrow(geometry) != 105L) {
    stop("Expected 105 county geometries; found ", nrow(geometry), ".", call. = FALSE)
  }
  if (any(!sf::st_is_valid(geometry))) {
    geometry <- sf::st_make_valid(geometry)
  }

  geometry
}

join_county_geometry <- function(county_geometry, atlas) {
  joined <- county_geometry |>
    dplyr::left_join(
      atlas,
      by = "county_name",
      relationship = "one-to-one"
    )

  if (nrow(joined) != 105L || anyNA(joined$county_population)) {
    stop("County geometry did not join one-to-one with the atlas data.", call. = FALSE)
  }

  joined
}

create_data_audit <- function(atlas) {
  tibble::tibble(
    check = c(
      "County rows",
      "Unique county names",
      "Counties with DS/AI programs",
      "Counties with online program impact",
      "Missing broadband-coverage values",
      "Low-income digital-access values outside 0-1",
      "Duplicate county names"
    ),
    value = c(
      nrow(atlas),
      dplyr::n_distinct(atlas$county_name),
      sum(atlas$has_programs == 1L),
      sum(atlas$online_impact_score > 0),
      sum(atlas$broadband_coverage_missing),
      sum(!atlas$low_income_digital_access_valid),
      sum(duplicated(atlas$county_name))
    ),
    interpretation = c(
      "Complete Kansas county coverage expected",
      "Must match the row count",
      "Physical provider counties in the baseline model",
      "Provider-side online supply, not resident utilization",
      "Converted from the -1 sentinel to NA",
      "Excluded from the access-shadow index pending validation",
      "Must equal zero"
    )
  )
}
