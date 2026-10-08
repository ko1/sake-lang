-- NOT NULL, then storage, then uniqueness with the INTEGER PRIMARY KEY first
CREATE TABLE u (id INTEGER PRIMARY KEY, name TEXT NOT NULL, age INTEGER, code TEXT UNIQUE);
INSERT INTO u VALUES (1, 'ann', 30, 'A');
INSERT INTO u VALUES (1, NULL, 31, 'A');
INSERT INTO u VALUES (2, 'bob', 'old', 'A');
INSERT INTO u VALUES (1, 'bob', 31, 'A');
INSERT INTO u VALUES (2, 'bob', 31, 'A');
INSERT INTO u VALUES (2, 'bob', 31.5, 'B');
SELECT id, name, age, code FROM u ORDER BY id;
