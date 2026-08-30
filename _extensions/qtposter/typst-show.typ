#show: doc => qtposter(
$if(title)$title: [$title$],$endif$
$if(poster-authors)$authors: [$for(poster-authors)$$poster-authors$$sep$, $endfor$],$endif$
$if(institutes)$institutes: [$institutes$],$endif$
$if(paper)$paper: "$paper$",$endif$
$if(cols)$cols: $cols$,$endif$
$if(font)$font: "$font$",$endif$
$if(size)$size: $size$,$endif$
$if(footer)$footer: [$footer$],$endif$
doc,
)
