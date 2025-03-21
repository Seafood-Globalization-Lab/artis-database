# title: ARTIS Website Tables
# purpose: Create attribute/metadata tables used to display on the ARTIS website
# details: Use ARTIS data from KNB FAO v1 release.
# Github Issue: https://github.com/Seafood-Globalization-Lab/artis-model/issues/43
# created: 2025-01-13
# author: Althea Marks
# notes: This script needs some cleaning up. But hopefully will provide context to the website database workflow if I don't get around to documenting it properly.

# Setup -------------------------------------------------------------------
library(dplyr)
library(purrr) # iterate 
library(data.table)
library(worrms) # interact with WORMS API
library(magrittr)
library(arrow) # work with parquet
library(glue) # better way to put together strings
library(duckdb) # database
library(dbplyr) # duckdb R client
library(DBI) # database connection

### data directories
data_dir_knb <- file.path("~/Documents/UW-SAFS/ARTIS/data/KNB_2024_07_31/data/attribute tables")
outdir_website <- file.path("~", "Documents","UW-SAFS","ARTIS", "data","website_tables")
artis_fp <- file.path("~/Documents/UW-SAFS/ARTIS/data/KNB_2024_07_31/data/artis_midpoint_all_HS_all_yrs_knb_v1.parquet")
artis_pad_fp <- file.path("~/Documents/UW-SAFS/ARTIS/data/KNB_2024_07_31/data/artis_midpoint_all_HS_all_yrs_knb_v1_pad0.parquet")

# read in data --------------------------------------------------------------
# don't need if reading in cleaned version created below
web_sciname <- data.table::fread(file.path(data_dir_knb, "sciname.csv"))
# artis <- read_parquet(artis_fp)

# Check if any hs6 codes shorter than 5 digits (possible in ALL_HS_CODES not sure about this)
# This should be resolved in updates to the ARTIS model - I believe this is taken care of in the 
# 05-prep-db-tables script in the model, but the .csv files writen out by the model do not always
# retain the zeros depending on the data value type. Sometimes when reading in a .csv the data type
# infered is not "chr" which removes leading zeros in the hs6 code. If properly maintained as "chr" 
# value type then no zero padding needed. Parquet files are better at preserving data types

# This code chunk rewrites the artis data with proper zeros as a parquet
# artis %>%
#   mutate(hs6 = nchar(as.character(hs6))) %>%
#   summarise(min_length = min(hs6))

# I ran this and updated the parquet file 2025-03-14
# artis <- artis %>% 
#   mutate(hs6 = as.character(hs6),
#          hs6 = str_pad(hs6, width = 6, pad = "0"))
# write_parquet(artis, file.path(artis_pad_fp))


# Table - sciname ---------------------------------------------------------
# Use latest KNB v1 stable ARTIS release data
# Need complete taxonomic info for displaying taxa tree
# Problem area is superclass and subfamily - doesn't apply to all rows
# Either remove supercalss and subfamily entirely or provide specific guidence
# on how to handle missing values

#find rows when subfamily has a value and no genus
subfam_rows <- web_sciname %>%
  filter(!is.na(subfamily) & is.na(genus))
# result - no rows meet the criteria - all subfamily values have a genus
# could remove subfamily without disrupting the data

# subfamily values
subfam_rows_1 <- web_sciname %>%
  filter(!is.na(subfamily))

# subfamilies where value is not equal to family value
subfam_rows_2 <- web_sciname %>%
  filter(!is.na(subfamily) & subfamily!=family)
# result - there are ~1,200 rows where subfamily is not equal to family
# looks like subfamily is important to retain

# Solution:
# if subfamily is not NA then the family should point to the subfamily value
# and subsequently point to genus next (where there is always a value).
# if subfamily is NA then family should point to genus. 

superclass_rows <- web_sciname %>%
  filter(!is.na(superclass) & is.na(class)) #%>% 
#select(-c(genus, subfamily, family, order))
# result - two rows "chondrichthyes" and "osteichthyes"
# can not remove superclass without disrupting the data

# Solution: 
# if superclass is not NA then phylum should point to superclass and terminate.
# if superclass is NA then phylum should point to class.

missing_king <- web_sciname %>% 
  filter(is.na(kingdom)) %>% 
  # sciname table missing sciname "chordata" - add manually
  bind_rows(data.frame = c(sciname = "chordata"))

######## fill in missing taxa classification schema values with WoRMS
new_classifications <- data.frame()

for (i in missing_king$sciname) {
  # Use tryCatch to handle errors
  tryCatch({
    # Query WoRMS for records
    records <- wm_records_names(i)
    
    # Check if records exist
    if (length(records) > 0) {
      # Get the AphiaID for the first match
      aphia_id <- records[[1]]$AphiaID[1]
      
      # Retrieve the full classification hierarchy
      classification <- wm_classification(aphia_id)
      
      # Reshape classification and add sciname
      classification_df <- classification %>%
        select(rank, scientificname) %>%
        pivot_wider(names_from = rank, values_from = scientificname) %>%
        mutate(sciname = i) %>%
        mutate(across(everything(), tolower))
      
      # Append to the results data frame
      new_classifications <- bind_rows(new_classifications, classification_df)
    }
  }, error = function(e) {
    # Skip scinames that cause errors and continue the loop
    message("Error for sciname: ", i, " - ", conditionMessage(e))
  })
}

# create dataframe for sciname that did not return results with worms
missing_hip <- data.frame(
  sciname = "hippoglossinae",
  kingdom = "animalia",
  phylum = "chordata",
  class = "teleostei ",
  order = "pleuronectiformes",
  family = "paralichthyidae ",
  genus = "hippoglossina")

# all column names to lower case
names(new_classifications) <- tolower(names(new_classifications))

# collect and format new classifications 
missing_corrected <- missing_king %>%
  select(sciname) %>%
  left_join(new_classifications, by = c("sciname")) %>% 
  filter(!is.na(kingdom)) %>% # remove rows that weren't matched in worms
  # bind manual info for hippoglossina
  bind_rows(missing_hip) %>% 
  # only retain ARTIS taxa classification columns
  select(sciname, genus, subfamily, family, order, class, phylum, kingdom) %>% 
  mutate(common_name = web_sciname$common_name[match(sciname, web_sciname$sciname)])


# only keep classification columns that exsist in ARTIS data
# coallesce the classification columns from the join (only one will have a value)
web_sciname_clean <- web_sciname %>%
  filter(!sciname %in% missing_corrected$sciname) %>% 
  bind_rows(missing_corrected) %>%
  # only retain scinames that are in ARTIS data
  filter(sciname %in% artis$sciname)

fwrite(web_sciname_clean, file.path(outdir_website,
                                    "sciname_website_2025_01_27.csv"))


# Test sciname table ------------------------------------------------------

# Not confident in the creation of sciname table. Spot checks here will insure 
# the structure of the sciname table is consistent and appropriate to join onto 
# artis for the purposes of summarizing trade by a specific taxa rank name

# read in sciname table created above
sciname_web <- fread(file.path(outdir_website,"sciname_website_2025_01_27.csv"))
sciname_web <- sciname_web %>% 
  mutate_all(~na_if(.,""))

# write out rows that are missing common name values - Jessica may manually update
# missing_common <- sciname_web %>% 
#   filter(is.na(common_name))
# fwrite(missing_common, file.path(outdir_website, "sciname_missing_common_names_2025_03_17.csv"))

test_sciname <- sciname_new

sciname_testing <- test_sciname %>% 
  mutate(
    # create column by matching sciname values to rank columns
    taxa_rank = case_when(
      stringr::str_detect(sciname, " ") ~ "species",
      sciname == genus ~ "genus",
      sciname == subfamily ~ "subfamily",
      sciname == family ~ "family",
      sciname == order ~ "order",
      sciname == class ~ "class",
      sciname == superclass ~ "superclass",
      sciname == phylum ~ "phylum",
      sciname == kingdom ~ "kingdom"),
    # create column that translates taxa_rank to numbers 
    taxa_rank_level = case_when(
      taxa_rank == "species" ~ 9,
      taxa_rank == "genus" ~ 8,
      taxa_rank == "subfamily" ~ 7,
      taxa_rank == "family" ~ 6,
      taxa_rank == "order" ~ 5,
      taxa_rank == "class" ~ 4,
      taxa_rank == "superclass" ~ 3,
      taxa_rank == "phylum" ~ 2,
      taxa_rank == "kingdom" ~ 1
    )) %>% 
  select(-isscaap)

# Compare
sciname_testing <- sciname_testing %>% 
  mutate(
    # create column that counts text values to determine taxa rank
    taxa_rank_count = case_when(
      taxa_rank == "species" ~  
        rowSums(!is.na(across(c(genus, family, order, class, phylum, kingdom)))) + 3,
      taxa_rank == "genus" ~ 
        rowSums(!is.na(across(c(genus, family, order, class, phylum, kingdom)))) + 2,
      taxa_rank == "subfamily" ~
        rowSums(!is.na(across(c(subfamily, family, order, class, phylum, kingdom)))) + 1,
      taxa_rank == "family" ~
        rowSums(!is.na(across(c(family, order, class, phylum, kingdom)))) + 1,
      taxa_rank == "order" ~
        rowSums(!is.na(across(c(order, class, phylum, kingdom)))) + 1,
      taxa_rank == "class" ~
        rowSums(!is.na(across(c(class, phylum, kingdom)))) +1,
      taxa_rank == "superclass" ~
        rowSums(!is.na(across(c(superclass, phylum, kingdom)))),      
      taxa_rank == "phylum" ~
        rowSums(!is.na(across(c(phylum, kingdom)))),
      taxa_rank == "kingdom" ~ 
        !is.na(kingdom)),
    # compare the results of taxa_rank_level to taxa_rank_count
    diff_test = taxa_rank_level - taxa_rank_count
  )

# FIXIT Add taxa_rank_test values for superclass and subfamily for secondary test on those ranks to 
# determine if classification values fully represented. (may need additional conditional check)

#### Checks - Test the taxa classification schema is properly filled in

# Test 1
# We expect that every sciname value will exactly match a text value in one of the 
# taxa rank columns (e.g. genus, subfamily, family, order, class, superclass, phylum, kingdom)
# This test will fail if a sciname value does not match to a taxa rank column
if(sum(is.na(sciname_testing$diff_test)) > 0){
  
  cli::cli_warn(c(
    "Sciname value must match a taxa rank column value (e.g. genus, family etc.):",
    "x" = "Problem in classify_prod_dat.R; either a manual correction or a fishbase/sealifebase record.",
    "i" = "Need to pass to meet ARTIS assumptions about taxa classification organization.",
    "i" = "{sum(is.na(sciname_testing$diff_test))} failing taxa recorded in `sciname_na` dataframe."
  ))
  
  sciname_na <- sciname_testing %>% 
    filter(is.na(sciname_testing$diff_test))
  
} else{
  cli::cli_inform(c("Test PASSED -- all sciname values matched a taxa rank value."))
}

# taxa rank evaluations/detections not in alignment
# taxa_rank and taxa_rank_test should be the same thus diff_test should be 0
# NAs may represent subfamily and/or superclass scinames - just detect diff_test 
if(sum(sciname_testing$diff_test != 0, na.rm = TRUE) > 0){
  
  cli::cli_warn(c(
    "All taxa rank columns must have all values appropriate for the taxa rank (i.e. no gaps in classification schema):",
    "x" = "Problem in classify_prod_dat.R; either a manual correction or a fishbase/sealifebase record.",
    "i" = "subfamily and superclass taxa rank columns are not required.",
    "i" = "Need to pass to meet ARTIS assumptions about taxa classification organization.",
    "i" = "{sum(sciname_testing$diff_test != 0, na.rm = TRUE)} failing taxa recorded in `sciname_missing_ranks` dataframe"
  ))
  
  sciname_missing_ranks <- sciname_testing %>% 
    filter(diff_test != 0)
} else{
  cli::cli_inform(c("Test PASSED -- all expected sciname taxa rank values present."))
}


# Notes - corrections needed
# 1) sciname == hippoglossinae - was the manually added taxa classification - not found by worms. 
# Flagged here because sciname does not equal genus name - Do we want to keep to match trade? 
# Change above - remove genus, add subfamily "hippoglossinae"

# chondrichthyes superclass needs "chordata" phylum value added - currently NA

# correction scipt based on sciname tests

sciname_new <- sciname_web %>% 
  mutate(
    # missing phylum values
    phylum = case_when(
      family == "petromyzontidae" ~ "chordata",
      sciname == "chondrichthyes" ~ "chordata", # in sciname
      genus == "protopterus" ~ "chordata",
      .default = phylum),
    # missing family value
    family = case_when(
      sciname == "macrobrachium" ~ "palaemonidae",
      .default = family),
    # fix error in classification not found in worms
    subfamily = case_when(
      sciname == "hippoglossinae" ~ "hippoglossinae",
      .default = subfamily),
    genus = case_when(
      sciname == "hippoglossinae" ~ NA,
      .default = genus)
  )

# write out corrected sciname table
fwrite(sciname_new, file.path(outdir_website, "sciname_website_2025_03_19.csv"))



# create summary snet tables by taxa rank ------------------------------------

# tables used on website to display trade data for all trade reported at and under a 
# taxa rank. i.e. genus thunnis will represent all trade reported directly at thunnis
# and all species within that genus. 

# website artis database version is reduced in size to allow for faster queries and 
# data loading in the GUI interface. The medium "custom" ARTIS for the website
# is filtered down to trade flows greater than 1 tonne and assigns a single
# hs_version to each year. 

## convert artis to duckdb and run group_by and summarize by taxa rank in duckb
# significantly reduce amount of RAM needed to processes. Was crashing my R session
# when I read artis into memory and ran this summary. 

# read in sciname table created above
sciname_web <- fread(file.path(outdir_website,"sciname_website_2025_03_19.csv"))

# fill in empty cells with NAs
sciname_web <- sciname_web %>% 
  mutate_all(~na_if(.,""))

# create temporary database
con <- dbConnect(duckdb(), dbdir = ":memory:")
# read parquet artis directly into database
dbExecute(con, "
          CREATE TABLE tbl_artis AS
          SELECT * FROM read_parquet(
            '~/Documents/UW-SAFS/ARTIS/data/KNB_2024_07_31/data/artis_midpoint_all_HS_all_yrs_knb_v1_pad0.parquet')
          ")
# second way of writing new table to duckdb - from R dataframe
dbWriteTable(con, "tbl_sciname", sciname_web)
# check if table is created
dbGetQuery(con, "SHOW TABLES")
#dbGetQuery(con, "DESCRIBE tbl_artis")
#dbGetQuery(con, "DESCRIBE tbl_sciname")
#glimpse(tbl(con, "tbl_artis"))

# Create function to use duckdb tables to run by taxa rank summaries and write out to local .csv

# yes I am lazy and relying on global environment variables not as arguements
artis_by_taxa_rank <- function(taxa_rank_col){
  # create query object
  result <- tbl(con, "tbl_artis") %>% 
    # filter to trade flows greater than 1 tonne
    filter(live_weight_t > 1) %>% 
    # Filter to single hs_version / year pairings
    filter(
      # Use HS96 from 1996-2003 (inclusive)
      ((hs_version == "HS96") & (year <= 2003)) |
        # Use HS02 from 2004-2009 (inclusive)
        ((hs_version == "HS02") & (year >= 2004 & year <= 2009)) |
        # Use HS07 from 2010-2012 (inclusive)
        ((hs_version == "HS07") & (year >= 2010 & year <= 2012)) |
        # Use HS12 from 2013-2020 (inclusive)
        ((hs_version == "HS12") & (year >= 2013 & year <= 2020))
    ) %>% 
    left_join(tbl(con, "tbl_sciname") %>% 
                select(sciname, taxa_rank_col) %>% 
                filter(!is.na(.data[[taxa_rank_col]])), # remove NA is taxa rank column
              by = "sciname") %>% 
    group_by(.data[[taxa_rank_col]], importer_iso3c, exporter_iso3c, hs6, 
             dom_source, source_country_iso3c, habitat, method, hs_version, year) %>% 
    summarise(live_weight_t = sum(live_weight_t),
              product_weight_t = sum(product_weight_t),
              .groups = "drop") %>% 
    rename(sciname = taxa_rank_col) %>% 
    select(importer_iso3c, exporter_iso3c, hs6, product_weight_t, dom_source,
           source_country_iso3c, sciname, habitat, method, live_weight_t, 
           hs_version, year)
  
  # run query and write result as table in duckdb
  result %>% compute(glue("tbl_artis_{taxa_rank_col}"), temporary = TRUE)
  
  # write duckdb table out as local csv
  dbExecute(con, glue("COPY tbl_artis_{taxa_rank_col} TO '{outdir_website}/artis_{taxa_rank_col}_website_{Sys.Date()}.csv' WITH (HEADER, DELIMITER ',')"))
}

taxa_ranks <- c("genus", "subfamily", "family", "order", "class", "superclass",
                "phylum", "kingdom")

# run as single chunk
{
  timestart <- Sys.time()
  map(taxa_ranks, ~ artis_by_taxa_rank(.x))
  timeend <- Sys.time()
  timeend - timestart
  beepr::beep()
}
dbGetQuery(con, "SHOW TABLES")
# RESULT NOTES
# Time difference of 4.571202 mins! and did my RAM usage was at 80%, no crashing!
# ~ 6 mins with 8 tables
# 1.86 mins?! More available RAM maybe? Or just filtering ARTIS before join probs

# Create consumption table with existing schema (used for old postgre SQL workflow)

# This is not working for me right now. 
# dbExecute(con, "
#   CREATE TABLE tbl_consumption AS
#   SELECT *
#   FROM read_csv(
#     '~/Documents/UW-SAFS/ARTIS/data/KNB_2024_07_31/data/consumption_all_hs_all_year.csv',
#     columns = {
#       record_id: INTEGER,
#       year: INTEGER,
#       hs_version: VARCHAR,
#       source_country_iso3c: VARCHAR,
#       exporter_iso3c: VARCHAR,
#       consumer_iso3c: VARCHAR,
#       dom_source: VARCHAR,
#       sciname: VARCHAR,
#       habitat: VARCHAR,
#       method: VARCHAR,
#       consumption_source: VARCHAR,
#       sciname_hs_modified: VARCHAR,
#       consumption_live_t: DOUBLE
#     })
# ")

dbExecute(con, "
  CREATE TABLE tbl_consumption AS
  FROM 
    '~/Documents/UW-SAFS/ARTIS/data/KNB_2024_07_31/data/consumption_all_hs_all_year.csv'
")

dbGetQuery(con, "DESCRIBE tbl_consumption")
# delete table from duckdb
# dbExecute(con, "DROP TABLE tbl_consumption;")

result_2 <- tbl(con, "tbl_consumption") %>% 
  # filter to trade flows greater than 1 tonne
  filter(consumption_live_t > 1) %>% 
  # Filter to single hs_version / year pairings
  filter(
    # Use HS96 from 1996-2003 (inclusive)
    ((hs_version == "HS96") & (year <= 2003)) |
      # Use HS02 from 2004-2009 (inclusive)
      ((hs_version == "HS02") & (year >= 2004 & year <= 2009)) |
      # Use HS07 from 2010-2012 (inclusive)
      ((hs_version == "HS07") & (year >= 2010 & year <= 2012)) |
      # Use HS12 from 2013-2020 (inclusive)
      ((hs_version == "HS12") & (year >= 2013 & year <= 2020))
  )

# run query and write result as new table in duckdb (replacing isn't working)
result_2 %>% compute("tbl_consumption_custom", temporary = FALSE)

# write duckdb table out as local csv
dbExecute(con, glue("COPY tbl_consumption_custom TO '{outdir_website}/consumption_custom_website_{Sys.Date()}.csv' WITH (HEADER, DELIMITER ',')"))

# create snet table version filtered down the same way
result_3 <- tbl(con, "tbl_artis") %>% 
  # filter to trade flows greater than 1 tonne
  filter(live_weight_t > 1) %>% 
  # Filter to single hs_version / year pairings
  filter(
    # Use HS96 from 1996-2003 (inclusive)
    ((hs_version == "HS96") & (year <= 2003)) |
      # Use HS02 from 2004-2009 (inclusive)
      ((hs_version == "HS02") & (year >= 2004 & year <= 2009)) |
      # Use HS07 from 2010-2012 (inclusive)
      ((hs_version == "HS07") & (year >= 2010 & year <= 2012)) |
      # Use HS12 from 2013-2020 (inclusive)
      ((hs_version == "HS12") & (year >= 2013 & year <= 2020))
  )
result_3 %>% compute("tbl_artis_custom", temporary = FALSE)
dbExecute(con, glue("COPY tbl_artis_custom TO '{outdir_website}/artis_custom_website_{Sys.Date()}.csv' WITH (HEADER, DELIMITER ',')"))

dbGetQuery(con, "DESCRIBE tbl_artis_custom")

# disconnect from database - destroys temporary duckdb used for computing
dbDisconnect(con)



# combine consumption csv -------------------------------------------------

# con_fp <- file.path("~/Documents/UW-SAFS/ARTIS/data/KNB_2024_07_31/data/consumption")
# list.files(con_fp)
# 
# # List all CSV files
csv_files <- list.files(con_fp, pattern = "\\.csv$", full.names = TRUE)

library(readr)
# Read and bind all CSVs
combined_df <- csv_files %>%
  lapply(read_csv) %>%
  bind_rows()

# View combined dataframe
glimpse(combined_df)

fwrite(combined_df, file.path(con_fp, "consumption_all_hs_all_year.csv"))

# Table - products --------------------------------------------------------
# commodity metadata - ensure all HS versions are included 

web_products <- data.table::fread(file.path(data_dir_knb, "products.csv"))

#### need to combine my local KNB trade files to single parquet file
#library(arrow)
# knb_trade_files <- list.files(file.path("~/Documents/UW-SAFS/ARTIS/data/KNB_2024_07_31/data/trade/"), full.names = TRUE)
# 
# combined_table <- tibble()
# combined_table <- arrow_table(combined_table)
# 
# # Loop through files and read them as Arrow Tables
# for (i in seq_along(knb_trade_files)) {
#   combined_table <- concat_tables(combined_table, 
#                                   arrow_table(read_csv_arrow(knb_trade_files[i]))
#   )
# }
# 
# # Write the combined Arrow Table to a Parquet file
# write_parquet(combined_table, 
#               file.path("~/Documents/UW-SAFS/ARTIS/data/KNB_2024_07_31/data",
#                         "artis_midpoint_all_HS_all_yrs_knb_v1.parquet"))

knb_trade <- read_parquet(file.path("~/Documents/UW-SAFS/ARTIS/data/KNB_2024_07_31/data","artis_midpoint_all_HS_all_yrs_knb_v1.parquet"))

# Only want HS product codes that are in trade data
web_products_clean <- web_products %>%
  filter(hs6 %in% knb_trade$hs6) 

# fwrite(web_products_clean, file.path(outdir_website,
#                                      "products_website_2025_01_17.csv"))

####### 2025-03-10 Need to add HS version to products table


# classification values map directly to hs_versions, I did not find direct documentation
# of this key, but makes sense. We filtered out HS92 for ARTIS, and was untouched 
# in product codes probably. I updated `Seafood-Globalization-Lab/artis-database/create_sql_tables/create_products.sql` script to replace classification with hs_version
web_products_hs <- web_products_clean %>% 
  mutate(hs_version = case_when(
    classification == "H0" ~ "HS92",
    classification == "H1" ~ "HS96",
    classification == "H2" ~ "HS02",
    classification == "H3" ~ "HS07", 
    classification == "H4" ~ "HS12",
    classification == "H5" ~ "HS17",
  )) %>% 
  select(-classification) %>% 
  mutate(hs6 = as.character(hs6),
         hs6 = case_when(str_length(hs6) == 5 ~ paste("0", hs6, sep = ""), 
                         TRUE ~ hs6
         )) %>% 
  distinct() %>% 
  select(hs6, description, parent, hs_version, presentation, state)


fwrite(web_products_hs, file.path(outdir_website,
                                  "products_website_2025_03_11.csv"))

# Table - nutrient --------------------------------------------------------
# This table is not included in KNB v1 release
# get table from Whitney



