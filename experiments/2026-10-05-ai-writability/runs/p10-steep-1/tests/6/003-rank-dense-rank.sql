-- rank() is the position of the first peer; dense_rank() counts peer groups
CREATE TABLE score (player TEXT, pts INTEGER);
INSERT INTO score VALUES ('a', 50), ('b', 70), ('c', 50), ('d', 90), ('e', 70), ('f', 50), ('g', 10);
SELECT player, pts, rank() OVER (ORDER BY pts DESC), dense_rank() OVER (ORDER BY pts DESC) FROM score ORDER BY player;
SELECT player, rank() OVER (ORDER BY pts), dense_rank() OVER (ORDER BY pts) FROM score ORDER BY pts, player;
-- without ORDER BY every row is a peer of every other
SELECT player, rank() OVER (), dense_rank() OVER () FROM score ORDER BY player;
