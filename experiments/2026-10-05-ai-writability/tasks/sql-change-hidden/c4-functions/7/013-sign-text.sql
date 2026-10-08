-- sign of TEXT: numeric literal after trimming, else NULL
SELECT sign('  77'), sign('-.5'), sign('5.'), sign('-0');
SELECT sign('7 apples'), sign('x7'), sign('--1');
SELECT sign('3e2'), sign('-2E-3');
SELECT typeof(sign('9')), typeof(sign('nine'));
SELECT sign('4x') IS NULL, -'4x';
