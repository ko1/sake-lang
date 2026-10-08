SELECT 'xy' GLOB 'x' || '?' = 1, 'xy' GLOB 'z*' = 0, 'xy' NOT GLOB 'z*' = 1;
SELECT 'k' GLOB 'k' IS 1, 'k' GLOB 'j' IS NOT 1, 'k' NOT GLOB 'k' IN (0, 5);
SELECT NOT 'abc' GLOB '*b*' OR 'abc' GLOB 'a??', NOT ('abc' GLOB '*b*' OR 'abc' GLOB 'x*');
SELECT 'ab' GLOB 'a*' AND NOT 'ab' GLOB '*a';
CREATE TABLE p (s TEXT, pre TEXT, suf TEXT);
INSERT INTO p VALUES ('red apple', 'red', 'apple'), ('green pear', 'red', 'pear'), ('red pear', 'gr', 'pear');
SELECT s FROM p WHERE s GLOB pre || '*' || suf ORDER BY s;
SELECT s FROM p WHERE s NOT GLOB pre || '*' ORDER BY s;
