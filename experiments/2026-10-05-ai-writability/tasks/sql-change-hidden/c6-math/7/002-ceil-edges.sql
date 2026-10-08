-- negative values, negative zero, and argument count
SELECT ceil(-2.0001), ceil(-0.25), ceil(-0.25) || '', ceil(2.0e3), typeof(ceil(2.0e3));
SELECT ceil('+8'), ceil('5.'), ceil('1e'), ceil('0x10'), ceil(1 / 2), ceil(1.0 / 2);
SELECT ceiling(4.4, 1);
SELECT CeIl();
