CREATE TABLE fruit (name TEXT, qty INTEGER);
SELECT count(*) FROM fruit;
INSERT INTO fruit VALUES ('apple', 3), ('pear', NULL), ('plum', 7);
SELECT count(*) FROM fruit;
SELECT COUNT(*) FROM fruit WHERE qty > 2;
SELECT count(*) FROM fruit WHERE 0;
SELECT count(*) + 10, typeof(count(*)) FROM fruit;
