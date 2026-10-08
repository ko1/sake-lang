-- INSERT ... SELECT with a full ORDER BY numbers the rows in that order
CREATE TABLE raw (nm TEXT, score INTEGER);
INSERT INTO raw VALUES ('ivy', 70), ('jo', 95), ('kai', 80);
CREATE TABLE ranked (nm TEXT);
INSERT INTO ranked SELECT nm FROM raw ORDER BY score DESC;
SELECT rowid, nm FROM ranked ORDER BY rowid;
INSERT INTO ranked SELECT nm || '2' FROM raw WHERE score > 75 ORDER BY nm;
SELECT rowid, nm FROM ranked ORDER BY rowid;
