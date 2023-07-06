

CREATE TABLE complete_consumption(
  record_id SERIAL NOT NULL PRIMARY KEY,
  iso3c VARCHAR(3),
  hs6 VARCHAR(6),
  sciname VARCHAR(33),
  habitat VARCHAR(7),
  method VARCHAR(11),
  year INTEGER,
  consumption_live_t FLOAT,
  source_country_iso3c VARCHAR(7),
  dom_source VARCHAR(8),
  hs_version VARCHAR(4)
)
