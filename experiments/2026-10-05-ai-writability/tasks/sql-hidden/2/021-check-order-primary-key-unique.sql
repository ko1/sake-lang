CREATE TABLE q (alt TEXT UNIQUE, code TEXT, k INTEGER, PRIMARY KEY (code));
INSERT INTO q VALUES ('a', 'b', 1);
INSERT INTO q VALUES ('a', 'b', 2);
INSERT INTO q VALUES ('a', 'c', 2);
INSERT INTO q VALUES ('z', 'b', 2);
INSERT INTO q VALUES ('z', NULL, 2);
CREATE TABLE q2 (code TEXT PRIMARY KEY, alt TEXT UNIQUE);
INSERT INTO q2 VALUES ('a', 'b'), ('a', 'b');
SELECT alt, code, k FROM q;
