# ARTIS Database

# Installations

1. Download PostgreSQL: https://www.postgresql.org/download/
2. Download pgAdmin: https://www.pgadmin.org/download/

## Directory and File Structure

- prep_db_files.R
  - Takes raw snet files to a database table
- create_sql_tables
  - SQL files to create the different tables
  

## Database Structure

### ARTIS snet table

| Column Name | Description |
| ----------- | ----------- |
| exporter_iso3c| ISO3C code for direct ***exporter*** country |
| importer_iso3c| ISO3C code for direct ***importer*** country |
| source_country_iso3c | ISO3C code for the country that produced the specific product |
| dom_source | Defines whether trade record was a "domestic export", "foreign export" or "error export" |
| hs6 | HS 6 digit code used to identify what product is being traded. |
| sciname | species name traded under the specific HS product and 6-digit code. |
| habitat | classifies whether the specific species' habitat *(marine/inland/unknown)*. |
| method | defines method of production *(aquaculture/capture/unknown)*. |
| product_weight_t | product weight in tonnes. |
| live_weight_t | live weight in tonnes. |
| year | year in which trade occured. |

| exporter_iso3c | importer_iso3c | source_country_iso3c | dom_source | hs6 | sciname | habitat | method | product_weight_t | live_weight_t | year |
| ----------- | ----------- | ----------- | ----------- | ----------- | ----------- | ----------- | ----------- | ----------- | ----------- | ----------- |
| CAN | USA | CAN | domestic export | 030212 | oncorhynchus keta | marine | capture | 870.34 | 1131.45 | 2017 |
| CHL | ITA | PER | foreign export | 230120 | engraulis ringens | marine | capture | 344.889 | 1026.11 | 2017 |

***Note:***

  - ***Domestic Export:*** An export where the specific product was produced in the same country as it was exported from.
  
  - ***Foreign Export:*** An export where a specific product is imported from a source country and then re-exported by another country.
  
  - ***Error Export:*** An export that cannot be explained by domestic or foreign export records nor production records.

### Production table
This table has all FAO production records for all countries in ARTIS for 1996 - 2020.

| Column Name | Description |
| ----------- | ----------- |
| iso3c | ISO3 code for the producing country |
| sciname | species produced (matches with sciname column in sciname table) |
| method | production method *(aquaculture/capture/unknown)* |
| habitat | habitat where species resides *(marine/inland/unknown)* |
| live_weight_t | Live weight in tonnes. |
| year | Year species was produced. |

#### Sample Production table entry
| iso3c | sciname | method | habitat | live_weight_t | year |
| ----------- | ----------- | ----------- | ----------- | ----------- | ----------- |
| SWE | abramis brama | capture | inland | 7 | 2006 |

### SAU Production table
This table has all SAU production records for all countries in ARTIS for 1996 - 2019. Note all production is marine capture.

| Column Name | Description |
| ----------- | ----------- |
| country_name_en | Producing country name in english |
| country_iso3_alpha | Producing country ISO3 3 letter code |
| country_iso3_numeric | Producing country ISO3 numeric code |
| eez | Exclusive Economic Zone |
| sector | economic sector |
| sciname | species produced (matches with sciname column in sciname table) |
| year | Year species was produced |
| live_weight_t | Live weight in tonnes |


### Baci table
This table has all BACI bilateral trade records for all countries in ARTIS for 1996 - 2020.

| Column Name | Description |
| ----------- | ----------- |
| exporter_iso3c | ISO3 3 letter code for direct ***exporter*** country |
| importer_iso3c | ISO3 3 letter code for direct ***importer*** country |
| hs6 | HS 6 digit code used to identify what product is being traded |
| product_weight_t | product weight in tonnes |
| hs_version | HS code version for the year used |
| year | year trade occured |

### Countries table
This table contains metadata about countries in the ARTIS database.

| Column Name | Description |
| ----------- | ----------- |
| iso3c | ISO3 3 letter code for country |
| country_name | Country name in english |
| owid_region | Country's region as defined by Our World in Data |
| continent | Country's continent as defined by R countrycode package |

### Nutrient metadata table
This table contains the nutrient content per 100g of the species in the ARTIS database.

| Column Name | Description |
| ----------- | ----------- |
| sciname | species scientific name |
| calcium_mg | calcium content (mg) per 100 g of species |
| iron_mg | iron content (mg) per 100 g of species |
| protein_g | protein content (g) per 100 g of species |
| fattyacids_g | fatty acid content (g) per 100 g of species |
| vitamina_mcg | vitamin a content (mcg) per 100 g of species |
| vitaminb12_mcg | vitamin b12 content (mcg) per 100 g of species |
| zinc_mg | zinc content (mg) per 100 g of species |

### Complete consumption table
This table contains consumption estimates from trade.

| Column Name | Description |
| ----------- | ----------- |
| iso3c | ISO3 3 letter code of consuming country |
| hs6 | HS 6 digit code used to identify what product is being consumed |
| sciname | species scientific name |
| method | production method *(aquaculture/capture/unknown)* |
| habitat | habitat where species resides *(marine/inland/unknown)* |
| source_country_iso3c | ISO3 3 letter code of country of origin |
| dom_source | Defines whether trade record was a "domestic export", "foreign export" or "error export" |
| hs_version | HS code version for the year |
| population | population of consuming country (sourced from FAO) |
| year | year of consumption |

### Code max resolved taxa table
This is a conversion table to resolve a scientific name from higher order taxa (family, order, class etc) to a more specific species based on the HS product and HS version used.

| Column Name | Description |
| ----------- | ----------- |
| hs_version | HS code version for the year |
| hs6 | species scientific name |
| sciname | original scientific name determined by production records |
| sciname_hs_modified | more specific/resolved scientific name given hs version and hs product |

---

### Products table
This table contains information about what each HS 6-digit code represents.

| Column Name | Description |
| ----------- | ----------- |
| hs6 | HS 6-digit product code |
| description | Product description |
| presentation | Product form ***(fillet, whole, fats and oils, non-fish, non-fmp form, other body parts, other meat, livers and roes)*** |
| state | Product state ***(live, frozen, preserved, fresh, not for humans, reduced)*** |


#### Sample products table entry
| hs6 | description | presentation | state |
| ----------- | ----------- | ----------- | ----------- |
| 030212 | Fish; Pacific salmon (oncorhynchus spp.), Atlantic salmon (salmo salar), Danube salmon (hucho hucho), fresh or chilled (excluding fillets, livers, roes and other fish meat of heading no. 0304)| whole | fresh |


