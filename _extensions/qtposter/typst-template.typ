// qtposter: peace-of-posters を使う Quarto 用の薄いテンプレート．
#import "@preview/peace-of-posters:0.6.0" as pop

// 著者と所属から「氏名(所属)」の行を作る (acposter の `make_byline` と同じ規則)．
// 所属が1つなら全員の後ろに1つだけ付け，複数なら著者ごとに対にする．
#let byline(authors, institutes) = {
  if authors.len() == 0 { return none }
  if institutes.len() == 0 { return authors.join([・]) }
  if institutes.len() == 1 { return authors.join([・]) + [(] + institutes.at(0) + [)] }
  authors
    .enumerate()
    .map(((i, a)) => a + [(] + institutes.at(calc.min(i, institutes.len() - 1)) + [)])
    .join([・])
}

// 用紙に合った版面を選ぶ．**`paper` を受けるのに `layout-a0` 決め打ちだった** (2026-09-02 に修正)．
// peace-of-posters の版面は表題・見出し・本文の文字寸法を用紙ごとに持っているので
// (a0 は表題 75pt，a1 は 53pt)，A1 に a0 の版面を当てると字だけ大きいまま組まれていた．
#let layout-for(paper) = {
  if paper == "a1" { pop.layout-a1 }
  else if paper == "a2" { pop.layout-a2 }
  else if paper == "a3" { pop.layout-a3 }
  else if paper == "a4" { pop.layout-a4 }
  else { pop.layout-a0 }
}

#let qtposter(
  title: "",
  subtitle: none,
  authors: (),
  institutes: (),
  paper: "a0",
  font: "Yu Gothic",
  // 既定は用紙に合った本文の寸法 (a0 なら 33pt)．`font-size:` で変えられる．
  size: none,
  footer: none,
  logo: none,
  accent: none,
  margin: 2cm,
  fig-max-height: 25%,
  doc,
) = {
  // ページ番号は消す (Quarto の既定は "1"．ポスターは1枚なので要らない)．
  // **注記 (footer) は表題帯の中に入れる** (acposter と同じ位置．2026-08-31)．
  // ページの下端に別の帯として置くと，acposter・ggposter と見た目が揃わないうえ，
  // 本文の流れに置いた時期には箱が紙面いっぱいのときに帯だけが2ページ目へ溢れていた．
  // 表題帯の中なら，紙面がどれだけ詰まっても溢れない．
  let poster-layout = layout-for(paper)
  set page(
    paper: paper,
    margin: margin,
    numbering: none,
  )
  set text(
    font: font,
    size: if size != none { size } else { poster-layout.at("body-size") },
    lang: "ja",
  )

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
  pop.set-poster-layout(poster-layout)
  pop.set-theme(pop.uni-fr)
  // 差し色は見出し帯の塗りと枠だけを差し替える (uni-fr の他の設定は残す)．
  if accent != none {
    pop.update-theme(
      heading-box-args: (inset: 0.6em, width: 100%, fill: accent, stroke: accent),
    )
  }

  // **表題帯は中央揃えにし，著者と所属を「氏名(所属)」の1行にまとめる**
  // (acposter の `.title-band` と同じ見た目．2026-08-31 に3系統で揃えた)．
  // peace-of-posters の既定は左揃えで，著者と所属を別々の行に積む．
  // 注記は `keywords:` の枠を借りて，帯のいちばん下に小さく置く．
  {
    set align(center)
    pop.title-box(
      title,
      subtitle: subtitle,
      authors: byline(authors, institutes),
      institutes: none,
      keywords: if footer != none { text(size: 0.5em)[#footer] },
      logo: logo,
    )
  }
  // **段組みはフィルタ側が掛ける** (`boxes.lua`)．`{.full}` の箱で段組みを
  // いったん閉じて全幅で置き，また開き直す必要があるため，ここでは掛けない．
  // `cols` はフィルタが読む (typst-show.typ 経由で渡ってくる値と同じもの)．
  doc
}
