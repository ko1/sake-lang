-- Explicit left, explicit right, then the left column, then the right column, else BINARY.
CREATE TABLE pairs (id INTEGER, ci TEXT COLLATE NOCASE, cs TEXT, ct TEXT COLLATE RTRIM);
INSERT INTO pairs VALUES (1, 'Pen', 'pen', 'pen '), (2, 'ink', 'INK', 'Ink'), (3, 'cap', 'cap ', 'CAP');
SELECT id, ci = cs, cs = ci, ci = ct, ct = ci, cs = ct, ct = cs FROM pairs ORDER BY id;
SELECT id, cs = ci COLLATE RTRIM, ci COLLATE RTRIM = cs, cs COLLATE NOCASE = ct COLLATE BINARY FROM pairs ORDER BY id;
SELECT 'Pen' = 'pen', 'Pen' = 'pen ' COLLATE RTRIM, 'pen ' COLLATE BINARY = 'pen' COLLATE RTRIM;
