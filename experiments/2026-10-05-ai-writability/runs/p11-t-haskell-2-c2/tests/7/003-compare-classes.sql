-- blobs sort after numbers and text; compared bytewise
SELECT X'41' = X'41', X'41' = 'A', X'41' != 'A', X'41' > 'zz';
SELECT 99 < X'00', 1.5 < X'', 'zzz' < X'', NULL < X'00';
SELECT X'01' < X'0100', X'0001' < X'01', X'7F' < X'80', X'FF' > X'00FF';
SELECT X'' = X'', X'AB' = x'ab', X'41' IS X'41', X'41' IS 'A', X'' IS NULL;
SELECT X'05' BETWEEN X'01' AND X'09', X'05' BETWEEN 1 AND 'z', 5 BETWEEN 1 AND X'00';
CREATE TABLE t (i INTEGER, s TEXT);
INSERT INTO t VALUES (12, 'A');
SELECT i = X'3132', s = X'41', i < X'00', s < X'00' FROM t;
