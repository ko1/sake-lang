CREATE TABLE addr (city TEXT, zip TEXT, floor INTEGER);
INSERT INTO addr VALUES ('rome', NULL, 1), ('rome', NULL, 1), ('rome', '001', NULL), (NULL, NULL, NULL), (NULL, NULL, NULL), ('rome', '001', NULL);
SELECT DISTINCT city, zip, floor FROM addr ORDER BY city, zip, floor;
SELECT DISTINCT zip FROM addr ORDER BY zip DESC;
SELECT DISTINCT floor IS NULL, city IS NULL FROM addr ORDER BY 1, 2;
SELECT count(*) FROM addr;
