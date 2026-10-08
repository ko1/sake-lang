CREATE TABLE plays (song TEXT, listener TEXT);
INSERT INTO plays VALUES ('s1', 'a'), ('s2', 'a'), ('s2', 'b'), ('s3', 'a'), ('s3', 'b'), ('s3', 'c');
SELECT song FROM plays GROUP BY song ORDER BY count(*) DESC;
SELECT song, count(*) FROM plays GROUP BY song ORDER BY count(*), song;
SELECT listener FROM plays GROUP BY listener ORDER BY min(song) DESC, listener;
SELECT count(*) FROM plays ORDER BY count(*);
