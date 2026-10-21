#!/bin/bash
# Walks the blog with curl: walk.sh http://127.0.0.1:PORT
# Prints each response's status, the headers that matter and the body, with what changes per run replaced
# (CSRF tokens, the host's port). Run against the Sake blog and the Ruby twin; diff the two outputs.
base=$1
jar=$(mktemp)
trap 'rm -f "$jar"' EXIT
token=""

show() { # method path [curl args...]
  local method=$1 path=$2; shift 2
  local out hdr
  out=$(mktemp); hdr=$(mktemp)
  curl -s -o "$out" -D "$hdr" -b "$jar" -c "$jar" -X "$method" "$@" "$base$path"
  local status ctype loc
  status=$(head -1 "$hdr" | tr -d '\r' | cut -d' ' -f2)
  ctype=$(grep -i '^content-type:' "$hdr" | tr -d '\r' | cut -d' ' -f2-)
  loc=$(grep -i '^location:' "$hdr" | tr -d '\r' | cut -d' ' -f2- | sed "s#$base#http://HOST#")
  echo "== $method $path -> $status"
  [ -n "$ctype" ] && echo "  content-type: $ctype"
  [ -n "$loc" ] && echo "  location: $loc"
  if [ "$status" -lt 400 ] || [ "$status" = 422 ]; then
    t=$(grep -o 'name="csrf-token" content="[^"]*"' "$out" | head -1 | sed 's/.*content="//; s/"$//')
    [ -n "$t" ] && token=$t
    sed -E 's/(name="csrf-token" content=|name="authenticity_token" value=)"[^"]*"/\1"TOKEN"/g' "$out" | sed 's/^/  | /'
  else
    # error pages differ (Rails' development page vs. a short one): only their title line
    grep -o '<title>[^<]*</title>' "$out" | head -1 | sed 's/^/  | /'
    [ -n "$WALK_DEBUG" ] && sed 's/<[^>]*>//g' "$out" | grep -v '^\s*$' | head -${WALK_DEBUG_LINES:-8} | sed 's/^/  ! /'
  fi
  echo
  rm -f "$out" "$hdr"
}
form() { echo "--data-urlencode authenticity_token=$token"; }

show GET /
show GET /up
show GET /articles/new
show GET /session/new
show POST /session $(form) --data-urlencode email_address=one@example.com --data-urlencode password=wrong
show GET /session/new
show POST /session $(form) --data-urlencode email_address=one@example.com --data-urlencode password=password
show GET /articles/new
show POST /articles $(form) --data-urlencode "article[title]=Hello Rails" --data-urlencode "article[body]=short"
show POST /articles $(form) --data-urlencode "article[title]=Hello Rails" --data-urlencode "article[body]=I am on Rails & Sake!"
show GET /articles/1
show GET /articles/1/edit
show PATCH /articles/1 $(form) --data-urlencode "article[title]=" --data-urlencode "article[body]=I am on Rails & Sake!"
show POST /articles/1 $(form) --data-urlencode _method=patch --data-urlencode "article[title]=Hello again" --data-urlencode "article[body]=I am on Rails & Sake!"
show GET /articles/1
show POST /articles/1/comments $(form) --data-urlencode "comment[commenter]=matz" --data-urlencode "comment[body]=<b>nice</b>"
show POST /articles/1/comments $(form) --data-urlencode "comment[commenter]=ko1" --data-urlencode "comment[body]=thanks"
show GET /articles/1
show POST /articles/1/comments/1 $(form) --data-urlencode _method=delete
show GET /articles/1
show GET /articles
show DELETE /session $(form)
show GET /
show DELETE /articles/1 $(form)
show GET /articles/999
show GET /nope
