CREATE TABLE docs (id INTEGER, body TEXT);
INSERT INTO docs VALUES (1, 'the cat sat'), (2, 'catalog of cats'), (3, 'dog'), (4, NULL);
SELECT id, instr(body, 'cat'), instr(body, 'at') FROM docs ORDER BY id;
UPDATE docs SET body = replace(body, 'cat', 'bird') WHERE instr(body, 'cat') > 0;
SELECT id, body FROM docs ORDER BY id;
SELECT replace('xxx', 'x', 'xx'), replace('ababab', 'aba', '-'), replace(3.5, 5, 0), instr('AbC', 'c');
SELECT replace('abc', 'abc', ''), instr('', 'a'), instr(100, 0), typeof(instr(1, 1));
