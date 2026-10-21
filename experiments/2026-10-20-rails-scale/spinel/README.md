# Rails ガイドのブログを roundhouse + Spinel に通す（2026-10-21、ローカル）

Sake の Rails 移植がブログ（Sake 版）を sp4 で 60.2 秒で検査する（`../README.md` の 4 節）のと比べるため、同じブログの
本物の Rails 8.1.3 版（`../blog_rb/`）を [roundhouse](https://github.com/rubys/roundhouse) の `--target spinel` で
Ruby に変換し、[Spinel](https://github.com/matz/spinel) でコンパイルした。poly（Spinel の実行時に型を見る値）の数、
Spinel の解析時間、動くかを見た。

**この README の数字はすべてローカル（16 コア、30 GB、他の session の作業あり、負荷 1.4〜9）で、sp4 ではない。**

## 方法

- roundhouse `3196e43f9d779ac9a88a005cdb1b1bddade76f37`（2026-10-20、`roundhouse 2026.9.18 (3196e43f)`）。Rust 製。
  `cargo build --release --bin roundhouse`（rust-toolchain.toml が固定する 1.98.1 を rustup が取得、3 分 50 秒）。
- Spinel `922ad15a388f1513d05e69a500d7f2d377a34e82`（2026-10-21、`spinel 2026.09.12+11816 (922ad15a3) [gcc 15.2.0 (cc)]`）。
  `make deps`（rubygems.org から prism 1.9.0、rbs 4.0.1）と `make -j8`。gcc は Ubuntu 15.2.0-16ubuntu1。
- `spin` が spin.toml の依存として rubys/spinel-bcrypt `v0.1.1`（`cc29f69ee8bd52f1b2d39639b25458909e7cd476`）を
  `~/.cache/spin/` に取る。アプリが使う gem で Spinel のプログラムに入るのはこれだけ（Rails の gem は一切入らない。下記）。
- 手順は roundhouse の docs/guide/spinel.md のとおり: `roundhouse --target spinel blog -o out-spinel`、`spin build`。
  計測は `spin build` と同じ引数（`spin flags`、`spin-flags.txt`）で `spinel` を直接呼び、`--timing`（段ごとの時間、
  docs/profiling.md）、`--warn-widen`、`--emit-types`（docs/emit-types.md）を足した。
- `run.sh WORK ROUNDHOUSE SPINEL_DIR [N]` が全部やる: blog_rb の複製（blog_rb 自体は変えない）、下の回避 1、roundhouse を
  N 回、`spinel -c`（解析と C の生成だけ）を N 回、C のコンパイルまでの build を N 回（各 `/usr/bin/time` で wall と最大 RSS）、
  `--emit-types` から `classify.rb` で poly を数える、行数、DB の用意（回避 2）、バイナリを立てて `../walk.sh`、
  `../blog_rb/run.out` との差分。sp4 では `run.sh /tmp/x ~/roundhouse/target/release/roundhouse ~/spinel 3` のように
  走らせればよい（roundhouse と Spinel のビルドは別途。sp4 の ~/sake-bench/spinel-src は dd29ea35 で古い）。
- 結果は `local-2026-10-21/`: `run1.log`〜`run3.log` が run.sh の出力（1・2 回目は直す前の run.sh）。`classify.txt`、
  `warn-widen.txt`、`timing-*.txt`、`walk.out`、`walk-normalized.diff` は 1 回目のもの（数は 3 回とも同じ）。

### 回避したこと（ブログ側 1 つ、生成物 1 つ、環境 1 つ）

1. **`spin build` が Spinel の段で止まった**: `blog/app/views/comments/_form.html.erb:1: undefined method
   'comment_path' for a Class: no class in the program defines a class method 'comment_path' (NoMethodError)`。
   ガイドの `form_with model: [ article, article.comments.build ]` を roundhouse が `RouteHelpers.comment_path([ article,
   Comment.new(article: article) ].id)` に下ろしていた。原因は roundhouse の `nested_resource_form`
   （src/lower/view_to_library/form_with.rs:1175）が入れ子の形を `[親, 定数.new(...)]` しか認識しないこと
   （roundhouse の fixture のブログは scaffold 由来で `[@article, Comment.new]` と書く）。`roundhouse check` は 0 エラーで、
   ここは Spinel が最初に気づく。複製の側を `[ article, Comment.new ]` に変えた（Rails の出力は同じ HTML。
   show.html.erb ではコメントの一覧を先に描くので、`build` が関連に足す未保存のコメントも表に出ない）。
2. **生成された db/seed.sql が通らない**: seeds.rb の `User.create!(email_address: ..., password: "password")` が
   `INSERT INTO users (id, email_address, password, ...)` になり、`table users has no column named password`。
   has_secure_password の仮想属性を列として書いている。run.sh はこの行を CRuby の bcrypt で作った
   `password_digest` に書き換えて（`seed_fix.rb`）流す（sqlite3 の CLI が無いので ruby の sqlite3 gem で）。
3. ローカルに libsqlite3-dev が無く、リンクの `-lsqlite3` が見つからない。run.sh は `libsqlite3.so.0` への symlink を
   置いて `LIBRARY_PATH` に足す（リンクできるときは何もしない）。

### 警告

- roundhouse の変換: `authentication.rb` の `extend ActiveSupport::Concern` と `included do ... end` が「lower_residue:
  not modelled and is dropped」、`sessions_controller.rb:8` の `params.permit(...)` が `constant read Params has
  unresolved type`。ただし `before_action :require_authentication` と `allow_unauthenticated_access` は各
  コントローラの `process_action` に展開されていて、walk でも認証の挙動は Rails と同じだった。
- `spin build` の `--rbs`: 11 件の「`@error_details: Array[ErrorDetail]` stays a boxed array」（`full.1-other.txt`）。
- 上流のビルド時の警告（直していない、こちらのコードではない）: roundhouse の cargo build で dead_code 1 件
  （`ConstantReaderIndex::current`）、Spinel の make で gcc 3 件（vendor/prism の pm_memchr.c:31
  -Wdiscarded-qualifiers、src/codegen_call.c:4874 の -Wformat-overflow ×2）。

## 結果

### 時間と RSS（ローカル）

run.sh の 1 回目（02:32〜02:42 UTC = JST 11:32〜11:42）の中の 2 回ずつ:

| 段 | 1 | 2 | 最大 RSS |
|---|---|---|---|
| roundhouse（変換） | 0.19 秒 | 0.18 秒 | 48 MB |
| `spinel -c`（解析 + C 生成） | 75.0 秒 | 72.9 秒 | 328 MB |
| 　うち analysis | 66.3 秒 | 64.6 秒 | |
| 　うち analysis_fixpoint（32 ラウンド） | 51.3 秒 | | |
| `spinel -o`（C のコンパイルまで） | 93.0 秒 | 93.5 秒 | 343 MB |
| 　うち cc_total（16 並列に分割） | 15.4 秒 | 15.3 秒 | |

負荷は開始時 1.38、終了時 3.2。
fixpoint の中で長いのは promote_shared_stored_strings 10.3 秒、infer_write_types 5.2 秒、narrow_object_arrays 5.1 秒
（`timing-c.1.txt`）。

**再実行**（2 回目の run.sh、02:42〜02:54 UTC = JST 11:42〜11:54、別の session の Sake の検査が 2〜3 本並走して負荷 3.6 → 9.2）:
`spinel -c` 108.2 / 102.7 秒（analysis 98.4 / 88.4 秒）、`spinel -o` 124.8 / 117.4 秒（cc_total 22.8 / 20.8 秒）、
RSS は同じ（328 / 342 MB）、roundhouse 0.21 / 0.23 秒。負荷で 1.4 倍ほど遅くなる。widen の数・行数・walk の結果は 1 回目と同じ。
（この回は run.sh の seed の書き換えが digest の `/` で sed ごと失敗した。seed_fix.rb に直し、walk 以降だけ流し直した。
直した run.sh を通しで流した結果が下の「3 回目」。）

**3 回目**（直した run.sh を通しで、02:55〜03:06 UTC = JST 11:55〜12:06、負荷 6.9 → 8.0）: `spinel -c` 104.0 / 86.7 秒
（analysis 92.1 / 77.3 秒）、`spinel -o` 134.6 / 119.2 秒（cc_total 20.5 / 19.6 秒）、RSS 328 / 343 MB、roundhouse 0.21 / 0.22 秒。
widen の数・行数・walk の結果は同じ。

負荷が低かった 1 回目（analysis 65 秒前後、`spinel -c` 73〜75 秒）を目安とし、比べる値は sp4 で取り直す。

### 行数

- 元のブログ: Ruby 184 行（models・controllers・concerns・helpers）、ERB 191 行、routes 10 行。
- 変換後の Ruby（`out-spinel/` の `*.rb`）: アプリ側 4,655 行（app/ 3,374、main.rb と boot.rb 1,223、config 52、db 6）、
  roundhouse のランタイム（runtime/、Rails の代わり）184 ファイル 50,147 行（コンパイルに入るのは 151 ファイル 43.0 千行）、
  test/ 4,698 行（build には入らない）、bcrypt 242 行。ほかに Spinel 自身の builtins/ と packages/（set、json、openssl ほか）。
- 生成された C: 129,886 行（7.7 MB）。

### poly（`--warn-widen` / `--emit-types`）

`--warn-widen` は引数か戻り値の枠が untyped（boxed poly）に広がるたびに 1 件出す。**2,610 件**（引数 1,698、戻り値 912）。
`--emit-types` の diagnostics と件数は一致する。場所は出力したファイル（`#<SPINEL_SOURCE>` の印を外した複製で取り直した）で分けた。
widen = 警告の数、unbound = そのうち「never bound: no call site gives it a type」（このプログラムでは呼ばれない）、
def_w / defs = 広がった枠を持つメソッド / 全メソッド、poly_n / nodes = 型が poly か poly を含む容器（poly_array、
*_poly_hash）の式 / 型の付いた全式。

| どこ | widen | unbound | def_w / defs | poly_n / nodes |
|---|---:|---:|---:|---:|
| アプリ（app/ config/ main.rb boot.rb） | 225 | 10 | 195 / 468 | 2,163 / 10,416（21%） |
| 　models（列のアクセサ・検索・関連を roundhouse が合成） | 168 | 10 | 157 / 369 | 1,394 / 5,876 |
| 　views | 26 | 0 | 12 / 22 | 78 / 1,546 |
| 　controllers | 8 | 0 | 8 / 37 | 114 / 766 |
| 　routes（config/routes.rb、route_helpers.rb） | 1 | 0 | 1 / 13 | 2 / 229 |
| 　main.rb（ルーティングとディスパッチ） | 21 | 0 | 16 / 20 | 570 / 1,876 |
| roundhouse のランタイム（runtime/） | 1,967 | 238 | 1,318 / 3,024 | 15,953 / 87,276（18%） |
| 　active_record | 464 | 4 | 327 / 641 | 3,583 / 15,174 |
| 　active_support_ext | 140 | 48 | 83 / 115 | |
| 　db | 132 | 23 | 92 / 170 | |
| 　tep（HTTP サーバ） | 116 | 53 | 92 / 189 | |
| 　action_dispatch / action_controller / action_view | 97 / 80 / 65 | | | |
| gem（bcrypt） | 3 | 2 | 3 / 16 | 6 / 334 |
| Spinel の builtins と packages | 415 | 219 | 262 / 454 | 2,581 / 13,087 |
| 計 | 2,610 | 469 | 1,778 / 3,962 | 20,703 / 111,113（19%） |

元のソースの行に `#<SPINEL_SOURCE>` で帰されるのは 2,610 件中 202 件（models 160、authentication.rb 10、views 26、
controllers 6）。models の行は合成されたコードを `class Article < ApplicationRecord` の 1 行に帰したもの。

例（`classify.txt` の末尾、`warn-widen.txt` が全件）:

- モデル: `Article#title=`・`#body=` の引数、`#created_at` の戻り値、`#comments`（関連）の戻り値（`Array[untyped]` から）、
  `schema_columns` の戻り値、`initialize(attrs)`・`update(attrs)` の引数。`title=` の why の連鎖をたどると、
  `from_stmt` の `Db.column_text_opt(stmt, 3)` → ランタイムの問い合わせキャッシュの `cell_text` → その `@texts`
  （runtime/db.rb:286、`@texts = [""]; @texts.pop` と書いてあるが `Array[untyped]`）から untyped が来ている。
  4 モデルとも列の setter のうち 4 個ずつがこの連鎖で、モデルの列の型はランタイムの側で失われている。
- コントローラ: Authentication の `authenticated?`・`resume_session`・`require_authentication` など 8 個の戻り値。
- ビュー: 各テンプレートの `notice`・`alert` 引数（flash の値）。
- ランタイム: `SqliteAdapter.where(conditions)`・`insert(attrs)`・`update(attrs)` の引数、`all`・`find` の戻り値。
- gem: bcrypt の `Password#==(secret)` の引数。

## 動くか

動いた。`build/bin/blog -p PORT -b 127.0.0.1`（green thread のサーバ、Rack ではない）を `../walk.sh` で 26 リクエスト歩いた。
**26 個の状態コードと Location はすべて Rails と同じ**で、サインイン・認証の要るページのリダイレクト・検証エラーの 422・
コメントの作成と削除・`<b>` のエスケープ・flash も同じ。`../blog_rb/run.out` との生の diff は 351 行で、ほとんどが書き方の違い
（Rails の開発モードが入れる `<!-- BEGIN/END app/views/... -->`、属性の順、`<input ... />` と `<input ...>`）。
`normalize.rb` でそれを揃えた diff（`walk-normalized.diff`）は 48 行で、中身の違いは 5 種類:

1. stylesheet の href: Rails `/stylesheets/application.css`、Spinel 版 `/assets/application.css`（13 ページ）。
2. 302/303 のリダイレクトに content-type が無い（Rails は `text/html; charset=utf-8`、10 応答）。
3. パスワード欄の `size="72"` が無い（ビューは `maxlength: 72` だけを書き、Rails の password_field が size を足す。2 か所）。
4. 検証エラーで空になったタイトル欄の `value=""` が無い（1 か所）。
5. 404 の 2 ページ: Rails は開発用のエラーページ（`<title>Action Controller: Exception caught</title>`、charset=UTF-8）、
   Spinel 版は title の無い短いページ（charset=utf-8）。状態コードは同じ。

アセット（`make assets`）は流していないので CSS 自体は 404 になる（walk は取りに行かない）。

## roundhouse がしていることと Sake の generate との違い

- **Rails を動かさない。** roundhouse は Rails のアプリのソースを Rust で静的に解析し（アプリを起動しない、DB も読まない）、
  DSL を変換時に解く: ルートは main.rb の `case`、`before_action` は各コントローラの `process_action` の if、モデルは
  schema から列ごとのアクセサと SQL 文字列を持つメソッド（`Article.from_stmt`、`Db.prepare("SELECT id, body, ... FROM articles")`）、
  ERB はテンプレートごとの文字列を組むメソッド（`Views::Articles.show(@article, notice, alert)`）。
- **Rails の代わりは roundhouse のランタイム**（runtime/、手で書かれた Spinel 向けの Ruby、約 43 千行がコンパイルに入る）。
  Rails 8.1.3 の gem のコードはどこにも入らない。Spinel が見るのは「メタプログラミングの無い Rails の形」に下ろした後のプログラム。
- Sake 版は Rails 8.1.3 の gem を Sake に移植したもの（Rails の lib/ と同じ構成）の上に、アプリをクラス本体の `.rb`
  （メソッドの無いモデルは Rails と同じファイル）と関数の `.sake` で置き、
  起動時の generate（Sake で書いた生成器を検査・実行する）がルートなどから約 3,100 行を生成して、移植した Rails ごと検査する。
  DSL を解く場所が、roundhouse では Rust の変換器（検査されない）、Sake ではプログラムの一部（検査される）。
- poly の扱い: Spinel は推論で決まらない枠を poly に広げてコンパイルを続ける（実行時に型を見る）。Sake には poly が無く、
  型は合併のまま持ち、合併のどの型でも操作が成り立つかを検査する（`../README.md` の 7 節: フィールドの 83.6% が 1 種類、
  3.5% が 6 種類以上）。ここの「widen 2,610 件」と Sake のフィールドの合併の幅は別の指標で、直接は比べられない。

## 比較の注意

- **機械と負荷が違う**: ここはローカル（16 コア、負荷 1.4〜9、他の session の作業あり）、Sake の 60.2 秒は sp4（占有、負荷 0.00、
  governor performance）。Sake の同じ検査のローカルの値は 92 秒（負荷 1.1〜1.4）。Spinel のこの数字は sp4 では測っていない。
- **解析しているものの範囲が違う**: Spinel の 65 秒は roundhouse が Rails を解いた後のプログラム（アプリ側 4.7 千行 +
  ランタイム 43 千行、ほかに Spinel のライブラリ）の推論。Sake の 60 秒は Rails 8.1.3 の移植と生成コードとアプリ全体の型検査。
  roundhouse の変換（0.2 秒）は検査ではない（`roundhouse check` は 0 エラーだったが、回避 1 の誤りを見逃した）。
- **していることが違う**: Spinel は型を推論して C を出す（エラーで止めるのは refusal だけで、広がった所は poly で通す）、
  Sake は型の誤りを報告する検査器。Spinel の時間には C の生成（約 8 秒）が入り、C のコンパイル（15 秒）は別に書いた。
- 「Spinel は Rails 規模で 10 時間」という伝聞（`../README.md` の冒頭）が何を指すかは分からない。roundhouse で Rails を
  除いた後のこの経路では、ブログの解析は 1 分強だった。Rails そのものを Spinel に通すことは試していない。
