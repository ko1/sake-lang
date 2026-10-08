-- ROLLBACK also undoes created, dropped and altered tables, views and indexes
CREATE TABLE keep (a INTEGER);
INSERT INTO keep VALUES (1);
CREATE VIEW kv AS SELECT a FROM keep;
BEGIN;
CREATE TABLE temp1 (x INTEGER);
INSERT INTO temp1 VALUES (9);
DROP VIEW kv;
CREATE INDEX ka ON keep (a);
ALTER TABLE keep ADD COLUMN b TEXT DEFAULT 'new';
SELECT a, b FROM keep;
ROLLBACK;
SELECT * FROM temp1;
SELECT a FROM kv;
SELECT * FROM keep;
DROP INDEX ka;
CREATE TABLE temp1 (y INTEGER);
SELECT count(*) FROM temp1;
