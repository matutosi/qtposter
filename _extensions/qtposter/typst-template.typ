// qtposter: peace-of-posters を使う Quarto 用の薄いテンプレート．
#import "@preview/peace-of-posters:0.6.0" as pop

#let qtposter(
  title: "",
  subtitle: none,
  authors: "",
  institutes: "",
  paper: "a0",
  cols: 3,
  font: "Yu Gothic",
  size: 32pt,
  footer: none,
  logo: none,
  accent: none,
  margin: 2cm,
  fig-max-height: 25%,
  doc,
) = {
  // ページ番号は消す (Quarto の既定は "1"．ポスターは1枚なので要らない)．
  // **注記の帯 (footer) はページの下端に置く**．本文の流れの最後に置くと，
  // 箱が紙面いっぱいになったときに帯だけが2ページ目へ溢れる (2026-08-31 に実例)．
  set page(
    paper: paper,
    margin: margin,
    numbering: none,
    footer-descent: 0pt,
    // 帯は下の余白に置くので，本文より小さくして2行でも収まるようにする．
    footer: if footer != none { pop.bottom-box()[#text(size: 0.6em)[#footer]] },
  )
  set text(font: font, size: size, lang: "ja")

  // **表は booktabs 調にする** (acposter・ggposter と同じ見た目)．
  // Quarto の既定は全罫線で，3系統のうち qtposter だけ見た目が違っていた．
  // 引くのは**上端・見出しの下・下端の3本だけ**．縦罫は引かない．
  // (Quarto は見出しの下に `table.hline()` を自分で入れるので，ここでは
  //  上端と下端を `stroke` の関数で描く．)
  set table(
    stroke: (x, y) => (
      top: if y == 0 { 0.08em } else { none },
      bottom: none,
    ),
    inset: 0.3em,
  )
  show table: it => block(stroke: (bottom: 0.08em), inset: (bottom: 0.15em), it)
  // 図は箱の幅に収める (既定では原寸で組まれ，箱からはみ出す)．
  set image(width: 100%)

  // **図の高さの上限**．幅を合わせただけだと，縦長の画像1枚で箱が伸びきり，
  // 後ろの箱が紙面から溢れる (acposter の `--fig-max-h` と同じ役目)．
  // 上限は**その箱に使える高さ** (`layout()` が返す，段の残りの高さ) の割合で決める．
  // 収まらない画像は縦横の比を保ったまま縮める (`scale`)．
  // ヘッダーの `fig-max-height:` (例 `30%`) で変えられる．
  show image: it => layout(size => {
    let cap = size.height * fig-max-height
    let m = measure(it)
    if m.height > cap and cap > 0pt {
      let f = cap / m.height
      box(width: m.width * f, height: cap,
          scale(x: f * 100%, y: f * 100%, origin: top + left, it))
    } else {
      it
    }
  })
  pop.set-poster-layout(pop.layout-a0)
  pop.set-theme(pop.uni-fr)
  // 差し色は見出し帯の塗りと枠だけを差し替える (uni-fr の他の設定は残す)．
  if accent != none {
    pop.update-theme(
      heading-box-args: (inset: 0.6em, width: 100%, fill: accent, stroke: accent),
    )
  }

  pop.title-box(
    title,
    subtitle: subtitle,
    authors: authors,
    institutes: institutes,
    logo: logo,
  )
  // **段組みはフィルタ側が掛ける** (`boxes.lua`)．`{.full}` の箱で段組みを
  // いったん閉じて全幅で置き，また開き直す必要があるため，ここでは掛けない．
  // `cols` はフィルタが読む (typst-show.typ 経由で渡ってくる値と同じもの)．
  doc
}
