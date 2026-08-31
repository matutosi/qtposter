# qtposter

**Quarto + Typst で学会用のポスターを作るプロジェクト** (2026-08-30 開始)．
まずは既存の作例を調べ，何ができていて何に困っているかを整理するところから始める．

- 親の管理は [todo/.claude/CLAUDE.md](../../.claude/CLAUDE.md)．**進捗はここが正**．
- 近い系統のプロジェクト (置き換えではなく別系統)
  - [acposter](../../acposter/.claude/CLAUDE.md): md → PDF の学術ポスター (pandoc + ヘッドレス Chrome，LaTeX 不使用)．
  - `../../docposter`: Quarto + `_extensions` でポスターを組む既存の一式 (`quarto-poster` 系)．
  - `../../ggposter`: R/ggplot2 でポスターを描く R パッケージ．

## 構成

| ファイル・ディレクトリ | 中身 |
|---|---|
| `_extensions/qtposter/` | Quarto の Typst 形式の拡張 (`_extension.yml`・`typst-template.typ`・`typst-show.typ`・`boxes.lua`) |
| `poster.qmd` | 検証用の見本 (A0・3段・日本語) |
| `README.md` | 使い方と書き方の約束 |
| `images/` | 見本が使う仮の画像 (acposter から借用) |
| `notes/survey_quarto_typst.md` | Quarto + Typst のポスター作例の調査・テンプレート比較・試作で踏んだ罠 (2026-08-30) |

**組版は [peace-of-posters](https://github.com/jonaspleyer/peace-of-posters) (MIT) に任せ，
qtposter は Markdown の書き方を決める薄い層だけを持つ** (2026-08-30 ユーザ確定)．

## 進捗状況

### 現在の状態

- 2026-08-31 11:30 (このセッション，MATUTOSI_DP) その4
  **ライセンスと CI を3系統で揃えた** (ユーザ指示)．
  - **MIT の `LICENSE` を置いた** (ggposter は元から MIT)．README にも節を足した．
  - **CI を新設した** (`.github/workflows/test.yml`)．Ubuntu と macOS で
    Quarto 1.10.18 を入れ，見本4本を組み，`pdftotext` で中身を確かめ，
    `check_poster_pdf.ps1` で検算し，PDF を成果物として上げる．
  - **和文は `pdftotext` で抜き出せない** (Typst の PDF は CJK に ToUnicode を
    持たない)．目印は**欧文の文字列**にした (`boxes.lua`・`grid.boxes` など)．
  - **CI では和文フォントを差し替える**．見本は Yu Gothic だが，Ubuntu は
    Noto Sans CJK JP，macOS は Hiragino Sans を `-M font:` で渡す
    (`-M` の上書きが効くことは実機で確認した)．

- 2026-08-31 10:55 (このセッション，MATUTOSI_DP) その3
  **3系統で揃えられるものを揃えた** (ユーザ指示)．
  - **README の項目と順序**を3つ共通にした (つくれるもの → 前提 → 使い方 → 書き方の約束 →
    配置の決め方 → 見本 → 姉妹ツールとの行き来 → 構成 → 現状と経緯)．内容は揃えられないが，
    **どこに何が書いてあるかは揃う**．
  - **検算を足した** (`check_poster_pdf.ps1`)．acposter だけが持っていた項目．
    ページ数 (常に1)・用紙実寸・埋め込みフォントを見る．**出力の文言も acposter に揃えた**．
  - **画像の救済を移した** (`!` の付け忘れ)．`Link` フィルタで拡張子を見て画像に直す．
  - 残る差は `{.full}`・画像の高さの上限・表の体裁 (booktabs 調)・CI の4つ．

- 2026-08-31 09:45 (このセッション，MATUTOSI_DP) その2
  **見本を4本に揃えた** (ユーザ指示の1)．acposter の4本を基準に，`poster_howto.qmd`
  (機能の一巡り)・`poster_howto2.qmd` (入力と出力)・`golf_course.qmd` (実際に近い例) を新設し，
  `poster_grid.qmd` を `poster_howto3.qmd` に改名した．画像も acposter と同じものを置いた．
  - **Quarto 1.10 は `columns:` を自分のページ段組みとして使う**ことが分かった
    (`#set page(columns: 3)` が出て qtposter の段組みと**二重になり**，箱の幅が 1/9 になる)．
    `grid`・`orientation` と同じ**予約キーの衝突**．`boxes.lua` の `Meta` で `columns` を
    消してから渡すようにした．**流し込みの見本を目視していなかったので見落としていた**．
  - **注記の帯 (footer) をページの下端 (`page(footer:)`) へ移した**．本文の流れの最後に
    置くと，箱が紙面いっぱいのときに帯だけが2ページ目へ溢れる (golf_course で実際に発生)．
    帯の文字は本文の 0.6 倍にして，長い注記でも1行に収まるようにした．
  - ページ番号 (`numbering: none`) も消した (Quarto の既定で "1" が出ていた)．
  - **検証**: 5本とも 1 ページで組め，PNG に起こして目視確認．

- 2026-08-31 09:20 (このセッション，MATUTOSI_DP) その1
  **Quarto を 1.10.18 (Typst 0.15.1) へ上げ，`grid:` を `grid.cell` に置き換えた**
  (ユーザ指示の3)．ギロチン分割の制限 (縦にも横にも切れ目が無い配置は組めない) は無くなった．
  - **上げるだけでは動かなかった**．peace-of-posters 0.5.0 は Typst 0.12 で廃止された
    `locate()` を使っており，`error: only element functions can be used as selectors` で落ちる．
    **0.6.0 へ上げて解決**．0.6.0 では `title-box` の引数が `image:` → `logo:` に変わっている．
  - **これで qtposter は Quarto 1.5 以降が要る** (0.6.0 も `grid.cell` も Typst 0.11 以降)．
    **X280 の2台は 1.4 のままなので，そのままでは組めない** (次にやること に書いた)．
  - 古いギロチン分割の経路は**消した** (0.6.0 が 1.4 で動かない以上，到達しないため)．
    中身は git の履歴にある．
  - **この PC の PATH はまだ 1.4** (ユーザ領域の旧版が残っている)．書籍系
    (`write_book`・`writings`) を巻き込まないよう，PATH は動かしていない．
    qtposter を組むときは `C:\Program Files\Quarto\bin\quarto.exe` を明示して呼ぶ．
  - **検証**: `poster_grid.qmd`・`poster.qmd` とも 1.10 で組め，PNG に起こして目視確認
    (配置は従来と同じ)．中間 `.typ` に `grid.cell(x:…, y:…, colspan:…, rowspan:…)` が
    出ていることも確認．

- 2026-08-31 09:40 (x280-home)
  **`grid:` (座標で配置) と `subtitle`・`logo`・`accent` に対応した** (ユーザ指示の5・6)．
  - **Quarto 1.4 が同梱する Typst は 0.10 で `grid.cell` が無い**ことが分かった
    (実機で確認．`error: function grid does not contain field cell`)．
    colspan/rowspan が書けないので，**ギロチン分割**で組む — 箱をまたがない縦の
    切れ目を探して `#grid` の2列に分け，無ければ横の切れ目で上下に分け，再帰する．
    切れ目が1つも無い配置だけは組めないので，箱の名前を挙げてエラーにする．
    **Quarto を上げて Typst 0.11 以降になれば `grid.cell` の素直な対応に置き換えてよい**．
  - **`grid` も Quarto の予約キーだった** (`orientation` と同種)．
    `validate-yaml: false` を書けば通る．**キー名を変えると3つで揃わなくなる**ので，
    検証を切るほうを採った (README に明記)．
  - **差し色は `#` を落として渡す**．Typst の writer が補間した `#` を逃がすため，
    `rgb("#1a7a3c")` がそのままでは通らない
    (`error: color string contains non-hexadecimal letters`)．
    `boxes.lua` で先頭の `#` を落とし，`typst-show.typ` で `rgb("#" + "...")` と組む．
  - `subtitle`・`logo` は peace-of-posters の `title-box` の `subtitle:`・`image:` に渡す．
    差し色は `pop.update-theme(heading-box-args: ...)` で見出し帯だけ差し替える．
  - **検証**: 見本 `poster_grid.qmd` を新設し，PNG に起こして目視確認
    (はじめに=左2列，方法|調査地=横並び，まとめ=左2列，結果一覧=右列3行ぶん)．
    ロゴ・差し色も別途目視確認．書き間違い (重なり・名前の食い違い) が
    名指しで止まることも確認．`poster.qmd` は 397,349 bytes のまま変わらず．

- 2026-08-31 06:30 (このセッション，x280-home)
  **ggposter・acposter とヘッダーのキー名を揃えた** (ユーザ確定の 1・2・c)．
  3系統の比較は `todo/.claude/notes/poster_tools.md` にある．
  `boxes.lua` に `Meta` フィルタを足し，`author`/`institute`/`note`/`columns`/`font-size`
  を正として，従来の `poster-authors`・`institutes`・`footer`・`cols`・`size` を
  別名として受ける (内部で従来のキーへ寄せるので `typst-show.typ` は変更なし)．
  `poster.qmd` と README を正のキー名に書き換えた．
  **`size` を正にしないのは，ggposter が `size` を用紙の意味で使っているため**．
  - **検証**: 正のキー名で `poster.pdf` を作り直して**変更前と同じ 397,349 bytes**，
    旧キー名だけで書いた原稿と正のキー名だけで書いた原稿も**同じ 193,465 bytes**
    (PDF には時刻が入るのでハッシュは毎回変わる．大きさで見るのが正しい)．
  - **`orientation` は受けないことにした**．peace-of-posters の `layout-a0` が縦固定な
    うえ，**`orientation` は Quarto 自身が予約していて (値は `rows`/`columns`)，
    `landscape` と書くと Quarto の YAML 検証がフィルタより先に弾く**
    (警告を出そうとして気づいた)．README にも書いた．
  - **`grid:` は qtposter には無い**．ggposter と acposter では同じ書式なので，
    その2つの間では「移し替えの共通形」として使える．
  - **まだ揃っていないもの** (キー名ではなく機能の差): `subtitle`・ロゴ・差し色は
    qtposter に無い (ggposter にはある)．必要になったら `typst-template.typ` に足す．

- 2026-08-30 08:03 (このセッション，x280-home)
  **peace-of-posters を出発点にすると決め (ユーザ確定)，Quarto 拡張の最小版を作って A0 の
  日本語ポスターを1枚組めるところまで確かめた**．`# 見出し` = 箱，`{.break}` = 段送り，
  画像は既定で段幅いっぱい．検証3点 (日本語フォント・A0 の段組み・図) はすべて通った．
  踏んだ罠3つは notes に記録した (拡張は `template:` ではなく `template-partials:`，
  Quarto が画像を原寸 pt で焼き込む，`columns` は自動で段を分けない)．

- 2026-08-30 07:30 (x280-home)
  ディレクトリを作り `.claude/CLAUDE.md` を置いた．**Quarto + Typst のポスター作例の調査**に着手．

### 次にやること

**【決定 2026-08-30】出発点は peace-of-posters (ユーザ確定)**．
座標型の poster-syndrome は v0.1.0 の単発リリースで，中身が動く学会ポスターには
枠の手直しが残るため採らない．非対称が要る箇所は Typst 素の `grid` (`colspan`/`rowspan`) で足す．

- **【2026-08-31】X280 の2台 (`x280-kwu`・`x280-home`) の Quarto を上げる**．
  qtposter は **Quarto 1.5 以降が要る**ようになった (peace-of-posters 0.6.0 も
  `grid.cell` も Typst 0.11 以降)．1.4 のままだと `poster.qmd` すら組めない．
  上げ方は `winget upgrade --id Posit.Quarto` (MATUTOSI_DP では 1.10.18 が入った)．
  **旧版がユーザ領域 (`AppData\Local\Apps\Quarto`) に残ると PATH はそちらを向く**ので，
  `quarto --version` で確かめる (向いていなければフルパスで呼ぶか，旧版を消す)．
- **【要判断】acposter (pandoc+Chrome) との棲み分け**．どちらを主にするかは未決．
- **【点検 2026-08-31】acposter と比べて足りないもの** (実際に組んで確かめた．
  検証用の qmd は残していない)．
  1. ~~`::: row` (画像の横並び)~~ → **`::: {layout-ncol=2}` で並ぶ** (2026-08-31 に確認．
     Quarto の記法をそのまま使う．見本 `poster_howto.qmd` で実演)．
  2. **`{.full}` (全幅の箱)** が無い．書いても効かず，ふつうの箱になる．
     `grid:` を使えば `w:` で同じことができる．
  3. ~~画像の救済が無い~~ → **2026-08-31 に足した** (`Link` フィルタ．acposter と同じ約束)．
  4. **画像の高さの上限** (acposter の `--fig-max-h` 相当) が無い．
     いまは見本側で `{width=…%}` を書いて抑えている．
  5. ~~検算が無い~~ → **2026-08-31 に `check_poster_pdf.ps1` を足した**
     (ページ数・用紙実寸・埋め込みフォント．出力の文言は acposter に揃えた)．
  6. **表の体裁**が pandoc 既定の全罫線．acposter・ggposter は booktabs 調．
  7. ~~見本が2本~~ → **2026-08-31 に4本へ揃えた** (acposter・ggposter と同じ内容・同じ順)．
  8. ~~CI が無い~~ → **2026-08-31 に足した** (`.github/workflows/test.yml`．
     Ubuntu・macOS で見本4本を組み，欧文の目印で中身を確かめ，検算まで走らせる)．
  - 動くことを確かめたもの: 表・箇条書き (入れ子も)・コードブロック (色つき)・
    画像・数式・`{.break}`・`grid:`・副題・ロゴ・差し色．
  - **向き (`orientation`) は仕様上できない** (peace-of-posters の layout-a0 が縦固定，
    かつ Quarto の予約キー)．
- **【決定 2026-08-31】独立リポジトリにした** (ユーザ確定)．`git init` ＋ GitHub `matutosi/qtposter` (Private)．
  親リポジトリは許可制の `.gitignore` なので，親からは追跡されない．
- 次の一手の候補: 非対称配置 (`grid` の `rowspan`) を md から書けるようにする，
  実データの原稿で1枚組んでフォントサイズの当たりを取る．
- 詳しくは [notes/survey_quarto_typst.md](../notes/survey_quarto_typst.md)．
