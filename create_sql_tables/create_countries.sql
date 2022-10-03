
CREATE TABLE countries(
    record_id SERIAL NOT NULL PRIMARY KEY,
    iso3c VARCHAR(3),
    country_name VARCHAR(100),
    owid_region VARCHAR(100),
    continent VARCHAR(100)
);