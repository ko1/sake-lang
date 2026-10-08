CREATE TABLE expenses (cat TEXT, amt INTEGER);
INSERT INTO expenses VALUES ('food', 30), ('rent', 500), ('food', 25), ('fun', 40), ('fun', 10), ('fun', 6);
SELECT cat, sum(amt) AS spent FROM expenses GROUP BY cat ORDER BY spent;
SELECT cat, count(*) AS n FROM expenses GROUP BY cat ORDER BY n DESC, cat;
SELECT cat AS amt, max(amt) AS top FROM expenses GROUP BY cat ORDER BY amt;
SELECT cat, sum(amt) FROM expenses GROUP BY cat ORDER BY 2 DESC;
