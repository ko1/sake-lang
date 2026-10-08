-- floor rounds a REAL down and keeps it REAL; an INTEGER comes back as is
SELECT floor(1.7), floor(-1.7), floor(-0.2), floor(9.0), typeof(floor(9.0));
SELECT floor(42), typeof(floor(42)), floor(-8), floor(NULL);
CREATE TABLE temp (city TEXT, deg REAL);
INSERT INTO temp VALUES ('oslo', -3.5), ('rome', 18.9), ('lima', 0.4), ('cairo', 31.0);
SELECT city, floor(deg) FROM temp ORDER BY floor(deg), city;
