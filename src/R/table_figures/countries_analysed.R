# ============================================================================================
# IDB: Air monitoring
# ============================================================================================
# @Goal: Create configuration file for setup of packages and functions used in the project
#
# @Date: Nov 2024
# @author: Marcos

# Get all libraries and functions
source(here::here("src", "config", "config_utils.R"))

# ============================================================================================
# I: Import data
# ============================================================================================
# Define the path to the folder containing the files
path_all_constitutions      <- "data/constitutions_all"
path_filtered_constitutions <- "data/constitutions_filtered"

# ============================================================================================
# II: Process data
# ============================================================================================
# Call the function to process the constitutions
constitutions_all      <- process_constitutions(path_all_constitutions)
constitutions_filtered <- process_constitutions(path_filtered_constitutions)

# Create the new dataframe with rows in constitutions_all but not in constitutions_filtered
constitutions_difference <- dplyr::anti_join(constitutions_all,
                                             constitutions_filtered, by = c("Country", "Year"))

# ============================================================================================
# III: Save data
# ============================================================================================

# Export dataframes as LaTeX table
latex_table_removed_cons <- xtable(constitutions_difference,
                                   caption = "Constitution Removed from the final dataset",
                                   label = "tab:constitutions")

latex_table_final_sample <- xtable(constitutions_filtered,
                                   caption = "Final Sample in Dataset",
                                   label = "tab:constitutions")
# ===
# Save first table
# ===

# Open a connection to the file
sink("results/tables/latex_removed_sample.txt")

# Print the LaTeX table to the file
print(latex_table_removed_cons, type = "latex", include.rownames = FALSE)

# Close the connection
sink()

# ===
# Save second table
# ===

# Open a connection to the file
sink("results/tables/latex_final_sample.txt")

# Print the LaTeX table to the file
print(latex_table_final_sample, type = "latex", include.rownames = FALSE)

# Close the connection
sink()
