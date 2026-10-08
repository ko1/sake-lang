-- a UNIQUE index cannot be created over rows that already conflict
CREATE TABLE sub (email TEXT, list TEXT, since INTEGER);
INSERT INTO sub VALUES ('a@x', 'news', 1), ('a@x', 'deals', 2), ('b@x', 'news', 2), ('b@x', 'news', 3);
CREATE UNIQUE INDEX sub_email ON sub (email);
CREATE UNIQUE INDEX sub_pair ON sub (list, email);
CREATE UNIQUE INDEX sub_since ON sub (since, list);
INSERT INTO sub VALUES ('c@x', 'news', 2);
INSERT INTO sub VALUES ('a@x', 'deals', 9);
DELETE FROM sub WHERE since = 3;
CREATE UNIQUE INDEX sub_pair ON sub (list, email);
INSERT INTO sub VALUES ('b@x', 'news', 7);
SELECT email, list, since FROM sub ORDER BY email, list;
CREATE UNIQUE INDEX sub_pair ON sub (since);
CREATE UNIQUE INDEX sub_one ON sub (email, list, since);
SELECT count(*) FROM sub;
