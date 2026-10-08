-- index names may not be a table's name; other index errors
CREATE TABLE alpha (a INTEGER);
CREATE TABLE beta (b INTEGER);
CREATE VIEW gamma AS SELECT 1 AS g;
CREATE INDEX alpha ON beta (b);
CREATE UNIQUE INDEX Beta ON alpha (a);
CREATE INDEX IF NOT EXISTS alpha ON alpha (a);
CREATE INDEX ix ON alpha (a);
CREATE UNIQUE INDEX ix ON beta (b);
CREATE INDEX IF NOT EXISTS ix ON beta (b);
DROP INDEX alpha;
DROP INDEX IF EXISTS alpha;
DROP INDEX ix;
DROP INDEX Ix;
CREATE INDEX ix ON beta (b);
SELECT 'ok';
