CREATE TABLE temps (city TEXT, deg REAL, rank INTEGER);
INSERT INTO temps VALUES ('oslo', -3.5, 3), ('rome', 18.25, NULL), ('cairo', 31.0, 1);
SELECT min(deg), max(deg) FROM temps;
SELECT min(rank), max(rank), typeof(max(rank)) FROM temps;
SELECT min(deg), max(rank) FROM temps WHERE city = 'nowhere';
SELECT max(deg) - min(deg) FROM temps;
SELECT MIN(rank * 10) FROM temps;
