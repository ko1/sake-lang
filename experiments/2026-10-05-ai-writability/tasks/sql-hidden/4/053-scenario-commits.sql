-- A version history: commits point to their parent commit and author.
CREATE TABLE devs (dev TEXT PRIMARY KEY, team TEXT);
CREATE TABLE commits (id INTEGER PRIMARY KEY, parent INTEGER, dev TEXT, msg TEXT, added INTEGER, removed INTEGER);
INSERT INTO devs VALUES ('ko', 'core'), ('mi', 'core'), ('ta', 'docs'), ('yu', 'web');
INSERT INTO commits VALUES (1, NULL, 'ko', 'init', 100, 0), (2, 1, 'mi', 'parser', 40, 5), (3, 2, 'ko', 'fix', 2, 2),
  (4, 2, 'ta', 'docs', 30, 0), (5, 3, 'mi', 'speed', 10, 20), (6, 5, 'ko', 'revert', 20, 10);
INSERT INTO commits VALUES (6, 4, 'yu', 'dup', 1, 1);
-- each commit with its parent's message
SELECT c.id, c.msg, p.msg FROM commits c LEFT JOIN commits p ON p.id = c.parent ORDER BY c.id;
-- commits with more than one child (branch points)
SELECT id, msg FROM commits c WHERE (SELECT count(*) FROM commits k WHERE k.parent = c.id) > 1;
-- leaf commits
SELECT id FROM commits c WHERE NOT EXISTS (SELECT 1 FROM commits k WHERE k.parent = c.id) ORDER BY id;
-- grandparents
SELECT c.id, g.id FROM commits c JOIN commits p ON p.id = c.parent JOIN commits g ON g.id = p.parent ORDER BY c.id;
-- net lines per team, all teams
SELECT team, coalesce(sum(added - removed), 0) FROM devs LEFT JOIN commits USING (dev) GROUP BY team ORDER BY team;
-- commits whose author differs from the parent's author's team
SELECT c.id FROM commits c JOIN commits p ON p.id = c.parent JOIN devs dc ON dc.dev = c.dev JOIN devs dp ON dp.dev = p.dev
  WHERE dc.team <> dp.team ORDER BY c.id;
-- the biggest commit of each developer
SELECT dev, (SELECT msg FROM commits WHERE commits.dev = devs.dev ORDER BY added + removed DESC LIMIT 1) FROM devs ORDER BY dev;
-- developers with no commits
SELECT dev FROM devs WHERE dev NOT IN (SELECT dev FROM commits) ORDER BY dev;
DELETE FROM commits WHERE id IN (SELECT c.id FROM commits c WHERE c.dev = 'ta');
SELECT count(*), sum(added) FROM commits;
SELECT msg FROM commits JOIN devs USING (dev) WHERE team = 'core' AND id > 4 ORDER BY id;
SELECT c.msg FROM commits c JOIN commits p ON p.id = c.parent WHERE p.dev = 'ko' ORDER BY c.id;
SELECT id FROM commits JOIN devs USING (team);
INSERT INTO commits (parent, dev, msg, added, removed) VALUES ((SELECT max(id) FROM commits), 'yu', 'ui', 15, 0);
SELECT c.id, p.msg, team FROM commits c JOIN commits p ON p.id = c.parent JOIN devs d ON d.dev = c.dev WHERE c.id = 7;
