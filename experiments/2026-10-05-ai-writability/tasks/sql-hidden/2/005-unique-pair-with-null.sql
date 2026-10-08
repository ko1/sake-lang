CREATE TABLE lnk (src TEXT, dst TEXT, w INTEGER, UNIQUE (src, dst));
INSERT INTO lnk VALUES ('a', 'b', 1), ('a', NULL, 2), ('a', NULL, 3), (NULL, NULL, 4);
INSERT INTO lnk VALUES ('b', 'a', 5);
INSERT INTO lnk VALUES ('a', 'b', 6);
INSERT INTO lnk VALUES (NULL, 'b', 7), (NULL, 'b', 8);
UPDATE lnk SET dst = 'b' WHERE w = 2;
UPDATE lnk SET dst = 'c' WHERE w = 2;
SELECT w, coalesce(src, '?'), coalesce(dst, '?') FROM lnk ORDER BY w;
