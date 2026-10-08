-- GLOB binds like = and LIKE: tighter operators group first, level 6 is left-associative
SELECT 'ab' GLOB 'a' || '*', 'abc' GLOB 'x' || '*';
SELECT 'a' GLOB 'a' = 1, 'a' GLOB 'b' = 0, 'x' GLOB 'y' = 1;
SELECT 'x' GLOB 'x' IN (1), 'a' NOT GLOB 'a' IS 0, 'a' GLOB 'a' BETWEEN 0 AND 1;
SELECT NOT 'abc' GLOB 'a*', NOT 'abc' GLOB 'b*';
SELECT 'abc' GLOB 'a*' AND 'abc' GLOB '*c', 'abc' GLOB 'x*' OR 'abc' GLOB '*c';
CREATE TABLE t (a TEXT, b TEXT);
INSERT INTO t VALUES ('apple', 'ap'), ('banana', 'ba'), ('cherry', 'ap');
SELECT a FROM t WHERE a GLOB b || '*' ORDER BY a;
SELECT a, a GLOB b || '*' = 0 FROM t ORDER BY a;
