SELECT X'10' < X'20', X'10' <= X'10', X'20' >= X'2000', X'AA' <> X'AB', X'AA' == x'aa';
SELECT X'00' > 1000000, X'00' > 'zzzz', X'00' > -1.5, X'' > '';
SELECT 'B' = X'42', 66 = X'42', X'42' != 'B';
SELECT X'80' > X'7FFF', X'0100' > X'01', X'' < X'00';
SELECT NULL = X'00', X'00' <> NULL;
