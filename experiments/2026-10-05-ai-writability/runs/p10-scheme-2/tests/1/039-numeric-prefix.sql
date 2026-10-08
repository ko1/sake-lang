-- Text read as a number by its numeric prefix.
SELECT '3abc' + 0;
SELECT ' -2.5e1x' + 0;
SELECT '5.' + 0;
SELECT 'abc' + 0;
SELECT '-' + 0;
SELECT '1e' + 0;
SELECT '1e5x' * 1;
SELECT '.5' + 1;
SELECT '+7' - 1;
SELECT '  12  ' * 2;
SELECT '1.5.5' + 0;
SELECT 'e5' + 1;
SELECT '2e+2' + 0, '2e-1z' + 0;
SELECT typeof('4' + 0), typeof('4.0' + 0);
