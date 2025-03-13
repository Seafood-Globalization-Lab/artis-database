CREATE TABLE snet(
    record_id SERIAL NOT NULL PRIMARY KEY,
    importer_iso3c VARCHAR(3),
    exporter_iso3c VARCHAR(3),
    hs6 VARCHAR(6),
    product_weight_t FLOAT,
    dom_source VARCHAR(100),
    source_country_iso3c VARCHAR(7),
    family VARCHAR(100),
    habitat VARCHAR(100),
    "method" VARCHAR(100),
    live_weight_t FLOAT,
    hs_version VARCHAR(4),
    "year" INT
);