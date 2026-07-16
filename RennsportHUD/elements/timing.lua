---@meta
---@diagnostic disable: lowercase-global

local totalSectors = #ac.getSim().lapSplits

--- Calculates the ideal lap time in milliseconds from the best overall splits.
---@param doOnce boolean @This is here so this is only executed once.
---@return integer @The ideal lap time in milliseconds.
function idealLapTime(doOnce)
  if doOnce then
    doOnce = false
    local IdealMs = 0
    for i = 0, totalSectors - 1 do
      IdealMs = IdealMs + playerCar().bestSplits[i]
    end
    return IdealMs
  end
end

local emptyTimeString = '--:--.---'
local timeColor = rgbm.colors.white
local sectors, previousLaps, currentLap, lapCount, idealLap

--- Resets the timing.
---@param all boolean @Determines if all timings should be reset.
function resetTiming(all)
  sectors = {}
  for i = 1, totalSectors do
    table.insert(sectors, 0)
  end

  currentLap = {
    lapTime = 0,
    sectors = sectors,
    delta = 0,
  }

  if all then
    lapCount = 0
    previousLaps = {}
    idealLap = 0
  end
end

ac.onSessionStart(function(sessionIndex, restarted) resetTiming(true) end)

resetTiming(true)

--- Draws one BEST/LAST/IDEAL stat at a shared width so all three match regardless of content length.
---@return number @Stat height, for vertOffset bookkeeping.
local function drawStat(position, name, vertOffset, label, contentTxt, labelWidth, valueWidth, statWidth, bgLeft, bgRight, contentColor)
  local statHeight = position.timing.lapStats.y
  local fontSizeSmall = scale(14)
  local gap = scale(6)

  ui.setCursor(vec2(0, vertOffset))
  ui.childWindow(name, vec2(statWidth, statHeight), function()
    ui.drawRectFilled(vec2(0, 0), vec2(labelWidth, statHeight), bgLeft)
    ui.drawRectFilled(vec2(labelWidth, 0), vec2(statWidth, statHeight), bgRight)
    ui.pushDWriteFont(app.font.black)
    ui.setCursorX(scale(6))
    ui.dwriteTextAligned(label, fontSizeSmall, -1, 0, vec2(labelWidth - scale(6), statHeight), false, color.white)
    ui.setCursor(vec2(labelWidth + gap, 0))
    ui.dwriteTextAligned(contentTxt, fontSizeSmall, -1, 0, vec2(valueWidth, statHeight), false, contentColor)
    ui.popDWriteFont()
  end)

  return statHeight
end

function script.timing(dt)
  local position = getPositionTable()
  local playerSession = ac.getSim()
  local vertOffset = app.padding
  local horiOffset = 0
  local fontSizeSmall = scale(14)
  if playerCar().isLapValid then
    timeColor = color.white
  else
    timeColor = color.uired
  end

  local newSectorIndex = playerCar().currentSector + 1
  if newSectorIndex ~= previouslastTimedSector then
    lastTimedSector = previouslastTimedSector
    previouslastTimedSector = newSectorIndex

    if playerCar().previousSectorTime > 0 then
      currentLap.sectors[lastTimedSector] = playerCar().previousSectorTime
    else
      local sumSectors = 0
      for i = 1, totalSectors do
        sumSectors = sumSectors + currentLap.sectors[i]
      end
      if lastTimedSector then currentLap.sectors[lastTimedSector] = playerCar().previousLapTimeMs - sumSectors end
    end
  end

  if lapCount ~= playerCar().lapCount then
    lapCount = playerCar().lapCount

    currentLap.lapTime = playerCar().previousLapTimeMs
    currentLap.lapNum = lapCount

    if playerCar().bestLapTimeMs > 0 then
      currentLap.delta = math.max(0, currentLap.lapTime - playerCar().bestLapTimeMs)
    else
      currentLap.delta = 0
    end

    if currentLap.lapTime <= playerCar().bestLapTimeMs or playerCar().bestLapTimeMs == 0 then
      for i, lap in ipairs(previousLaps) do
        lap.delta = math.max(0, lap.lapTime - playerCar().bestLapTimeMs)
      end
    end

    if playerCar().isLastLapValid then
      currentLap.color = color.white
    else
      currentLap.color = color.uired
    end

    table.insert(previousLaps, currentLap)

    if #previousLaps > 5 then table.remove(previousLaps, 1) end

    resetTiming(false)
    idealLap = formatTime(idealLapTime(true), false, true, true, true)
  end

  if settings.timingShowCurrentLap then
    local labelStr = 'CURRENT TIME'
    local contentStr = formatTime(playerCar().lapTimeMs, false, true, true, true)

    local labelSize = measureText(labelStr, app.font.black, fontSizeSmall)
    local contentSize = measureBox(contentStr, app.font.medium, scale(42), scaleVec2(204, 34))

    local boxWidth = math.round(math.max(position.timing.currentLap.x, position.timing.pos.currentLapTxt.x * 2 + labelSize.x, position.timing.pos.currentLapContent.x * 2 + contentSize.x))
    local boxHeight = math.round(math.max(position.timing.currentLap.y, position.timing.pos.currentLapContent.y + contentSize.y + position.timing.pos.currentLapTxt.y))
    local boxSize = vec2(boxWidth, boxHeight)

    ui.setCursor(vec2(0, vertOffset))
    ui.childWindow('CurrentTime', boxSize, function()
      ui.drawRectFilled(vec2(0, 0), boxSize, setColorMult(color.black, 50))
      ui.pushDWriteFont(app.font.black)
      ui.setCursor(position.timing.pos.currentLapTxt)
      ui.dwriteTextAligned(labelStr, fontSizeSmall, 0, 0, labelSize, false, color.white)
      ui.popDWriteFont()
      ui.pushDWriteFont(app.font.medium)
      ui.setCursor(position.timing.pos.currentLapContent)
      ui.dwriteTextAligned(contentStr, scale(42), 0, 0, contentSize, false, timeColor)
      ui.popDWriteFont()
    end)
    vertOffset = math.floor(vertOffset + boxSize.y + scale(8))
  end

  if settings.timingShowLapStats then
    local bestContentTxt, lastContentTxt, idealContentTxt
    local bestColor, lastLapColor = color.black, color.white
    local statLabels, statValues = {}, {}

    if settings.timingLapStatsBest then
      bestContentTxt = emptyTimeString
      if playerCar().bestLapTimeMs == playerCar().bestLapTimeMs and playerCar().bestLapTimeMs ~= 0 then bestColor = color.purple end
      if playerCar().bestLapTimeMs > 0 then bestContentTxt = formatTime(playerCar().bestLapTimeMs, false, true, true, true) end
      table.insert(statLabels, 'BEST')
      table.insert(statValues, bestContentTxt)
    end
    if settings.timingLapStatsLast then
      lastContentTxt = emptyTimeString
      if #previousLaps > 0 then lastLapColor = previousLaps[#previousLaps].color end
      if playerCar().previousLapTimeMs > 0 then lastContentTxt = formatTime(playerCar().previousLapTimeMs, false, true, true, true) end
      table.insert(statLabels, 'LAST')
      table.insert(statValues, lastContentTxt)
    end
    if settings.timingLapStatsIdeal then
      idealContentTxt = emptyTimeString
      if idealLap ~= 0 then idealContentTxt = idealLap end
      table.insert(statLabels, 'IDEAL')
      table.insert(statValues, idealContentTxt)
    end

    local labelWidth = measureBoxMax(statLabels, app.font.black, fontSizeSmall, vec2(0, 0), scale(12)).x
    local valueWidth = measureBoxMax(statValues, app.font.black, fontSizeSmall, vec2(0, 0), scale(10)).x
    local statWidth = math.round(labelWidth + scale(6) + valueWidth)

    if settings.timingLapStatsBest then
      local statHeight = drawStat(position, 'StatsBest', vertOffset, 'BEST', bestContentTxt, labelWidth, valueWidth, statWidth, setColorMult(bestColor, 65), setColorMult(bestColor, 50), color.white)
      vertOffset = math.floor(vertOffset + statHeight)
    end
    if settings.timingLapStatsLast then
      local statHeight = drawStat(position, 'StatsLast', vertOffset, 'LAST', lastContentTxt, labelWidth, valueWidth, statWidth, setColorMult(color.black, 80), setColorMult(color.black, 65), lastLapColor)
      vertOffset = math.floor(vertOffset + statHeight)
    end
    if settings.timingLapStatsIdeal then
      local statHeight = drawStat(position, 'StatsIdeal', vertOffset, 'IDEAL', idealContentTxt, labelWidth, valueWidth, statWidth, setColorMult(color.black, 80), setColorMult(color.black, 65), color.white)
      vertOffset = vertOffset + statHeight
    end
    vertOffset = math.floor(vertOffset + scale(45))
  end

  if settings.timingShowTable then
    local columSpace = scale(4)

    local lapItems, timeItems, deltaItems, sectorItems = { 'Lap' }, { 'Time' }, { 'Delta Best' }, {}
    for i = 1, totalSectors do
      table.insert(sectorItems, 'S' .. i)
    end

    table.insert(lapItems, lapCount + 1)
    table.insert(timeItems, currentLap.lapTime > 0 and formatTime(currentLap.lapTime, false, true, true, true) or emptyTimeString)
    table.insert(deltaItems, currentLap.delta > 0 and formatTime(currentLap.delta, false, true, true, true) or '')
    for i = 1, totalSectors do
      table.insert(sectorItems, currentLap.sectors[i] > 0 and formatTime(currentLap.sectors[i], false, true, true, true) or emptyTimeString)
    end
    for _, lap in ipairs(previousLaps) do
      table.insert(lapItems, lap.lapNum)
      table.insert(timeItems, lap.lapTime > 0 and formatTime(lap.lapTime, false, true, true, true) or emptyTimeString)
      table.insert(deltaItems, lap.delta > 0 and ('+' .. formatTime(lap.delta, false, true, true, true)) or '')
      for i = 1, totalSectors do
        table.insert(sectorItems, lap.sectors[i] > 0 and formatTime(lap.sectors[i], false, true, true, true) or emptyTimeString)
      end
    end

    local headerH, contentH = position.timing.table.header.y, position.timing.table.contentheight
    local lapColW = measureBoxMax(lapItems, app.font.black, fontSizeSmall, vec2(position.timing.table.lap, 0)).x
    local timeColW = measureBoxMax(timeItems, app.font.black, fontSizeSmall, vec2(position.timing.table.time, 0)).x
    local deltaColW = measureBoxMax(deltaItems, app.font.black, fontSizeSmall, vec2(position.timing.table.time, 0)).x
    local sectorColW = measureBoxMax(sectorItems, app.font.black, fontSizeSmall, vec2(position.timing.table.time, 0)).x

    local mainTableW = lapColW + columSpace + timeColW + columSpace + deltaColW + columSpace
    local sectorsTableW = (sectorColW + columSpace) * totalSectors

    ui.setCursor(vec2(0, vertOffset))
    ui.childWindow('TimingTableHeader', vec2(mainTableW, headerH), function()
      ui.drawRectFilled(vec2(0, 0), vec2(mainTableW, headerH), setColorMult(color.black, 80))
      ui.pushDWriteFont(app.font.black)
      ui.dwriteTextAligned('Lap', fontSizeSmall, 0, 0, vec2(lapColW, headerH), false, color.white)
      horiOffset = 0 + lapColW + columSpace
      ui.setCursor(vec2(horiOffset, 0))
      ui.dwriteTextAligned('Time', fontSizeSmall, -1, 0, vec2(timeColW, headerH), false, color.white)
      horiOffset = horiOffset + timeColW + columSpace
      ui.setCursor(vec2(horiOffset, 0))
      ui.dwriteTextAligned('Delta Best', fontSizeSmall, -1, 0, vec2(deltaColW, headerH), false, color.white)
      horiOffset = horiOffset + deltaColW + columSpace
      ui.popDWriteFont()
    end)
    ui.setCursor(vec2(math.round(horiOffset), vertOffset))
    ui.childWindow('TimingTableHeaderSectors', vec2(sectorsTableW, headerH), function()
      ui.drawRectFilled(vec2(0, 0), vec2(sectorsTableW, headerH), setColorMult(color.black, 80))
      secPos = columSpace
      for i = 1, totalSectors do
        ui.setCursorY(0)
        ui.setCursorX(secPos)
        ui.pushDWriteFont(app.font.black)
        ui.dwriteTextAligned('S' .. i, fontSizeSmall, -1, 0, vec2(sectorColW, headerH), false, color.white)
        ui.popDWriteFont()
        secPos = (sectorColW + columSpace) * i
      end
    end)
    vertOffset = math.floor(vertOffset + headerH)

    ui.setCursor(vec2(0, vertOffset))
    ui.childWindow('TimingTableContentCurrent', vec2(mainTableW, contentH), function()
      local currLapTime = emptyTimeString
      local currLapDelta = ''
      if currentLap.lapTime > 0 then currLapTime = formatTime(currentLap.lapTime, false, true, true, true) end
      if currentLap.delta > 0 then currLapDelta = formatTime(currentLap.delta, false, true, true, true) end
      ui.drawRectFilled(vec2(0, 0), vec2(mainTableW, contentH), setColorMult(color.black, 50))
      ui.pushDWriteFont(app.font.black)
      ui.dwriteTextAligned(lapCount + 1, fontSizeSmall, 0, 0, vec2(lapColW, contentH), false, color.white)
      horiOffset = 0 + lapColW + columSpace
      ui.setCursor(vec2(horiOffset, 0))
      ui.dwriteTextAligned(currLapTime, fontSizeSmall, -1, 0, vec2(timeColW, contentH), false, timeColor)
      horiOffset = horiOffset + timeColW + columSpace
      ui.setCursor(vec2(horiOffset, 0))
      ui.dwriteTextAligned(currLapDelta, fontSizeSmall, -1, 0, vec2(deltaColW, contentH), false, timeColor)
      horiOffset = horiOffset + deltaColW + columSpace
      ui.popDWriteFont()
    end)
    ui.setCursor(vec2(math.round(horiOffset), vertOffset))
    ui.childWindow('TimingTableContentSectors', vec2(sectorsTableW, contentH), function()
      ui.drawRectFilled(vec2(0, 0), vec2(sectorsTableW, contentH), setColorMult(color.black, 50))
      secPos = columSpace
      for i = 1, totalSectors do
        local currLapSector = emptyTimeString
        if currentLap.sectors[i] > 0 then currLapSector = formatTime(currentLap.sectors[i], false, true, true, true) end
        ui.setCursor(vec2(secPos, 0))
        ui.pushDWriteFont(app.font.black)
        ui.dwriteTextAligned(currLapSector, fontSizeSmall, -1, 0, vec2(sectorColW, contentH), false, timeColor)
        ui.popDWriteFont()
        secPos = (sectorColW + columSpace) * i
      end
    end)
    vertOffset = vertOffset + contentH

    for p = #previousLaps, 1, -1 do
      local reverseIndex = #previousLaps - p + 1
      ui.setCursor(vec2(0, vertOffset + contentH * (reverseIndex - 1)))
      ui.childWindow('TimingTableContentPrev' .. reverseIndex, vec2(mainTableW, contentH), function()
        local prevLapTime = emptyTimeString
        local prevLapDelta = ''
        if previousLaps[p].lapTime > 0 then prevLapTime = formatTime(previousLaps[p].lapTime, false, true, true, true) end
        if previousLaps[p].delta > 0 then prevLapDelta = '+' .. formatTime(previousLaps[p].delta, false, true, true, true) end
        ui.drawRectFilled(vec2(0, 0), vec2(mainTableW, contentH), setColorMult(color.black, 50))
        ui.pushDWriteFont(app.font.black)
        ui.dwriteTextAligned(previousLaps[p].lapNum, fontSizeSmall, 0, 0, vec2(lapColW, contentH), false, previousLaps[p].color)
        horiOffset = 0 + lapColW + columSpace
        ui.setCursor(vec2(horiOffset, 0))
        ui.dwriteTextAligned(prevLapTime, fontSizeSmall, -1, 0, vec2(timeColW, contentH), false, previousLaps[p].color)
        horiOffset = horiOffset + timeColW + columSpace
        ui.setCursor(vec2(horiOffset, 0))
        ui.dwriteTextAligned(prevLapDelta, fontSizeSmall, -1, 0, vec2(deltaColW, contentH), false, color.uired)
        horiOffset = horiOffset + deltaColW + columSpace
        ui.popDWriteFont()
      end)

      ui.setCursor(vec2(math.round(horiOffset), vertOffset + contentH * (reverseIndex - 1)))
      ui.childWindow('TimingTableContentSectorsPrev' .. reverseIndex, vec2(sectorsTableW, contentH), function()
        ui.drawRectFilled(vec2(0, 0), vec2(sectorsTableW, contentH), setColorMult(color.black, 50))
        secPos = columSpace
        for i = 1, totalSectors do
          local currLapSector = emptyTimeString
          if previousLaps[p].sectors[i] > 0 then currLapSector = formatTime(previousLaps[p].sectors[i], false, true, true, true) end
          ui.setCursor(vec2(secPos, 0))
          ui.pushDWriteFont(app.font.black)
          ui.dwriteTextAligned(currLapSector, fontSizeSmall, -1, 0, vec2(sectorColW, contentH), false, previousLaps[p].color)
          ui.popDWriteFont()
          secPos = (sectorColW + columSpace) * i
        end
      end)
    end
  end
end
