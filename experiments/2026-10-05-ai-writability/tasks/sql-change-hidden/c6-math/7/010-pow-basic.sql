-- power and pow give a REAL
SELECT pow(3, 4), power(3, 4), typeof(power(3, 4)), pow(-3, 3), pow(-3, 4);
SELECT pow(4, 0.5), pow(8, -1), pow(100, 1.5), pow(2.5, 2), pow(0, 3), pow(7, 0);
SELECT pow(-27, 0.5), power(-1, 0.25), pow(NULL, 0), power(0, NULL);
