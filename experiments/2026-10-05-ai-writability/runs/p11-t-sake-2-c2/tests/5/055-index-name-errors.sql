-- index names: their own name space, but not a table's name
CREATE TABLE t (a INTEGER);
CREATE TABLE u (b INTEGER);
CREATE INDEX idx ON t (a);
CREATE INDEX idx ON u (b);
CREATE INDEX IDX ON t (a);
CREATE INDEX u ON t (a);
CREATE INDEX T ON u (b);
DROP INDEX nope;
DROP INDEX t;
CREATE INDEX IF NOT EXISTS idx ON u (b);
DROP INDEX idx;
DROP INDEX idx;
SELECT 'end';
