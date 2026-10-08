SELECT replace('banana', 'an', 'AN'), replace('aaaa', 'aa', 'b'), replace('abc', '', 'x'), replace('abc', 'z', 'y');
SELECT replace(1000, 0, 9), replace(2.5, '.', ','), typeof(replace(10, 1, 2)), replace('a-b-c', '-', '');
SELECT replace(NULL, 'a', 'b'), replace('a', NULL, 'b'), replace('a', 'a', NULL);
SELECT instr('banana', 'na'), instr('banana', 'x'), instr('banana', 'B'), instr(31415, 14), instr('abc', '');
SELECT instr(NULL, 'a'), instr('a', NULL), instr(2.5, '.'), instr('aaa', 'aa');
