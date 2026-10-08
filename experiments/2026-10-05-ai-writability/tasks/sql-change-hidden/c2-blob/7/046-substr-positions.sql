SELECT substr(X'0102030405', 2), substr(X'0102030405', 2, 3), substr(X'0102030405', -2);
SELECT substr(X'0102030405', 0, 3), substr(X'0102030405', 4, -2), substr(X'0102030405', 9), substr(X'0102030405', -3, 2);
SELECT typeof(substr(X'0102', 1, 1)), typeof(substr(X'0102', 5)), substr(NULL, 1);
