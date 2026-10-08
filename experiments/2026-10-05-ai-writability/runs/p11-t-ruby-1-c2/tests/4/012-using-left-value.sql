-- An unqualified USING column is one column whose value is the left side's.
CREATE TABLE staff (id INTEGER, name TEXT);
CREATE TABLE badges (id INTEGER, color TEXT);
INSERT INTO staff VALUES (1, 'ann'), (2, 'bob'), (3, 'cid');
INSERT INTO badges VALUES (1, 'red'), (3, 'blue'), (4, 'gold');
SELECT id, staff.id, badges.id, color FROM staff LEFT JOIN badges USING (id) ORDER BY id;
SELECT id, color FROM badges LEFT JOIN staff USING (id) WHERE name IS NULL ORDER BY id;
SELECT name FROM staff JOIN badges USING (id) WHERE id > 1 ORDER BY id;
SELECT id FROM staff LEFT JOIN badges USING (id) ORDER BY id DESC;
