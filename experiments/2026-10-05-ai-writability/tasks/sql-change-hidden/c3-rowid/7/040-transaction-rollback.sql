-- ROLLBACK restores rows and rowids; numbering continues from what is present
CREATE TABLE tx (s TEXT);
INSERT INTO tx VALUES ('a'), ('b');
BEGIN;
INSERT INTO tx VALUES ('c');
INSERT INTO tx (rowid, s) VALUES (500, 'd');
UPDATE tx SET rowid = 77 WHERE s = 'a';
DELETE FROM tx WHERE s = 'b';
ROLLBACK;
SELECT rowid, s FROM tx ORDER BY rowid;
INSERT INTO tx VALUES ('e');
SELECT rowid, s FROM tx ORDER BY rowid;
