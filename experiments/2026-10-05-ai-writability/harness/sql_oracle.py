#!/usr/bin/env python3
"""Expected output of a SQL test script (P10), computed with SQLite as SPEC.md defines it.

    python3 harness/sql_oracle.py FILE.sql...        prints FILE's expected output (one file only)
    python3 harness/sql_oracle.py --write FILE.sql... writes FILE.out next to each; exits 1 if any
                                                     test was rejected (reasons on stderr)

SPEC.md (large/sql/spec/) is the definition; SQLite only computes it. Where they differ, this script
either makes SQLite follow the spec or rejects the test:
  - every CREATE TABLE gets STRICT (the spec's typing rules are those of STRICT tables);
  - round() is replaced by the spec's definition (SQLite's own rounds via a 16-17 digit decimal form);
  - a REAL is printed by the spec's rule (%.15g plus ".0"); a value where SQLite's own text differs
    rejects the test (about 1 in 10,000 random doubles);
  - a BLOB (P11 change c2) prints as X'<uppercase hex>';
  - an error whose message is not in the spec's catalogue rejects the test;
  - a test whose output changes under PRAGMA reverse_unordered_selects (the order is not fixed by the
    spec: a missing ORDER BY, ties, group_concat order, bare columns) is rejected.
"""
import re
import sqlite3
import sys
from decimal import Decimal, ROUND_HALF_UP


class Reject(Exception):
    pass


def split_statements(text):
    """Statements ended by ';' (outside quotes and comments). Returns (statements, trailing text)."""
    stmts, buf, i, n = [], [], 0, len(text)
    while i < n:
        ch = text[i]
        if ch in "'\"":
            j = i + 1
            while j < n:
                if text[j] == ch:
                    if j + 1 < n and text[j + 1] == ch:
                        j += 2
                        continue
                    break
                j += 1
            buf.append(text[i:j + 1])
            i = j + 1
        elif text.startswith("--", i):
            j = text.find("\n", i)
            j = n if j < 0 else j
            buf.append(text[i:j])
            i = j
        elif text.startswith("/*", i):
            j = text.find("*/", i + 2)
            j = n if j < 0 else j + 2
            buf.append(text[i:j])
            i = j
        elif ch == ";":
            stmts.append("".join(buf) + ";")
            buf = []
            i += 1
        else:
            buf.append(ch)
            i += 1
    return stmts, "".join(buf)


def strip_comments(s):
    # one pass, so whichever comment starts first wins ("/* -- */" is one block comment)
    return re.sub(r"--[^\n]*|/\*.*?(?:\*/|\Z)", " ", s, flags=re.S)


CREATE_TABLE = re.compile(r"\A\s*create\s+table\b", re.I)


def adapt(stmt):
    if CREATE_TABLE.match(strip_comments(stmt)):
        body = stmt.rstrip()[:-1].rstrip()          # without ';'
        if body.endswith(")"):
            return body + " STRICT;"
    return stmt


def spec_round(x, n=0):
    """SPEC 'round': half away from zero on the value's %.17g decimal form; n < 0 counts as 0."""
    if x is None or n is None:
        return None
    if isinstance(x, str) or isinstance(x, bytes):
        x = text_to_number(x)
    x = float(x)
    n = max(int(n), 0) if not isinstance(n, str) else max(int(text_to_number(n)), 0)
    if x != x or x in (float("inf"), float("-inf")):
        return x
    q = Decimal("%.17g" % x).quantize(Decimal(1).scaleb(-n), rounding=ROUND_HALF_UP)
    return float(q)


NUM_PREFIX = re.compile(r"\s*([+-]?(\d+\.?\d*|\.\d+)([eE][+-]?\d+)?)")


def text_to_number(s):
    m = NUM_PREFIX.match(s)
    if not m:
        return 0
    t = m.group(1)
    if re.fullmatch(r"[+-]?\d+", t):
        return int(t)
    return float(t)


def fmt_real(x):
    if x != x:
        return "NaN"
    if x == float("inf"):
        return "Inf"
    if x == float("-inf"):
        return "-Inf"
    if x == 0:
        return "0.0"
    s = "%.15g" % x
    if "e" in s:
        m, e = s.split("e")
        return (m if "." in m else m + ".0") + "e" + e
    return s if "." in s else s + ".0"


def fmt_value(v, conn):
    if v is None:
        return "NULL"
    if isinstance(v, bool):
        return str(int(v))
    if isinstance(v, int):
        return str(v)
    if isinstance(v, float):
        mine = fmt_real(v)
        theirs = conn.execute("select cast(? as text)", (v,)).fetchone()[0]
        if v == v and abs(v) != float("inf") and mine != theirs:
            raise Reject("REAL %r prints as %s by the spec but %s in SQLite" % (v, mine, theirs))
        return mine
    if isinstance(v, bytes):  # P11 change c2: X'<uppercase hex>'
        return "X'" + v.hex().upper() + "'"
    return v


# The spec's error catalogue (SPEC.md "Errors"): messages SQLite prints as the spec defines them.
CATALOGUE = [
    # stage 1
    r"no such table: .+", r"no such column: .+", r"table .+ already exists", r"duplicate column name: .+",
    r"table .+ has no column named .+", r"cannot store (INTEGER|REAL|TEXT) value in (INTEGER|REAL|TEXT) column .+",
    r"table .+ has \d+ columns but \d+ values were supplied", r"\d+ values for \d+ columns",
    r"no such function: .+", r"wrong number of arguments to function .+\(\)",
    r"\d+(st|nd|rd|th) ORDER BY term out of range - should be between 1 and \d+", r"no tables specified",
    r"all VALUES must have the same number of terms",
    # stage 2
    r"(NOT NULL|UNIQUE) constraint failed: .+", r"datatype mismatch",
    # stage 3
    r"misuse of aggregate function .+\(\)", r"misuse of aggregate: .+\(\)", r"aggregate functions are not allowed in the GROUP BY clause",
    r"HAVING clause on a non-aggregate query", r"DISTINCT aggregates must have exactly one argument",
    r"\d+(st|nd|rd|th) GROUP BY term out of range - should be between 1 and \d+", r"integer overflow",
    # stage 4
    r"ambiguous column name: .+", r"sub-select returns \d+ columns - expected 1", r"row value misused",
    r"cannot join using column .+ - column not present in both tables",
    # stage 5
    r"SELECTs to the left and right of (UNION|UNION ALL|INTERSECT|EXCEPT) do not have the same number of result columns",
    r"\d+(st|nd|rd|th) ORDER BY term does not match any column in the result set",
    r"duplicate WITH table name: .+", r"view .+ already exists", r"cannot modify .+ because it is a view",
    r"use DROP VIEW to delete view .+", r"use DROP TABLE to delete table .+", r"no such view: .+",
    r"cannot start a transaction within a transaction", r"cannot commit - no transaction is active",
    r"cannot rollback - no transaction is active", r"Cannot add a NOT NULL column with default value NULL",
    r"Cannot add a UNIQUE column", r"Cannot add a PRIMARY KEY column",
    r"there is already another table or index with this name: .+", r"index .+ already exists",
    r"there is already a table named .+", r"there is already an index named .+", r"no such index: .+",
    # stage 6
    r"misuse of window function .+\(\)", r"no such window: .+",
    r"RANGE with offset PRECEDING/FOLLOWING requires one ORDER BY expression",
    r"frame starting offset must be a non-negative integer", r"frame ending offset must be a non-negative integer",
    r"argument of ntile must be a positive integer", r"misuse of aliased window function .+",
    r"unsupported frame specification", r"frame (starting|ending) offset must be a non-negative number",
    r"second argument to nth_value must be a positive integer"]
# P11 changes: each change's extra messages, one regular expression per line, in
# large/sql/changes/<change>/catalogue.txt.
import glob as _glob, os as _os
for _f in sorted(_glob.glob(_os.path.join(_os.path.dirname(_os.path.abspath(__file__)), "..", "large", "sql", "changes", "*", "catalogue.txt"))):
    CATALOGUE += [l.rstrip("\n") for l in open(_f) if l.strip() and not l.startswith("#")]
CATALOGUE_RE = re.compile(r"\A(" + "|".join(CATALOGUE) + r")\Z")


def error_message(e):
    msg = str(e)
    if "syntax error" in msg or msg in ("incomplete input",) or msg.startswith("unrecognized token"):
        return "syntax error"
    if not CATALOGUE_RE.match(msg):
        raise Reject("error not in the spec's catalogue: %s" % msg)
    return msg


def run(text, reverse):
    conn = sqlite3.connect(":memory:", isolation_level=None)
    conn.create_function("round", 1, spec_round, deterministic=True)
    conn.create_function("round", 2, spec_round, deterministic=True)
    if reverse:
        conn.execute("PRAGMA reverse_unordered_selects=1")
    stmts, rest = split_statements(text)
    if strip_comments(rest).strip():
        raise Reject("text after the last ';'")
    out = []
    for stmt in stmts:
        if not strip_comments(stmt).strip().rstrip(";").strip():
            continue
        try:
            rows = conn.execute(adapt(stmt)).fetchall()
        except sqlite3.Error as e:
            out.append("Error: " + error_message(e) + "\n")
            continue
        except OverflowError as e:
            raise Reject("python overflow: %s" % e)
        for row in rows:
            out.append("|".join(fmt_value(v, conn) for v in row) + "\n")
    return "".join(out)


def expected(path):
    text = open(path, encoding="utf-8").read()
    a = run(text, False)
    b = run(text, True)
    if a != b:
        raise Reject("output depends on row order the spec leaves open (PRAGMA reverse_unordered_selects)")
    return a


def main(argv):
    write = argv[:1] == ["--write"]
    paths = argv[1:] if write else argv
    if not paths or (not write and len(paths) != 1):
        sys.exit(__doc__)
    bad = 0
    for path in paths:
        try:
            out = expected(path)
        except Reject as e:
            bad += 1
            print("REJECT %s: %s" % (path, e), file=sys.stderr)
            continue
        if write:
            with open(re.sub(r"\.sql\Z", ".out", path), "w", encoding="utf-8") as f:
                f.write(out)
        else:
            sys.stdout.write(out)
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main(sys.argv[1:])
