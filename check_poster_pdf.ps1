<#
.SYNOPSIS
  できたポスター PDF を検算する (ページ数・用紙実寸・埋め込みフォント)．

.DESCRIPTION
  `quarto render` は「組めたか」しか教えないので，**刷る前に気づきたいこと**を
  ここで見る．出力の文言は acposter の `make_poster_pdf.ps1` と揃えてある
  (3系統で同じことを同じ言い方で報告するため)．

  - **ページ数**: ポスターは常に 1．2 以上なら，どこかの箱・図・表が紙面から溢れている．
  - **用紙実寸**: 指定した用紙 (既定 A0 縦) と合っているか．
  - **埋め込みフォント**: 和文フォントが埋め込まれているか
    (埋め込まれていないと，別の PC や印刷所で字が化ける)．

  ページ数と用紙実寸は poppler の `pdfinfo`，フォントは `pdffonts` を使う
  (どちらも TeX Live に同梱されている)．無ければ PDF を直接読んで数えるが，
  **Typst の PDF は圧縮されていて読み取れない**ので，その旨だけを伝える．

.EXAMPLE
  pwsh -File check_poster_pdf.ps1                       # 直下の PDF を全部見る
  pwsh -File check_poster_pdf.ps1 -Pdf poster.pdf
  pwsh -File check_poster_pdf.ps1 -Pdf poster.pdf -Paper a1
#>
[CmdletBinding()]
param(
  [string]$Pdf = '',
  [ValidateSet('a0', 'a1', 'a2')][string]$Paper = 'a0'
)

$ErrorActionPreference = 'Stop'

# A系列の縦向き実寸 (mm)．qtposter は縦固定 (peace-of-posters の layout-a0)．
$SIZE_MM = @{ a0 = @{ w = 841; h = 1189 }; a1 = @{ w = 594; h = 841 }; a2 = @{ w = 420; h = 594 } }

$targets = if ($Pdf) {
  if (-not (Test-Path $Pdf)) { throw "PDF が無い: $Pdf" }
  @((Resolve-Path $Pdf).Path)
} else {
  @(Get-ChildItem -Path . -Filter '*.pdf' -File | ForEach-Object { $_.FullName })
}
if ($targets.Count -eq 0) { throw 'PDF が見つからない．-Pdf で指定する．' }

$pdfinfo  = (Get-Command pdfinfo  -ErrorAction SilentlyContinue).Source
$pdffonts = (Get-Command pdffonts -ErrorAction SilentlyContinue).Source

$mm = $SIZE_MM[$Paper]
$expectW = $mm.w * 72.0 / 25.4
$expectH = $mm.h * 72.0 / 25.4
$ng = 0

foreach ($f in $targets) {
  Write-Host ('完成: {0} ({1:N0} bytes)' -f $f, (Get-Item $f).Length)

  if (-not $pdfinfo) {
    Write-Host 'note   : pdfinfo が無いので検算できない (TeX Live か poppler を入れる)．'
    continue
  }

  $info = & $pdfinfo $f 2>$null
  $pages = ($info | Select-String '^Pages:\s+(\d+)').Matches.Groups[1].Value
  Write-Host ('ページ数: {0} (ポスターは常に1のはず)' -f $pages)
  if ($pages -ne '1') {
    $ng++
    Write-Warning 'ページ数が1でない．どこかの箱・図・表が紙面から溢れている．中身を減らすか，図の width を下げる．'
  }

  $size = ($info | Select-String '^Page size:\s+([\d.]+) x ([\d.]+)').Matches
  if ($size.Count -gt 0) {
    $actualW = [double]$size.Groups[1].Value
    $actualH = [double]$size.Groups[2].Value
    Write-Host ('用紙実寸: {0:N0} x {1:N0} pt (見込み {2:N0} x {3:N0} pt)' -f $actualW, $actualH, $expectW, $expectH)
    if ([Math]::Abs($actualW - $expectW) -gt 3 -or [Math]::Abs($actualH - $expectH) -gt 3) {
      $ng++
      Write-Warning ('用紙実寸が指定した {0} と合っていない．ヘッダーの paper を確かめる．' -f $Paper)
    }
  }

  if ($pdffonts) {
    # 1行目は見出し，2行目は罫線なので落とす．先頭のサブセット接頭辞 (ABCDEF+) も外す．
    $fonts = & $pdffonts $f 2>$null |
             Select-Object -Skip 2 |
             ForEach-Object { ($_ -split '\s+')[0] -replace '^[A-Z]{6}\+', '' } |
             Where-Object { $_ } | Sort-Object -Unique
    Write-Host ('埋め込みフォント: {0}' -f ($fonts -join ', '))
    if ($fonts.Count -eq 0) {
      $ng++
      Write-Warning 'フォントが埋め込まれていない．別の PC や印刷所で字が化ける．'
    }
  }
  Write-Host ''
}

if ($ng -gt 0) { Write-Host ('検算: {0} 件の警告' -f $ng) } else { Write-Host '検算: 問題なし' }
