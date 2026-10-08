#!/usr/bin/env python3
"""Lists names in P10 test scripts that are SQLite keywords (the spec says tests avoid them):
column names in CREATE TABLE / ADD COLUMN, aliases after AS, table/view/index names.
    python3 harness/sql_names_check.py DIR...
"""
import re, sys, glob, os
KW = set("""ABORT ACTION ADD AFTER ALL ALTER ALWAYS ANALYZE AND AS ASC ATTACH AUTOINCREMENT BEFORE BEGIN BETWEEN BY
CASCADE CASE CAST CHECK COLLATE COLUMN COMMIT CONFLICT CONSTRAINT CREATE CROSS CURRENT CURRENT_DATE CURRENT_TIME
CURRENT_TIMESTAMP DATABASE DEFAULT DEFERRABLE DEFERRED DELETE DESC DETACH DISTINCT DO DROP EACH ELSE END ESCAPE
EXCEPT EXCLUDE EXCLUSIVE EXISTS EXPLAIN FAIL FILTER FIRST FOLLOWING FOR FOREIGN FROM FULL GENERATED GLOB GROUP
GROUPS HAVING IF IGNORE IMMEDIATE IN INDEX INDEXED INITIALLY INNER INSERT INSTEAD INTERSECT INTO IS ISNULL JOIN
KEY LAST LEFT LIKE LIMIT MATCH MATERIALIZED NATURAL NO NOT NOTHING NOTNULL NULL NULLS OF OFFSET ON OR ORDER
OTHERS OUTER OVER PARTITION PLAN PRAGMA PRECEDING PRIMARY QUERY RAISE RANGE RECURSIVE REFERENCES REGEXP REINDEX
RELEASE RENAME REPLACE RESTRICT RETURNING RIGHT ROLLBACK ROW ROWS SAVEPOINT SELECT SET TABLE TEMP TEMPORARY THEN
TIES TO TRANSACTION TRIGGER UNBOUNDED UNION UNIQUE UPDATE USING VACUUM VALUES VIEW VIRTUAL WHEN WHERE WINDOW WITH
WITHOUT""".split()) | {"INTEGER", "REAL", "TEXT", "WINDOW"}
pats = [r"\b(\w+)\s+(?:INTEGER|REAL|TEXT)\b", r"\bAS\s+(\w+)", r"\b(?:TABLE|VIEW|INDEX|INTO|FROM|JOIN|UPDATE)\s+(\w+)",
        r"\bRENAME\s+(?:COLUMN\s+)?\w+\s+TO\s+(\w+)", r"\bRENAME\s+TO\s+(\w+)"]
bad = 0
for d in sys.argv[1:]:
    for f in sorted(glob.glob(os.path.join(d, "**", "*.sql"), recursive=True)):
        text = re.sub(r"'(?:[^']|'')*'", "''", open(f).read())
        text = re.sub(r"--[^\n]*|/\*.*?\*/", " ", text, flags=re.S)
        found = set()
        for p in pats:
            for m in re.finditer(p, text, re.I):
                w = m.group(1)
                if w.upper() in KW and w.upper() not in ("IF", "NOT", "EXISTS", "SELECT", "VALUES", "WITH", "DEFAULT", "UNIQUE", "PRIMARY", "COLUMN", "TO", "ON", "AS", "CAST", "NULL", "INTEGER", "REAL", "TEXT"):
                    found.add(w)
        if found:
            bad += 1
            print(f, sorted(found))
print("files with keyword names:", bad)
