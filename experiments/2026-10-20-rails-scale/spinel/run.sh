#!/bin/bash
# The Rails guide's blog (blog_rb, Rails 8.1.3) through roundhouse --target spinel and Spinel:
# transpile, Spinel analysis+codegen (-c), the full build (C compile included), the widen counts,
# then serve the binary and drive it with examples/apps/rails_blog/walk.sh.
# usage: run.sh WORK ROUNDHOUSE SPINEL_DIR [N]
#   WORK        a new directory for the copy of blog_rb and every output (must not exist)
#   ROUNDHOUSE  the roundhouse binary (cargo build --release --bin roundhouse)
#   SPINEL_DIR  a Spinel checkout after `make deps && make` (bin/spinel, bin/spin)
#   N           runs of each timed step (default 2)
# Prints one line per timed run and the walk's diff summary, then DONE. Needs curl, ruby with the
# sqlite3 and bcrypt gems (seeding), and the build prerequisites in roundhouse's docs/guide/spinel.md.
set -eu
work=$1 rh=$2 spdir=$3 n=${4:-2}
here=$(cd "$(dirname "$0")" && pwd)
exp=$(dirname "$here")
[ -e "$work" ] && { echo "run.sh: $work exists" >&2; exit 1; }
mkdir -p "$work"
work=$(cd "$work" && pwd)
export PATH="$spdir/bin:$PATH"
cd "$work"

echo "# $(date -u +%FT%TZ) $(hostname) load=$(cut -d' ' -f1-3 /proc/loadavg) nproc=$(nproc)"
echo "# $("$rh" --version) / $(spinel --version) / $(cc --version | head -1)"

# The link needs -lsqlite3; without libsqlite3-dev, point the linker at the runtime library.
if ! echo 'int main(void){return 0;}' | cc -x c - -lsqlite3 -o /dev/null 2>/dev/null; then
  mkdir -p libshim
  ln -s "$(ls /usr/lib/x86_64-linux-gnu/libsqlite3.so.0 /usr/lib64/libsqlite3.so.0 2>/dev/null | head -1)" libshim/libsqlite3.so
  export LIBRARY_PATH="$work/libshim${LIBRARY_PATH:+:$LIBRARY_PATH}"
  echo "# no libsqlite3.so for the linker: LIBRARY_PATH=$LIBRARY_PATH"
fi

rsync -a --exclude log --exclude tmp --exclude storage "$exp/blog_rb/" blog/
# roundhouse's nested form_with only takes `[parent, Klass.new]`; the guide writes `article.comments.build`.
sed -i 's/form_with model: \[ article, article.comments.build \]/form_with model: [ article, Comment.new ]/' blog/app/views/comments/_form.html.erb
grep -q 'model: \[ article, Comment.new \]' blog/app/views/comments/_form.html.erb || { echo "run.sh: the _form workaround did not apply" >&2; exit 1; }

for i in $(seq "$n"); do
  rm -rf out-spinel
  /usr/bin/time -f "roundhouse run $i: %e s %M KB exit=%x" -o rh.$i.time "$rh" --target spinel blog -o out-spinel > rh.$i.log 2>&1
  cat rh.$i.time
done
grep -h 'warning' rh.1.log | sed 's#.*/blog/#  rh warning: blog/#' || true

cd out-spinel
flags=$(spin flags 2>/dev/null)
[ -n "$flags" ] || { echo "run.sh: spin flags printed nothing" >&2; exit 1; }
echo "$flags" > ../spin-flags.txt
for i in $(seq "$n"); do
  /usr/bin/time -f "spinel -c run $i: %e s %M KB exit=%x" -o ../c.$i.time spinel $flags main.rb -c -o ../blog.c --force --timing > ../c.$i.log 2>&1
  cat ../c.$i.time
  grep -E 'phase=(frontend|analysis|codegen_program|write_c) ' ../c.$i.log | sed 's/^/  /'
done
mkdir -p build/bin
for i in $(seq "$n"); do
  rm -f build/bin/blog
  /usr/bin/time -f "spinel full build run $i: %e s %M KB exit=%x" -o ../full.$i.time spinel $flags main.rb -o build/bin/blog --timing --warn-widen > ../full.$i.log 2>&1
  cat ../full.$i.time
  grep -E 'phase=(analysis|codegen_program|cc_compile|cc_total) ' ../full.$i.log | sed 's/^/  /'
done
[ -x build/bin/blog ] || { echo "run.sh: no binary" >&2; exit 1; }
echo "warn-widen warnings: $(grep -c ': warning: .* widened to untyped' ../full.1.log)"
cd ..

# Widen counts by emitted file: the same tree with the #<SPINEL_SOURCE> markers as plain comments.
cp -a out-spinel out-nomark
rm -rf out-nomark/build
grep -rl --include='*.rb' '#<SPINEL_SOURCE>' out-nomark | xargs -r sed -i 's/^\(\s*\)#<SPINEL_SOURCE>/\1# SOURCE /'
(cd out-nomark && spinel ${flags//out-spinel/out-nomark} main.rb --emit-types -o ../types-nomark.json > ../types-nomark.log 2>&1)
(cd out-spinel && spinel $flags main.rb --emit-types -o ../types-mark.json > ../types-mark.log 2>&1)
ruby "$here/classify.rb" types-nomark.json --files --examples 12 > classify.txt
grep -E '^(app|runtime|spinel|gem|total) ' classify.txt | grep -v -E '^(runtime|spinel) [a-z]' || true
ruby -rjson -e 'd = JSON.parse(File.read(ARGV[0]))["diagnostics"].select { _1["message"].include?("widened") }
  m = d.select { _1["file"].start_with?("blog/") }
  puts "widened, attributed by #<SPINEL_SOURCE> to the blog sources: #{m.size} of #{d.size}"' types-mark.json

echo "lines: transpiled Ruby (out-spinel, *.rb):"
for d in app config db runtime test; do
  printf '  %-8s %8s\n' "$d" "$(find out-spinel/$d -name '*.rb' -print0 2>/dev/null | xargs -0 -r cat | wc -l)"
done
printf '  %-8s %8s\n' "top" "$(cat out-spinel/*.rb | wc -l)"
printf '  %-8s %8s\n' "bcrypt" "$(find ~/.cache/spin/packages/bcrypt-* -name '*.rb' -print0 | xargs -0 cat | wc -l)"
echo "lines: generated C (blog.c): $(wc -l < blog.c) ($(du -h blog.c | cut -f1))"

# Serve and walk, with db/seed.sql's users row fixed (seed_fix.rb).
cd out-spinel
ruby "$here/seed_fix.rb" db/seed.sql ../seed-fixed.sql
rm -f storage/development.sqlite3
ruby -rsqlite3 -e 'SQLite3::Database.new(ARGV[0]).execute_batch(File.read(ARGV[1]))' storage/development.sqlite3 ../seed-fixed.sql
port=$(ruby -rsocket -e 's = TCPServer.new("127.0.0.1", 0); puts s.addr[1]; s.close')
./build/bin/blog -p "$port" -b 127.0.0.1 > ../server.out 2>&1 &
pid=$!
trap 'kill $pid 2>/dev/null; wait $pid 2>/dev/null' EXIT
for i in $(seq 1 100); do curl -s -o /dev/null "http://127.0.0.1:$port/up" && break; sleep 0.1; done
"$exp/../../examples/apps/rails_blog/walk.sh" "http://127.0.0.1:$port" > ../walk.out
kill $pid; wait $pid 2>/dev/null || true
trap - EXIT
cd ..
# Markup-level diff too: normalize.rb drops Rails' development-mode BEGIN/END template comments and
# compares each tag with its attributes sorted and without a void tag's "/".
diff "$exp/blog_rb/run.out" walk.out > walk.diff || true
diff <(ruby "$here/normalize.rb" "$exp/blog_rb/run.out") <(ruby "$here/normalize.rb" walk.out) > walk-normalized.diff || true
echo "walk: $(grep -c '^==' walk.out) requests; statuses differ at $(diff <(grep '^==' "$exp/blog_rb/run.out") <(grep '^==' walk.out) | grep -c '^>') of them; diff lines raw $(grep -c '^[<>]' walk.diff), normalized $(grep -c '^[<>]' walk-normalized.diff)"
echo "# end $(date -u +%FT%TZ) load=$(cut -d" " -f1-3 /proc/loadavg)"
echo DONE
