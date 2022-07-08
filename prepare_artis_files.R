
# Libraries
library(tidyverse)
library(countrycode)

# Resetting workspace
rm(list=ls())

# Directories and filenames
datadir <- "/project/database/inputs"
outdir <- "/project/database/outputs"

sciname_filename <- "sciname_metadata_original.csv"
isscaap_filename <- "sciname_isscaap_matches.csv"
countries_filename <- "countries.csv"
hs_codes_filename <- "ALL_HS_Codes.csv"
prod_filename <- "clean_fao_prod.csv"

################################################################################
# Creating sciname table

# Initial dataframes
sciname <- read.csv(file.path(datadir, sciname_filename))
isscaap <- read.csv(file.path(datadir, isscaap_filename))

# Joining and renaming sciname metadata and isscaap groups
sciname <- sciname %>%
  full_join(isscaap, by="SciName") %>%
  rename(isscaap = isscaap_group) %>%
  rename(common_name = CommonName) %>%
  rename(fresh = fresh01, brack = brack01, saltwater = saltwater01)

# All column names lower case
colnames(sciname) <- tolower(colnames(sciname))

# Writing out results
write.csv(sciname, file.path(outdir, "sciname.csv"), row.names=FALSE)

################################################################################
# Creating Country metadata table
# ISO 3 code, ISO 2 code, country name, region

# Read in list of countries found in K Drive data folder
countries <- read.csv(file.path(datadir, countries_filename))

# Add country metadata
countries <- countries %>%
  mutate(iso2c = countrycode(iso3c, origin="iso3c", destination="iso2c"),
         country_name = countrycode(iso3c, origin="iso3c", destination="country.name"),
         continent = countrycode(iso3c, origin="iso3c", destination="continent"),
         eu_status = countrycode(iso3c, origin="iso3c", destination="eu28")) %>%
  mutate(eu_status = case_when(
    eu_status == "EU" ~ TRUE,
    TRUE ~ FALSE
  ))

# Writing out results
write.csv(countries, file.path(outdir, "countries.csv"), row.names=FALSE)

################################################################################
# Creating Product metadata table
# hs codes, descriptions, FMFO status, product form

# Read in list of HS codes found in K Drive Data folder
products <- read.csv(file.path(datadir, hs_codes_filename))

products <- products %>%
  mutate(Code = as.character(Code)) %>%
  mutate(Code = case_when(
    str_length(Code) < ~ paste("0", Code, sep=""),
    TRUE ~ Code
  ))

# Read in all hs-hs_match files concentrate on:
# code_pre, code_post, presentation_pre, presentation_post, state_pre, state_post

# Get list of all hs-hs-match files
prep_state_files <- list.files(path=datadir, pattern="hs-hs-match", include.dirs=TRUE)
prep_state <- data.frame()

for (i in 1:length(prep_state_files)) {
  curr_file <- file.path(datadir, prep_state_files[i])
  curr_prep_state <- read.csv(curr_file)
  
  curr_prep_state <- curr_prep_state %>%
    select(Code_pre, Code_post, Presentation_pre, Presentation_post, State_pre, State_post)
  
  curr_prep_state <- data.frame(
    hs6 = c(curr_prep_state$Code_pre, curr_prep_state$Code_post),
    presentation = c(curr_prep_state$Presentation_pre, curr_prep_state$Presentation_post),
    state = c(curr_prep_state$State_pre, curr_prep_state$State_post)
    ) %>%
    distinct() %>%
    mutate(hs6 = as.character(hs6)) %>%
    mutate(hs6 = case_when(
      str_length(hs6) < 6 ~ paste("0", hs6, sep="")
    ))
  
  prep_state <- prep_state %>%
    bind_rows(curr_prep_state)
}

products <- products %>%
  left_join(prep_state, by=c("Code"="hs6"))

# Writing out results
write.csv(products, file.path(outdir, "products.csv"), row.names=FALSE)

################################################################################
# Creating connecting table between sciname and products
# Should contain Species, HS codes, liveweight cfs


################################################################################
# Cleaning BACI data

################################################################################
# Cleaning Production data

# clean fao file found in Outputs/model_inputs on K Drive
prod <- read.csv(file.path(datadir, prod_filename))

# Filtering down to relevant columns (no duplications with other tables)
prod <- prod %>%
  select(c(country_iso3_alpha, SciName, prod_method, habitat, quantity, year)) %>%
  rename(
    iso3c = country_iso3_alpha,
    sciname = SciName,
    environment = habitat,
    live_weight_t = quantity
  )

# Writing out results
write.csv(prod, file.path(outdir, "prod.csv"), row.names=FALSE)

################################################################################
