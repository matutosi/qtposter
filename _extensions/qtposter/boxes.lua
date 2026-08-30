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

-- 差し色は `#1a7a3c` と書けるようにしたいが，Typst の writer は補間した `#` を
-- 逃がすため `rgb("#1a7a3c")` がそのままでは通らない (2026-08-31 に実機で確認．
-- `error: color string contains non-hexadecimal letters`)．
-- ここで先頭の `#` を落とし，typst-show.typ 側で `rgb("#" + "...")` と組み立てる．
local function strip_hash(meta)
  if meta.accent ~= nil then
    local v = (pandoc.utils.stringify(meta.accent):gsub('^#', ''))
    meta.accent = pandoc.MetaString(v)
  end
  return meta
end

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
  return strip_hash(meta)
end

-- ---------------------------------------------------------------------------
-- `grid:` (座標で配置を決める) — acposter・ggposter と同じ書式
--
--   grid:
--     columns: 3
--     boxes:
--       - {name: INTRO, x: 0, y: 0, w: 2}
--       - {name: TALL,  x: 2, y: 0, h: 3}
--
-- **Quarto 1.4 が同梱する Typst 0.10 には `grid.cell` が無い**ので，
-- colspan/rowspan をそのまま書けない (2026-08-31 に実機で確認．
-- `error: function grid does not contain field cell`)．
-- そこで**ギロチン分割**する: 箱をまたがない縦の切れ目を探して `#grid` の2列に分け，
-- 無ければ横の切れ目で上下に分け，これを再帰する．
-- ポスターの配置はほぼこれで表せる (切れ目が1つも無い配置だけは組めないので，
-- そのときは名指しでエラーにする)．Quarto を上げて Typst 0.11 以降になれば，
-- `grid.cell` の素直な対応に置き換えてよい．
-- ---------------------------------------------------------------------------

local function num(v, default)
  if v == nil then return default end
  local n = tonumber(pandoc.utils.stringify(v))
  return n or default
end

local function read_grid(meta_grid)
  local cols = num(meta_grid.columns, 2)
  if cols < 1 then error('grid.columns は 1 以上にする．') end
  local boxes = {}
  if meta_grid.boxes == nil then error('grid: に boxes が無い．') end
  for _, b in ipairs(meta_grid.boxes) do
    local name = pandoc.utils.stringify(b.name or '')
    if name == '' then error('grid.boxes の各要素には name が要る．') end
    local box = {
      name = name,
      x = num(b.x, 0), y = num(b.y, 0),
      w = num(b.w, 1), h = num(b.h, 1),
    }
    if box.x < 0 or box.y < 0 then
      error("grid.boxes の '" .. name .. "' の x/y は 0 以上にする．")
    end
    if box.w < 1 or box.h < 1 then
      error("grid.boxes の '" .. name .. "' の w/h は 1 以上にする．")
    end
    if box.x + box.w > cols then
      error("grid.boxes の '" .. name .. "' が右へはみ出す (x+w=" ..
            (box.x + box.w) .. " > columns=" .. cols .. ")．")
    end
    boxes[#boxes + 1] = box
  end
  -- 重なりを調べる
  local seen = {}
  for _, b in ipairs(boxes) do
    for xi = b.x, b.x + b.w - 1 do
      for yi = b.y, b.y + b.h - 1 do
        local k = xi .. ',' .. yi
        if seen[k] then
          error("grid.boxes の '" .. b.name .. "' と '" .. seen[k] ..
                "' が同じマス (" .. k .. ") で重なっている．")
        end
        seen[k] = b.name
      end
    end
  end
  return cols, boxes
end

-- 区画 [x0,x1) x [y0,y1) を，箱をまたがない切れ目で2つに割る．
-- 縦の切れ目を先に探し (左右に並ぶ)，無ければ横 (上下に積む)．
local function split(boxes, x0, x1, y0, y1)
  for cx = x0 + 1, x1 - 1 do
    local crosses, left, right = false, {}, {}
    for _, b in ipairs(boxes) do
      if b.x < cx and b.x + b.w > cx then crosses = true break end
      if b.x + b.w <= cx then left[#left + 1] = b else right[#right + 1] = b end
    end
    if not crosses and #left > 0 and #right > 0 then
      return 'v', cx, left, right
    end
  end
  for cy = y0 + 1, y1 - 1 do
    local crosses, top, bottom = false, {}, {}
    for _, b in ipairs(boxes) do
      if b.y < cy and b.y + b.h > cy then crosses = true break end
      if b.y + b.h <= cy then top[#top + 1] = b else bottom[#bottom + 1] = b end
    end
    if not crosses and #top > 0 and #bottom > 0 then
      return 'h', cy, top, bottom
    end
  end
  return nil
end

-- 本文を「見出し名 → その箱の中身のブロック列」に切り分ける．
-- `# ` より前の内容は箱に属さないので，そのまま先頭に置く．
local function split_into_boxes(blocks)
  local preamble, order, content = pandoc.List(), {}, {}
  local cur = nil
  for _, blk in ipairs(blocks) do
    if blk.t == "Header" and blk.level == 1 then
      cur = { name = pandoc.utils.stringify(blk.content),
              broken = blk.classes:includes("break"),
              blocks = pandoc.List() }
      order[#order + 1] = cur
      content[cur.name] = cur
    elseif cur then
      cur.blocks:insert(blk)
    else
      preamble:insert(blk)
    end
  end
  return preamble, order, content
end

local function raw(s) return pandoc.RawBlock("typst", s) end

local function emit_box(out, item)
  out:insert(raw('#pop.column-box(heading: [' .. esc(item.name) .. '])['))
  for _, b in ipairs(item.blocks) do out:insert(b) end
  out:insert(raw(']'))
end

-- 区画を再帰的に切り分けて Typst を組み立てる．
local function emit_region(out, boxes, content, x0, x1, y0, y1)
  if #boxes == 1 then
    emit_box(out, content[boxes[1].name])
    return
  end
  local dir, cut, first, second = split(boxes, x0, x1, y0, y1)
  if dir == nil then
    local names = {}
    for _, b in ipairs(boxes) do names[#names + 1] = b.name end
    error('grid: の配置を Typst 0.10 で組めない (縦にも横にも切れ目が無い): ' ..
          table.concat(names, ', ') .. '\n' ..
          'どれかの箱の x/y/w/h を，長方形に切り分けられる形に直す．')
  end
  if dir == 'v' then
    out:insert(raw('#grid(columns: (' .. (cut - x0) .. 'fr, ' .. (x1 - cut) ..
                   'fr), column-gutter: 1em,'))
    out:insert(raw('['))
    emit_region(out, first, content, x0, cut, y0, y1)
    out:insert(raw('],['))
    emit_region(out, second, content, cut, x1, y0, y1)
    out:insert(raw('],)'))
  else
    -- 上下は素直に並べるだけでよい (Typst は既定で縦に流す)．
    emit_region(out, first, content, x0, x1, y0, cut)
    emit_region(out, second, content, x0, x1, cut, y1)
  end
end

function Pandoc(doc)
  local preamble, order, content = split_into_boxes(doc.blocks)
  local out = pandoc.List()
  for _, b in ipairs(preamble) do out:insert(b) end

  if doc.meta.grid ~= nil then
    local cols, boxes = read_grid(doc.meta.grid)

    -- 見出しと boxes の突き合わせ (どちらかにしか無いものはエラー)．
    local placed = {}
    for _, b in ipairs(boxes) do
      if content[b.name] == nil then
        error("grid.boxes の '" .. b.name .. "' に当たる `# 見出し` が本文に無い．")
      end
      if placed[b.name] then
        error("grid.boxes に '" .. b.name .. "' が2回出てくる．")
      end
      placed[b.name] = true
    end
    for _, item in ipairs(order) do
      if not placed[item.name] then
        error("本文の `# " .. item.name .. "` が grid.boxes に無い．")
      end
      if item.broken then
        io.stderr:write("[warning] grid: を使うときは {.break} は効かない (" ..
                        item.name .. ")．配置は grid: が決める．\n")
      end
    end

    local rows = 0
    for _, b in ipairs(boxes) do
      if b.y + b.h > rows then rows = b.y + b.h end
    end
    emit_region(out, boxes, content, 0, cols, 0, rows)
    -- 段組みへの流し込みは使わないので，テンプレート側の columns() を1段にする．
    doc.meta.cols = pandoc.MetaString("1")
  else
    for _, item in ipairs(order) do
      -- `# 見出し {.break}` と書いたら，その箱から次の段へ送る．
      -- Typst の columns は「あふれたら次の段」なので，A0 では自動では分かれない．
      if item.broken then out:insert(raw('#colbreak()')) end
      emit_box(out, item)
    end
  end

  doc.blocks = out
  return doc
end
