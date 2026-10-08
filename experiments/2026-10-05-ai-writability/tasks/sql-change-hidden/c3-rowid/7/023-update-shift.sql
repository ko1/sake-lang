-- shifting every rowid, and a later insert continuing from the new largest
CREATE TABLE slot (s TEXT);
INSERT INTO slot VALUES ('a'), ('b'), ('c');
UPDATE slot SET rowid = rowid + 100;
SELECT rowid, s FROM slot ORDER BY 1;
UPDATE slot SET oid = oid * -1 WHERE s <> 'b';
INSERT INTO slot VALUES ('d');
SELECT rowid, s FROM slot ORDER BY 1;
