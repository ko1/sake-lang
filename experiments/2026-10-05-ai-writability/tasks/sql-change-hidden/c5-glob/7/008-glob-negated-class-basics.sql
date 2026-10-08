SELECT 'z' GLOB '[^aeiou]', 'e' GLOB '[^aeiou]', 'E' GLOB '[^aeiou]', '' GLOB '[^aeiou]';
SELECT 'x5' GLOB 'x[^0-9]', 'xy' GLOB 'x[^0-9]', 'x' GLOB 'x[^0-9]', 'xyz' GLOB 'x[^0-9]';
SELECT ']' GLOB '[^]]', 'a' GLOB '[^]]', '-' GLOB '[^-]', 'b' GLOB '[^a-]', '-' GLOB '[^a-]', '^' GLOB '[^^]', 'v' GLOB '[^^]';
