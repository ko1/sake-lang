SELECT 1 = 1, 1 == 1, 1 = 2;
SELECT 1 != 2, 1 <> 2, 2 != 2, 2 <> 2;
SELECT 1 < 2, 2 <= 2, 3 > 4, 4 >= 4;
SELECT 1 = 1.0, 2.5 > 2, -1 < 0.5;
SELECT 'abc' < 'abd', 'ab' < 'abc', 'b' > 'abc';
SELECT 1 = NULL, NULL = NULL, NULL <> 1, NULL < 1;
SELECT typeof(1 < 2), typeof(NULL > 1);
SELECT 12 = '12', '12' = 12;
