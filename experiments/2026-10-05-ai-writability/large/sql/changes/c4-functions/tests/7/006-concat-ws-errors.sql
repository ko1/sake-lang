-- concat_ws needs a separator and at least one value
SELECT concat_ws(',');
SELECT concat_ws();
SELECT concat_ws(',', 'ok');
CREATE TABLE addr (id INTEGER, street TEXT, city TEXT, zip TEXT);
INSERT INTO addr VALUES (1, '1 Main St', 'Springfield', '12345'), (2, NULL, 'Shelby', NULL);
SELECT id, concat_ws(', ', street, city, zip) FROM addr ORDER BY id;
SELECT Concat_Ws(' ');
