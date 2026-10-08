-- RENAME COLUMN: unique indexes and table constraints follow the column
CREATE TABLE seat (row_no INTEGER, col_no INTEGER, holder TEXT, UNIQUE (row_no, col_no));
CREATE UNIQUE INDEX seat_holder ON seat (holder);
INSERT INTO seat VALUES (1, 1, 'ann'), (1, 2, 'bob');
ALTER TABLE seat RENAME COLUMN row_no TO r;
ALTER TABLE seat RENAME COLUMN holder TO who;
INSERT INTO seat VALUES (1, 1, 'cy');
INSERT INTO seat VALUES (2, 1, 'ann');
INSERT INTO seat (r, col_no, who) VALUES (2, 2, 'dan');
SELECT r, col_no, who FROM seat ORDER BY r, col_no;
SELECT row_no FROM seat;
ALTER TABLE seat RENAME COLUMN row_no TO rr;
ALTER TABLE seat RENAME COLUMN holder TO h;
ALTER TABLE seats RENAME COLUMN r TO s;
SELECT count(*) FROM seat WHERE who IS NOT NULL;
