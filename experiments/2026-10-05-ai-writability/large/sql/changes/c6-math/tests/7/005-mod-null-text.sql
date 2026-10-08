-- a zero divisor, NULL or non-numeric text gives NULL; numeric text is converted
SELECT mod(7, 0), mod(7, 0.0), mod(0, 0), mod(NULL, 2), mod(2, NULL);
SELECT mod('7', 3), mod(' 10 ', '4'), mod('2.5', 1), mod('7x', 3), mod(7, 'abc');
SELECT mod(-6, 3), typeof(mod(-6, 3));
SELECT mod(1);
SELECT MOD(1, 2, 3);
SELECT mod();
