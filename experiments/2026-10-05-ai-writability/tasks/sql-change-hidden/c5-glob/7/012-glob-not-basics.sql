SELECT 'Mar' NOT GLOB 'M*', 'mar' NOT GLOB 'M*', 'mar' NOT GLOB '[a-z]??', 'mar' NOT GLOB '[^a-z]*';
SELECT NOT 'abc' NOT GLOB 'a*', 'q' NOT GLOB 'q' = 0, 'q' NOT GLOB 'r' || '*';
CREATE TABLE emails (addr TEXT);
INSERT INTO emails VALUES ('ann@example.org'), ('bob@test.net'), ('CAROL@Example.org'), ('dave@example.com');
SELECT addr FROM emails WHERE addr NOT GLOB '*@example.*' ORDER BY addr;
SELECT addr FROM emails WHERE addr NOT GLOB '*.org' AND addr NOT GLOB '*.net' ORDER BY addr;
