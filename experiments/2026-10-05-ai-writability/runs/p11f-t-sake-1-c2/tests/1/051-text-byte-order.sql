SELECT 'B' < 'a', 'Z' < 'a', 'abc' < 'abd', 'ab' < 'abc';
SELECT 'a' < 'aa', '10' < '9', ' z' < 'a', '_' < 'a';
CREATE TABLE w (word TEXT);
INSERT INTO w VALUES ('banana'), ('Apple'), ('apple'), ('Banana'), ('cherry'), ('123'), (''), ('a b');
SELECT word FROM w ORDER BY word;
SELECT word FROM w ORDER BY word DESC LIMIT 3;
SELECT word FROM w WHERE word > 'B' ORDER BY word;
SELECT word FROM w ORDER BY lower(word), word;
