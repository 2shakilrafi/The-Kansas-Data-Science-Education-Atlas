library(targets)

source("R/read-data.R")
source("R/accessibility.R")
source("R/maps.R")
source("R/optimization.R")
source("R/optimization-map.R")

tar_option_set(
  packages = c(
    "dplyr", "ggplot2", "janitor", "purrr", "readr", "sf", "tibble",
    "tidyr", "units"
  ),
  seed = 20260824
)

list(
  tar_target(atlas_file, "dataset7.csv", format = "file"),
  tar_target(
    county_geometry_file,
    "../frontend/public/kansas-counties.geojson",
    format = "file"
  ),
  tar_target(atlas, read_atlas(atlas_file)),
  tar_target(data_audit, create_data_audit(atlas)),
  tar_target(county_geometry, read_county_geometry(county_geometry_file)),
  tar_target(spatial_atlas, join_county_geometry(county_geometry, atlas)),
  tar_target(county_pairs, build_county_pairs(atlas)),
  tar_target(
    accessibility,
    calculate_accessibility_scenarios(
      county_pairs,
      catchments_km = c(50, 100, 150),
      beta = 3
    )
  ),
  tar_target(
    accessibility_classified,
    classify_access_shadow(accessibility, atlas)
  ),
  tar_target(
    access_map,
    build_access_map(county_geometry, accessibility_classified)
  ),
  tar_target(nearest_provider, calculate_nearest_provider(county_pairs)),
  tar_target(
    scenario_summary,
    create_scenario_summary(accessibility_classified)
  ),
  tar_target(
    priority_counties_100km,
    create_priority_table(accessibility_classified, catchment_km = 100)
  ),
  tar_target(validation, validate_accessibility(accessibility, atlas)),
  tar_target(all_county_pairs, build_all_county_pairs(atlas)),
  tar_target(
    expansion_sites,
    run_expansion_optimization(
      all_county_pairs,
      atlas,
      catchment_km = 100,
      beta = 3,
      max_sites = 5
    )
  ),
  tar_target(accessibility_plot, plot_accessibility_map(access_map)),
  tar_target(access_shadow_plot, plot_access_shadow_map(access_map)),
  tar_target(
    scenario_distribution_plot,
    plot_scenario_distribution(accessibility_classified)
  ),
  tar_target(
    expansion_sites_plot,
    plot_expansion_sites(county_geometry, atlas, expansion_sites)
  ),
  tar_target(
    data_audit_file,
    write_csv_output(data_audit, "output/tables/data-audit.csv"),
    format = "file"
  ),
  tar_target(
    accessibility_file,
    write_csv_output(
      accessibility_classified,
      "output/tables/accessibility-by-county.csv"
    ),
    format = "file"
  ),
  tar_target(
    nearest_provider_file,
    write_csv_output(
      nearest_provider,
      "output/tables/nearest-provider.csv"
    ),
    format = "file"
  ),
  tar_target(
    scenario_summary_file,
    write_csv_output(
      scenario_summary,
      "output/tables/scenario-summary.csv"
    ),
    format = "file"
  ),
  tar_target(
    priority_counties_file,
    write_csv_output(
      priority_counties_100km,
      "output/tables/priority-counties-100km.csv"
    ),
    format = "file"
  ),
  tar_target(
    validation_file,
    write_csv_output(validation, "output/tables/model-validation.csv"),
    format = "file"
  ),
  tar_target(
    expansion_sites_file,
    write_csv_output(
      expansion_sites,
      "output/tables/expansion-site-recommendations.csv"
    ),
    format = "file"
  ),
  tar_target(
    accessibility_plot_file,
    save_plot_output(
      accessibility_plot,
      "output/figures/accessibility-scenarios.png",
      width = 12,
      height = 5.5
    ),
    format = "file"
  ),
  tar_target(
    access_shadow_plot_file,
    save_plot_output(
      access_shadow_plot,
      "output/figures/access-shadow-scenarios.png",
      width = 12,
      height = 6.5
    ),
    format = "file"
  ),
  tar_target(
    scenario_distribution_plot_file,
    save_plot_output(
      scenario_distribution_plot,
      "output/figures/scenario-distributions.png",
      width = 8,
      height = 5
    ),
    format = "file"
  ),
  tar_target(
    expansion_sites_plot_file,
    save_plot_output(
      expansion_sites_plot,
      "output/figures/expansion-site-recommendations.png",
      width = 11,
      height = 6
    ),
    format = "file"
  )
)
