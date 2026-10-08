SELECT '[' || trim('  pad  ') || ']', '[' || ltrim('  pad  ') || ']', '[' || rtrim('  pad  ') || ']';
SELECT trim('xxhixx', 'x'), ltrim('xxhixx', 'x'), rtrim('xxhixx', 'x'), trim('abcXcba', 'abc');
SELECT trim(1200, '0'), ltrim(0.5, '0'), trim('--a-b--', '-'), trim('aaa', 'a') || '|';
SELECT trim(NULL), trim('x', NULL), ltrim('  tab', ' '), '[' || trim('	x ') || ']';
