#show: doc => qtposter(
$if(title)$title: [$title$],$endif$
$if(subtitle)$subtitle: [$subtitle$],$endif$
$if(poster-authors)$authors: ($for(poster-authors)$[$poster-authors$],$endfor$),$endif$
$if(institutes)$institutes: ($for(institutes)$[$institutes$],$endfor$),$endif$
$if(paper)$paper: "$paper$",$endif$
$if(font)$font: "$font$",$endif$
$if(size)$size: $size$,$endif$
$if(footer)$footer: [$footer$],$endif$
$if(logo)$logo: image("$logo$"),$endif$
$if(accent)$accent: rgb("#" + "$accent$"),$endif$
$if(fig-max-height)$fig-max-height: $fig-max-height$,$endif$
doc,
)
