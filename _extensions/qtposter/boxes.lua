-- `# 見出し` から次の `# 見出し` までを1つの箱 (pop.column-box) にまとめる．
-- acposter の「# 見出し = 箱」の約束と同じにして，書き方を揃える．

-- 見出しの中身を Typst の記法へ書き出す．
-- **`stringify` で文字列にしてはいけない** (2026-09-02)．それまでは
-- `# *Rubus* の分布` の斜体が落ちて立体になり (学名はポスターで斜体が要る)，
-- 逆に `# #1 の話` の `#` は逃がされないまま Typst のコード開始として渡っていた．
-- pandoc の Typst writer に書かせれば，強調は残り，記号は writer が逃がす．
-- `wrap_text = 'none'` は，長い見出しが途中で折り返されて改行が混じるのを防ぐため．
local WOPTS = pandoc.WriterOptions({ wrap_text = 'none' })
local function heading_typst(inlines)
  local s = pandoc.write(pandoc.Pandoc({ pandoc.Plain(inlines) }), 'typst', WOPTS)
  return (s:gsub('%s+$', ''))
end

-- ヘッダーの値を整数へ (無ければ既定値)．
-- **書き間違いを黙って既定値に落とさない** (2026-09-02．acposter の `to_num` と同じ)．
-- それまでは `x: 0.9` が `grid.cell` の書き出しで Lua の内部エラー
-- (`number has no integer representation`) になり，`x: なにか` は警告も出ないまま
-- 既定値の 0 として別の場所へ置かれていた．
local function to_num(v, default, what)
  if v == nil then return default end
  local s = pandoc.utils.stringify(v)
  local n = tonumber(s)
  if n == nil or n ~= math.floor(n) then
    error(('%s は整数で書く (今は "%s")．'):format(what, s))
  end
  return math.floor(n)
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

-- `[説明](図.png)` のような書き間違い (画像記法 `![...]` の `!` の付け忘れ) を
-- 画像として救済する．**acposter (`poster.lua`) と同じ約束**にして揃える．
-- 直すのは拡張子が画像のときだけなので，ふつうのリンクは触らない．
local IMAGE_EXT = { png = true, jpg = true, jpeg = true, gif = true, svg = true, webp = true }

function Link(el)
  local ext = el.target:match('%.([%a]+)$')
  if ext and IMAGE_EXT[ext:lower()] then
    local img = pandoc.Image(el.content, el.target, el.title, el.attr)
    -- ここで作った画像に `Image` フィルタは掛からないので，幅の既定値は自分で入れる．
    if not img.attributes.width then img.attributes.width = "100%" end
    return img
  end
  return nil
end

-- ---------------------------------------------------------------------------
-- 行末の改行 (SoftBreak) の詰め方．**和文が絡む境目は詰め，欧文どうしの境目にだけ空白を残す**．
-- 無条件に空白を残すと，1文1行で書いた和文が「である． 管理の停止に…」と間延びし，
-- 無条件に落とすと，1文1行で書いた英文が単語ごとくっつく ("plants,to clarify")．
-- 2026-09-02 まで qtposter だけこの処理が無く，`poster.pdf` に実際に空白が出ていた．
--
-- **ここは acposter の `poster.lua`・スキル `build-abstract-pdf`・`build-slide-pdf` と
-- 同じ判定の写しである** (CJK_RANGES / is_cjk / is_transparent / edge_cp / Inlines)．
-- **どれか1つを直したら，残りも同じに直す**．
-- ---------------------------------------------------------------------------
local CJK_RANGES = {
  { 0x3000, 0x303F },   -- CJK の約物 (、。「」)
  { 0x3040, 0x30FF },   -- ひらがな・カタカナ (・ を含む)
  { 0x31F0, 0x31FF },   -- カタカナ拡張
  { 0x3400, 0x4DBF },   -- 漢字 拡張A
  { 0x4E00, 0x9FFF },   -- 漢字
  { 0xF900, 0xFAFF },   -- 互換漢字
  { 0xFF00, 0xFF60 },   -- 全角の英数・約物 (，．()「」)
  { 0xFFE0, 0xFFE6 },   -- 全角の記号
}

local function is_cjk(cp)
  if cp == nil then return false end
  for _, r in ipairs(CJK_RANGES) do
    if cp >= r[1] and cp <= r[2] then return true end
  end
  return false
end

-- 半角の約物・空白は「透ける」ものとして飛ばす．和文でも丸括弧・記号は半角で書くので
-- (ユーザの表記ルール)，`…と)` の `)` だけを見て「和文ではない」と判じないため．
-- 欧文で飛ばしても，その奥に出てくるのはラテン文字なので判定は変わらない．
local function is_transparent(cp)
  return cp == 0x20 or cp == 0x09
      or (cp >= 0x21 and cp <= 0x2F) or (cp >= 0x3A and cp <= 0x40)
      or (cp >= 0x5B and cp <= 0x60) or (cp >= 0x7B and cp <= 0x7E)
end

-- 隣の要素の「境目の文字」の符号位置を返す (last なら末尾から，そうでなければ先頭から)．
-- Emph や Code に包まれていても中の文字が見えるよう stringify を通す．
local function edge_cp(il, last)
  if il == nil then return nil end
  local ok, s = pcall(pandoc.utils.stringify, il)
  if not ok or s == nil or s == '' then return nil end
  local cps = {}
  for _, c in utf8.codes(s) do cps[#cps + 1] = c end
  local from, to, step = 1, #cps, 1
  if last then from, to, step = #cps, 1, -1 end
  for i = from, to, step do
    if not is_transparent(cps[i]) then return cps[i] end
  end
  return nil
end

function Inlines(ils)
  local has_softbreak = false
  for _, il in ipairs(ils) do
    if il.t == 'SoftBreak' then has_softbreak = true; break end
  end
  if not has_softbreak then return nil end

  local out = pandoc.Inlines({})
  for i, il in ipairs(ils) do
    if il.t == 'SoftBreak' then
      -- **どちらか一方でも和文なら詰める**．空白を入れるのは両側とも欧文のときだけ
      -- (pandoc の既定の書き出しと同じ振る舞い)．和文と欧文の境目は，和文の組版では
      -- 空白を置かない．「ともに和文のときだけ詰める」にすると，
      -- 「…である．⏎2025年には…」が「である． 2025年」になってしまう．
      if not (is_cjk(edge_cp(ils[i - 1], true)) or is_cjk(edge_cp(ils[i + 1], false))) then
        out:insert(pandoc.Space())
      end
    else
      out:insert(il)
    end
  end
  return out
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
  -- **`columns` は Quarto 自身も使う** (2026-08-31 に Quarto 1.10 で判明)．
  -- 残したままだと Quarto が `#set page(columns: 3)` を出し，qtposter の
  -- `columns(cols, doc)` と**段組みが二重になる** (箱の幅が 1/9 になり紙面が壊れる)．
  -- 段数は `cols` へ写し終えているので，ここで消す (`grid`・`orientation` と同種の衝突)．
  meta.columns = nil
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
-- 座標は `grid.cell(x:, y:, colspan:, rowspan:)` にそのまま渡す (Typst 0.11 以降)．
-- **どんな配置でも組める**．
--
-- 2026-08-31 まではギロチン分割 (箱をまたがない切れ目で再帰的に割る) で組んでいた．
-- Quarto 1.4 が同梱する Typst 0.10 に `grid.cell` が無かったためで，
-- **縦にも横にも切れ目が無い配置は組めない**という制限があった．
-- Quarto 1.10 (Typst 0.15) へ上げ，peace-of-posters も 0.6.0 にしたので，
-- **その版でしか動かない**古い経路は消した (中身は git の履歴にある)．
-- ---------------------------------------------------------------------------

local function read_grid(meta_grid)
  local cols = to_num(meta_grid.columns, 2, 'grid.columns')
  if cols < 1 then error('grid.columns は 1 以上にする．') end
  local boxes = {}
  if meta_grid.boxes == nil then error('grid: に boxes が無い．') end
  for _, b in ipairs(meta_grid.boxes) do
    local name = pandoc.utils.stringify(b.name or '')
    if name == '' then error('grid.boxes の各要素には name が要る．') end
    local box = {
      name = name,
      x = to_num(b.x, 0, ("grid.boxes の '" .. name .. "' の x")),
      y = to_num(b.y, 0, ("grid.boxes の '" .. name .. "' の y")),
      w = to_num(b.w, 1, ("grid.boxes の '" .. name .. "' の w")),
      h = to_num(b.h, 1, ("grid.boxes の '" .. name .. "' の h")),
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

-- 本文を「見出し名 → その箱の中身のブロック列」に切り分ける．
-- `# ` より前の内容は箱に属さないので，そのまま先頭に置く．
local function split_into_boxes(blocks)
  local preamble, order, content = pandoc.List(), {}, {}
  local cur = nil
  for _, blk in ipairs(blocks) do
    if blk.t == "Header" and blk.level == 1 then
      local name = pandoc.utils.stringify(blk.content)
      -- **同じ見出し名は許さない** (2026-09-02)．箱は名前で引くので，2回書くと
      -- `grid:` の経路で先の箱の中身が黙って消えていた (acposter は元から止まる)．
      if content[name] then
        error("本文に `# " .. name .. "` が2回出てくる．見出しは1回ずつにする．")
      end
      cur = { name = name,
              heading = heading_typst(blk.content),
              broken = blk.classes:includes("break"),
              full = blk.classes:includes("full"),
              blocks = pandoc.List() }
      order[#order + 1] = cur
      content[name] = cur
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
  out:insert(raw('#pop.column-box(heading: [' .. item.heading .. '])['))
  for _, b in ipairs(item.blocks) do out:insert(b) end
  out:insert(raw(']'))
end

-- Typst 0.11 以降の経路: 座標をそのまま `grid.cell` に渡す．
local function emit_grid_cells(out, boxes, content, cols)
  local widths = {}
  for _ = 1, cols do widths[#widths + 1] = '1fr' end
  out:insert(raw('#grid(columns: (' .. table.concat(widths, ', ') ..
                 '), column-gutter: 1em, row-gutter: 1em,'))
  for _, b in ipairs(boxes) do
    out:insert(raw(('grid.cell(x: %d, y: %d, colspan: %d, rowspan: %d)['):
                   format(b.x, b.y, b.w, b.h)))
    emit_box(out, content[b.name])
    out:insert(raw('],'))
  end
  out:insert(raw(')'))
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
      if item.full then
        io.stderr:write("[warning] grid: を使うときは {.full} は効かない (" ..
                        item.name .. ")．全幅にするには w を columns と同じにする．\n")
      end
    end

    emit_grid_cells(out, boxes, content, cols)
    -- 段組みへの流し込みは使わないので，テンプレート側の columns() を1段にする．
    doc.meta.cols = pandoc.MetaString("1")
  else
    -- 段組みの流し込み．**`# 見出し {.full}` の箱はいったん段組みを閉じて全幅で置き，
    -- そのあと段組みを開き直す** (acposter の `{.full}` と同じ約束)．
    -- Typst の `columns()` は入れ子にできるが「途中で1つだけ全幅」は書けないので，
    -- 段組みの塊を切って間に挟む形にする．
    local cols = to_num(doc.meta.cols, 3, 'columns (段数)')
    if cols < 1 then error('columns (段数) は 1 以上にする．') end

    local open = false            -- いま段組みの塊を開いているか
    local function open_columns()
      if not open then
        out:insert(raw('#columns(' .. cols .. ')['))
        open = true
      end
    end
    local function close_columns()
      if open then
        out:insert(raw(']'))
        open = false
      end
    end

    for _, item in ipairs(order) do
      if item.full then
        if item.broken then
          io.stderr:write('[warning] {.full} の箱に {.break} は要らない (' ..
                          item.name .. ')．全幅の箱は段組みの外に出る．\n')
        end
        close_columns()
        emit_box(out, item)
      else
        open_columns()
        -- `# 見出し {.break}` と書いたら，その箱から次の段へ送る．
        -- Typst の columns は「あふれたら次の段」なので，A0 では自動では分かれない．
        if item.broken then out:insert(raw('#colbreak()')) end
        emit_box(out, item)
      end
    end
    close_columns()
  end

  doc.blocks = out
  return doc
end
