

CREATE TABLE consumption(
  record_id SERIAL NOT NULL PRIMARY KEY,
  year INTEGER,
  hs_version VARCHAR(4),
  source_country_iso3c VARCHAR(7),
  exporter_iso3c VARCHAR(3),
  consumer_iso3c VARCHAR(3),
  sciname VARCHAR(33),
  sciname_hs_modified VARCHAR(33),
  habitat VARCHAR(7),
  method VARCHAR(11),
  dom_source VARCHAR(8),
  consumption_type VARCHAR(8),
  end_use VARCHAR(24),
  consumption_t FLOAT,
  consumption_t_capped FLOAT
)
