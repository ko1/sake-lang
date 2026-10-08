-- A scalar subquery has no collation, even over a NOCASE column or with an explicit COLLATE.
CREATE TABLE cfg (k TEXT COLLATE NOCASE, val TEXT);
INSERT INTO cfg VALUES ('Mode', 'Fast'), ('level', 'HIGH');
SELECT (SELECT k FROM cfg WHERE val = 'Fast') = 'mode';
SELECT 'MODE' = (SELECT k FROM cfg WHERE val = 'Fast');
SELECT (SELECT val COLLATE NOCASE FROM cfg WHERE k = 'LEVEL') = 'high';
SELECT k FROM cfg WHERE k = (SELECT 'mode');
SELECT val FROM cfg WHERE (SELECT 'LEVEL') = k;
