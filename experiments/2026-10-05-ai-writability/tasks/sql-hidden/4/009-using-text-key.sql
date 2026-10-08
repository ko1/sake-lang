-- USING compares like =: text keys match only when equal byte for byte.
CREATE TABLE words (w TEXT, lang TEXT);
CREATE TABLE gloss (w TEXT, meaning TEXT);
INSERT INTO words VALUES ('Haus', 'de'), ('casa', 'it'), ('maison', 'fr'), ('hus', 'no');
INSERT INTO gloss VALUES ('haus', 'house?'), ('casa', 'house'), ('maison', 'house'), ('HUS', 'house!');
SELECT w, lang, meaning FROM words JOIN gloss USING (w) ORDER BY w;
SELECT w, meaning FROM words LEFT JOIN gloss USING (w) ORDER BY lang;
SELECT words.w, gloss.w FROM words JOIN gloss ON upper(words.w) = upper(gloss.w) ORDER BY 1;
SELECT count(*) FROM words JOIN gloss USING (w) WHERE meaning = 'house';
