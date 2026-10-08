-- network packets: header byte, payload, per-source ranking
CREATE TABLE pkts (seq INTEGER PRIMARY KEY, src TEXT, raw BLOB);
INSERT INTO pkts (src, raw) VALUES ('n1', X'0148692121'), ('n2', X'02414243'), ('n1', X'0161'), ('n2', X'01'), ('n1', X'02FFFF00');
WITH parsed AS (SELECT seq, src, substr(raw, 1, 1) AS hdr, substr(raw, 2) AS body FROM pkts)
SELECT seq, hex(hdr), length(body), CASE hdr WHEN X'01' THEN 'data' WHEN X'02' THEN 'ctl' END FROM parsed ORDER BY seq;
SELECT src, count(*), max(raw), min(length(raw)) FROM pkts GROUP BY src ORDER BY src;
SELECT seq, src, rank() OVER (PARTITION BY src ORDER BY length(raw) DESC, seq) FROM pkts ORDER BY seq;
SELECT seq FROM pkts WHERE substr(raw, 1, 1) IN (SELECT X'02') ORDER BY seq;
CREATE VIEW big AS SELECT seq, raw FROM pkts WHERE length(raw) >= 4;
SELECT seq, raw FROM big ORDER BY raw DESC;
SELECT raw FROM pkts WHERE seq = 2 UNION SELECT CAST('ABC' AS BLOB) UNION SELECT X'02414243' ORDER BY 1;
