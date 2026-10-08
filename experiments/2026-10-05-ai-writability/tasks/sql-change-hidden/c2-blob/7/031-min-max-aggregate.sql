CREATE TABLE z (g TEXT, v BLOB);
INSERT INTO z VALUES ('a', X'05'), ('a', X'0500'), ('a', NULL), ('b', X'FF'), ('b', X'00FF'), ('c', NULL);
SELECT g, min(v), max(v), count(v), count(*) FROM z GROUP BY g ORDER BY g;
SELECT min(v), max(v) FROM z;
