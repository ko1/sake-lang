SELECT instr(X'68656C6C6F', 'll'), instr('hello', X'6C6F'), instr(X'616263', 'z');
CREATE TABLE m (id INTEGER, b BLOB);
INSERT INTO m VALUES (1, X'78795A'), (2, X'5A7879'), (3, X'7878');
SELECT id, instr(b, X'5A'), instr(b, 'xy') FROM m ORDER BY id;
