CREATE TABLE code_max_resolved_taxa(
  record_id SERIAL NOT NULL PRIMARY KEY,
  hs_version VARCHAR(4),
  hs6 VARCHAR(6),
  sciname VARCHAR(100),
  sciname_hs_modified VARCHAR(100)
);
