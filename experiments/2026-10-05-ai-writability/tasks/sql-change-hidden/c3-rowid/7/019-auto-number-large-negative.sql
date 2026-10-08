-- after a large explicit rowid the next is one more; all-negative rowids count up too
CREATE TABLE big (t TEXT);
INSERT INTO big (rowid, t) VALUES (1000000, 'm');
INSERT INTO big VALUES ('n');
SELECT rowid, t FROM big ORDER BY rowid;
CREATE TABLE neg (t TEXT);
INSERT INTO neg (rowid, t) VALUES (-10, 'p'), (-7, 'q');
INSERT INTO neg VALUES ('r'), ('s');
SELECT rowid, t FROM neg ORDER BY rowid;
