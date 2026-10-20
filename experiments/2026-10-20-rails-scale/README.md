# Rails 規模の解析時間（2026-10-20〜）

ko1「spinel は rails 規模で解析に10時間みたいな話を聞きました。Sake だとどれくらいになるかやってみてほしい。つまり、
Rails 規模のウェブアプリを作れるまで準備して、それを解析してみて」。最初の数字（下の 1）に「全然小さいんじゃない？」、
選択肢を示したところ「Rails やりましょう」。

10 時間という数字は伝聞で、ここでは確かめていない。Spinel の側は測っていない。

## 方針

1. 10-12 の Rails 型フレームワーク（1,359 行）とブログで、規模に対する伸び方を先に見る（下の 1）。
2. Rails 8.1.3 そのものを gem ごとに移植する（`sakelib/rails/<gem>/`、Rails の lib/ と同じ構成。指示は `brief.md`）。
   Rails 8.1.3 の 12 gem の lib/ はコード 108,218 行（空行とコメントを除く。activerecord 40,325、activesupport 16,634、
   actionpack 15,615、railties 10,600、actionview 8,826、activemodel 3,974、ほか）。
3. その上に多様な大きいアプリを書き、解析時間を sp4 で測る。

移植の量は `ruby coverage.rb`（各 Sake ファイルの先頭の「Port of ...」から、移植した Ruby のコード行と Sake のコード行を数える）。

## 1. 予備: ブログの複製（ローカル、1 回ずつ）

**この節の時間は sp4 ではなくローカル（16 コア、負荷 0.3〜0.8）での 1 回の計測で、傾向を見るためのもの。**
`scale_blog.rb N` は 10-12 のブログ（`rails/blog`、10-12 からの複製）の Post/Comment の組を N 組に名前を変えて複製する
（Post1/Comment1 … PostN/CommentN、テーブル・ルート・コントローラ・ビューも）。`bin/sake -c bin/server.sake`
（既定のレベル 1、フレームワーク・WEBrick・Rack・ERB などプログラム全体）の時間と最大 RSS。

| N | アプリ（行） | 10-12 の生成器 | 直した生成器 |
|---|---|---|---|
| 1 | 326 | 2.09 秒 81 MB | |
| 16 | 4,526 | 5.27 秒 203 MB | 4.82 秒 171 MB |
| 32 | 9,006 | 11.32 秒 370 MB | 8.26 秒 281 MB |
| 64 | 17,966 | 31.13 秒 859 MB | 17.33 秒 479 MB |
| 128 | 35,886 | 106.83 秒 2,244 MB | 63.36 秒 852 MB |

**10-12 の生成器では 2 乗に伸びた**（倍にするごとに 2.75 倍、3.4 倍）。段階ごとの時間（`phases.rb`）で resolver の
check_all と lower が N の倍で 3.9 倍・3.7 倍。各コントローラが自分の関数として約 283 個（ソース約 47 万文字）を持っていた:
生成器がパーシャル（4N 個）と `_render_object` を `def ApplicationController....` に書き、`class XController <
ApplicationController` がそれを 2N 個のコントローラ全部に貼り込む（Sake の `<` は継承ではなく複製で、複製は貼った先ごとに
検査される）。**直した**: パーシャルと `_render_object` を 1 つのクラス `ActionView::Partials`（ヘルパを include）に置き、
ビューはそこを呼ぶ（`rails/rails_generate.sake`、`rails/action_view.sake`）。curl のシナリオ（`rails/run.sh`）の応答は
10-12 の `run.out` と同じ（違いは生成コードの行数 429 → 439 と、毎回変わるセッション ID だけ）。

直した後も 64 → 128 で 3.65 倍。resolver と lower は線形になり（N=64 → 128 で 2.04 → 4.51 秒、0.98 → 1.69 秒）、
残りは型の検査器（20.2 → 59.7 秒）と generate の段（生成器のプログラム自体の検査と実行、4.1 → 11.6 秒）。
型の検査器のインスタンス化（`run_body`）の回数は線形（N=32 で 20,834、64 で 40,514）で、1 回あたりが重くなる:
重いのは N 個のモデルの型の合併を受ける関数（`ActionView::OutputBuffer.append`、`form_with`、`create_table`、
`polymorphic_path`）。合併の大きさに比例する仕事を、合併を受ける呼び出しの数（これも N に比例）だけしている、という
仮説で、まだ確かめていない（切り分けは、合併を作らない形に書き換えたブログで同じ N を測ること）。人工的な複製で詰めるより、
Rails の移植で同じ形が出るかを見ることにした。

この節の計測は「規模」としては小さい: フレームワークは Rails の 1.3%、アプリは同じ形の複製。

## 2. Rails の移植

第 1 段（2026-10-20 開始、並行 5 体）: activesupport A・B、arel と SQLite のアダプタ、ActionDispatch、SQLite3 の組み込み
（インタプリタ）。第 2 段: activemodel、activerecord のモデル層、actionview、actioncontroller、railties。
