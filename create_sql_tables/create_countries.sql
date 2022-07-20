
CREATE TABLE countries(
    record_id SERIAL NOT NULL PRIMARY KEY,
    iso3c VARCHAR(3),
    iso2c VARCHAR(2),
    country_name VARCHAR(100),
    continent VARCHAR(100),
    eu_status BOOLEAN
);