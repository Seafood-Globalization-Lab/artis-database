
CREATE TABLE production(
  record_id SERIAL NOT NULL PRIMARY KEY,
  iso3c VARCHAR(3),
  sciname VARCHAR(100),
  method VARCHAR(12),
  habitat VARCHAR(6),
  live_weight_t FLOAT,
  "year" INTEGER
);