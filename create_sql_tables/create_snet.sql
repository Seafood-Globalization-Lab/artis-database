CREATE TABLE snet(
    record_id SERIAL NOT NULL PRIMARY KEY,
    exporter_iso3c VARCHAR(3),
    importer_iso3c VARCHAR(3),
    hs6 VARCHAR(6),
    product_weight_t FLOAT,
    dom_source VARCHAR(100),
    source_country_iso3c VARCHAR(7),
    sciname VARCHAR(100),
    habitat VARCHAR(100),
    "method" VARCHAR(100),
    hs_version VARCHAR(4),
    "year" INT,
    live_weight_t FLOAT
);