-- `# 見出し` から次の `# 見出し` までを1つの箱 (pop.column-box) にまとめる．
-- acposter の「# 見出し = 箱」の約束と同じにして，書き方を揃える．
local function esc(s)
  local BS = string.char(92)
  return (s:gsub(BS, BS..BS):gsub("%[", BS.."["):gsub("%]", BS.."]"))
end

-- Quarto は幅の指定が無い画像を `#box(width: 900.0pt, image(...))` のように
-- 原寸 (pt) で焼き込む．A0 の段幅を超えて隣へはみ出すので，既定で 100% にする．
-- 幅を自分で書いた画像 (`{width=60%}`) はそのまま尊重する．
function Image(img)
  if not img.attributes.width then
    img.attributes.width = "100%"
    return img
  end
end

-- 姉妹ツール (ggposter・acposter) が同じ意味に使っているキー名も受ける．
-- 正は author / institute / note / paper / columns / font-size で，
-- 内部 (typst-show.typ) が使う名前へ寄せるだけなので，古い書き方もそのまま通る．
-- 先に並べた名前ほど優先する．
local META_ALIASES = {
  { "poster-authors", { "author", "authors", "poster-authors" } },
  { "institutes",     { "institute", "institutes", "affiliation", "affiliations" } },
  { "footer",         { "note", "funding", "footer" } },
  { "cols",           { "columns", "cols" } },
  -- `size` は ggposter では用紙を指すため，正は `font-size`．
  -- qtposter が元から使っていた `size` も引き続き受ける．
  { "size",           { "font-size", "font_size", "size" } },
}

-- 向き (orientation) は受けない．peace-of-posters の layout-a0 が縦で固定なうえ，
-- `orientation` は Quarto 自身が予約していて (値は rows / columns)，
-- `landscape` と書くと Quarto の YAML 検証がフィルタより先に弾く (2026-08-31 に確認)．

function Meta(meta)
  for _, rule in ipairs(META_ALIASES) do
    local target, names = rule[1], rule[2]
    for _, k in ipairs(names) do
      if meta[k] ~= nil then
        meta[target] = meta[k]
        break
      end
    end
  end
  return meta
end

function Pandoc(doc)
  local out = pandoc.List()
  local open = false
  for _, blk in ipairs(doc.blocks) do
    if blk.t == "Header" and blk.level == 1 then
      if open then out:insert(pandoc.RawBlock("typst", "]")) end
      -- `# 見出し {.break}` と書いたら，その箱から次の段へ送る．
      -- Typst の columns は「あふれたら次の段」なので，A0 では自動では分かれない．
      if blk.classes:includes("break") then
        out:insert(pandoc.RawBlock("typst", "#colbreak()"))
      end
      local h = esc(pandoc.utils.stringify(blk.content))
      out:insert(pandoc.RawBlock("typst",
        '#pop.column-box(heading: [' .. h .. '])['))
      open = true
    else
      out:insert(blk)
    end
  end
  if open then out:insert(pandoc.RawBlock("typst", "]")) end
  doc.blocks = out
  return doc
end
