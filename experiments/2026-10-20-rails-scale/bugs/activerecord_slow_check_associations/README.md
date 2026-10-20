# activerecord: the associations test takes 80 s to check

`bin/sake -c --strict associations.sake` (run in test/sakelib/rails/activerecord/, where the test and its
`associations_schema.rb` / `associations_models.rb` live; copies here) took **80.0 s, 592 MB** on 2026-10-20
(HEAD dad1c7a1 plus the uncommitted activerecord part 6 tree, load average ~4). The same library with one model
(`base.sake`) checks in 10.8 s, 250 MB.

Shape: 7 models, each a class that includes ActiveRecord's ~15 modules (Base's include list), a per-model
`Post::ActiveRecord_Relation` class including ActiveRecord::Relation (with QueryMethods, FinderMethods,
Calculations, SpawnMethods, Batches) and, for the 5 models some collection association targets, a
`Comment::ActiveRecord_Associations_CollectionProxy` including Relation again plus CollectionProxy: 12 copies of
Relation in all. `generated.sake` is what the generator writes (`bin/sake --dump=generated`), 2,357 lines.
Rails' shape: Rails makes the same per-model relation classes (relation_delegate_class).
