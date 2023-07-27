
library(tidyverse)
library(DBI)
library(RPostgres)

# Note: make sure to have a .Renviron file has the arguments
  # DB_NAME, DB_PORT, DB_USERNAME, DB_PASSWORD
  # if you just created the .Renviron file for the first time please restart your R session

# open connection to database
# Note: always close the connection after making all calls to the database (dbDisconnect(con))
con <- dbConnect(RPostgres::Postgres(),
                 host="localhost",
                 dbname=Sys.getenv("DB_NAME"),
                 port=Sys.getenv("DB_PORT"),
                 user=Sys.getenv("DB_USERNAME"),
                 password=Sys.getenv("DB_PASSWORD"))

# list all tables in the
dbListTables(con)

# Examples

# Get whole tables--------------------------------------------------------------
# Get whole ARTIS disaggregated trade table
artis <- dbGetQuery(con, 'SELECT * FROM snet')

# Get whole production table (FAO Production data used to build the ARTIS disaggregated trade table)
fao_production <- dbGetQuery(con, 'SELECT * FROM production')

# Get whole SAU production table (NOT used to build the ARTIS disaggregated trade table)
sau_production <- dbGetQuery(con, 'SELECT * FROM sau_production')

# Get taxonomic hierarchy for taxa in ARTIS table
sciname_metadata <- dbGetQuery(con, 'SELECT * FROM sciname')

# Get whole BACI bilateral trade records (these trade records are used to build the ARTIS disaggregated trade table)
baci <- dbGetQuery(con, 'SELECT * FROM baci')

# Get whole table of HS product code metadata (ie HS code, hs version, descriptions, etc)
products <- dbGetQuery(con, 'SELECT * FROM products')

# Get whole table of consumption
consumption <- dbGetQuery(con, 'SELECT * FROM complete_consumption')

# Get metadata for countries (ISO3 codes, country names, regions, etc)
country_metadata <- dbGetQuery(con, 'SELECT * FROM countries')

# Get whole nutrient data
nutrient_metadata <- dbGetQuery(con, 'SELECT * FROM nutrient_metadata')

# Get a conversion table from higher order taxonomic names to more specific species names
code_max_resolved_taxa <- dbGetQuery(con, 'SELECT * FROM code_max_resolved_taxa')


# Get filtered version of tables------------------------------------------------
# Get all production data where Peru is the producer
prod_filtered <- dbGetQuery(con, 'SELECT * FROM production WHERE iso3c = "PER"')
# Get all production data where Peru is the producer and the year is 2018
prod_filtered_2 <- dbGetQuery(con, 'SELECT * FROM production WHERE iso3c = "PER" AND year = 2018')

# Get summarized version of tables----------------------------------------------

# Get the estimates for product weights and live weights for all trade by year
artis_summarized <- dbGetQuery(con,
                               'SELECT SUM(product_weight_t), sum(live_weight_t), year FROM snet
                               GROUP BY year')
# Get estimates for live weight by year for all trade from China to the USA
artis_summarized_filtered <- dbGetQuery(con,
                                        'SELECT SUM(live_weight_t), year
                                        FROM snet WHERE exporter_iso3c = "CHN" AND importer_iso3c = "USA')

# close connection to database
dbDisconnect(con)


