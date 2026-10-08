-- ORDER BY names from the first simple-select: an alias or a plain column
CREATE TABLE fruit (fname TEXT, kcal INTEGER);
CREATE TABLE veg (vname TEXT, kcal INTEGER);
INSERT INTO fruit VALUES ('fig', 74), ('apple', 52);
INSERT INTO veg VALUES ('kale', 49), ('corn', 86);
SELECT fname, kcal FROM fruit UNION SELECT vname, kcal FROM veg ORDER BY kcal;
SELECT fname AS food, kcal AS energy FROM fruit UNION SELECT vname, kcal FROM veg ORDER BY energy DESC LIMIT 3;
SELECT fname AS food, kcal FROM fruit UNION ALL SELECT vname, kcal FROM veg ORDER BY food;
SELECT kcal, fname FROM fruit EXCEPT SELECT kcal, vname FROM veg ORDER BY fname DESC;
SELECT upper(fname) AS u FROM fruit UNION SELECT vname FROM veg ORDER BY u;
