
CREATE TABLE countries(
    iso3c VARCHAR(3) NOT NULL PRIMARY KEY,
    iso2c VARCHAR(2),
    country_name VARCHAR(100),
    continent VARCHAR(100),
    eu_status BOOLEAN
);