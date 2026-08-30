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

- 2026-08-31 09:40 (このセッション，x280-home)
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

- **【要判断】acposter (pandoc+Chrome) との棲み分け**．どちらを主にするかは未決．
- **【点検 2026-08-31】acposter と比べて足りないもの** (実際に組んで確かめた．
  検証用の qmd は残していない)．
  1. **`::: row` (画像の横並び)** が無い．書いても縦に並ぶ．
  2. **`{.full}` (全幅の箱)** が無い．書いても効かず，ふつうの箱になる．
     `grid:` を使えば `w:` で同じことができる．
  3. **画像の救済**が無い．`!` を付け忘れた `[説明](図.png)` はただの文字列になる
     (acposter は拡張子を見て画像に直す)．
  4. **画像の高さの上限** (acposter の `--fig-max-h: 30vh` 相当) が無い．
  5. **検算が無い**．acposter はページ数・用紙実寸・箱の数・埋め込みフォントを表示するが，
     qtposter は `quarto render` 任せ．
  6. **表の体裁**が pandoc 既定の全罫線．acposter・ggposter は booktabs 調．
  7. **見本が2本** (acposter は4本)．
  8. **CI が無い** (acposter は GitHub Actions で Mac/Linux のビルドを確かめている)．
  - 動くことを確かめたもの: 表・箇条書き (入れ子も)・コードブロック (色つき)・
    画像・数式・`{.break}`・`grid:`・副題・ロゴ・差し色．
  - **向き (`orientation`) は仕様上できない** (peace-of-posters の layout-a0 が縦固定，
    かつ Quarto の予約キー)．
- **【決定 2026-08-31】独立リポジトリにした** (ユーザ確定)．`git init` ＋ GitHub `matutosi/qtposter` (Private)．
  親リポジトリは許可制の `.gitignore` なので，親からは追跡されない．
- 次の一手の候補: 非対称配置 (`grid` の `rowspan`) を md から書けるようにする，
  実データの原稿で1枚組んでフォントサイズの当たりを取る．
- 詳しくは [notes/survey_quarto_typst.md](../notes/survey_quarto_typst.md)．
