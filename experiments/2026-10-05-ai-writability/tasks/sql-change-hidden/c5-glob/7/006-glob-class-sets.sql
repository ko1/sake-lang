SELECT 'e' GLOB '[aeiou]', 'E' GLOB '[aeiou]', 'y' GLOB '[aeiou]', '' GLOB '[aeiou]';
SELECT 'grey' GLOB 'gr[ae]y', 'gray' GLOB 'gr[ae]y', 'groy' GLOB 'gr[ae]y', 'greay' GLOB 'gr[ae]y';
SELECT '?' GLOB '[?]', 'q' GLOB '[?]', 'a?' GLOB 'a[?]', 'what?' GLOB '*[?]', 'what' GLOB '*[?]';
SELECT '[x' GLOB '[[]x', 'x' GLOB '[[]x', ']]' GLOB '[]][]]', '-' GLOB '[-]', '+' GLOB '[-+]', '-' GLOB '[+-]';
CREATE TABLE notes (id INTEGER PRIMARY KEY, body TEXT);
INSERT INTO notes (body) VALUES ('*important*'), ('normal'), ('[draft] plan'), ('ok?');
SELECT id FROM notes WHERE body GLOB '[*]*' ORDER BY id;
SELECT id FROM notes WHERE body GLOB '[[]*]*' ORDER BY id;
