CREATE TABLE c (code TEXT UNIQUE, n INTEGER);
INSERT INTO c VALUES ('a', 1), ('b', 2), ('c', 3);
UPDATE c SET code = code || '-' || n;
SELECT code FROM c ORDER BY n;
UPDATE c SET code = 'same';
UPDATE c SET code = 'same' WHERE n = 2;
UPDATE c SET code = upper(code) WHERE n <> 2;
SELECT code, n FROM c ORDER BY n;
