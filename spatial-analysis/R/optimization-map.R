plot_expansion_sites <- function(county_geometry, atlas, expansion_sites) {
  strategies <- unique(expansion_sites$strategy)
  base_map <- dplyr::bind_rows(
    lapply(
      strategies,
      function(label) dplyr::mutate(county_geometry, strategy = label)
    )
  ) |>
    sf::st_transform(5070)

  provider_points <- atlas |>
    dplyr::filter(has_programs == 1L) |>
    sf::st_as_sf(
      coords = c("county_longitude", "county_latitude"),
      crs = 4326,
      remove = FALSE
    )
  provider_points <- dplyr::bind_rows(
    lapply(
      strategies,
      function(label) dplyr::mutate(provider_points, strategy = label)
    )
  ) |>
    sf::st_transform(5070)

  selected_points <- expansion_sites |>
    dplyr::left_join(
      atlas |>
        dplyr::select(
          county_name,
          county_longitude,
          county_latitude
        ),
      by = c("selected_county" = "county_name"),
      relationship = "many-to-one"
    ) |>
    sf::st_as_sf(
      coords = c("county_longitude", "county_latitude"),
      crs = 4326,
      remove = FALSE
    ) |>
    sf::st_transform(5070)

  ggplot2::ggplot() +
    ggplot2::geom_sf(
      data = base_map,
      fill = "#f1f5f9",
      color = "white",
      linewidth = 0.2
    ) +
    ggplot2::geom_sf(
      data = provider_points,
      shape = 21,
      fill = "#334155",
      color = "white",
      size = 2,
      stroke = 0.35
    ) +
    ggplot2::geom_sf(
      data = selected_points,
      ggplot2::aes(size = site_number),
      shape = 21,
      fill = "#f59e0b",
      color = "#7c2d12",
      stroke = 0.5
    ) +
    ggplot2::geom_sf_text(
      data = selected_points,
      ggplot2::aes(label = site_number),
      size = 2.8,
      fontface = "bold"
    ) +
    ggplot2::facet_wrap(ggplot2::vars(strategy)) +
    ggplot2::scale_size_continuous(range = c(4, 7), guide = "none") +
    ggplot2::coord_sf(datum = NA) +
    ggplot2::labs(
      title = "Greedy location-allocation recommendations",
      subtitle = paste(
        "Numbers show selection order; dark points are existing",
        "provider counties"
      ),
      caption = paste(
        "The 100 km screen maximizes incremental distance-decayed reach",
        "under each objective."
      )
    ) +
    map_theme()
}
