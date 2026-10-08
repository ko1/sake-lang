-- renaming an INTEGER PRIMARY KEY column keeps it the rowid
CREATE TABLE gx (id INTEGER PRIMARY KEY, t TEXT);
INSERT INTO gx (t) VALUES ('a'), ('b');
ALTER TABLE gx RENAME COLUMN id TO key2;
INSERT INTO gx (t) VALUES ('c');
SELECT key2, rowid, t FROM gx ORDER BY 1;
INSERT INTO gx (rowid, t) VALUES (3, 'd');
