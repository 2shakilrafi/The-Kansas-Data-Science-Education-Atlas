standardize_numeric <- function(x) {
  spread <- stats::sd(x, na.rm = TRUE)
  if (!is.finite(spread) || spread == 0) {
    return(rep(0, length(x)))
  }
  (x - mean(x, na.rm = TRUE)) / spread
}

rescale_zero_one <- function(x) {
  bounds <- range(x, na.rm = TRUE)
  if (!all(is.finite(bounds)) || diff(bounds) == 0) {
    return(rep(0, length(x)))
  }
  (x - bounds[[1]]) / diff(bounds)
}

build_all_county_pairs <- function(atlas) {
  points <- atlas |>
    sf::st_as_sf(
      coords = c("county_longitude", "county_latitude"),
      crs = 4326,
      remove = FALSE
    ) |>
    sf::st_transform(5070)

  distance_km <- sf::st_distance(points, points) |>
    units::set_units("km") |>
    units::drop_units()

  pairs <- tidyr::expand_grid(
    site_id = seq_len(nrow(points)),
    demand_id = seq_len(nrow(points))
  ) |>
    dplyr::mutate(
      site_county = points$county_name[site_id],
      demand_county = points$county_name[demand_id],
      distance_km = as.numeric(distance_km),
      demand_population = points$county_population[demand_id]
    )

  if (nrow(pairs) != nrow(atlas)^2 || any(pairs$distance_km < 0)) {
    stop("The all-county distance matrix is invalid.", call. = FALSE)
  }

  pairs
}

create_equity_need_index <- function(atlas) {
  atlas |>
    dplyr::transmute(
      county_name,
      poverty_need = standardize_numeric(poverty_rate),
      broadband_need = -standardize_numeric(broadband_access_index),
      education_need = -standardize_numeric(
        young_adult_bachelors_plus_rate
      )
    ) |>
    dplyr::mutate(
      equity_need_index = rowMeans(
        dplyr::pick(poverty_need, broadband_need, education_need)
      ),
      equity_priority_multiplier = 1 + 2 *
        rescale_zero_one(equity_need_index)
    )
}

optimize_expansion_sites <- function(
    all_pairs,
    atlas,
    strategy = c("Population reach", "Equity priority"),
    catchment_km = 100,
    beta = 3,
    max_sites = 5) {
  strategy <- match.arg(strategy)
  if (max_sites < 1L) {
    stop("max_sites must be at least 1.", call. = FALSE)
  }

  demand <- atlas |>
    dplyr::mutate(demand_id = dplyr::row_number()) |>
    dplyr::left_join(create_equity_need_index(atlas), by = "county_name") |>
    dplyr::arrange(demand_id)

  weighted_pairs <- all_pairs |>
    dplyr::mutate(
      reach_weight = distance_weight(distance_km, catchment_km, beta)
    )

  existing_sites <- atlas$county_name[atlas$has_programs == 1L]
  candidate_sites <- sort(atlas$county_name[atlas$has_programs == 0L])

  current_coverage <- weighted_pairs |>
    dplyr::filter(site_county %in% existing_sites) |>
    dplyr::summarise(
      coverage = max(reach_weight),
      .by = demand_id
    ) |>
    dplyr::arrange(demand_id) |>
    dplyr::pull(coverage)

  baseline_zero <- current_coverage == 0
  priority_multiplier <- if (strategy == "Equity priority") {
    demand$equity_priority_multiplier
  } else {
    rep(1, nrow(demand))
  }

  selections <- vector("list", max_sites)
  selected <- character()

  for (site_number in seq_len(max_sites)) {
    available <- setdiff(candidate_sites, selected)
    candidate_scores <- purrr::map_dfr(
      available,
      function(candidate) {
        candidate_weights <- weighted_pairs |>
          dplyr::filter(site_county == candidate) |>
          dplyr::arrange(demand_id) |>
          dplyr::pull(reach_weight)

        improvement <- pmax(current_coverage, candidate_weights) -
          current_coverage

        tibble::tibble(
          candidate = candidate,
          objective_gain = sum(
            demand$county_population * priority_multiplier * improvement
          )
        )
      }
    ) |>
      dplyr::arrange(dplyr::desc(objective_gain), candidate)

    winner <- candidate_scores$candidate[[1]]
    winner_gain <- candidate_scores$objective_gain[[1]]
    winner_weights <- weighted_pairs |>
      dplyr::filter(site_county == winner) |>
      dplyr::arrange(demand_id) |>
      dplyr::pull(reach_weight)

    current_coverage <- pmax(current_coverage, winner_weights)
    selected <- c(selected, winner)
    winner_attributes <- atlas |>
      dplyr::filter(county_name == winner)

    selections[[site_number]] <- tibble::tibble(
      strategy = strategy,
      site_number = site_number,
      selected_county = winner,
      objective_gain = winner_gain,
      cumulative_equivalent_population_covered = sum(
        demand$county_population * current_coverage
      ),
      cumulative_zero_access_population_reached = sum(
        demand$county_population[baseline_zero & current_coverage > 0]
      ),
      selected_county_population = winner_attributes$county_population,
      selected_county_poverty_rate = winner_attributes$poverty_rate,
      selected_county_broadband_index =
        winner_attributes$broadband_access_index,
      selected_county_four_year_colleges =
        winner_attributes$four_year_colleges
    )
  }

  dplyr::bind_rows(selections)
}

run_expansion_optimization <- function(
    all_pairs,
    atlas,
    catchment_km = 100,
    beta = 3,
    max_sites = 5) {
  purrr::map_dfr(
    c("Population reach", "Equity priority"),
    ~ optimize_expansion_sites(
      all_pairs = all_pairs,
      atlas = atlas,
      strategy = .x,
      catchment_km = catchment_km,
      beta = beta,
      max_sites = max_sites
    )
  )
}
