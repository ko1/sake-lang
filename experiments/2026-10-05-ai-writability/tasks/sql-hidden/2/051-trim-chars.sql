CREATE TABLE t (raw TEXT, junk TEXT);
INSERT INTO t VALUES ('**a*b**', '*'), ('<<tag>>', '<>'), ('  sp  ', ' '), ('xyxhixyx', 'yx'), ('none', '');
SELECT raw, trim(raw, junk), ltrim(raw, junk), rtrim(raw, junk) FROM t ORDER BY raw;
SELECT '[' || trim(raw) || ']' FROM t WHERE raw LIKE ' %' ORDER BY raw;
SELECT trim(-100, '-'), rtrim(2.50, '0'), ltrim(007, '0'), trim(NULL, 'x'), ltrim('abc', NULL);
SELECT length(rtrim('ab   ')), length(ltrim('   ab')), trim('', 'a') = '';
