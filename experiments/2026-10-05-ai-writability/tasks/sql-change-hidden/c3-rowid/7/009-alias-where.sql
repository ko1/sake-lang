-- in WHERE a rowid name is the rowid, not a result alias of that name
CREATE TABLE ln (txt TEXT);
INSERT INTO ln VALUES ('aa'), ('bb'), ('cc');
SELECT txt, 4 - rowid AS rowid FROM ln WHERE rowid = 3;
SELECT txt, rowid + 100 AS oid FROM ln WHERE oid < 3 ORDER BY txt;
SELECT txt, length(txt) * 0 AS rowid FROM ln WHERE rowid IN (1, 2) ORDER BY txt;
