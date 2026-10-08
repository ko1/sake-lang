-- text arguments and argument count for trunc
SELECT trunc('15'), typeof(trunc('15')), trunc(' 15.9 '), trunc('-0.5e1'), trunc('15abc'), trunc('');
CREATE TABLE raw (s TEXT);
INSERT INTO raw VALUES ('3.99'), ('-3.99'), ('n/a'), ('12');
SELECT s, trunc(s), typeof(trunc(s)) FROM raw ORDER BY s;
SELECT trunc();
SELECT Trunc(1.5, 2);
