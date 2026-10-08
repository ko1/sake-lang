CREATE TABLE words (w TEXT);
INSERT INTO words VALUES ('banana'), ('Apple'), ('cherry'), (NULL), ('apple');
SELECT min(w), max(w) FROM words;
SELECT min(upper(w)), max(length(w)) FROM words;
SELECT min(w) FROM words WHERE w LIKE 'a%';
SELECT max(w) FROM words WHERE w > 'b';
