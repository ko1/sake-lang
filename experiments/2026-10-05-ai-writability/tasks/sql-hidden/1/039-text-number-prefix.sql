SELECT '42abc' + 0, '  9 lives' + 0, '-12x' * 1;
SELECT '3.25kg' + 0, '.75' * 4, '7.' + 0;
SELECT '1e2' + 0, '1e2x' + 0, '1ex' + 0, '1e+' + 0, '1E-1' + 0;
SELECT 'x5' + 0, '' + 0, ' ' + 0, '+' + 0, '.' + 0;
SELECT '+.5' + 0, '-.5e1' + 0;
SELECT '00042' + 0;
SELECT typeof('12' + 0), typeof('12.' + 0), typeof('12e0' + 0), typeof('nope' + 0);
SELECT '10' + '20', '10' || '20';
