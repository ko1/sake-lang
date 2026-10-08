-- a bare ORDER BY name that is an alias means the result column; inside an expression it is the rowid
CREATE TABLE r (v TEXT);
INSERT INTO r VALUES ('x'), ('y'), ('z');
SELECT v, 10 - rowid AS rowid FROM r ORDER BY rowid;
SELECT v, 10 - rowid AS rowid FROM r ORDER BY rowid * 1;
SELECT v, -oid AS oid FROM r ORDER BY oid DESC;
SELECT v, -oid AS oid FROM r ORDER BY -oid;
