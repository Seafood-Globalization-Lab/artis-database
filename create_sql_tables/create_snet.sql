CREATE TABLE snet(
    record_id SERIAL NOT NULL PRIMARY KEY,
    exporter_iso3c VARCHAR(3),
    importer_iso3c VARCHAR(3),
    dom_source VARCHAR(100),
    source_country_iso3c VARCHAR(7),
    hs6 VARCHAR(6),
    sciname VARCHAR(100),
    environment VARCHAR(100),
    "method" VARCHAR(100),
    product_weight_t FLOAT,
    live_weight_t FLOAT,
    hs_version VARCHAR(4),
    "year" INT,
    snet_est VARCHAR(3)
);