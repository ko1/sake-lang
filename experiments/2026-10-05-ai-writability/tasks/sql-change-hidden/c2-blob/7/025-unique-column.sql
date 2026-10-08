CREATE TABLE tok (t BLOB UNIQUE, owner TEXT);
INSERT INTO tok VALUES (X'AB', 'ann'), (X'AB00', 'bob'), (NULL, 'cy'), (NULL, 'dee');
INSERT INTO tok VALUES (x'ab', 'eve');
INSERT INTO tok VALUES (CAST('x' AS BLOB), 'fay');
INSERT INTO tok VALUES (X'78', 'gus');
SELECT owner, t FROM tok ORDER BY owner;
