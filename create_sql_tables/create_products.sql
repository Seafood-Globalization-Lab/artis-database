
CREATE TABLE products(
  record_id  SERIAL NOT NULL PRIMARY KEY,
  hs6 VARCHAR(6) NOT NULL,
  description VARCHAR(255),
  parent VARCHAR(6),
  classification VARCHAR(3),
  presentation VARCHAR(25),
  state VARCHAR(20)
);