SELECT abs(-5), abs(5), abs(0), typeof(abs(-5));
SELECT abs(-2.5), abs(2.5), typeof(abs(-2.5));
SELECT abs('-3'), typeof(abs('-3'));
SELECT abs('4x'), abs('abc'), abs('-2.5e1');
SELECT abs(NULL);
SELECT abs(-0.0), abs(3 - 10);
CREATE TABLE t (id INTEGER, d INTEGER, s TEXT);
INSERT INTO t VALUES (1, -7, '-1'), (2, 3, '8'), (3, -1, 'z');
SELECT id, abs(d), abs(s) FROM t ORDER BY abs(d);
