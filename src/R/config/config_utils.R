# ============================================================================================
# Constitutions Project
# ============================================================================================
# @Goal: Create configuration file for setup of packages and functions used in the project
#
# @Date: Nov 2024
# @author: Marcos

# Load libraries - groundhog increases code reproducibility
library(groundhog)            # You need to have at least R version = 4.3.1

# Loading required packages 
groundhog.library(
  pkg  = c("here",
           "quanteda",
           "stringr", 
           "tidyr",
           "xtable"),
  date = "2024-12-01")
  
# ############################################################################################
# Functions
# ############################################################################################

# Function --------------------------------------------------------------------
# @Arg       : directory_path is a string specifying the path to the folder with text files
# @Arg       : file_pattern is a string specifying the pattern to match the files
# @Output    : A data frame with columns: Country, Year, and Size (number of words)
# @Purpose   : Processes constitution text files by extracting country and year from filenames,
#              counting the number of words in each document using advanced tokenization,
#              and compiling the information into a data frame
# @Written_on: 07/12/2023
# @Written_by: Marcos Paulo
  
  process_constitutions <- function(directory_path, file_pattern = "\\.txt$") {

    # Get the list of text files in the directory
    file_list <- list.files(path = directory_path, pattern = file_pattern, full.names = TRUE)
    
    # Initialize vectors to store data
    Country <- c()
    Year <- c()
    Size <- c()
    
    # Loop through each file
    for (file in file_list) {
      
      # Get the filename without the path
      filename <- basename(file)
      
      # Remove the file extension
      filename_no_ext <- tools::file_path_sans_ext(filename)
      
      # Use regular expression to extract the country and year
      match <- str_match(filename_no_ext, "^(.*)_(\\d{4})$")
      
      # Check if the filename matches the expected pattern
      if (!is.na(match[1])) {
        # Extract country and year
        country <- match[2]
        year <- as.numeric(match[3])
        
        # Read the content of the file with appropriate encoding
        text <- readLines(file, warn = FALSE, encoding = "UTF-8")
        
        # Combine all lines into a single string
        text <- paste(text, collapse = " ")
        
        # Tokenize the text into words using quanteda
        tokens <- tokens(text, what = "word", remove_punct = TRUE)
        
        # Count the number of tokens (words)
        word_count <- sum(ntoken(tokens))
        
        # Append the data to vectors
        Country <- c(Country, country)
        Year <- c(Year, year)
        Size <- c(Size, word_count)
      } else {
        # If the filename doesn't match, print a warning
        warning(paste("Filename does not match the pattern: ", filename))
      }
    }
    
    # Create a data frame
    df <- data.frame(Country = Country, Year = Year, Size = Size)
    
    # Sort the data frame by country and year
    df <- df[order(df$Country, df$Year), ]
    
    # Return the data frame
    return(df)
  }
