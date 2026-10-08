SELECT instr(X'0102030102', X'0102'), instr(X'0102030102', X'0301'), instr(X'0102', X'03'), instr(X'01', X'0102');
SELECT instr(X'00FF00', X'FF'), instr(X'0A', NULL), instr(NULL, X'0A');
