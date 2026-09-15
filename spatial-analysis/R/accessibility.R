distance_weight <- function(distance_km, catchment_km, beta = 3) {
  if (catchment_km <= 0) {
    stop("catchment_km must be positive.", call. = FALSE)
  }
  if (beta <= 0) {
    stop("beta must be positive.", call. = FALSE)
  }

  dplyr::if_else(
    distance_km <= catchment_km,
    exp(-beta * (distance_km / catchment_km)^2),
    0
  )
}

build_county_pairs <- function(atlas) {
  demand <- atlas |>
    sf::st_as_sf(
      coords = c("county_longitude", "county_latitude"),
      crs = 4326,
      remove = FALSE
    ) |>
    sf::st_transform(5070)

  providers <- demand |>
    dplyr::filter(total_program_impact_score > 0)

  if (nrow(providers) == 0L) {
    stop("No provider counties were found.", call. = FALSE)
  }

  distance_km <- sf::st_distance(demand, providers) |>
    units::set_units("km") |>
    units::drop_units()

  pairs <- tidyr::expand_grid(
    provider_id = seq_len(nrow(providers)),
    demand_id = seq_len(nrow(demand))
  ) |>
    dplyr::mutate(
      distance_km = as.numeric(distance_km),
      demand_county = demand$county_name[demand_id],
      provider_county = providers$county_name[provider_id],
      population = demand$county_population[demand_id],
      supply = providers$total_program_impact_score[provider_id]
    )

  expected_rows <- nrow(demand) * nrow(providers)
  if (nrow(pairs) != expected_rows || any(pairs$distance_km < 0)) {
    stop("The county-provider distance matrix is invalid.", call. = FALSE)
  }

  pairs
}

calculate_accessibility <- function(pairs, catchment_km, beta = 3) {
  weighted_pairs <- pairs |>
    dplyr::mutate(
      weight = distance_weight(distance_km, catchment_km, beta)
    )

  provider_ratios <- weighted_pairs |>
    dplyr::summarise(
      supply = dplyr::first(supply),
      weighted_demand = sum(population * weight),
      .by = c(provider_id, provider_county)
    ) |>
    dplyr::mutate(
      provider_ratio = dplyr::if_else(
        weighted_demand > 0,
        supply / weighted_demand,
        0
      )
    )

  weighted_pairs |>
    dplyr::left_join(
      provider_ratios |>
        dplyr::select(provider_id, provider_ratio),
      by = "provider_id",
      relationship = "many-to-one"
    ) |>
    dplyr::summarise(
      county_population = dplyr::first(population),
      physical_access_per_100k = sum(provider_ratio * weight) * 100000,
      reachable_providers = sum(weight > 0),
      .by = c(demand_id, demand_county)
    ) |>
    dplyr::mutate(
      catchment_km = catchment_km,
      decay_beta = beta
    )
}

calculate_accessibility_scenarios <- function(
    pairs,
    catchments_km = c(50, 100, 150),
    beta = 3) {
  purrr::map_dfr(
    catchments_km,
    \(catchment) calculate_accessibility(pairs, catchment, beta)
  )
}

classify_access_shadow <- function(accessibility, atlas) {
  accessibility |>
    dplyr::left_join(
      atlas |>
        dplyr::select(
          county_name,
          broadband_access_index,
          poverty_rate,
          county_population,
          has_programs
        ),
      by = c("demand_county" = "county_name"),
      relationship = "many-to-one",
      suffix = c("_model", "_atlas")
    ) |>
    dplyr::mutate(
      physical_median = stats::median(physical_access_per_100k),
      digital_median = stats::median(broadband_access_index),
      physical_group = dplyr::if_else(
        physical_access_per_100k <= physical_median,
        "Low physical access",
        "High physical access"
      ),
      digital_group = dplyr::if_else(
        broadband_access_index <= digital_median,
        "Low digital access",
        "High digital access"
      ),
      access_type = factor(
        paste(physical_group, digital_group, sep = " + "),
        levels = c(
          "Low physical access + Low digital access",
          "Low physical access + High digital access",
          "High physical access + Low digital access",
          "High physical access + High digital access"
        )
      ),
      access_shadow = access_type ==
        "Low physical access + Low digital access",
      .by = catchment_km
    )
}

calculate_nearest_provider <- function(pairs) {
  pairs |>
    dplyr::slice_min(distance_km, n = 1, with_ties = FALSE, by = demand_id) |>
    dplyr::transmute(
      county_name = demand_county,
      nearest_provider_county = provider_county,
      nearest_provider_distance_km = distance_km
    ) |>
    dplyr::arrange(dplyr::desc(nearest_provider_distance_km))
}

create_scenario_summary <- function(accessibility_classified) {
  accessibility_classified |>
    dplyr::summarise(
      minimum = min(physical_access_per_100k),
      first_quartile = stats::quantile(physical_access_per_100k, 0.25),
      median = stats::median(physical_access_per_100k),
      third_quartile = stats::quantile(physical_access_per_100k, 0.75),
      maximum = max(physical_access_per_100k),
      counties_with_zero_access = sum(physical_access_per_100k == 0),
      access_shadow_counties = sum(access_shadow),
      access_shadow_population = sum(
        county_population_atlas[access_shadow]
      ),
      .by = catchment_km
    ) |>
    dplyr::arrange(catchment_km)
}

create_priority_table <- function(accessibility_classified, catchment_km = 100) {
  accessibility_classified |>
    dplyr::filter(
      .data$catchment_km == .env$catchment_km,
      access_shadow
    ) |>
    dplyr::arrange(
      physical_access_per_100k,
      broadband_access_index,
      dplyr::desc(poverty_rate)
    ) |>
    dplyr::transmute(
      county = demand_county,
      population = county_population_atlas,
      physical_access_per_100k,
      broadband_access_index,
      poverty_rate,
      local_program = has_programs == 1L
    )
}

validate_accessibility <- function(accessibility, atlas) {
  total_supply <- sum(atlas$total_program_impact_score)

  accessibility |>
    dplyr::summarise(
      original_supply = total_supply,
      distributed_supply = sum(
        physical_access_per_100k / 100000 * county_population
      ),
      absolute_difference = abs(original_supply - distributed_supply),
      supply_conserved = absolute_difference < 1e-8,
      all_access_nonnegative = all(physical_access_per_100k >= 0),
      county_rows = dplyr::n(),
      .by = catchment_km
    ) |>
    dplyr::arrange(catchment_km)
}
