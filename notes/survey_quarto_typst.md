# Quarto + Typst で学会ポスターを作る例の調査

2026-08-30 調査 (日本語・英語の両方)．
一次情報は Web のみ (手元で動かしての検証はまだしていない)．

## 要点 (先に結論)

- **道具立ては大きく3系統**．
  1. Quarto 公式の Typst テンプレート (`quarto-ext/typst-templates/poster`)．最も手軽だが素っ気ない．
  2. Typst 側のポスター用パッケージ (`typst-poster`・`peace-of-posters` ほか) を Quarto から呼ぶ．
  3. `typst-template.typ` を自分で書き換えた自作拡張 (higgi13425/quarto_poster など)．
- **速さと版管理のしやすさは，ほぼ全員が良い点として挙げる**．LaTeX より速く，ソースがテキストなので差分で追える．
- **困りごとは「レイアウトの微調整」と「相互参照」と「印刷入稿」に集中する**．
  段組みからのはみ出し，フォントサイズの手動調整，Typst 出力での相互参照の不備，CMYK 非対応．
- **日本語は Typst 自体は得意** (禁則処理は良好・フォントは埋め込まれる)．
  ただし**フォント名の指定と探索パスでつまずく**のは要旨・スライドのスキルと同じ罠．

## 1. どのようなポスターを作っているのか

| 例 | 何を作っているか | 特徴 |
|---|---|---|
| [quarto-ext/typst-templates/poster](https://github.com/quarto-ext/typst-templates/tree/main/poster) | Quarto 公式の薄いラッパ．`quarto use template quarto-ext/typst-templates/poster` で雛形が出る | YAML で `size` (例 `"36x24"`)・`poster-authors`・`departments`・`institution-logo`・`footer-text`/`-url`/`-emails`/`-color`・`keywords` を指定．縦横どちらも可 |
| [pncnmnp/typst-poster](https://github.com/pncnmnp/typst-poster) | Typst 単体の学術ポスターテンプレート．Quarto から呼ぶ例が多い | 段数を引数で指定 (既定3段)．題・著者・フッタのフォントサイズを個別に調整できる．ロゴは 1080x170 px 前提 |
| [higgi13425/quarto_poster](https://github.com/higgi13425/quarto_poster) | 実物大の研究ポスター一式．60x30・72x30・72x36 インチと**ユーロ A0 (33x47 インチ)** | サイズごとに `.qmd` を用意し，`_extensions/` の `typst-template.typ` が体裁を持つ．R/RStudio の Render ボタンで PDF |
| [blag.bapt.xyz の授業ポスター](https://blag.bapt.xyz/posts/typst-posters/) | 授業紹介のポスターを**25枚まとめて**生成 | Quarto プロジェクトに入れて一括レンダ．LaTeX より大幅に速いと報告 |
| [ペパボ研究所ブログ](https://rand.pepabo.com/article/2026/06/15/typst/) (2026-06-15) | JSAI2026 の発表スライドと**研究所紹介の A0 ポスター** | 共通テンプレートでスライドとポスターの体裁をそろえる．図は CeTZ (TikZ 相当) でコード化．**コーディングエージェントとの相性の良さ**を前面に出している |
| Typst Universe のパッケージ群 | [peace-of-posters](https://typst.app/universe/package/peace-of-posters/)・[postercise](https://typst.app/universe/package/postercise/)・[simple-research-poster](https://typst.app/universe/package/simple-research-poster/)・[placard](https://typst.app/universe/package/placard/)・[poster-syndrome](https://typst.app/universe/package/poster-syndrome/) | 任意の用紙・段数・縦横に対応するもの (simple-research-poster)，箱と段の組み合わせで組むもの (peace-of-posters)，配置を座標で決めるもの (poster-syndrome) など，**設計思想が分かれている** |

**作り方の型はおおむね共通**する．
YAML に題・著者・所属・ロゴ・用紙寸法を書き，本文は Markdown の見出しで区切り，段組みはテンプレートが流し込む．
R や Python の図はコードチャンクから直接埋める．

## 2. 困っている点

### Quarto と Typst のつなぎ目

- **相互参照 (`@fig-...`) が Typst 出力で崩れることがある**．
  参照ラベルの書き換え (`[-@fig-elephant]` で「図」の接頭辞を外す) は
  LaTeX 経由の PDF と HTML では効くが，**Typst では効かない** ([quarto-cli#12258](https://github.com/quarto-dev/quarto-cli/issues/12258))．
  参照そのものが通らないという報告もある ([Discussion #9921](https://github.com/orgs/quarto-dev/discussions/9921))．
  副図 (patchwork など) では参照の切れ目を `` `{=typst}` `` で補う回避策が要る．
- **段の幅を百分率で指定するとはみ出す**．Quarto 側で fraction 型に切り替える修正が入っている ([PR #11579](https://github.com/quarto-dev/quarto-cli/pull/11579))．
- ポスター形式そのものは長く**要望先行**だった ([Discussion #2205](https://github.com/orgs/quarto-dev/discussions/2205))．
  Paged.js での HTML 経由を待つ声もあったが，実際には Typst が先に実用になった．

### レイアウトの調整

- **フォントサイズを YAML で手で詰める**運用が前提 (higgi13425)．
  入りきらなければ縮める，という**目視での試行錯誤**が残る．
- **崩れたらテンプレート (`typst-template.typ`) を直す**必要がある．Markdown 側だけでは閉じない．
- 既定が3段のテンプレートを2段にすると，**他の既定値も併せて調整が要る** (typst-poster)．
- Typst 0.12 (2024-10) で段をまたぐ図の配置が入り，事情は改善した方向にある．

### Typst 自体の未成熟さ

[blag.bapt.xyz](https://blag.bapt.xyz/posts/typst-posters/) と [Zenn の製本用 PDF の記事](https://zenn.dev/nabetani/articles/c8deca489b4880) が具体的に挙げているもの．

- **CMYK のカラープロファイルが無視される** (出力は RGB)．
- **PDF 画像を貼れない** (図は PNG/SVG に変換して持ち込む)．
- 色の再定義が繰り返しできない，関数の定義順に制約がある．
- 縦方向の余白の計算が面倒．
- 図表番号を任意の値から始められない，相互参照のリンク文字列を作れない，縦書きは不可．
- 一方で**フォントはサブセットで確実に埋め込まれ，禁則処理は良好**という評価は一致している．

### 日本語

- Quarto 1.4 (2024-01) 以降 `format: typst` が使え，**LaTeX 系の日本語の面倒を避けられる**のが導入の動機になっている．
- **フォントは名前とパスの指定でつまずく**．
  `quarto typst fonts --font-path <フォントの置き場>` で**Typst が認識している名前**を確かめてから指定する，という手順が要る．
  (要旨スキルで UD デジタル教科書体の名前に引っかかったのと同じ種類の罠．)
- 学会ポスターの日本語書体は**ゴシック系1書体に絞る**のが定石 (メイリオ・UD ゴシック・ヒラギノ)．明朝は遠目に細って読めない．

## 3. 追加した観点 (調べていて必要だと思ったもの)

- **印刷入稿に耐えるか**．日本の印刷所は PDF/X-1a や PDF/X-4，CMYK，塗り足し3mm を求めることが多い．
  **Typst は現状 RGB 出力のみで，PDF/X も出せない**．
  学内のプロッタ出力や布ポスターなら問題になりにくいが，**印刷所へ入稿する運用なら別工程 (後段での変換) が要る**．
- **図の解像度**．A0 は原寸が大きいので，R の図は `dpi` と文字サイズを原寸基準で決めないと，画面で良くても印刷でつぶれる．
- **崩れの検出をどうするか**．
  はみ出し・空きすぎは PDF を見るまで分からない．acposter では**目視運用**と決めた経緯があるので，同じ判断でよいか揃える．
- **エージェントとの相性**．
  ペパボ研の記事が明示している通り，**テキストのソースであること**が生成・修正を任せやすい最大の理由になっている．
  この観点は qtposter を作る動機そのものに関わる．
- **既存プロジェクトとの棲み分け**．
  `../acposter` (pandoc + ヘッドレス Chrome，CSS で組む)，`../docposter` (Quarto + `_extensions` の既存一式)，
  `../ggposter` (R/ggplot2) と**目的が重なる**．qtposter を Typst 系として立てるなら，**どれを主にするかを決めておく**必要がある．
  - 固定版面のポスターでは，**CSS は固定版面向けの思想ではない**という指摘 (ペパボ研) が acposter 方式の弱点を突いている．
  - 逆に Typst 方式は**記法を1つ覚える必要**があり，CSS の知識は使えない．

## 4. qtposter への示唆 (案，未確定)

- 出発点は **`simple-research-poster` か `peace-of-posters`** が有力．任意用紙・任意段数に素直に対応し，箱で組めるため．
  公式テンプレートは体裁の自由度が低く，A0 の日本語ポスターには手を入れる前提になる．
- **最初に確かめるべきは3点**: (1) 日本語フォントの指定が通るか，(2) A0 で段組みが崩れないか，(3) R の図を原寸で入れたときの解像度．
- 相互参照は**ポスターでは使わない**割り切りも成り立つ (図番号を本文から参照しない構成にする)．

## 出典

- [quarto-ext/typst-templates (poster)](https://github.com/quarto-ext/typst-templates/tree/main/poster)
- [Quarto: Typst Basics](https://quarto.org/docs/output-formats/typst.html) / [Custom Typst Formats](https://quarto.org/docs/output-formats/typst-custom.html)
- [Quarto Discussion #2205 (ポスターは作れるか)](https://github.com/orgs/quarto-dev/discussions/2205)
- [Quarto Discussion #9921 (Typst で相互参照が効かない)](https://github.com/orgs/quarto-dev/discussions/9921) / [Issue #12258](https://github.com/quarto-dev/quarto-cli/issues/12258) / [PR #11579](https://github.com/quarto-dev/quarto-cli/pull/11579)
- [pncnmnp/typst-poster](https://github.com/pncnmnp/typst-poster)
- [higgi13425/quarto_poster](https://github.com/higgi13425/quarto_poster)
- [blag.bapt.xyz: course poster templates](https://blag.bapt.xyz/posts/typst-posters/)
- [ペパボ研究所: Typst のすゝめ (2026-06-15)](https://rand.pepabo.com/article/2026/06/15/typst/)
- [Zenn: Typst で製本用 PDF を作りたい](https://zenn.dev/nabetani/articles/c8deca489b4880)
- Typst Universe: [peace-of-posters](https://typst.app/universe/package/peace-of-posters/) / [postercise](https://typst.app/universe/package/postercise/) / [simple-research-poster](https://typst.app/universe/package/simple-research-poster/) / [placard](https://typst.app/universe/package/placard/) / [poster-syndrome](https://typst.app/universe/package/poster-syndrome/)
- [R for the Rest of Us: High-Quality PDFs with Quarto and Typst (2025-11)](https://rfortherestofus.com/2025/11/quarto-typst-pdf)

## 5. 非対称なレイアウト (acposter の `poster_howto3` 相当) はあったか

**結論: Quarto + Typst の「ポスターの作例」としては見当たらなかった**．
ただし**Typst の側には手段があり，表現力ではむしろ素直**である (下表)．

| 手段 | 座標で置けるか | 縦またがり (rowspan) | 全幅の箱 | howto3 との近さ |
|---|---|---|---|---|
| [poster-syndrome](https://typst.app/universe/package/poster-syndrome/) | **できる**．`(x: 60, y: 563, width: 500, height: 55)` の辞書でフレームを定義 | 座標指定なので不要 | できる | **最も近い**．acposter の `grid:` と同じ発想．Figma で矩形を描いて座標を書き出す運用を想定している |
| Typst 素の `grid` | **できる**．`grid.cell(x:, y:, colspan:, rowspan:)` | **`rowspan` で直接書ける** | `colspan` で書ける | 組版エンジンの標準機能なので確実 |
| [peace-of-posters](https://typst.app/universe/package/peace-of-posters/) | できない (段組み方式) | 不可．代わりに `stretch-to-next: true` で高さの凸凹を吸収 | `columns()` の外に `column-box()` を置く，`bottom-box()` で下部全幅 | **中間**．全幅の箱と高さ揃えは書けるが，右に縦3行またがりの箱は無理 |
| [quarto-ext の公式ポスター](https://github.com/quarto-ext/typst-templates/tree/main/poster)・[typst-poster](https://github.com/pncnmnp/typst-poster)・[higgi13425](https://github.com/higgi13425/quarto_poster) | できない | 不可 | テンプレート次第 | **遠い**．いずれも**N段への流し込み**が基本で，箱の位置は本文の順序で決まる |
| Quarto の `layout="[[1,1],[1]]"` 記法 | できない (行と相対幅のみ) | **不可** | 行を1要素にすれば全幅 | acposter の `layout:` (行列) に相当．**howto3 の縦またがりは表せない** |

**含意**．

- 「上に2つ・下に全幅」程度の非対称なら，Quarto の `layout` 記法や peace-of-posters で足りる．
- **howto3 のような「右に縦3行またがり」は，座標指定 (poster-syndrome) か Typst 素の `grid` の `rowspan` が要る**．
- ただし**Quarto の md から `grid:` 相当を書くには，テンプレート側に受け口を自作する必要がある**．
  これは acposter で Lua フィルタ + CSS Grid に対してやったのと**同じ作業**になる
  (書き先が CSS ではなく `.typ` になるだけ)．
  つまり**非対称配置は Typst に乗り換える理由にはならない**．乗り換えの理由になるのは，
  固定版面向けの組版エンジンであること・日本語の禁則処理・図を CeTZ でコード化できることのほう．

## 6. テンプレート2種の比較 (peace-of-posters と poster-syndrome)

**設計思想が正反対の2つ**を比べる．流し込み型か，座標型か．

| | [peace-of-posters](https://github.com/jonaspleyer/peace-of-posters) (PoP) | [poster-syndrome](https://typst.app/universe/package/poster-syndrome/) |
|---|---|---|
| 考え方 | **箱を順に流し込む**．用紙・段数・向きを仮定しない | **枠を座標で先に決め**，名前で中身を流し込む |
| 書き方 | `set-poster-layout(layout-a0)` / `set-theme(uni-fr)` / `title-box(title, subtitle, authors, institutes, keywords)` / `column-box(heading, stretch-to-next)` / `bottom-box` | `#let frames = (title: (x: 60, y: 563, width: 500, height: 55), cover-image: (x: 60, y: 60, width: 500, height: 500), ...)` |
| 段組み | Typst の `columns()` + `colbreak()` | 概念として無い (座標がすべて) |
| 非対称な配置 | 全幅の箱・`bottom-box`・`stretch-to-next` まで．**縦またがりは不可** | **本領**．howto3 の「右に縦3行またがり」も自然に書ける |
| 内容が増減したとき | **自動で流れる**．崩れにくい | **枠の高さを手で直す**．あふれても勝手には伸びない |
| 外部ツール連携 | 無し | **Figma 等で矩形を描いて座標を書き出す**運用を想定 |
| テーマ | あり (`uni-fr` ほか)．`update-theme` で調整 | 配色・体裁を辞書で上書きする方式 |
| ライセンス | MIT | MPL-2.0 |
| 成熟度 | Typst Universe に長くあり，独立したドキュメントサイトを持つ | **v0.1.0 (2025-07-24) の1リリースのみ**．公式の互換保証は無いと明記 |
| 作者 | jonaspleyer | baptiste ([blag.bapt.xyz](https://blag.bapt.xyz/posts/typst-posters/) で25枚一括生成を書いた人と同一) |

**第3の候補**: [simple-research-poster](https://typst.app/universe/package/simple-research-poster/) (v0.2.0，2026-04-27，Typst 0.13 以上)．
任意用紙・任意段数・縦横に対応する素直な流し込み型で，**位置づけは PoP と同じ**．
`typst init @preview/simple-research-poster:0.2.0` で始められる．PoP より新しく，情報は少ない．

### どちらを採るか (案)

**PoP (流し込み型) を主にするのが妥当**と考える．理由は次の3点．

1. **学会ポスターは直前まで中身が動く**．文字数が変われば座標型は枠を手で直すことになる．
2. **成熟度の差が大きい**．poster-syndrome は 0.1.0 の単発リリースで，互換の保証も明記されていない．
3. **非対称が要る箇所だけ Typst 素の `grid` (`colspan`/`rowspan`) や `place` で足せる**．
   座標型を丸ごと採る必要は無い．

**逆に poster-syndrome が向くのは**，体裁を先に決めて中身を後から詰める作り方をするとき
(Figma でデザインしてから流し込む，同じ枠で複数枚を量産する)．
[blag.bapt.xyz の25枚一括生成](https://blag.bapt.xyz/posts/typst-posters/) がまさにこの使い方にあたる．

## 7. 実際に組んで分かった罠 (2026-08-30，試作時)

peace-of-posters で A0 の日本語ポスターを1枚組んで確かめた．**調査だけでは出てこなかった罠が3つ**あった．

1. **Quarto の拡張は `template:` ではなく `template-partials:` に両方を並べる**．
   `template: typst-template.typ` と書くと，それが pandoc テンプレートそのものとして使われ，
   **本文が消えた PDF (A4・空)** ができる．エラーにならないので気づきにくい．
   正しくは `template-partials:` に `typst-show.typ` と `typst-template.typ` の**両方**を並べる．
2. **Quarto は幅の指定が無い画像を原寸の pt で焼き込む**．
   生成された `.typ` には `#box(width: 900.0pt, image("images/nmds.png"))` と出る．
   A0 の段幅を超えて隣の段に重なる．`set image(width: 100%)` を書いても**この box が優先されて効かない**．
   Lua フィルタで画像に `width="100%"` を与えるのが確実 (書き手の `{width=60%}` は尊重する)．
3. **Typst の `columns` は「あふれたら次の段」なので，A0 では自動で段が分かれない**．
   内容が1段に収まると，右の2段が丸ごと空くだけになる．
   段の切れ目は `#colbreak()` を明示する必要がある (qtposter では `# 見出し {.break}` に割り当てた)．

**確かめた3点の結果**．

- **日本語フォント**: `set text(font: "Yu Gothic", lang: "ja")` で通る．
  PDF には `YuGothic-Regular`・`YuGothic-Bold` がサブセットで埋め込まれた．禁則処理も正しい．
- **A0 の段組み**: 上の 3 のとおり，明示の段送りが要る．崩れはしない．
- **図**: 上の 2 の対処で段幅に収まる．解像度は元の PNG 次第 (A0 原寸で作る必要は残る)．

**版の情報**: Quarto 1.4.554 (同梱 Typst 0.10.0)・単体の Typst 0.11.1・peace-of-posters 0.5.0．
**同梱 0.10.0 でも peace-of-posters 0.5.0 は通った**．
