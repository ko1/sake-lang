-- pi with arguments is an error; pi in a computation over rows
SELECT pi(1);
SELECT Pi(NULL);
SELECT pi(1, 2);
CREATE TABLE circle (id INTEGER, r REAL);
INSERT INTO circle VALUES (1, 1.0), (2, 2.0), (3, 0.5);
SELECT id, pi() * r * r, round(2 * pi() * r, 3) FROM circle ORDER BY id;
