# The "levenshtein" micro benchmark, in Ruby: the same program as levenshtein.sake.
def levenshtein(s, t)
  a = s.bytes
  b = t.bytes
  m = a.length
  n = b.length
  return n if m == 0
  return m if n == 0
  prev = Array.new(n + 1, 0)
  curr = Array.new(n + 1, 0)
  j = 0
  while j <= n
    prev[j] = j
    j += 1
  end
  i = 1
  while i <= m
    curr[0] = i
    j = 1
    while j <= n
      cost = a[i - 1] == b[j - 1] ? 0 : 1
      del = prev[j] + 1
      ins = curr[j - 1] + 1
      sub = prev[j - 1] + cost
      best = del
      best = ins if ins < best
      best = sub if sub < best
      curr[j] = best
      j += 1
    end
    tmp = prev
    prev = curr
    curr = tmp
    i += 1
  end
  prev[n]
end

args = ARGV
count = args.length
min = -1
times = 0
i = 0
while i < count
  j = 0
  while j < count
    if i != j
      d = levenshtein(args[i], args[j])
      min = d if min == -1 || d < min
      times += 1
    end
    j += 1
  end
  i += 1
end
puts("times: #{times}")
puts("min_distance: #{min}")
