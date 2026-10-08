CREATE TABLE pk (id INTEGER, payload BLOB);
INSERT INTO pk VALUES (1, X'0102030405'), (2, X''), (3, NULL), (4, X'20');
SELECT id, length(payload) FROM pk ORDER BY id;
SELECT sum(length(payload)) FROM pk;
SELECT id FROM pk WHERE length(payload) > 0 ORDER BY id;
