SELECT round(2.5), round(-2.5), round(2.345, 2), round(1.005, 2), round(5);
SELECT round(3.14159, 3), round(-1.25, 1), round(1234.5678, -2), round(0.4), round(-0.4);
SELECT round('2.71828x', 2), round('abc'), round(NULL), round(1.5, NULL), typeof(round(7));
CREATE TABLE pr (p REAL);
INSERT INTO pr VALUES (19.995), (0.125), (2.675);
SELECT p, round(p, 2), round(p * 1.1, 1) FROM pr ORDER BY p;
