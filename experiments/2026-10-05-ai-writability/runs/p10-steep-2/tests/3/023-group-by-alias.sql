CREATE TABLE emails (addr TEXT);
INSERT INTO emails VALUES ('a@x.org'), ('b@y.com'), ('c@x.org'), ('d@z.net'), ('e@y.com');
SELECT substr(addr, instr(addr, '@') + 1) AS domain, count(*) FROM emails GROUP BY domain ORDER BY domain;
SELECT length(addr) AS len, count(*) AS n FROM emails GROUP BY len ORDER BY n;
SELECT count(*) AS c FROM emails GROUP BY c;
