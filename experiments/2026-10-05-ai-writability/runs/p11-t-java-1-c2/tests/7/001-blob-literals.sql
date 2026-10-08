-- blob literals and how a blob prints
SELECT X'4142', x'0aff', X'';
SELECT X'00', x'DeadBeef', X'7f80';
SELECT X'010203' AS b, 'X''01''' AS t;
SELECT X'414';
SELECT X'4G';
SELECT 1, x'ABC';
SELECT X'41 42';
SELECT X'CAFE';
