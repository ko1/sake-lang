-- UNION over three sources removes duplicates across all of them
CREATE TABLE jan (city TEXT, temp INTEGER);
CREATE TABLE feb (city TEXT, temp INTEGER);
CREATE TABLE mar (city TEXT, temp INTEGER);
INSERT INTO jan VALUES ('oslo', -5), ('rome', 8), ('oslo', -5);
INSERT INTO feb VALUES ('oslo', -3), ('rome', 8);
INSERT INTO mar VALUES ('rome', 12), ('oslo', -3), ('lima', 20);
SELECT city, temp FROM jan UNION SELECT city, temp FROM feb UNION SELECT city, temp FROM mar ORDER BY city, temp;
SELECT city FROM jan UNION SELECT city FROM feb UNION SELECT city FROM mar ORDER BY city DESC;
SELECT temp FROM jan UNION ALL SELECT temp FROM feb UNION SELECT temp FROM mar ORDER BY temp;
