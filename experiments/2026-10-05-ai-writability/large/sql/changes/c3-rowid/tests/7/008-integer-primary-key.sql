-- an INTEGER PRIMARY KEY column is the rowid under another name
CREATE TABLE member (id INTEGER PRIMARY KEY, nick TEXT);
INSERT INTO member (nick) VALUES ('kat'), ('lou');
INSERT INTO member (rowid, nick) VALUES (30, 'max');
SELECT rowid, id, oid, nick FROM member ORDER BY id;
SELECT * FROM member WHERE rowid = 2;
UPDATE member SET rowid = 40 WHERE nick = 'kat';
UPDATE member SET id = 41 WHERE nick = 'lou';
SELECT id, rowid, nick FROM member ORDER BY 1;
INSERT INTO member (oid, nick) VALUES (40, 'ned');
CREATE TABLE code (k INTEGER, v TEXT, PRIMARY KEY (k));
INSERT INTO code VALUES (5, 'five'), (NULL, 'six');
SELECT rowid, k, v FROM code ORDER BY rowid;
