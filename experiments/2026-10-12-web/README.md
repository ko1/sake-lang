# ウェブ領域: Sinatra と Rails 型（2026-10-12）

ko1「Sinatra とかできそう？ ウェブ領域いけるか試して。Rails まで行けるとかっこいいね」。

## 方法

既にある Rack 3・Rackup・WEBrick（TCPServer とスレッドの実サーバ）・ERB・JSON の移植の上に、エージェント 2 体が並行して書いた（指示は `brief.md`、各約 20〜25 分）。インタプリタ（`lib/`）は触らせず、見つけたバグは `bugs/` に再現を残させ、リードが直した。

- **A: Sinatra 4.2.1 の移植**（`sakelib/sinatra.sake`、`sakelib/mustermann.sake`）。同じアプリと同じ要求を Sake の移植と本物の gem（今回 `gem install sinatra` で 4.2.1、mustermann 3.1.1、tilt 2.9.0、rack-protection 4.2.1 を入れた）で流し、出力を突き合わせる（`test/sakelib/sinatra.{sake,rb}`、`mustermann.{sake,rb}`）。デモは `sinatra/`。
- **B: Rails 型**（`rails/`）。Rails 8.1.3 の名前と振る舞いに沿って、ルーティング・コントローラ・ビュー・モデルの核を書き、Rails ガイドのブログ（投稿とコメント、CRUD、検証、flash、レイアウト）を載せる。ヘルパが出す HTML は本物の Rails 8.1.3（ActionView・ActiveModel 単体）と突き合わせる（`rails/compare.{rb,sake}`）。

## 結果

**Sinatra はほぼそのまま書ける。** 移植は本物の gem とバイト単位で同じ応答を返す（テストでも、実サーバ越しでも）。デモの todo アプリは Sake 67 行・Ruby 67 行で、9 本の要求（一覧、フォームの POST と 303、空入力の 400、JSON、404、Cookie のセッション）を curl で流して「same responses」（`sinatra/run.out`）。

```ruby
get(app, "/todos/:id") do                      # Ruby: get "/todos/:id" do
  todo = find(app, "#{params(app)["id"]}")     #         todo = find(params["id"])
  halt(app, 404) unless todo                   #         halt 404 unless todo
  erb(app, :show, Hash[locals: Hash[todo: todo, visits: session(app)["visits"]]])
end
```

ブロックを保持できない点は、クラス本体を `def routes(app)` という 1 つの関数にし、要求ごとに走らせ直すことで越えた。`get`/`before`/`error` の各呼び出しは、その段階で合えばブロックをその場で走らせ、合わなければ何もしない。最初に合ったルートは `Sinatra::Halt` を投げる（Ruby の `throw :halt`）。動くもの: 全メソッド、Mustermann のパターン（`:name`、`*`、`(.:format)?`、Regexp）、params、status/headers/body、halt、redirect、pass、not_found/error ハンドラ、パターン付き before/after、erb（views ディレクトリ、レイアウト、インライン）、JSON、Cookie セッション（HMAC 署名）、settings、`public/` の静的ファイル、既定の保護ヘッダ、`run!`。無いもの: `error MyError do`（クラスは値でないので、全部受けのハンドラの中で `case e in MyError`）、遅延 settings、`use`/`register`、`stream`、テンプレートからの `@ivar`（`locals:` で渡す）。規模: Sinatra の base.rb 1536 行（コード）→ 824 行、Mustermann の該当部分 1012 行 → 198 行。

**Rails は「形」まで行けた。生成の段が要る。** ブログが実サーバ（WEBrick）で動き、curl のシナリオ（一覧、新規、検証エラーの 422「2 errors prohibited…」、作成と 302、flash、コメント追加、空コメントの alert、サーバ再起動後に JSON ファイルから復元、編集と PATCH、コメントと投稿の DELETE、存在しない投稿の 404、ルートの無い 404）が通る（`rails/run.out`）。`link_to`・`form_with`・`button_to`・`content_tag`・`pluralize`・`errors.full_messages`・ルートヘルパの HTML は本物の Rails 8.1.3 と同じ 67 行。

```ruby
# Rails (config/routes.rb)                      # Sake (blog/config/routes.sake)
Rails.application.routes.draw do                class ActionDispatch::Routing::Mapper
  resources :posts do                             def draw(map)
    resources :comments, only: [:create,            resources map, :posts do
                                :destroy]             resources map, :comments, {only: Array[:create, :destroy]}
  end                                               end
  root "posts#index"                                root map, "posts#index"
end                                               end
                                                end
```

Rails が立っている Ruby の 3 つの機構に、Sake の形を 1 つずつ当てた（`rails/notes.md` に対訳）。

| Ruby の機構 | Rails での使いどころ | Sake の形 |
|---|---|---|
| `instance_exec` で DSL オブジェクトにブロックを走らせる | routes.rb、schema.rb | DSL クラスを開き直して関数を書く（`def draw(map)`）。DSL オブジェクトは `self` ではなく第 1 引数 |
| 起動時のコード定義（`define_method`、`send`、`eval` でのテンプレートのコンパイル） | ルートヘルパ、モデルの属性、アクションの呼び出し、ERB | **生成の段**: `bin/sake bin/rails.sake generate` が `tmp/generated/` に Sake を書き出す（ルート 30 行、モデル 33（10-13 に 114 から。下の追記）、ビュー 183、コントローラ 47）。検査器がそれを読むので、テンプレートの誤り（`Post.titel(post)`）がサーバを起動する前に出る |
| コードをデータとして持つ（`before_action :x`、`has_many`、`validates`） | コントローラとモデルのクラス本体 | アプリが書くフック関数: `def before_action(c, action)` に `case`、`def validate(post)` に `validates post, :title, {...}` の行、`def comments(post) = Comment.where({post_id: @id})` |

テンプレートは Rails の書き方のまま中身が Sake の式で（`<%= link_to "Show this post", post %>`、`render "form", post: @post`）、「既に HTML」を型（`ActiveSupport::SafeBuffer`）にしたので、エスケープも Rails と同じに効き、検査器がどの値が HTML か知っている。無いもの: CSRF、暗号化 Cookie セッション（サーバのメモリに置いた）、respond_to/JSON、before_action と before_destroy 以外のコールバック、`has_many` の宣言（関数を手で書く）、presence と length 以外の検証、マイグレーション、Rails の双子アプリ。保存は JSON ファイル（SQLite の結合が無く、Rails の `where`/`order` の API のほうが SQL より大事なので）。規模: フレームワーク 1,362 行、ブログ 393 行 + 生成 374 行。

## 利用感レポート

良かったこと:
- **括弧なしの呼び出しで DSL がそのまま読める。** `resources map, :posts do`、`link_to "Show", post`、`validates post, :title, {...}`、Sinatra の `get(app, "/") do`。Ruby との差は「DSL オブジェクトを第 1 引数で渡す」ことだけ。
- **生成したコードも検査される。** Rails なら最初の要求で NoMethodError になるテンプレートの綴り間違いが、起動前に `did you mean Post.title?` になる。
- **オプションの Record（`{notice: "..."}`）** が Rails のオプション Hash の代わりになり、`case opts in {notice:}` で形が検査される。
- **既定レベルでブログの報告は 0。** `--strict` では 8 件で、すべて「before_action が `@post` を入れたので、後のテンプレートでは nil でない」という Rails の慣用句（検査器はこの順序を追えない）。

つらかったこと（重い順）:
1. **ライブラリの `rescue` が、アプリ次第で「投げられない」エラーになる。** Sinatra 内部の `rescue Pass` は、アプリが `pass` を一度も呼ばないとプログラム全体の検査で「never raised」になる。全部受けの `rescue => e` にして `Pass` 以外を投げ直すしかなかった。（10-13: 「never raised」は警告の項目 `unused-rescue` になった。下の追記）
2. **実行時に定義するコードが書けない。** Rails の大半（ルートヘルパ、属性、`send(action)`、テンプレート）は生成の段で書き出すしかなく、生成物が古いことを誰も知らせない。型のフィールドをデータとして読む手段（`T.fields`、Symbol でのフィールド読み書き）があれば、生成するモデルのコードの大半が要らなくなる。（10-13: 入れた。下の追記）
3. **Rails の名前が Sake の組み込みとぶつかる。** `new` アクション → `new_`、`Post.new(params)` → `Post.build(params)`、`params.require` → `require_`（`require` は文）。`attr_accessor post` の書き込み関数 `set_post` が、scaffold の callback 名 `set_post` とぶつかる（→ `attr_reader post`）。
4. **基底クラスは子のフィールドを使えない。** Rails の「基底クラスが、子が持つはずのものを呼ぶ」は、必須関数のモジュールを毎回挟む。（10-13: `read_field(r, :id)` で読めるようになった）
5. **1 か所で作るクラスはフィールドの型が 1 つ。** 共通の関数で作る `Relation` が Post と Comment の両方を持って混ざった（`mixed`）。Relation は Array にし、`Post.where(...).order(...)` の連鎖は失った。
6. **params の値の型が長い再帰的な和**（String、Array、Hash、nil）で、使うたびに `x => Array` が要り、エラーには約 600 文字の型が出る。
7. 細かいもの: ブロックの引数の数が厳密（レイアウトの裸の `yield` を `yield(nil)` に）、テンプレートの誤りの位置が生成ファイルの行で .erb の行でない、`puts` の後に `IO.flush` が要る（Ruby と同じ）、~~`Time.utc` が 6 引数を取らない~~（10-13 に入れた）、`{}` が空の Record で Hash でない。

## 見つかったバグと直したもの

- `attr_accessor body` の型で `def set_body(b, v)` を定義すると「組み込み操作は再定義できない」と拒まれた（`bugs/sinatra_attr_setter_called_builtin.sake`）。**直した**: 書き込み関数と同名の関数は生成された書き込み関数を置き換え、`x.T.body = v` と `+=` もそれを呼ぶ（Ruby で attr_accessor の後に `body=` を定義したのと同じ）。引数の数が 2 でない場合（Rails の `set_post(c)`）は「`attr_accessor post` の書き込み関数」と言い、`attr_reader` を案内する（`test/samples/user_setter*.sake`）。
- Rails 側はインタプリタのバグなし。

## 頼まれた組み込み・ko1 の判断が要るもの

- **判断**: 上の 1（ライブラリの rescue）。案: 読み込んだライブラリの中の rescue には「never raised」を出さない。
- ~~**判断**: 型のフィールドをデータとして扱う操作~~ → 入れた（10-13、下の追記）。
- **判断**: 生成・マクロの段を言語として持つか（今は `tmp/generated/` を手で作り直す）。→ 10-13 に `generate` として入れた（下の追記）。
- ~~追加するだけで済むもの~~ → 入れた（10-13）: HMAC（`OpenSSL::HMAC`、sakelib/openssl.sake）、`Time.utc(y, m, d, h, mi, s)` と `Time.gm`、`__dir__`（と `__FILE__`・`__LINE__`）、パターンでの束縛（`in [Integer => code, …]`）、`Rack::Response#[]`。Sinatra の移植・テスト・デモはセッションの署名、Halt の変換、views の場所をこれらで書き直した（応答は変わらず「same responses」）。

## 追記（2026-10-13）: フィールドを名前で読み書きする

ko1「2は追加して書き直して」。`T.field_names`・`T.read_field(x, name)`・`T.write_field(x, name, v)`（Ruby の `Struct.members`・`#[]`・`#[]=`）を入れ、Rails 型のモデルを書き直した。

- Rails が反射で得る属性関数（`read_attribute_for_validation`、行との変換 `_to_row`/`_from_row`、`_id`、タイムスタンプ、`model_name`、フォームからの代入）は `ActiveRecord::Base` に 1 度だけ書いた。生成するモデルはフィールドと列の型による変換だけで、114 行 → 33 行。
- 型は保たれる: 変換は `case name in :title then write_field(r, name, ActiveRecord::Type.string(value))` の形で、各 `in` が名前をリテラルに絞るので、フィールドはそれぞれ自分の型だけを持つ（`Post.title` は `String | nil` のまま）。この過程で、`String.to_sym` から来た Symbol が `in :title` で絞られない穴が見つかり、直した（絞らないと全フィールドに String と Integer が入り、`Post.errors` まで汚れて 10 件の `[mixed]` が出た）。
- 変換が生成に残る理由: 列の型は db/schema.sake にあり、検査器はフィールドの型をソースから知る必要がある。`_table` が残る理由: `once` はプログラムの場所ごとに 1 つの値で、Base の関数は 1 つの場所の写しなので。
- 結果: `run.sh` の応答は前と同じ（違いはタイムスタンプと所要時間だけ）、`--strict` の報告は前と同じ 8 件、`compare` は Rails と同じ（compare.sake の手書きの `read_attribute_for_validation` も `read_field` 1 行にした）。
- 規模: active_record 250 → 304 行、rails_generate 346 → 313 行、生成物 374 → 293 行。

### 「never raised」を警告に（つらかったこと 1）

ko1「そもそも防衛的にライブラリじゃなくても書くよね？」。ライブラリだけ外す案はやめ、「begin 本体が決して投げない例外の `rescue`」をどのレベルにも入らない項目 `unused-rescue` に分けた。既定では警告でプログラムは走り、`--strict=2,unused-rescue` と選んだときだけエラー。「前の節が既に捕まえる `rescue`」（必ず届かない節）は `rescue` 項目としてレベル 1 のエラーのまま。理由: 防御的な `rescue` は普通に書くもので、投げるものがあるかはプログラム全体で決まり、離れた場所の変更（アプリから `pass` を消す）が触っていないライブラリを止める。

- `sakelib/sinatra.sake` の `_route` は `rescue Pass` に戻した。`pass` を呼ばないアプリ（このデモ）は sinatra.sake を指す警告が 1 つ出て、走る。
- `run.sh` は前と同じ応答（same responses）、sakelib の Sinatra テストも同じ。

## 追記（2026-10-13）: 生成の段 `generate`

ko1 が承認した「実行前の段で eval、毎回検査」（DESIGN.md、仕様は docs/spec.md §3）を入れ、Rails 型の生成の段を置き換えた。

- 言語: ファイルの最上位の文 `generate "gen", "arg", ...`（`require` と同じく文字列リテラル）。プログラムを検査する前に gen.sake を独立したプログラムとして同じレベルで検査して走らせ（引数が ARGV）、標準出力をソースとしてその位置に繋ぎ、全体を検査して走らせる。生成物の位置は `(generate at FILE:LINE):N`。生成器が `# sake-origin: FILE:LINE` を書くと、そこから次の印までの行はその位置として報告される（静的エラー、実行時エラー、backtrace、「reached by」）。`bin/sake --dump=generated FILE` で生成物を見る。
- ブログ: `config/application.sake` の 4 つの `require "../tmp/generated/..."` を `generate "../bin/rails", "source"` の 1 行にした。`bin/rails.sake` は `routes` と `source`（4 つの生成物を続けて印字）だけで、`generate`（ファイルへの書き出し）と `tmp/generated/` は**消した**（古い経路は残していない）。テンプレートのコンパイラは `.erb` の各部分の前に `# sake-origin: app/views/...:行` を書く（生成物 293 行 → 印 135 行込みで 429 行）。`run.sh` から生成の手順が無くなり、代わりに `--strict --dump=generated` で生成物の行数を出す。
- 結果: `run.sh` の応答は前と同じ（セッション id・ポート・時刻・所要時間を除いて diff なし）。`--strict -c test/requests.sake` は前と同じ 8 件・同じ中身（すべて nil）。違いは位置で、3 件が .erb の行（`app/views/posts/_form.html.erb:3`、`index.html.erb:8`、`show.html.erb:3`）、2 件が印の無い生成物（ルートヘルパの `_to_param`、`_render_object` の `case`）を `(generate at test/../config/application.sake:6):N` で、3 件は手書きのファイルのまま。テンプレートの綴り間違い（`Post.titel(@post)`）は `app/views/posts/show.html.erb:3: error: undefined function Post.titel / hint: did you mean Post.title?` になった（前は `tmp/generated/views.sake:95`）。
- 起動の費用（このマシン、負荷平均 6〜8 / 16 コアの共有環境、各 5 回）: `bin/sake -c bin/server.sake` が前 1.76〜1.82 秒、後 2.01〜2.25 秒で、約 0.3 秒増えた。生成器を単独で走らせると 1.23〜1.33 秒（Ruby の起動と sakelib の読み込みを含む。前の `bin/rails generate` は 1.07〜1.22 秒）なので、段の正味は起動の共有分だけ安い。サーバの起動ごと・`-c` ごとに払う。

利用感（良くなったこと）:
- **生成物が古くならない。** テンプレートを直してサーバを起動し直すだけ。「generate を忘れた」が起きない。手順が 1 つ減り、生成ファイル 4 つ（374 行）がリポジトリから消えた。
- **誤りがテンプレートの行を指す。** origin の印は生成器が 1 行書くだけで、テンプレートのコンパイラの変更は約 5 行。
- 生成器は「ソースを印字する普通のプログラム」なので、単体で `bin/sake bin/rails.sake source` と走らせて見られ、`--dump=generated` と同じものが出る。新しい API を覚えなくてよかった。

利用感（悪くなったこと・気になること）:
- **起動が毎回 0.3 秒遅い。** 生成器のプログラム（action_dispatch・active_record などを require する）を毎回検査する。生成器とアプリはライブラリを共有するので、検査は二重。キャッシュには「生成器が読んだファイル」を知る手段が要る（TODO 7）。
- **生成物が目に見えない。** 読むには `--dump=generated` を打つ。エラーの hint にそれを書いた。
- **生成器の `puts` はすべてソースになる。** デバッグの印字は `warn`（標準エラー）に出す必要がある。
- 位置の名前が長い: 「reached by」の連鎖に `(generate at test/../config/application.sake:6):425` が何度も出る。`nil is stored at line 421` は生成物に限らずファイル名を持たない（前は `controllers.sake` の 40 行で、同じく曖昧だった）。
- `generate` を置く位置が意味を持つ: モデルの `class Post < ApplicationRecord` は `app/models/*` より前に要る（`<` は最初の `class Post` に書く規則）ので、`generate` を `require "../app/models/*"` の前に置いた。

## ファイル

- `brief.md`: 指示。`bugs/`: 再現。
- `sinatra/`: デモ（`app.sake`、Ruby の双子 `app.rb`、`views/`、`run.sh`、`run.out`）。移植の本体とメモは `sakelib/sinatra.sake`、`sakelib/notes/sinatra.md`、`sakelib/mustermann.sake`、`sakelib/notes/mustermann.md`。
- `rails/`: フレームワーク（`action_*.sake`、`active_*.sake`、`rails.sake`、生成器 `rails_generate.sake`）、`blog/`（Rails の配置）、`compare.{rb,sake}`、`run.sh`、`run.out`、`notes.md`（対訳、16 件の摩擦、保存の理由、規模）。
