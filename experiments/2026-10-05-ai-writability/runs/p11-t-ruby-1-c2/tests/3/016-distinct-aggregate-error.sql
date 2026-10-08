CREATE TABLE notes (author TEXT, body TEXT);
INSERT INTO notes VALUES ('al', 'hi'), ('al', 'yo');
SELECT group_concat(DISTINCT body, '-') FROM notes;
SELECT group_concat(DISTINCT body) FROM notes WHERE author = 'zz';
SELECT author, group_concat(DISTINCT author, ', ') FROM notes GROUP BY author;
SELECT group_concat(DISTINCT author) FROM notes;
