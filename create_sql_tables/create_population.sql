
CREATE TABLE population(
  record_id SERIAL NOT NULL PRIMARY KEY,
  iso3c VARCHAR(3),
  year INTEGER,
  pop INTEGER
)
