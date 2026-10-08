SELECT 'Zeta' < 'alpha', 'a1' < 'aA', 'x' < 'xy', 'A B' < 'AB';
SELECT '9' > '10', '-1' < '0', '~' > 'z';
CREATE TABLE n (s TEXT);
INSERT INTO n VALUES ('b'), ('B'), ('ba'), ('a'), ('_x'), ('Ab'), ('9'), ('10'), (' a');
SELECT s FROM n ORDER BY s;
SELECT s FROM n ORDER BY s DESC LIMIT 4;
SELECT s FROM n WHERE s >= 'a' ORDER BY s;
SELECT s FROM n ORDER BY upper(s), s;
SELECT s FROM n WHERE s < 'A' ORDER BY s DESC;
