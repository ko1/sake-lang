-- A plain column in the subquery carries its column's affinity into the IN comparisons.
CREATE TABLE ints (i INTEGER);
CREATE TABLE texts (s TEXT);
INSERT INTO ints VALUES (1), (12);
INSERT INTO texts VALUES ('12'), ('1.0'), ('abc');
SELECT '12' IN (SELECT i FROM ints), '12' IN (SELECT i + 0 FROM ints);
SELECT 12 IN (SELECT s FROM texts), 12 IN (SELECT s || '' FROM texts);
SELECT i FROM ints WHERE i IN (SELECT s FROM texts) ORDER BY i;
SELECT s FROM texts WHERE s IN (SELECT i FROM ints) ORDER BY s;
SELECT s FROM texts WHERE s IN (SELECT i * 1 FROM ints) ORDER BY s;
SELECT 1.0 IN (SELECT s FROM texts), '1.0' IN (SELECT i FROM ints);
