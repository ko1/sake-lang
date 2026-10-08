-- sign of numbers is INTEGER -1, 0 or 1
SELECT sign(42), sign(-42), sign(0);
SELECT sign(3.75), sign(-0.001), sign(0.0);
SELECT typeof(sign(2.5)), typeof(sign(-9));
SELECT sign(NULL), typeof(sign(NULL));
SELECT sign(5 - 8), sign(2 * 0), sign(7 / 2.0);
SELECT sign();
SELECT sign(1, 2);
