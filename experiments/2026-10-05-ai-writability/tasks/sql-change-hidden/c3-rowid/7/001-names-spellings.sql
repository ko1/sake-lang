-- the three rowid names in mixed case, unqualified and qualified
CREATE TABLE city (cname TEXT, pop INTEGER);
INSERT INTO city VALUES ('Oslo', 700), ('Lima', 9000), ('Bern', 130);
SELECT _ROWID_, oId, RowId, cname FROM city ORDER BY cname;
SELECT city.OID, city."_rowid_" FROM city WHERE pop < 1000 ORDER BY 1;
SELECT typeof(_rowid_), typeof(city.oid) FROM city WHERE cname = 'Lima';
