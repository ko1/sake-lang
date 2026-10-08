SELECT 'b' GLOB '[abc]', 'd' GLOB '[abc]', 'B' GLOB '[abc]', 'ab' GLOB '[abc]';
SELECT 'cat' GLOB '[bc]at', 'bat' GLOB '[bc]at', 'rat' GLOB '[bc]at', 'cart' GLOB '[bc]at';
-- special characters inside a class stand for themselves
SELECT '*' GLOB '[*]', 'x' GLOB '[*]', 'a*' GLOB 'a[*]', 'ab' GLOB 'a[*]', '[' GLOB '[[]';
SELECT '^' GLOB '[a^]', 'a' GLOB '[a^]', 'b' GLOB '[a^]';
-- a leading ] is a member; a first or last - is the character -
SELECT ']' GLOB '[]a]', 'a' GLOB '[]a]', 'a]' GLOB 'a[]]', '-' GLOB '[a-]', '-' GLOB '[-a]', 'b' GLOB '[-a]';
-- ] outside a class is ordinary
SELECT 'a]' GLOB 'a]', ']' GLOB ']';
CREATE TABLE codes (code TEXT);
INSERT INTO codes VALUES ('A1'), ('B2'), ('C3'), ('a1'), ('X9'), ('B');
SELECT code FROM codes WHERE code GLOB '[ABC]*' ORDER BY code;
SELECT code FROM codes WHERE code GLOB '[aA]1' ORDER BY code;
