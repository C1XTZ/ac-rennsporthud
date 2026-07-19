---@meta
---@diagnostic disable: lowercase-global

--- Measures text with a given DWrite font/size, rounded to whole pixels.
---@param text any @Text to measure.
---@param font string @DWrite font string.
---@param fontSize number @Font size in px.
---@return vec2 @Measured width/height.
function measureText(text, font, fontSize)
  ui.pushDWriteFont(font)
  local size = ui.measureDWriteText(tostring(text), fontSize)
  ui.popDWriteFont()
  return vec2(math.round(size.x), math.round(size.y))
end

--- Box size for one string. Width grows past minSize.x if needed but height stays fixed.
---@param text any @Text to measure.
---@param font string @DWrite font string.
---@param fontSize number @Font size in px.
---@param minSize vec2 @Width is a floor, height is fixed.
---@param padding number? @Extra px added to measured width. Default 0.
---@return vec2 @Pass this as the size to dwriteTextAligned/childWindow/drawRectFilled.
function measureBox(text, font, fontSize, minSize, padding)
  padding = padding or 0
  local measured = measureText(text, font, fontSize)
  return vec2(math.round(math.max(minSize.x, measured.x + padding)), math.round(minSize.y))
end

--- Shrinks the font to fit a fixed box instead of growing the box.
---@param text any @Text to fit.
---@param font string @DWrite font string.
---@param fontSize number @Preferred font size.
---@param boxSize vec2 @Fixed box, never changes.
---@param minFontSize number? @Floor. Default 60% of fontSize.
---@param tolerance number? @Slight boxsize increase to avoid clipping. Default 3px * app.scale.
---@return number @Font size to actually draw with.
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

--- Like measureBox, but sized off the widest of a list of strings/numbers. Timing and Leaderboard tables.
---@param items table @Strings/numbers to measure.
---@param font string @DWrite font string.
---@param fontSize number @Font size in px.
---@param minSize vec2 @Width is a floor, height is fixed.
---@param padding number? @Extra px added to measured width. Default 0.
---@return vec2 @Widest of items, or minSize if none exceed it.
function measureBoxMax(items, font, fontSize, minSize, padding)
  padding = padding or 0
  local maxW = minSize.x
  ui.pushDWriteFont(font)
  for _, item in ipairs(items) do
    local m = ui.measureDWriteText(tostring(item), fontSize)
    if m.x + padding > maxW then maxW = m.x + padding end
  end
  ui.popDWriteFont()
  return vec2(math.round(maxW), math.round(minSize.y))
end
