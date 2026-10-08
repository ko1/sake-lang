-- unicode: code point of the first character
SELECT unicode('A'), unicode('apple'), unicode(' z');
SELECT unicode(''), unicode(NULL);
SELECT typeof(unicode('q')), typeof(unicode(''));
SELECT unicode(9), unicode(-12), unicode(3.25);
SELECT UNICODE('~'), Unicode('0');
