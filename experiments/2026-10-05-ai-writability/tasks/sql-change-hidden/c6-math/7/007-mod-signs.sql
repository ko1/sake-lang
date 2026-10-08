-- mod keeps the sign of the dividend and always gives a REAL
SELECT mod(20, 6), mod(-20, 6), mod(20, -6), mod(-20, -6), typeof(mod(20, 6));
SELECT mod(9.75, 4), mod(-9.75, 4), mod(1, 0.25), mod(2.5, 10), mod(-12, 4);
SELECT 9.75 % 4, mod(9.75, 4), 20 % 6, mod(20, 6);
