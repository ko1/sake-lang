-- removing duplicates by keeping the row with the smallest rowid
CREATE TABLE contact (email TEXT, nm TEXT);
INSERT INTO contact VALUES ('a@x', 'Ann'), ('b@x', 'Ben'), ('a@x', 'Annie'), ('c@x', 'Cy'), ('b@x', 'B');
SELECT email, count(*) FROM contact GROUP BY email HAVING count(*) > 1 ORDER BY email;
DELETE FROM contact WHERE rowid NOT IN (SELECT min(rowid) FROM contact GROUP BY email);
SELECT rowid, email, nm FROM contact ORDER BY rowid;
CREATE UNIQUE INDEX one_email ON contact (email);
INSERT INTO contact VALUES ('d@x', 'Di');
SELECT rowid, email FROM contact ORDER BY rowid;
