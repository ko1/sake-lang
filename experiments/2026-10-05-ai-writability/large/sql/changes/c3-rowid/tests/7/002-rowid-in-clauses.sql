-- the rowid works in WHERE, ORDER BY, expressions and aggregates
CREATE TABLE log (msg TEXT);
INSERT INTO log VALUES ('boot'), ('login'), ('error'), ('logout');
SELECT msg FROM log WHERE rowid > 2 ORDER BY rowid DESC;
SELECT rowid * 10, msg || '#' || rowid FROM log ORDER BY 1;
SELECT count(rowid), min(rowid), max(oid), sum(_rowid_) FROM log;
SELECT msg FROM log WHERE rowid BETWEEN 2 AND 3 ORDER BY msg;
SELECT msg FROM log WHERE rowid = '4';
SELECT msg FROM log ORDER BY rowid LIMIT 1 OFFSET 1;
