-- An IN subquery with more than one column is an error, and the statement has no effect.
CREATE TABLE k (id INTEGER, tag TEXT);
CREATE TABLE drop_list (id INTEGER, why TEXT);
INSERT INTO k VALUES (1, 'a'), (2, 'b'), (3, 'c');
INSERT INTO drop_list VALUES (2, 'old');
DELETE FROM k WHERE id IN (SELECT * FROM drop_list);
SELECT count(*) FROM k;
UPDATE k SET tag = 'x' WHERE id NOT IN (SELECT id, why FROM drop_list);
SELECT tag FROM k ORDER BY id;
SELECT id FROM k WHERE id IN (SELECT id, id FROM drop_list);
DELETE FROM k WHERE id IN (SELECT id FROM drop_list);
SELECT id, tag FROM k ORDER BY id;
SELECT id FROM k WHERE tag IN (SELECT * FROM (SELECT tag FROM k WHERE id = 3));
