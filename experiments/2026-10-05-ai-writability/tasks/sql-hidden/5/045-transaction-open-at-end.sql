-- a transaction still open at the end of the script is simply left
CREATE TABLE note (txt TEXT);
BEGIN;
INSERT INTO note VALUES ('kept');
COMMIT;
BEGIN TRANSACTION;
INSERT INTO note VALUES ('pending');
SELECT txt FROM note ORDER BY txt;
UPDATE note SET txt = txt || '!';
SELECT txt FROM note ORDER BY txt;
