# qtposter

**Quarto + Typst で学会用のポスター (A0) を組む**ための最小の拡張．

**Quarto 1.5 以降が要る** (2026-08-31 に確認した動作環境は 1.10.18 / Typst 0.15.1)．
組版に使う peace-of-posters 0.6.0 も `grid.cell` も **Typst 0.11 以降**の機能なので，
Quarto 1.4 (Typst 0.10) では組めない．

組版は [peace-of-posters](https://github.com/jonaspleyer/peace-of-posters) (MIT) に任せ，
qtposter は **Markdown の書き方を決める薄い層**だけを持つ．

## 使い方

```powershell
quarto render poster.qmd
```

`poster.qmd` の YAML で用紙・段数・書体を決める．

```yaml
title: "半自然草原の植生と管理"
subtitle: "管理の頻度と種組成"   # 省略可
author: ["松村 俊和"]
institute: "所属機関名"
paper: "a0"      # 用紙
columns: 3       # 段数
font: "Yu Gothic"
font-size: 32pt
note: "植生学会第30回大会"
logo: images/logo.png    # 省略可．表題帯の右に入る
accent: "#1a7a3c"        # 省略可．見出し帯の色 (既定は uni-fr の紺)
format: qtposter-typst
```

### キー名は姉妹ツールと共通 (別名でも通る)

同じ種類のポスターを作るツールが3系統ある
([ggposter](https://github.com/matutosi/ggposter)・acposter・qtposter)．
**ヘッダーのキー名は3つとも別名で受ける**ので，原稿を移し替えるときに書き直さずに済む．

| 意味 | 正 | 受ける別名 |
|---|---|---|
| 著者 | `author` | `authors`・`poster-authors` |
| 所属 | `institute` | `institutes`・`affiliation`・`affiliations` |
| 注記 | `note` | `funding`・`footer` |
| 段数 | `columns` | `cols` |
| 文字サイズ | `font-size` | `font_size`・`size` |
| 用紙 | `paper` | (無し) |
| 副題 | `subtitle` | (無し) |
| ロゴ | `logo` | (無し) |
| 差し色 | `accent` | (無し) |

**`size` を正にしない**のは，ggposter が `size` を**用紙**の意味で使っているため．
qtposter が元から使っていた `size` (文字サイズ) は別名として引き続き通る．

**向きは変えられない**．peace-of-posters の `layout-a0` が縦で固定なうえ，
`orientation` は Quarto 自身が予約していて (値は `rows`/`columns`)，
`landscape` と書くと Quarto の YAML 検証がフィルタより先に弾く．

**箱の配置を座標で決める `grid:` は3つとも同じ書式**で書ける
(qtposter は 2026-08-31 に対応．下の「非対称な配置」を見る)．
`grid:` を書かないときの段の切れ目は `{.break}` で決める．
3つの比較は `todo/.claude/notes/poster_tools.md` にある．

## 書き方の約束

- **`# 見出し` が1つの箱**になる (acposter の `build-poster-pdf` と同じ約束)．
- **`# 見出し {.break}` と書くと，その箱から次の段へ送る**．
  Typst の `columns` は「あふれたら次の段」なので，**A4 換算で余裕のある A0 では自動で分かれない**．
  段の切れ目は書き手が決める．
- **画像の幅は既定で段幅いっぱい**になる．`![図](a.png){width=60%}` と書けばその指定が優先される．

## 非対称な配置 (`grid:`)

段組みの流し込みではなく，**箱の位置を座標で決めたい**ときは `grid:` を書く．
**acposter・ggposter とまったく同じ書式**なので，配置ごと移し替えられる．

```yaml
grid:
  columns: 3
  boxes:
    - {name: はじめに, x: 0, y: 0, w: 2}   # 左2列ぶんの幅
    - {name: 結果一覧, x: 2, y: 0, h: 3}   # 右列で3行ぶんの高さ
    - {name: 方法,     x: 0, y: 1}
    - {name: 調査地,   x: 1, y: 1}
    - {name: まとめ,   x: 0, y: 2, w: 2}
validate-yaml: false
```

- `x`・`y` は **0 から数える**．`w`・`h` を省くと 1．
- **`validate-yaml: false` が要る**．`grid` は **Quarto 自身が予約しているキー**
  (HTML 版面の `sidebar-width` などを書くもの) なので，これを付けないと
  Quarto の YAML 検証がフィルタより先に弾く．**キー名を変えると3つのツールで
  揃わなくなる**ので，検証を切るほうを採った．
- 書き間違い (重なり・右へのはみ出し・本文の見出しと `boxes` の食い違い) は
  **名指しでエラーにして止める**．
- `{.break}` は `grid:` を使うときは効かない (配置は `grid:` が決める)．警告が出る．
- 見本は [`poster_grid.qmd`](poster_grid.qmd)．

### 仕組み (`grid.cell` に渡すだけ)

座標をそのまま Typst の `grid.cell(x:, y:, colspan:, rowspan:)` に渡す．
**どんな配置でも組める** (組めない配置は無い)．

2026-08-31 までは**ギロチン分割** (箱をまたがない切れ目で再帰的に割る) で組んでいた．
Quarto 1.4 が同梱する Typst 0.10 に `grid.cell` が無かったためで，
**縦にも横にも切れ目が無い配置は組めない**という制限があった．
Quarto 1.10 (Typst 0.15) へ上げてこの制限は無くなった．

## 中身を見たいとき

`_extensions/qtposter/_extension.yml` に `keep-typ: true` を足すと，
pandoc が作った `poster.typ` が残る (acposter の `-KeepHtml` にあたる)．

## 構成

| ファイル | 中身 |
|---|---|
| `_extensions/qtposter/_extension.yml` | 形式の定義 |
| `_extensions/qtposter/typst-template.typ` | peace-of-posters を呼ぶ関数 (`qtposter`) |
| `_extensions/qtposter/typst-show.typ` | YAML を関数の引数へ渡す |
| `_extensions/qtposter/boxes.lua` | `# 見出し` → 箱，`{.break}` → 段送り，画像の幅の既定値，ヘッダーのキー名の別名 |
| `poster.qmd` | 最小の見本 (段組みの流し込み) |
| `poster_howto.qmd` | **見本1: 機能の一巡り**．箱・段送り・表・図・図の横並びを1つずつ実演する |
| `poster_howto2.qmd` | **見本2: 入力と出力の早見表**．左の列に qmd へ書くもの，右の列にその結果 |
| `poster_howto3.qmd` | **見本3: 非対称な配置**．`grid:` の座標指定と，段組みとの使い分け |
| `golf_course.qmd` | **見本4: 実際のポスターに近い例** (架空のデータ)．`grid:` で非対称に置く |
| `images/` | 見本が使う仮の画像 |

**見本4本は ggposter・acposter と同じ内容・同じ順で揃えてある** (2026-08-31)．
acposter の `examples/` の4本，ggposter の `inst/extdata/poster_sample*.yml` が対応する．
「同じポスターを3つの書き方で書くとこうなる」を見比べられる．
