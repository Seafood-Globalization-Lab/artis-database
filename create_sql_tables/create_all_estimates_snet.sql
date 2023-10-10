CREATE TABLE all_estimates_snet(
    record_id SERIAL NOT NULL PRIMARY KEY,
    "year" INT,
    source_country_iso3c VARCHAR(7),
    exporter_iso3c VARCHAR(3),
    importer_iso3c VARCHAR(3),
    hs6 VARCHAR(6),
    hs_version VARCHAR(4),
    dom_source VARCHAR(100),
    sciname VARCHAR(100),
    habitat VARCHAR(100),
    method VARCHAR(100),
    product_weight_t FLOAT,
    product_weight_t_min FLOAT,
    product_weight_t_max FLOAT,
    live_weight_t FLOAT,
    live_weight_t_min FLOAT,
    live_weight_t_max FLOAT
);