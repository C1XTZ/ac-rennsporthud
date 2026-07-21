local widthCache, heightCache, cacheScale = {}, {}, nil

--- Returns an existing nested table, creating one first if needed.
---@param t table @Table to look up and store the nested table in.
---@param k any @Key identifying the nested table.
---@return table @The existing or newly created nested table.
local function nested(t, k)
  local v = t[k]
  if not v then
    v = {}
    t[k] = v
  end
  return v
end

--- Measures text with a given DWrite font/size, rounded to whole pixels.
---@param text string|number @Value to measure. Converted to a string.
---@param font string @DWrite font string.
---@param fontSize number @Font size in px.
---@param useCache boolean? @Caches width by string length for text containing no letters, otherwise by the full string. Disabled by default.
---@return vec2 @Measured width/height.
---@diagnostic disable-next-line: lowercase-global
function measureText(text, font, fontSize, useCache)
  text = tostring(text)

  if not useCache then
    ui.pushDWriteFont(font)
    local size = ui.measureDWriteText(text, fontSize)
    ui.popDWriteFont()
    return vec2(math.round(size.x), math.round(size.y))
  end

  if cacheScale ~= app.scale then
    widthCache, heightCache, cacheScale = {}, {}, app.scale
  end

  local widthBySize = nested(nested(widthCache, font), fontSize)
  local heightByFont = nested(heightCache, font)
  local h = heightByFont[fontSize]

  local isNumeric = not text:find('%a')
  local wKey = isNumeric and #text or text
  local w = widthBySize[wKey]

  if not w or not h then
    ui.pushDWriteFont(font)
    local measured = ui.measureDWriteText(text, fontSize)
    ui.popDWriteFont()
    w, h = math.round(measured.x), math.round(measured.y)
    widthBySize[wKey] = w
    heightByFont[fontSize] = h
  end

  return vec2(w, h)
end

--- Box size for one string. Width grows past minSize.x if needed but height stays fixed.
---@param text any @Text to measure.
---@param font string @DWrite font string.
---@param fontSize number @Font size in px.
---@param minSize vec2 @Width is a floor, height is fixed.
---@param padding number? @Extra px added to measured width. Default 0.
---@param useCache boolean? @See measureText. Default false.
---@return vec2 @Box size with width expanded to fit the text and height equal to minSize.y.
---@diagnostic disable-next-line: lowercase-global
function measureBox(text, font, fontSize, minSize, padding, useCache)
  padding = padding or 0
  local measured = measureText(text, font, fontSize, useCache)
  return vec2(math.round(math.max(minSize.x, measured.x + padding)), math.round(minSize.y))
end

--- Shrinks the font to fit a fixed box instead of growing the box.
---@param text any @Text to fit.
---@param font string @DWrite font string.
---@param fontSize number @Preferred font size.
---@param boxSize vec2 @Fixed box, never changes.
---@param minFontSize number? @Floor. Default 60% of fontSize.
---@param tolerance number? @Extra horizontal tolerance before shrinking the font. Defaults to scale(3).
---@return integer @Rounded font size to use.
---@diagnostic disable-next-line: lowercase-global
function fitFontSize(text, font, fontSize, boxSize, minFontSize, tolerance)
  minFontSize = math.round(minFontSize or fontSize * 0.6)
  tolerance = tolerance or scale(3)
  local size = math.round(fontSize)
  while size > minFontSize do
    local measured = measureText(text, font, size)
    if measured.x <= boxSize.x + tolerance then return size end
    size = size - 1
  end
  return minFontSize
end

--- Like measureBox, but sized off the widest of a list of strings/numbers.
---@param items (string|number)[] @Values to measure.
---@param font string @DWrite font string.
---@param fontSize number @Font size in px.
---@param minSize vec2 @Width is a floor, height is fixed.
---@param padding number? @Extra px added to measured width. Default 0.
---@param useCache boolean? @See measureText. Default false.
---@return vec2 @Box sized for the widest item, with height equal to minSize.y.
---@diagnostic disable-next-line: lowercase-global
function measureBoxMax(items, font, fontSize, minSize, padding, useCache)
  padding = padding or 0
  local maxW = minSize.x

  if not useCache then
    ui.pushDWriteFont(font)
    for _, item in ipairs(items) do
      local w = ui.measureDWriteText(tostring(item), fontSize).x + padding
      if w > maxW then maxW = w end
    end
    ui.popDWriteFont()
  else
    for _, item in ipairs(items) do
      local w = measureText(item, font, fontSize, true).x + padding
      if w > maxW then maxW = w end
    end
  end

  return vec2(math.round(maxW), math.round(minSize.y))
end
