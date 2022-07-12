
CREATE TABLE production(
  record_id SERIAL NOT NULL PRIMARY KEY,
  sciname VARCHAR(100),
  prod_method VARCHAR(12),
  environment VARCHAR(6),
  live_weight_t FLOAT,
  "year" INTEGER
);