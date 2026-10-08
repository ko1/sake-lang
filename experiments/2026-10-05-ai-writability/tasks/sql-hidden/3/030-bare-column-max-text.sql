CREATE TABLE words (lang TEXT, word TEXT, freq INTEGER);
INSERT INTO words VALUES ('en', 'apple', 50), ('en', 'zebra', 3), ('de', 'apfel', 40), ('de', 'zug', 8), ('fr', 'pomme', 30);
SELECT lang, max(word), freq FROM words GROUP BY lang ORDER BY lang;
SELECT lang, freq, min(word) FROM words GROUP BY lang ORDER BY freq;
SELECT word, max(freq) FROM words WHERE lang <> 'en';
SELECT lang, max(length(word)), word FROM words WHERE lang = 'de' GROUP BY lang;
