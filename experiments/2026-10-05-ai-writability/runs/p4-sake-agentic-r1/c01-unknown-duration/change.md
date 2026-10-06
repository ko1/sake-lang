# Change request: unknown durations

Some proxies do not report how long a request took. From now on the `DURATION` field may also be
`-`, meaning the duration is unknown.

- A line whose `DURATION` is `-` is valid (if its other fields are) and counts as a request
  everywhere as before: `count`, `4xx`, `5xx`, `bytes` and the busiest hour.
- `avg_ms` is the mean over the endpoint's requests whose duration is known, with the same
  rounding as before; `max_ms` is the largest known duration.
- If none of an endpoint's requests has a known duration, its `avg_ms` and `max_ms` are both
  printed as `-` (right-aligned in their columns like the numbers).
- `DURATION` that is neither `-` nor digits (for example `--` or `-5`) is still `bad duration`.

Everything else stays as in the specification.

## Example 1

Input:

```
2026-03-01T10:00:00 GET /api/users 200 512 30
2026-03-01T10:05:12 GET /api/users?page=2 200 488 -
2026-03-01T10:20:00 POST /api/login 401 64 12
2026-03-01T11:01:00 GET /api/users 503 - 1000
```

Output:

```
endpoint        count  4xx  5xx    bytes  avg_ms max_ms
GET /api/users      3    0    1     1000   515.0   1000
POST /api/login     1    1    0       64    12.0     12
busiest hour: 2026-03-01 10:00 (3 requests)
invalid lines: 0
```

## Example 2

Input:

```
2026-03-01T09:00:00 GET /health 200 2 -
2026-03-01T09:30:00 GET /health 200 2 -
2026-03-01T09:40:00 PUT /data 201 10 7
2026-03-01T09:50:00 PUT /data 201 10 --
```

Output:

```
endpoint    count  4xx  5xx    bytes  avg_ms max_ms
GET /health     2    0    0        4       -      -
PUT /data       1    0    0       10     7.0      7
busiest hour: 2026-03-01 09:00 (3 requests)
invalid lines: 1
  line 4: bad duration
```
