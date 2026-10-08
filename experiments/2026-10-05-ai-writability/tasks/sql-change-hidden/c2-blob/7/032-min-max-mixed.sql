SELECT max(x), min(x), count(x) FROM (SELECT 'zzz' AS x UNION ALL SELECT X'01' UNION ALL SELECT 1000 UNION ALL SELECT NULL);
SELECT max(X'00', 'zz'), min(X'00', 'zz'), max(X'01', X'0100'), min(X'02', 5, 'a');
SELECT max(X'01', NULL), min(X'', X'00');
