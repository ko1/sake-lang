-- hex(): uppercase hex of a blob or of a value's text form
SELECT hex(X'0aff'), hex(X''), hex(x'deadbeef');
SELECT hex('abc'), hex(12), hex(-5), hex(1.5);
SELECT hex(NULL), typeof(hex(NULL)), length(hex(NULL));
SELECT hex(CAST('Hi' AS BLOB)), hex(upper('hi')), typeof(hex(X'01'));
SELECT hex();
SELECT hex(X'01', X'02');
CREATE TABLE t (k INTEGER, b BLOB);
INSERT INTO t VALUES (1, X'00'), (2, X'1234'), (3, NULL);
SELECT k, hex(b) FROM t ORDER BY k;
