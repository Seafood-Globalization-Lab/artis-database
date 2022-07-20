
packdir <- "/project/ARTIS/Package"
setwd(packdir) # note: If running on zorro need to set directory to packdir before #devtools::install()

# Libraries
library(tidyverse, lib.loc = "/home/rahulab/R/x86_64-pc-linux-gnu-library/3.6/")
library(countrycode, lib.loc = "/home/rahulab/R/x86_64-pc-linux-gnu-library/3.6/")

# Resetting workspace
rm(list=ls())

# Directories and filenames
datadir <- "/project/ARTIS/ARTIS/database/inputs"
outdir <- "/project/ARTIS/ARTIS/database/outputs"

sciname_filename <- "sciname_metadata_original.csv"
isscaap_filename <- "sciname_isscaap_matches.csv"
countries_filename <- "countries.csv"
hs_codes_filename <- "All_HS_Codes.csv"
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
  rename(fresh = Fresh01, brack = Brack01, saltwater = Saltwater01)

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
    str_length(Code) < 6 ~ paste("0", Code, sep=""),
    TRUE ~ Code
  ))

# Read in all hs-hs_match files concentrate on:
# code_pre, code_post, presentation_pre, presentation_post, state_pre, state_post

# Get list of all hs-hs-match files
prep_state_files <- list.files(path=datadir, pattern="hs-hs-match", include.dirs=FALSE)
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
      str_length(hs6) < 6 ~ paste("0", hs6, sep=""),
      TRUE ~ hs6
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

baci_files <- list.files(path=datadir, pattern="baci_seafood_hs", include.dirs=FALSE)

baci <- data.frame()

for (i in 1:length(baci_files)) {
  curr_baci_filename <- baci_files[i]
  curr_baci <- read.csv(file.path(datadir, curr_baci_filename))
  
  curr_hs <- toupper(substring(curr_baci_filename, 14, 17))
  curr_year <- as.integer(substring(curr_baci_filename, nchar(curr_baci_filename) - 7, nchar(curr_baci_filename) - 4))
  
  curr_baci <- curr_baci %>%
    mutate(hs_version=curr_hs,
           year=curr_year) %>%
    select(c("exporter_iso3c", "importer_iso3c", "hs6", "total_q", "hs_version", "year")) %>%
    rename(product_weight_t = total_q)
  
  baci <- baci %>%
    bind_rows(curr_baci)
}

write.csv(baci, file.path(outdir, "baci.csv"), row.names=FALSE)

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
# Prepare and Combine all Snets created (min, mid, max)

snet_files <- list.files(path=datadir, pattern="artis_ts.csv")

snet <- data.frame()

for (i in 1:length(snet_files)) {
  curr_file <- snet_files[i]
  curr_snet <- read.csv(file.path(datadir, curr_file))
  
  snet_type <- tolower(substring(curr_file, 1, 3))
  
  curr_snet <- curr_snet %>%
    mutate(snet_est = snet_type) %>%
    mutate(hs_version = as.character(hs_version)) %>%
    mutate(hs_version = case_when(
      str_length(hs_version) == 1 ~ paste("0", hs_version, sep=""),
      TRUE ~ hs_version)) %>%
    mutate(hs_version = paste("HS", hs_version, sep=""))
  
  snet <- snet %>%
    bind_rows(curr_snet)
}

write.csv(snet, file.path(outdir, "snet.csv"), row.names=FALSE)
################################################################################
