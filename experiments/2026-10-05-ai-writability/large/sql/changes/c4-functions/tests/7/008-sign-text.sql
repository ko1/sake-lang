-- sign of TEXT: only text that is a numeric literal after trimming; otherwise NULL
SELECT sign('12'), sign('-3'), sign('0');
SELECT sign(' 2.5 '), sign('-1e2'), sign('+4');
SELECT sign('12abc'), sign('abc'), sign('');
SELECT sign('1e'), sign('-');
CREATE TABLE readings (id INTEGER, raw TEXT);
INSERT INTO readings VALUES (1, '15'), (2, '-0.5'), (3, 'n/a'), (4, NULL), (5, '0.0');
SELECT id, sign(raw) FROM readings ORDER BY id;
SELECT count(*) FROM readings WHERE sign(raw) IS NULL;
