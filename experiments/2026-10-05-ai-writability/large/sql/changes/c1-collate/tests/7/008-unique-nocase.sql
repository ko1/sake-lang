-- UNIQUE and PRIMARY KEY compare a column under its collation.
CREATE TABLE accounts (email TEXT PRIMARY KEY COLLATE NOCASE, handle TEXT UNIQUE COLLATE RTRIM, city TEXT, zone TEXT COLLATE NOCASE, UNIQUE (city, zone));
INSERT INTO accounts VALUES ('ann@x.org', 'ann', 'Oslo', 'north');
INSERT INTO accounts VALUES ('ANN@X.ORG', 'ann2', 'Rome', 'south');
INSERT INTO accounts VALUES ('bob@x.org', 'ann  ', 'Rome', 'south');
INSERT INTO accounts VALUES ('bob@x.org', ' ann', 'OSLO', 'NORTH');
INSERT INTO accounts VALUES ('cy@x.org', 'cy', 'Oslo', 'North');
INSERT INTO accounts VALUES ('dee@x.org', 'dee', 'Rome', 'x'), ('Dee@x.org', 'dee2', 'Rome', 'y');
UPDATE accounts SET email = 'Ann@X.org' WHERE handle = ' ann';
UPDATE accounts SET email = 'Bob@X.org' WHERE handle = ' ann';
SELECT email, handle, city, zone FROM accounts ORDER BY email COLLATE BINARY;
