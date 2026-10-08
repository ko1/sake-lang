-- A second LEFT JOIN can match against NULL-extended columns of the first (it never does).
CREATE TABLE countries (cc TEXT, cname TEXT);
CREATE TABLE capitals (cc TEXT, city TEXT);
CREATE TABLE mayors (city TEXT, mayor TEXT);
INSERT INTO countries VALUES ('fr', 'France'), ('it', 'Italy'), ('xx', 'Nowhere');
INSERT INTO capitals VALUES ('fr', 'Paris'), ('it', 'Rome');
INSERT INTO mayors VALUES ('Paris', 'P. Mayor'), ('Lyon', 'L. Mayor');
SELECT cname, k.city, mayor FROM countries c LEFT JOIN capitals k ON k.cc = c.cc
  LEFT JOIN mayors m ON m.city = k.city ORDER BY cname;
SELECT city FROM capitals k LEFT JOIN mayors m ON m.city = k.city;
SELECT cname, k.city, mayor FROM countries c LEFT JOIN capitals k ON k.cc = c.cc
  JOIN mayors m ON m.city = k.city ORDER BY cname;
SELECT cname, m.city FROM countries c LEFT JOIN capitals k ON k.cc = c.cc
  LEFT JOIN mayors m ON m.city = k.city OR k.city IS NULL ORDER BY cname, m.city;
