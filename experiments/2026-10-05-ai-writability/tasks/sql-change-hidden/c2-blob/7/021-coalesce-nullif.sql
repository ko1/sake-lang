SELECT nullif(X'01', X'01'), nullif(X'01', X'02'), nullif(X'31', '1'), nullif(X'31', 1);
SELECT nullif('A', X'41'), typeof(nullif(X'0101', X'01'));
