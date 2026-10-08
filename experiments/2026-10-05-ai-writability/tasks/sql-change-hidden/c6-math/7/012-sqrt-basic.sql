-- sqrt gives a REAL; negative arguments give NULL
SELECT sqrt(49), sqrt(3), sqrt(1.44), sqrt(1e-6), typeof(sqrt(49));
SELECT sqrt(-4), sqrt(-0.5), sqrt(NULL), sqrt(0.0);
CREATE TABLE area (room TEXT, m2 REAL);
INSERT INTO area VALUES ('hall', 6.25), ('den', 20.0), ('loft', -1.0), ('bath', 4.0);
SELECT room, sqrt(m2) FROM area ORDER BY room;
