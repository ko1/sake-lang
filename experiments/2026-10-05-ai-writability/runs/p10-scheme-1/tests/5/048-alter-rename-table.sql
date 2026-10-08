-- RENAME TO renames a table; its constraints and indexes follow it
CREATE TABLE draft (id INTEGER PRIMARY KEY, code TEXT UNIQUE, qty INTEGER NOT NULL);
INSERT INTO draft VALUES (1, 'a1', 5);
CREATE UNIQUE INDEX draft_qty ON draft (qty);
ALTER TABLE draft RENAME TO Final;
SELECT * FROM draft;
SELECT id, code, qty FROM final;
INSERT INTO final VALUES (2, 'a1', 6);
INSERT INTO final VALUES (3, 'b2', NULL);
INSERT INTO final VALUES (4, 'c3', 5);
INSERT INTO final VALUES (5, 'c3', 'many');
INSERT INTO final (code, qty) VALUES ('d4', 7);
SELECT id, code FROM Final ORDER BY id;
DROP INDEX draft_qty;
INSERT INTO final VALUES (6, 'e5', 5);
SELECT count(*) FROM FINAL;
