CREATE TABLE labels (tag TEXT, n INTEGER);
INSERT INTO labels VALUES ('Red', 1), ('red', 2), ('RED', 3), ('red', 4), (' red', 5);
SELECT tag, count(*), sum(n) FROM labels GROUP BY tag ORDER BY tag;
SELECT lower(trim(tag)) AS t, count(*) FROM labels GROUP BY t;
SELECT count(*) FROM labels GROUP BY upper(tag) ORDER BY 1;
