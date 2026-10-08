-- INTERSECT keeps the distinct rows present on both sides
CREATE TABLE morning (who TEXT);
CREATE TABLE evening (who TEXT);
INSERT INTO morning VALUES ('ann'), ('bob'), ('bob'), ('cid');
INSERT INTO evening VALUES ('bob'), ('cid'), ('cid'), ('dan');
SELECT who FROM morning INTERSECT SELECT who FROM evening ORDER BY who;
SELECT who FROM evening INTERSECT SELECT 'ann' ORDER BY who;
SELECT 1, 'a' INTERSECT SELECT 1, 'a';
SELECT 1, 'a' INTERSECT SELECT 1, 'A';
