SELECT hex(X'00'), hex(x'0a0b0c'), hex(X'FFFF');
SELECT hex('A'), hex(' '), hex(0), hex(-12), hex(2.5), hex(1e20);
SELECT hex(NULL) = '', hex(NULL) IS NULL;
SELECT HEX(X'7e');
