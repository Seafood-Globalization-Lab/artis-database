CREATE TABLE users(
  record_id SERIAL NOT NULL PRIMARY KEY,
  first_name VARCHAR(20),
  last_name VARCHAR(30),
  email VARCHAR(100),
  api_key VARCHAR(32),
  user_type VARCHAR(20),
  write BOOLEAN,
  read BOOLEAN,
  expiration_date VARCHAR(24)
);
