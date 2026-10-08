;;;
CREATE TABLE t (a INTEGER);
;
INSERT INTO t VALUES (1);
-- comment only
;
INSERT INTO t VALUES (2); ; ;
SELECT a FROM t ORDER BY a DESC;
	;
SELECT 'end';
