-- END is COMMIT; a transaction still open at the end of the script prints nothing
CREATE TABLE log (msg TEXT);
BEGIN;
INSERT INTO log VALUES ('first');
END;
ROLLBACK;
SELECT msg FROM log;
BEGIN;
INSERT INTO log VALUES ('second');
END TRANSACTION;
SELECT msg FROM log ORDER BY msg;
BEGIN;
INSERT INTO log VALUES ('third');
SELECT count(*) FROM log;
