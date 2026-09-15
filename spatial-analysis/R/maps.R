build_access_map <- function(county_geometry, accessibility_classified) {
  county_geometry |>
    dplyr::left_join(
      accessibility_classified,
      by = c("county_name" = "demand_county"),
      relationship = "one-to-many"
    )
}

map_theme <- function() {
  ggplot2::theme_void(base_size = 11) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", size = 15),
      plot.subtitle = ggplot2::element_text(color = "#475569"),
      plot.caption = ggplot2::element_text(color = "#64748b", hjust = 0),
      strip.text = ggplot2::element_text(face = "bold", size = 11),
      legend.position = "bottom"
    )
}

plot_accessibility_map <- function(access_map) {
  ggplot2::ggplot(access_map) +
    ggplot2::geom_sf(
      ggplot2::aes(fill = physical_access_per_100k),
      color = "white",
      linewidth = 0.18
    ) +
    ggplot2::scale_fill_viridis_c(
      option = "C",
      name = "Physical access\nper 100,000 residents"
    ) +
    ggplot2::facet_wrap(
      ggplot2::vars(catchment_km),
      labeller = ggplot2::labeller(
        catchment_km = \(x) paste0(x, " km catchment")
      )
    ) +
    ggplot2::coord_sf(datum = NA) +
    ggplot2::labs(
      title = "Distance-decayed DS/AI education accessibility",
      subtitle = "Enhanced two-step floating catchment area estimates",
      caption = paste(
        "Supply is the county program-impact score; demand is county population.",
        "Distances are straight-line county representative-point distances."
      )
    ) +
    map_theme()
}

plot_access_shadow_map <- function(access_map) {
  palette <- c(
    "Low physical access + Low digital access" = "#b2182b",
    "Low physical access + High digital access" = "#ef8a62",
    "High physical access + Low digital access" = "#67a9cf",
    "High physical access + High digital access" = "#2166ac"
  )

  ggplot2::ggplot(access_map) +
    ggplot2::geom_sf(
      ggplot2::aes(fill = access_type),
      color = "white",
      linewidth = 0.18
    ) +
    ggplot2::scale_fill_manual(
      values = palette,
      drop = FALSE,
      name = NULL
    ) +
    ggplot2::facet_wrap(
      ggplot2::vars(catchment_km),
      labeller = ggplot2::labeller(
        catchment_km = \(x) paste0(x, " km catchment")
      )
    ) +
    ggplot2::coord_sf(datum = NA) +
    ggplot2::labs(
      title = "Physical and digital DS/AI access types",
      subtitle = "Low/low counties form the baseline DS/AI access shadow",
      caption = "High and low are defined relative to the statewide median within each scenario."
    ) +
    map_theme()
}

plot_scenario_distribution <- function(accessibility_classified) {
  accessibility_classified |>
    dplyr::mutate(
      catchment = factor(
        paste0(catchment_km, " km"),
        levels = paste0(sort(unique(catchment_km)), " km")
      )
    ) |>
    ggplot2::ggplot(
      ggplot2::aes(x = catchment, y = physical_access_per_100k)
    ) +
    ggplot2::geom_violin(fill = "#7c3aed", alpha = 0.22, color = NA) +
    ggplot2::geom_boxplot(width = 0.18, outlier.alpha = 0.35) +
    ggplot2::labs(
      title = "Accessibility changes with the catchment assumption",
      x = "Catchment distance",
      y = "Physical access per 100,000 residents",
      caption = "The 50, 100, and 150 km scenarios are sensitivity analyses, not observed travel behavior."
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold"),
      panel.grid.minor = ggplot2::element_blank()
    )
}

write_csv_output <- function(data, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  readr::write_csv(data, path, na = "")
  path
}

save_plot_output <- function(plot, path, width, height) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  ggplot2::ggsave(
    filename = path,
    plot = plot,
    width = width,
    height = height,
    dpi = 180,
    bg = "white"
  )
  path
}
