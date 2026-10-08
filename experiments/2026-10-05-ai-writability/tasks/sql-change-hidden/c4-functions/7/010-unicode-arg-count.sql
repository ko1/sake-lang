-- unicode takes exactly one argument
SELECT unicode();
SELECT unicode('a', 'b');
CREATE TABLE w (id INTEGER, word TEXT);
INSERT INTO w VALUES (1, 'cat'), (2, ''), (3, NULL), (4, 'Dog');
SELECT id, unicode(word) FROM w ORDER BY id;
SELECT id FROM w WHERE unicode(word) > 90 ORDER BY id;
