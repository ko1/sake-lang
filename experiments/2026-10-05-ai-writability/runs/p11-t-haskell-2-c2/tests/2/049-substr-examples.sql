SELECT substr('hello', 2), substr('hello', 0, 2), substr('hello', -3, 2), substr('hello', 2, -1), substr(12345, 2, 2);
SELECT substr('hello', 1, 3), substr('hello', 5), substr('hello', 6), substr('hello', 3, 0), substr('hello', 1, 100);
SELECT substr(NULL, 1), substr('abc', NULL), substr('abc', 1, NULL), typeof(substr(123, 1));
SELECT substr(1.25, 3), substr('hello', 0), substr('hello', 0, 1);
