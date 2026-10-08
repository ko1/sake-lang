-- datatype mismatch, then NOT NULL, then the rowid's uniqueness, then storage, then UNIQUE
CREATE TABLE acct (num INTEGER NOT NULL, tag TEXT UNIQUE);
INSERT INTO acct (rowid, num, tag) VALUES (1, 10, 'a');
INSERT INTO acct (rowid, num, tag) VALUES ('q', NULL, 'a');
INSERT INTO acct (rowid, num, tag) VALUES (1, NULL, 'a');
INSERT INTO acct (rowid, num, tag) VALUES (1, 'zz', 'a');
INSERT INTO acct (rowid, num, tag) VALUES (2, 'zz', 'a');
INSERT INTO acct (rowid, num, tag) VALUES (2, 20, 'a');
SELECT rowid, num, tag FROM acct;
