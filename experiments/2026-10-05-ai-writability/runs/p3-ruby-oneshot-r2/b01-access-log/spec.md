# Access log summary

Read a web server access log from standard input and print a per-endpoint summary.

## Input

Each line is one request with six fields separated by one or more spaces:

```
TIMESTAMP METHOD PATH STATUS BYTES DURATION
```

- `TIMESTAMP`: `YYYY-MM-DDTHH:MM:SS` (digits exactly as shown), month 01-12, day 01-31, hour 00-23,
  minute and second 00-59.
- `METHOD`: one of `GET`, `POST`, `PUT`, `DELETE`.
- `PATH`: starts with `/`. Anything from the first `?` on is a query string and is ignored for grouping.
- `STATUS`: exactly three digits, 100-599.
- `BYTES`: a non-negative integer (digits only), or `-` for unknown (counts as nothing).
- `DURATION`: milliseconds, a non-negative integer (digits only).

Lines that are empty or contain only spaces are skipped silently. Any other line that breaks a rule
is invalid. Its reason is the first failing check in this order: `wrong field count`, `bad timestamp`,
`bad method`, `bad path`, `bad status`, `bad bytes`, `bad duration`. Line numbers count every input
line, starting at 1. There are at most 10,000 lines.

## Output

An endpoint is the method, one space, and the path without its query string. If there is at least
one valid request, print a header and one row per endpoint:

```
format("%-Ws %5s %4s %4s %8s %7s %6s", "endpoint", "count", "4xx", "5xx", "bytes", "avg_ms", "max_ms")
format("%-Ws %5d %4d %4d %8d %7s %6d", endpoint, count, n4xx, n5xx, bytes, avg, max)
```

(printf-style; `W` is the length of the longest endpoint, but at least 8.) `n4xx` counts statuses
400-499 and `n5xx` 500-599. `bytes` is the sum of known byte counts. `avg` is the mean duration with
exactly one decimal, rounded half up (for example `16.5`, `358.3`, `2.0`). Rows are sorted by count,
highest first, then by endpoint in byte order.

Then print `busiest hour: YYYY-MM-DD HH:00 (N requests)` for the date-and-hour with the most valid
requests; on a tie, the earliest.

If there are no valid requests, print `no valid requests` instead of the table and busiest hour.

Finally print `invalid lines: N` and, for each invalid line in input order, `  line K: REASON`.

## Example 1

Input:

```
2026-03-01T10:00:00 GET /api/users 200 512 30
2026-03-01T10:05:12 GET /api/users?page=2 200 488 45
2026-03-01T10:20:00 POST /api/login 401 64 12
2026-03-01T11:01:00 GET /api/users 503 - 1000
2026-03-01T11:02:00 POST /api/login 200 128 21
```

Output:

```
endpoint        count  4xx  5xx    bytes  avg_ms max_ms
GET /api/users      3    0    1     1000   358.3   1000
POST /api/login     2    1    0      192    16.5     21
busiest hour: 2026-03-01 10:00 (3 requests)
invalid lines: 0
```

## Example 2

Input:

```
2026-03-01T09:59:59 GET /health 200 2 1

2026-03-01T24:00:00 GET /health 200 2 1
2026-03-01T10:00:00 FETCH /health 200 2 1
2026-03-01T10:00:00 GET health 200 2 1
2026-03-01T10:00:00 GET /health 200 2
2026-03-01T10:00:00 GET /health 99 2 1
2026-03-01T10:00:00 GET /health 200 2 -1
```

Output:

```
endpoint    count  4xx  5xx    bytes  avg_ms max_ms
GET /health     1    0    0        2     1.0      1
busiest hour: 2026-03-01 09:00 (1 requests)
invalid lines: 6
  line 3: bad timestamp
  line 4: bad method
  line 5: bad path
  line 6: wrong field count
  line 7: bad status
  line 8: bad duration
```
