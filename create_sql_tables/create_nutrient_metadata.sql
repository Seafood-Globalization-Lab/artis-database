
CREATE TABLE nutrient_metadata(
  record_id SERIAL NOT NULL PRIMARY KEY,
  sciname VARCHAR(33),
  calcium_mg FLOAT,
  iron_mg FLOAT,
  protein_g FLOAT,
  fattyacids_g FLOAT,
  vitamina_mcg FLOAT,
  vitaminb12_mcg FLOAT,
  zinc_mg FLOAT
)


