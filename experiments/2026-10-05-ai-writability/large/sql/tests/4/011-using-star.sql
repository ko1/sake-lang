-- * leaves out the right side's copy of a USING column; q.* does not.
CREATE TABLE l (k INTEGER, a TEXT);
CREATE TABLE r (b TEXT, k INTEGER);
INSERT INTO l VALUES (1, 'one'), (2, 'two');
INSERT INTO r VALUES ('uno', 1), ('tres', 3);
SELECT * FROM l JOIN r USING (k);
SELECT * FROM r JOIN l USING (k);
SELECT * FROM l JOIN r ON l.k = r.k;
SELECT r.* FROM l JOIN r USING (k);
SELECT l.*, r.* FROM l JOIN r USING (k);
SELECT * FROM l LEFT JOIN r USING (k) ORDER BY k;
