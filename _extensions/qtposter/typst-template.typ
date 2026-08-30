// qtposter: peace-of-posters を使う Quarto 用の薄いテンプレート．
#import "@preview/peace-of-posters:0.5.0" as pop

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
  doc,
) = {
  set page(paper: paper, margin: margin)
  set text(font: font, size: size, lang: "ja")
  // 図は箱の幅に収める (既定では原寸で組まれ，箱からはみ出す)．
  set image(width: 100%)
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
    image: logo,
  )
  columns(cols, doc)
  if footer != none { pop.bottom-box()[#footer] }
}
