
library(tidyverse)
library(DBI)
library(RPostgres)

con <- dbConnect(RPostgres::Postgres(),
                 host="localhost",
                 dbname=Sys.getenv("DB_NAME"),
                 port=Sys.getenv("DB_PORT"),
                 user=Sys.getenv("DB_USERNAME"),
                 password=Sys.getenv("DB_PASSWORD"))

dbListTables(con)

snet <- dbGetQuery(con,
                       'SELECT hs_version, "year", snet_est, SUM(live_weight_t), sum(product_weight_t)
                       FROM snet
                       GROUP BY hs_version, "year", snet_est'
                       )

baci <- dbGetQuery(con,
                   'SELECT hs_version, "year", SUM(product_weight_t) AS product_weight_t
                   FROM baci
                   GROUP BY hs_version, "year"'
                   )

dbDisconnect(con)

snet <- snet %>%
  rename(live_weight_t = sum, product_weight_t = sum..5) %>%
  mutate(hs_version = as.character(hs_version)) %>%
  mutate(hs_version = case_when(
    str_length(hs_version) == 1 ~ paste("0", hs_version, sep=""),
    TRUE ~ hs_version
  )) %>%
  mutate(hs_version = paste("HS", hs_version, sep=""))

baci <- baci %>%
  mutate(snet_est = "baci")

snet <- snet %>%
  full_join(baci)

p <- snet %>%
  filter(snet_est == "baci" | snet_est == "max") %>%
  ggplot(aes(x=year, y=product_weight_t, colour=hs_version, linetype=snet_est, group=interaction(hs_version, snet_est))) +
  geom_line()

plot(p)

custom_snet <- snet %>%
  filter(
    ((hs_version == "HS96") & (year <= 2003)) |
      # Use HS02 from 2004-2009 (inclusive)
      ((hs_version == "HS02") & (year >= 2004 & year <= 2009)) |
      # Use HS07 from 2010-2012 (inclusive)
      ((hs_version == "HS07") & (year >= 2010 & year <= 2012)) |
      # Use HS12 from 2013-2019 (inclusive)
      ((hs_version == "HS12") & (year >= 2013 & year <= 2019))
  )
  
p_custom <- custom_snet %>%
  ggplot(aes(x=year, y=product_weight_t, colour=snet_est, group=snet_est)) +
  geom_line()

plot(p_custom)
