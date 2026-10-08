-- the rowid has INTEGER affinity, and no row is in scope in INSERT ... VALUES
CREATE TABLE w (word TEXT);
INSERT INTO w VALUES ('one'), ('two'), ('three');
SELECT word FROM w WHERE rowid = ' 2 ';
SELECT word FROM w WHERE oid IN ('1', '3') ORDER BY word;
SELECT word FROM w WHERE rowid > '2';
SELECT word, CASE rowid WHEN '3' THEN 'last' ELSE 'not' END FROM w ORDER BY word;
INSERT INTO w VALUES (oid || 'x');
INSERT INTO w VALUES ('four');
SELECT max(rowid), count(*) FROM w;
