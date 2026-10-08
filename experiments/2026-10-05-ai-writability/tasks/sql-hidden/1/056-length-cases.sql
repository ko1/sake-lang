SELECT length('a'), length('  two  '), length('it''s');
SELECT length(0), length(-0.5), length(1e-7), length(2.0 / 3);
SELECT length(12345678901234), length(1e15);
SELECT length(NULL), length(1 || NULL);
SELECT length(upper('abc')), LENGTH('line
break');
CREATE TABLE w (word TEXT, n REAL);
INSERT INTO w VALUES ('alpha', 1), ('be', 22.5), ('', NULL), ('gamma', -3);
SELECT word, length(word), length(n) FROM w ORDER BY length(word), word;
SELECT word FROM w WHERE length(word) > 2 ORDER BY word DESC;
SELECT typeof(length(n)) FROM w WHERE word = '';
