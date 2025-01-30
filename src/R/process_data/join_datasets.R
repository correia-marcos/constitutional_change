# ============================================================================================
# IDB: Air monitoring
# ============================================================================================
# @Goal: Create configuration file for setup of packages and functions used in the project
#
# @Date: Nov 2024
# @author: Marcos

# Get all libraries and functions
library(here)

# ============================================================================================
# I: Import data
# ============================================================================================
# Define the path to the folder containing the files
final_panel <- read.csv(here::here("results", "datasets", "final_dataset_panel.csv"))
all_textual <- read.csv(here::here("results", "datasets", "all_textual_variables(03_06).csv"))

# ============================================================================================
# II: Process data
# ============================================================================================
