CREATE TABLE w (word TEXT);
INSERT INTO w VALUES ('cat'), ('cart'), ('scat'), ('ca'), ('c'), ('dog'), ('a_c');
SELECT word FROM w WHERE word LIKE 'ca%' ORDER BY word;
SELECT word FROM w WHERE word LIKE '%at' ORDER BY word;
SELECT word FROM w WHERE word LIKE 'c_t' ORDER BY word;
SELECT word FROM w WHERE word LIKE '_' ORDER BY word;
SELECT word FROM w WHERE word LIKE '%a%' AND word LIKE '___%' ORDER BY word;
SELECT word FROM w WHERE word LIKE 'a_c' ORDER BY word;
SELECT 'abc' LIKE 'abc', 'abc' LIKE 'ab', '' LIKE '%', '' LIKE '_', 'x' LIKE '%%%';
