-- trunc rounds toward zero; INTEGER in gives INTEGER out, REAL gives REAL
SELECT trunc(1.7), trunc(-1.7), trunc(-0.3), trunc(5.0), typeof(trunc(5.0));
SELECT trunc(19), typeof(trunc(19)), trunc(-19), trunc(NULL);
CREATE TABLE reading (id INTEGER, val REAL);
INSERT INTO reading VALUES (1, 12.95), (2, -12.95), (3, 0.5), (4, -100.01);
SELECT id, val, trunc(val), typeof(trunc(val)) FROM reading ORDER BY id;
