-- IS / IS NOT use the collation; LIKE does not.
CREATE TABLE f (id INTEGER, t TEXT COLLATE RTRIM, u TEXT COLLATE NOCASE);
INSERT INTO f VALUES (1, 'go  ', 'Go'), (2, 'Go', NULL), (3, NULL, 'gO ');
SELECT id, t IS 'go', u IS 'GO', t IS NOT 'go', u IS NOT NULL FROM f ORDER BY id;
SELECT id FROM f WHERE t LIKE 'go' ORDER BY id;
SELECT id FROM f WHERE u LIKE 'go' ORDER BY id;
SELECT id FROM f WHERE u = 'go ' ORDER BY id;
