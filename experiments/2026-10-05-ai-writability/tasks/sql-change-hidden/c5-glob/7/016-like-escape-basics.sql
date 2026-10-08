SELECT '50%' LIKE '50\%' ESCAPE '\', '500' LIKE '50\%' ESCAPE '\', '500' LIKE '50%' ESCAPE '\';
SELECT 'x_1' LIKE 'x\_1' ESCAPE '\', 'xy1' LIKE 'x\_1' ESCAPE '\', 'X_1' LIKE 'x\_%' ESCAPE '\';
SELECT 'a+b' LIKE 'a#+b' ESCAPE '#', 'A+B' LIKE 'a#+b' ESCAPE '#', 'a#b' LIKE 'a##b' ESCAPE '#', 'a#b' LIKE 'a#b' ESCAPE '#';
SELECT 'abc' LIKE 'a' || '%' ESCAPE '\', 'a%' LIKE 'a' || '\%' ESCAPE '\', 'ax' LIKE 'a' || '\%' ESCAPE '\';
SELECT 'x' LIKE 'x' ESCAPE '/' = 1, 'x' NOT LIKE 'y' ESCAPE '/' = 1;
