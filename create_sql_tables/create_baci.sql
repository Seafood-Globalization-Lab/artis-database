
CREATE TABLE baci(
  record_id SERIAL NOT NULL PRIMARY KEY,
  exporter_iso3c VARCHAR(3),
  importer_iso3c VARCHAR(3),
  hs6 VARCHAR(6),
  product_weight_t FLOAT,
  hs_version VARCHAR(4),
  year INTEGER
);
