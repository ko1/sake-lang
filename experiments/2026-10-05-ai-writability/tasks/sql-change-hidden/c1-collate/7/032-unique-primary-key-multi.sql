-- A TEXT PRIMARY KEY and a multi-column UNIQUE use each column's own collation.
CREATE TABLE seats (room TEXT COLLATE NOCASE, seat TEXT, who TEXT PRIMARY KEY COLLATE NOCASE, UNIQUE (room, seat));
INSERT INTO seats VALUES ('Hall', 'a1', 'Kim');
INSERT INTO seats VALUES ('HALL', 'a1', 'Lee');
INSERT INTO seats VALUES ('HALL', 'A1', 'Lee');
INSERT INTO seats VALUES ('Attic', 'b2', 'KIM');
INSERT INTO seats SELECT 'hall', 'c3', 'lee';
SELECT room, seat, who FROM seats ORDER BY who COLLATE BINARY;
