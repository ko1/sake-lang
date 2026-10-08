CREATE TABLE p (code TEXT, a INTEGER, b INTEGER);
INSERT INTO p VALUES ('ABCDEFG', 3, 2), ('xyz', 0, 3), ('hello', -2, 5), ('12345', 9, 1), ('data', 2, NULL);
SELECT code, substr(code, a, b) FROM p ORDER BY code;
SELECT code, substr(code, a) FROM p ORDER BY code;
UPDATE p SET code = substr(code, 2, 3);
SELECT code FROM p ORDER BY code;
SELECT substr(3.14159, 1, 4), substr(-25, 1, 1), substr('', 1, 3) || '|';
