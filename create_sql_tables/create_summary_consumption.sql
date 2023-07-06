
CREATE TABLE summary_consumption(
  record_id SERIAL NOT NULL PRIMARY KEY,
  iso3c VARCHAR(3),
  hs6 VARCHAR(6),
  sciname VARCHAR(33),
  habitat VARCHAR(7),
  method VARCHAR(11),
  year INTEGER,
  domestic_consumption_t FLOAT,
  foreign_consumption_t FLOAT,
  supply FLOAT,
  hs_version VARCHAR(4)
)

