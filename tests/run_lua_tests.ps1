<#
.SYNOPSIS
  boxes.lua (Quarto の Typst 用 Lua フィルタ) の単体テスト．

.DESCRIPTION
  小さな md を pandoc に通し，出てきた Typst と，エラー・警告の文面を確かめる．
  **Quarto も Typst も Chrome も画像も要らない**ので速く，Windows / Mac / Linux の
  どれでも同じに走る (pandoc だけあればよい)．
  ポスターが「組めるか」ではなく「**書き間違いを黙って通さないか**」を主に見る．

  構成は acposter の `tests/run_lua_tests.ps1` と揃えてある (3系統で同じ書き方をするため)．
  違うのは出力が HTML ではなく Typst であることと，ヘッダーの値を見るために
  `tests/meta_probe.tpl` という小さなテンプレートを噛ませていること
  (Typst の出力そのものにはヘッダーの値が出ないため)．

.EXAMPLE
  pwsh -File tests/run_lua_tests.ps1
#>
[CmdletBinding()]
param([string]$Lua = '')

$ErrorActionPreference = 'Stop'
# 終了コードが0でない native コマンドで例外にしない (エラーの検査そのものが目的のため)．
$PSNativeCommandUseErrorActionPreference = $false

$root = Split-Path -Parent $PSScriptRoot
if (-not $Lua) { $Lua = Join-Path $root '_extensions/qtposter/boxes.lua' }
if (-not (Test-Path $Lua)) { throw "boxes.lua が無い: $Lua" }
$tpl = Join-Path $PSScriptRoot 'meta_probe.tpl'
if (-not (Test-Path $tpl)) { throw "meta_probe.tpl が無い: $tpl" }
if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) { throw 'pandoc が見つからない．' }

$tmpDir = Join-Path ([IO.Path]::GetTempPath()) ('qtposter-tests-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force $tmpDir | Out-Null

$script:passed   = 0
$script:failures = @()

function Invoke-Poster([string]$md) {
  $f  = Join-Path $tmpDir 'case.md'
  $ef = Join-Path $tmpDir 'stderr.txt'
  Set-Content -LiteralPath $f -Value $md -Encoding UTF8
  # `-implicit_figures` は Quarto に合わせるためではなく，図の caption で
  # 出力が膨らむのを避けるため (箱の組み立てを見るのが目的)．
  $out = & pandoc $f '--from=markdown-implicit_figures' '--to=typst' '--standalone' `
                  "--template=$tpl" "--lua-filter=$Lua" 2>$ef
  return @{
    Code = $LASTEXITCODE
    Out  = ($out -join "`n")
    Err  = ((Get-Content -LiteralPath $ef -Raw -ErrorAction SilentlyContinue) + '')
  }
}

function Test-Poster {
  param(
    [Parameter(Mandatory)][string]$Name,
    [Parameter(Mandatory)][string]$Md,
    [string[]]$Contains    = @(),   # 出力に必ずある文字列
    [string[]]$NotContains = @(),   # 出力にあってはいけない文字列
    [hashtable]$Count      = @{},   # 文字列 → 出てくる回数
    [string]$ErrorMatch    = '',    # これを含むエラーで止まるはず
    [string]$WarnMatch     = ''     # これを含む警告が出るはず (止まりはしない)
  )
  $r = Invoke-Poster $Md
  $bad = @()

  if ($ErrorMatch) {
    if ($r.Code -eq 0) {
      $bad += "エラーで止まるはずが通った (期待: $ErrorMatch)"
    } elseif ($r.Err -notmatch [regex]::Escape($ErrorMatch)) {
      $bad += "エラーの文面が違う (期待: $ErrorMatch / 実際: $($r.Err.Trim()))"
    }
  } elseif ($r.Code -ne 0) {
    $bad += "pandoc が失敗した: $($r.Err.Trim())"
  }

  if ($WarnMatch -and ($r.Err -notmatch [regex]::Escape($WarnMatch))) {
    $bad += "警告が出ていない (期待: $WarnMatch / 実際: $($r.Err.Trim()))"
  }
  foreach ($c in $Contains)    { if ($r.Out -notmatch [regex]::Escape($c)) { $bad += "出力に無い: $c" } }
  foreach ($c in $NotContains) { if ($r.Out -match    [regex]::Escape($c)) { $bad += "出力にある: $c" } }
  foreach ($k in $Count.Keys) {
    $n = ([regex]::Matches($r.Out, [regex]::Escape($k))).Count
    if ($n -ne $Count[$k]) { $bad += "$k の数が $n 個 (見込み $($Count[$k]) 個)" }
  }

  if ($bad.Count -eq 0) {
    $script:passed++
    Write-Host ('  ok   ' + $Name)
  } else {
    $script:failures += ($Name + "`n        - " + ($bad -join "`n        - "))
    Write-Host ('  FAIL ' + $Name) -ForegroundColor Red
  }
}

function Head([string]$s) { Write-Host ''; Write-Host $s -ForegroundColor Cyan }

# 各テストの md はこの前置きに本文を足して作る．
function New-Md([string]$header, [string]$body) { return "---`n$header---`n`n$body" }

# ============================================================ ヘッダーのキー名
Head 'ヘッダーのキー名 (3系統で揃えた別名)'

Test-Poster '正のキー (author / institute / note / columns / font-size) を受ける' `
  (New-Md "title: T`nauthor: [A, B]`ninstitute: [U]`nnote: 注記`ncolumns: 2`nfont-size: 26pt`n" "# One`n`na`n") `
  -Contains 'META|poster-authors|[A][B]', 'META|institutes|[U]', 'META|footer|注記',
            'META|cols|2', 'META|size|26pt'

Test-Poster '別名のキー (poster-authors / institutes / footer / cols / size) も受ける' `
  (New-Md "title: T`nposter-authors: [A]`ninstitutes: [U]`nfooter: F`ncols: 4`nsize: 30pt`n" "# One`n`na`n") `
  -Contains 'META|poster-authors|[A]', 'META|institutes|[U]', 'META|footer|F',
            'META|cols|4', 'META|size|30pt'

Test-Poster '正と別名が両方あれば正を採る' `
  (New-Md "title: T`nauthor: [新]`nposter-authors: [旧]`n" "# One`n`na`n") `
  -Contains 'META|poster-authors|[新]' -NotContains 'META|poster-authors|[旧]'

Test-Poster 'columns は消す (Quarto の段組みと二重にしない)' `
  (New-Md "title: T`ncolumns: 2`n" "# One`n`na`n") `
  -Contains 'META|columns|NONE', 'META|cols|2'

Test-Poster '差し色の先頭の # を落とす (Typst の rgb に渡すため)' `
  (New-Md "title: T`naccent: `"#1a7a3c`"`n" "# One`n`na`n") `
  -Contains 'META|accent|1a7a3c'

# ============================================================ 箱への切り分け
Head '箱への切り分け'

Test-Poster '# ごとに1つの箱になる' (New-Md "title: T`n" "# One`n`na`n`n# Two`n`nb`n") `
  -Count @{ '#pop.column-box(heading: [' = 2 } `
  -Contains '#pop.column-box(heading: [One])[', '#pop.column-box(heading: [Two])['

Test-Poster '最初の # より前の内容は箱の外に残す' (New-Md "title: T`n" "前置き`n`n# One`n`na`n") `
  -Contains '前置き', '#pop.column-box(heading: [One])['

Test-Poster '見出しが1つも無ければ箱は0個' (New-Md "title: T`n" "本文だけ`n") `
  -Count @{ '#pop.column-box(heading: [' = 0 } -Contains '本文だけ'

Test-Poster '段数の既定は3' (New-Md "title: T`n" "# One`n`na`n") -Contains '#columns(3)['

Test-Poster 'columns で段数が変わる' (New-Md "title: T`ncolumns: 2`n" "# One`n`na`n") `
  -Contains '#columns(2)['

Test-Poster '{.break} を付けた箱の前に colbreak が入る' `
  (New-Md "title: T`n" "# One`n`na`n`n# Two {.break}`n`nb`n") `
  -Count @{ '#colbreak()' = 1 }

Test-Poster '{.full} の箱は段組みをいったん閉じて外に出す' `
  (New-Md "title: T`n" "# One`n`na`n`n# Two {.full}`n`nb`n`n# Three`n`nc`n") `
  -Count @{ '#columns(3)[' = 2 }

Test-Poster '{.full} に {.break} を付けたら警告する' `
  (New-Md "title: T`n" "# One {.full .break}`n`na`n") `
  -WarnMatch '{.full} の箱に {.break} は要らない'

# ============================================================ 見出しの体裁
Head '見出しの体裁 (Typst の記法へ書き出す)'

Test-Poster '見出しの強調は Typst の記法で残る (学名の斜体)' `
  (New-Md "title: T`n" "# *Rubus* の分布`n`na`n") `
  -Contains '#pop.column-box(heading: [#emph[Rubus] の分布])['

Test-Poster '見出しの # は逃がす (Typst のコード開始と取り違えない)' `
  (New-Md "title: T`n" "# #1 の話`n`na`n") `
  -Contains '\#1 の話' -NotContains 'heading: [#1'

Test-Poster '見出しの角括弧は逃がす' (New-Md "title: T`n" "# 結果 [続き]`n`na`n") `
  -Contains '\[続き\]'

# ============================================================ 図・リンク
Head '図とリンクの扱い'

Test-Poster '幅の無い画像は 100% にする (原寸のはみ出しを防ぐ)' `
  (New-Md "title: T`n" "# One`n`n![a](x.png)`n") `
  -Contains 'image("x.png", width: 100.0%)'

Test-Poster '幅を書いた画像はそのまま' (New-Md "title: T`n" "# One`n`n![a](y.png){width=60%}`n") `
  -Contains 'image("y.png", width: 60.0%)'

Test-Poster '[メモ](x.png) は画像として救済する' (New-Md "title: T`n" "# One`n`n[メモ](z.png)`n") `
  -Contains 'image("z.png", width: 100.0%)' -NotContains '#link("z.png")'

Test-Poster '画像でない拡張子のリンクは救済しない' (New-Md "title: T`n" "# One`n`n[頁](a.html)`n") `
  -Contains '#link("a.html")'

# ============================================================ 行末の改行
Head '行末の改行 (和文は詰め，欧文は空白を残す)'

Test-Poster '欧文どうしの境目には空白が残る' (New-Md "title: T`n" "# One`n`nplants,`nto clarify`n") `
  -Contains 'plants, to clarify'

Test-Poster '和文どうしの境目は詰める' (New-Md "title: T`n" "# One`n`n和文は行末を`n詰めてよい．`n") `
  -Contains '和文は行末を詰めてよい．'

Test-Poster '和文と欧文の境目も詰める (和文の組版では空白を置かない)' `
  (New-Md "title: T`n" "# One`n`nである．`n2025年には`n") `
  -Contains 'である．2025年には'

Test-Poster '半角の約物ごしでも和文なら詰める' (New-Md "title: T`n" "# One`n`n終わる行 (注記)`nの次の和文．`n") `
  -Contains '(注記)の次の和文．'

# ============================================================ grid (座標で配置)
Head 'grid: (座標で配置)'

$g2 = "title: T`ngrid:`n  columns: 2`n  boxes:`n    - {name: One, x: 0, y: 0}`n    - {name: Two, x: 1, y: 0}`n"
$body2 = "# One`n`na`n`n# Two`n`nb`n"

Test-Poster '座標をそのまま grid.cell にする (0 起点)' (New-Md $g2 $body2) `
  -Contains 'grid.cell(x: 0, y: 0, colspan: 1, rowspan: 1)[',
            'grid.cell(x: 1, y: 0, colspan: 1, rowspan: 1)[',
            '#grid(columns: (1fr, 1fr)' `
  -NotContains '#columns('

Test-Poster 'w・h を省くと1になる' `
  (New-Md "title: T`ngrid:`n  columns: 3`n  boxes:`n    - {name: One, x: 0, y: 0, w: 2, h: 2}`n" "# One`n`na`n") `
  -Contains 'grid.cell(x: 0, y: 0, colspan: 2, rowspan: 2)['

Test-Poster 'grid: を使うと {.break} は効かないので警告する' `
  (New-Md $g2 "# One`n`na`n`n# Two {.break}`n`nb`n") `
  -WarnMatch 'grid: を使うときは {.break} は効かない'

Test-Poster 'grid: を使うと {.full} は効かないので警告する' `
  (New-Md $g2 "# One`n`na`n`n# Two {.full}`n`nb`n") `
  -WarnMatch 'grid: を使うときは {.full} は効かない'

# ============================================================ 書き間違いを止める
Head '書き間違いはエラーで止める'

Test-Poster 'grid の見出し名が本文に無い' `
  (New-Md $g2 "# One`n`na`n") -ErrorMatch 'に当たる `# 見出し` が本文に無い'

Test-Poster '本文の見出しが grid.boxes に無い' `
  (New-Md $g2 ($body2 + "`n# Three`n`nc`n")) -ErrorMatch '本文の `# Three` が grid.boxes に無い'

Test-Poster 'grid の箱どうしが同じマスで重なる' `
  (New-Md "title: T`ngrid:`n  columns: 2`n  boxes:`n    - {name: One, x: 0, y: 0, w: 2}`n    - {name: Two, x: 1, y: 0}`n" $body2) `
  -ErrorMatch '重なっている'

Test-Poster 'grid の箱が右へはみ出す' `
  (New-Md "title: T`ngrid:`n  columns: 2`n  boxes:`n    - {name: One, x: 1, y: 0, w: 2}`n" "# One`n`na`n") `
  -ErrorMatch '右へはみ出す'

Test-Poster 'grid に boxes が無い' (New-Md "title: T`ngrid:`n  columns: 2`n" "# One`n`na`n") `
  -ErrorMatch 'grid: に boxes が無い'

Test-Poster 'grid.boxes の要素に name が無い' `
  (New-Md "title: T`ngrid:`n  columns: 2`n  boxes:`n    - {x: 0, y: 0}`n" "# One`n`na`n") `
  -ErrorMatch 'name が要る'

Test-Poster 'grid.boxes に同じ名前が2回あれば止める' `
  (New-Md "title: T`ngrid:`n  columns: 2`n  boxes:`n    - {name: One, x: 0, y: 0}`n    - {name: One, x: 1, y: 0}`n" "# One`n`na`n") `
  -ErrorMatch "'One' が2回出てくる"

Test-Poster '本文に同じ見出し名が2回あれば止める (先の箱が黙って消えるため)' `
  (New-Md "title: T`n" "# One`n`nさいしょ`n`n# One`n`nあとから`n") `
  -ErrorMatch '`# One` が2回出てくる'

Test-Poster '座標が小数なら止める (0.9 を黙って 0 にしない)' `
  (New-Md "title: T`ngrid:`n  columns: 2`n  boxes:`n    - {name: One, x: 0.9, y: 0}`n" "# One`n`na`n") `
  -ErrorMatch '整数で書く'

Test-Poster '座標が数値でなければ止める (既定値に落とさない)' `
  (New-Md "title: T`ngrid:`n  columns: 2`n  boxes:`n    - {name: One, x: abc, y: 0}`n" "# One`n`na`n") `
  -ErrorMatch '整数で書く'

Test-Poster 'grid.columns が数値でなければ止める' `
  (New-Md "title: T`ngrid:`n  columns: abc`n  boxes:`n    - {name: One, x: 0, y: 0}`n" "# One`n`na`n") `
  -ErrorMatch '整数で書く'

Test-Poster 'columns が数値でなければ止める (段組みの流し込み)' `
  (New-Md "title: T`ncolumns: たくさん`n" "# One`n`na`n") -ErrorMatch '整数で書く'

# ============================================================ 後始末と結果
Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue

Write-Host ''
if ($failures.Count -eq 0) {
  Write-Host ('通過 {0} 件 / 失敗 0 件' -f $passed) -ForegroundColor Green
  exit 0
} else {
  Write-Host ('通過 {0} 件 / 失敗 {1} 件' -f $passed, $failures.Count) -ForegroundColor Red
  Write-Host ''
  foreach ($f in $failures) { Write-Host ('  ' + $f) -ForegroundColor Red }
  exit 1
}
