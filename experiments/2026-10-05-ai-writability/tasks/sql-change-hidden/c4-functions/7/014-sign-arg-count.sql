-- sign takes exactly one argument
SELECT SIGN();
SELECT sign(1, -1);
SELECT sign(sign(-4) * 3);
CREATE TABLE bal (acct TEXT, amount INTEGER);
INSERT INTO bal VALUES ('a', 50), ('b', -20), ('c', 0), ('d', -1);
SELECT acct FROM bal WHERE sign(amount) = -1 ORDER BY acct;
