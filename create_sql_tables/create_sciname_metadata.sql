
CREATE TABLE sciname(
    sciname VARCHAR(100) NOT NULL PRIMARY KEY,
    common_name VARCHAR(255),
    genus VARCHAR(100),
    subfamily VARCHAR(100),
    "family" VARCHAR(100),
    "order" VARCHAR(100),
    "class" VARCHAR(100),
    superclass VARCHAR(100),
    phylum VARCHAR(100),
    kingdom VARCHAR(100),
    aquarium VARCHAR(100),
    fresh BOOLEAN,
    brack BOOLEAN,
    saltwater BOOLEAN,
    isscaap VARCHAR(100)
);