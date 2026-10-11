require "pstore"
require "tmpdir"

Dir.mktmpdir do |dir|
  path = File.join(dir, "data.pstore")
  store = PStore.new(path)
  p(store.path == path)
  p(File.exist?(path))

  # a read-only transaction on a missing file sees an empty table and creates nothing
  p(store.transaction(true) { |s| s.keys })
  p(File.exist?(path))

  # write, then read back in a new transaction; the block's value is the transaction's value
  r = store.transaction do |s|
    s["name"] = "sake"
    s["list"] = [1, 2.5, nil, true]
    s["hash"] = {"a" => {"b" => [1]}}
    s[42] = "int key"
    :done
  end
  p(r)
  p(File.exist?(path))
  store.transaction(true) do |s|
    p(s.keys)
    p(s["name"])
    p(s["list"])
    p(s["hash"])
    p(s[42])
    p(s["missing"])
    p(s.fetch("name"))
    p(s.fetch("missing", "default"))
    p(s.key?("name"))
    p(s.root?("nope"))
    p(s.roots.size)
  end

  # another PStore on the same file sees the data
  other = PStore.new(path)
  p(other.transaction(true) { |s| s["list"] })

  # changes, delete
  store.transaction do |s|
    s["list"] = s["list"] + ["more"]
    p(s.delete("hash"))
    p(s.delete("hash"))
  end
  p(store.transaction(true) { |s| [s.keys, s["list"]] })

  # abort throws away the changes; commit ends the block early but keeps them
  store.transaction do |s|
    s["name"] = "changed"
    s.abort
    s["never"] = 1
  end
  p(store.transaction(true) { |s| [s["name"], s.key?("never")] })
  store.transaction do |s|
    s["name"] = "committed"
    s.commit
    s["never"] = 1
  end
  p(store.transaction(true) { |s| [s["name"], s.key?("never")] })

  # an exception in the block aborts the transaction, and the store is usable afterwards
  begin
    store.transaction do |s|
      s["name"] = "boom"
      raise ArgumentError, "oops"
    end
  rescue ArgumentError => e
    puts("ArgumentError: #{e.message}")
  end
  p(store.transaction(true) { |s| s["name"] })

  # ultra_safe writes a new file and renames it
  store.ultra_safe = true
  p(store.ultra_safe)
  store.transaction { |s| s["safe"] = "yes" }
  p(store.transaction(true) { |s| s["safe"] })
  p(Dir.children(dir).sort)

  # errors
  begin
    store["name"]
  rescue PStore::Error => e
    puts("PStore::Error: #{e.message}")
  end
  begin
    store.transaction(true) { |s| s["x"] = 1 }
  rescue PStore::Error => e
    puts("PStore::Error: #{e.message}")
  end
  begin
    store.transaction(true) { |s| s.delete("name") }
  rescue PStore::Error => e
    puts("PStore::Error: #{e.message}")
  end
  begin
    store.transaction { |s| store.transaction { |t| t["x"] = 1 } }
  rescue PStore::Error => e
    puts("PStore::Error: #{e.message}")
  end
  begin
    store.transaction(true) { |s| s.fetch("missing") }
  rescue PStore::Error => e
    puts("PStore::Error: #{e.message}")
  end
  begin
    PStore.new(File.join(dir, "no/such/dir/x.pstore"))
  rescue PStore::Error => e
    puts("PStore::Error: #{e.message.sub(dir, "DIR")}")
  end
  thread_safe = PStore.new(File.join(dir, "ts.pstore"), true)
  begin
    thread_safe.transaction { |s| thread_safe.transaction { |t| 1 } }
  rescue PStore::Error => e
    puts("PStore::Error: #{e.message}")
  end
end
