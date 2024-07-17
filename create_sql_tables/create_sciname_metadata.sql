
CREATE TABLE sciname(
    record_id SERIAL NOT NULL PRIMARY KEY,
    sciname VARCHAR(100) NOT NULL,
    common_name VARCHAR(255),
    genus VARCHAR(100),
    subfamily VARCHAR(100),
    "family" VARCHAR(100),
    "order" VARCHAR(100),
    "class" VARCHAR(100),
    superclass VARCHAR(100),
    phylum VARCHAR(100),
    kingdom VARCHAR(100),
    isscaap VARCHAR(100)
);