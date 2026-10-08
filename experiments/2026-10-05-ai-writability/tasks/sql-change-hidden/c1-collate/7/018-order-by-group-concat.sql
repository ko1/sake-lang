-- group_concat's ORDER BY follows the term's collation; ORDER BY a COLLATE term.
CREATE TABLE notes (grp INTEGER, word TEXT, w2 TEXT COLLATE NOCASE);
INSERT INTO notes VALUES (1, 'beta', 'beta'), (1, 'Alpha', 'Alpha'), (1, 'Gamma', 'Gamma'), (2, 'b', 'b'), (2, 'A', 'A');
SELECT grp, group_concat(word, ' ' ORDER BY word) FROM notes GROUP BY grp ORDER BY grp;
SELECT grp, group_concat(w2, ' ' ORDER BY w2) FROM notes GROUP BY grp ORDER BY grp;
SELECT group_concat(word, '' ORDER BY word COLLATE NOCASE DESC) FROM notes;
SELECT grp FROM notes ORDER BY word COLLATE NOCASE DESC LIMIT 2;
