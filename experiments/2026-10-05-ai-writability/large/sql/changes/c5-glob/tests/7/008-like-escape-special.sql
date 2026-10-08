-- the escape character escapes itself
SELECT 'a!b' LIKE 'a!!b' ESCAPE '!', 'ab' LIKE 'a!!b' ESCAPE '!', 'a!' LIKE 'a!!' ESCAPE '!';
-- a wildcard used as the escape character is no longer a wildcard
SELECT 'a%' LIKE 'a%%' ESCAPE '%', 'ab' LIKE 'a%%' ESCAPE '%', 'ab' LIKE 'a%b' ESCAPE '%';
SELECT 'a_' LIKE 'a__' ESCAPE '_', 'ab' LIKE 'a__' ESCAPE '_';
-- an escape character at the end of the pattern matches nothing
SELECT 'a' LIKE 'a!' ESCAPE '!', 'a!' LIKE 'a!' ESCAPE '!', 'ab' LIKE 'a%!' ESCAPE '!';
-- a NULL anywhere gives NULL
SELECT 'a' LIKE 'a' ESCAPE NULL, NULL LIKE 'a' ESCAPE '!', 'a' LIKE NULL ESCAPE '!', 'a' NOT LIKE 'a' ESCAPE NULL;
SELECT 'a%' NOT LIKE 'a!%' ESCAPE '!', 'ab' NOT LIKE 'a!%' ESCAPE '!';
CREATE TABLE rules (id INTEGER PRIMARY KEY, pat TEXT, esc TEXT);
INSERT INTO rules (pat, esc) VALUES ('5#%', '#'), ('5%', '#'), ('5$%', '$'), ('5%', NULL);
SELECT id, '5%' LIKE pat ESCAPE esc, '50' LIKE pat ESCAPE esc FROM rules ORDER BY id;
