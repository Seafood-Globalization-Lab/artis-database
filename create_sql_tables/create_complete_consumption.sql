

CREATE TABLE complete_consumption(
  record_id SERIAL NOT NULL PRIMARY KEY,
  year INTEGER,
  hs_version VARCHAR(4),
  source_country_iso3c VARCHAR(7),
  exporter_iso3c VARCHAR(3),
  consumer_iso3c VARCHAR(3),
  dom_source VARCHAR(8),
  sciname VARCHAR(33),
  habitat VARCHAR(7),
  method VARCHAR(11),
  consumption_source VARCHAR(8),
  sciname_hs_modified VARCHAR(33),
  consumption_t FLOAT
)
