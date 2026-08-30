# qtposter

**Quarto + Typst で学会用のポスター (A0) を組む**ための最小の拡張．
組版は [peace-of-posters](https://github.com/jonaspleyer/peace-of-posters) (MIT) に任せ，
qtposter は **Markdown の書き方を決める薄い層**だけを持つ．

## 使い方

```powershell
quarto render poster.qmd
```

`poster.qmd` の YAML で用紙・段数・書体を決める．

```yaml
title: "半自然草原の植生と管理"
author: ["松村 俊和"]
institute: "所属機関名"
paper: "a0"      # 用紙
columns: 3       # 段数
font: "Yu Gothic"
font-size: 32pt
note: "植生学会第30回大会"
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

**`size` を正にしない**のは，ggposter が `size` を**用紙**の意味で使っているため．
qtposter が元から使っていた `size` (文字サイズ) は別名として引き続き通る．

**向きは変えられない**．peace-of-posters の `layout-a0` が縦で固定なうえ，
`orientation` は Quarto 自身が予約していて (値は `rows`/`columns`)，
`landscape` と書くと Quarto の YAML 検証がフィルタより先に弾く．

**箱の配置を座標で決める `grid:` は qtposter には無い** (ggposter と acposter にはあり，
両者で同じ書式)．qtposter で段の切れ目を決めるのは `{.break}` だけ．
3つの比較は `todo/.claude/notes/poster_tools.md` にある．

## 書き方の約束

- **`# 見出し` が1つの箱**になる (acposter の `build-poster-pdf` と同じ約束)．
- **`# 見出し {.break}` と書くと，その箱から次の段へ送る**．
  Typst の `columns` は「あふれたら次の段」なので，**A4 換算で余裕のある A0 では自動で分かれない**．
  段の切れ目は書き手が決める．
- **画像の幅は既定で段幅いっぱい**になる．`![図](a.png){width=60%}` と書けばその指定が優先される．

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
| `poster.qmd` | 検証用の見本 |
| `images/` | 見本が使う仮の画像 |
