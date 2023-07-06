

CREATE TABLE sau_production(
  record_id SERIAL NOT NULL PRIMARY KEY,
  country_name_en VARCHAR(32),
  country_iso3_alpha VARCHAR(3),
  country_iso3_numeric VARCHAR(3),
  eez VARCHAR(42),
  sector VARCHAR(12),
  sciname VARCHAR(33),
  year INTEGER,
  live_weight_t FLOAT
)
