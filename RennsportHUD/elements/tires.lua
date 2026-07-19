---@param hue number @Hue value, should be 0-240.
---@return rgb @The RGB value.
--- A simplified version of a HSL to RGB converter where the saturation is always at 100%, and the lightness is at 50%.
function hueToRgb(hue)
  local h = hue / 60
  local c = 1
  local x = 1 - math.abs(h % 2 - 1)
  local r, g, b

  if h >= 0 and h < 1 then
    r, g, b = c, x, 0
  elseif h >= 1 and h < 2 then
    r, g, b = x, c, 0
  elseif h >= 2 and h < 3 then
    r, g, b = 0, c, x
  elseif h >= 3 and h < 4 then
    r, g, b = 0, x, c
  elseif h >= 4 and h < 5 then
    r, g, b = x, 0, c
  else
    r, g, b = c, 0, x
  end

  local m = 0.5 - c / 2

  return rgb(r + m, g + m, b + m)
end

---@param lutStr string @A LUT string.
---@return integer @The median temperature value of the highest performance value.
--- Inspired by pseudo code from leBluem, this calculates the median temperature value of the highest performance value from a LUT string.
function getLUTMedian(lutStr)
  if lutStr == '-1' then return -1 end
  local xTable, yTable = {}, {}
  local yHighest = -1
  for x, y in lutStr:gmatch('|(%d+)=(%d*%.?%d*)') do
    table.insert(xTable, tonumber(x))
    local yValue = tonumber(y)
    table.insert(yTable, yValue)
    if yValue > yHighest then yHighest = yValue end
  end

  if yHighest == -1 then return 0 end

  local xHighest = {}
  for i, y in ipairs(yTable) do
    if y == yHighest then table.insert(xHighest, xTable[i]) end
  end

  local xTotal = 0
  for _, x in ipairs(xHighest) do
    xTotal = xTotal + x
  end

  return xTotal / #xHighest
end

local tireIni = ac.INIConfig.carData(playerCar().index, 'tyres.ini')
local tireName = playerCar():tyresLongName():gsub('%s?%b()', '')

--- Retrieves a property value for a given tire name in a given section.
---@param sectionName string @The section to look in.
---@param propertyName string @The property to get.
---@return any @The property value for the given tire name in the given section.
local function getTireProperty(sectionName, propertyName)
  for index, section in tireIni:iterate(sectionName, true) do
    if tireIni:get(section, 'NAME', nil) and tireIni:get(section, 'NAME', nil)[1] == tireName then
      if propertyName == 'PERFORMANCE_CURVE' then
        return tireIni:get('THERMAL_' .. section, propertyName, 'string')
      else
        return tireIni:get(section, propertyName, 'string')
      end
    end
  end
  return '-1'
end

--- Retrieves the optimal pressures for the front and rear tires.
---@return number frontPressure @The optimal pressure for the front tires.
---@return number rearPressure @The optimal pressure for the rear tires.
local function getOptPressure()
  local frontPressure = getTireProperty('FRONT', 'PRESSURE_IDEAL')
  local rearPressure = getTireProperty('REAR', 'PRESSURE_IDEAL')
  return frontPressure, rearPressure
end

--- Retrieves the optimal temperatures for the front and rear tires.
---@return number frontOptTemp @The optimal temperature for the front tires.
---@return number rearOptTemp @The optimal temperature for the rear tires.
local function getOptTemperature()
  local frontCurve = getTireProperty('FRONT', 'PERFORMANCE_CURVE')
  local rearCurve = getTireProperty('REAR', 'PERFORMANCE_CURVE')
  local frontOptTemp, rearOptTemp

  if frontCurve == -1 or rearCurve == -1 then return -1, -1 end

  if string.match(frontCurve, '%.lut$') then
    frontOptTemp = getLUTMedian(ac.DataLUT11.carData(playerCar().index, frontCurve):serialize())
  else
    frontOptTemp = getLUTMedian(frontCurve)
  end

  if string.match(rearCurve, '%.lut$') then
    rearOptTemp = getLUTMedian(ac.DataLUT11.carData(playerCar().index, rearCurve):serialize())
  else
    rearOptTemp = getLUTMedian(rearCurve)
  end

  if frontOptTemp == -1 or rearOptTemp == -1 then return -1, -1 end

  tiresFound = true
  return frontOptTemp, rearOptTemp
end

local frontOptTemp, rearOptTemp = getOptTemperature()

local brakeIni = ac.INIConfig.carData(playerCar().index, 'brakes.ini')
local fOptBrakeTemp, rOptBrakeTemp, fBrakeLut, rBrakeLut

local brakesFound = false
if brakeIni:get('TEMPS_FRONT', 'PERF_CURVE', nil) then
  fBrakeLut = tostring(brakeIni:get('TEMPS_FRONT', 'PERF_CURVE', nil)[1])
  rBrakeLut = tostring(brakeIni:get('TEMPS_REAR', 'PERF_CURVE', nil)[1])
  brakesFound = true
end

if not fBrakeLut or not rBrakeLut then
  fOptBrakeTemp, rOptBrakeTemp = -1, -1
else
  if string.match(fBrakeLut, '%.lut$') and string.match(rBrakeLut, '%.lut$') then
    fOptBrakeTemp = getLUTMedian(ac.DataLUT11.carData(playerCar().index, fBrakeLut):serialize())
    rOptBrakeTemp = getLUTMedian(ac.DataLUT11.carData(playerCar().index, rBrakeLut):serialize())
  else
    fOptBrakeTemp = getLUTMedian(fBrakeLut)
    rOptBrakeTemp = getLUTMedian(rBrakeLut)
  end
end

local currComp = -1
local wearBg = rgbm(0.4, 0.4, 0.4, 1)

local wearPercent = { 0.50, 0.25, 0.0 }
local wearPercentColors = { getColorTable().red, getColorTable().yellow, getColorTable().white }

local tempSurface = {}
local tempOptimal = {}
local tempCore = {}
local surfaceWeight = 0.2
local barMult = 0.0689475729

--- Draws tiretemp numbers
---@param position table @Position table
---@param cursorPos vec2 @Where to draw this number.
---@param value number @The temperature value to display.
local function drawTempNum(position, cursorPos, value)
  local box = vec2(position.tires.tempbartxt.x, position.tires.tempbarheight / 2)
  local txt = string.format('%1.f', value)
  local fontSize = fitFontSize(txt, app.font.black, position.tires.tempbartxt.y, box)
  ui.setCursor(cursorPos)
  ui.dwriteTextAligned(txt, fontSize, 0, -1, box, false, color.white)
end

--- Draws one wheel's tire-temp/wear/brake/pressure diagram.
---@param position table @Position table
---@param name string @childWindow name
---@param wheelIdx integer @0-3, matches playerCar().wheels index
---@param hueRow table @This wheel's {outside, middle, inside} temp hues
---@param wearColor rgbm @This wheel's wear indicator color
---@param side table @sideConfig.left or sideConfig.right
---@param optBrakeTemp number @Front or rear optimal brake temp, whichever this wheel is
---@param cursorPos vec2 @Top-left corner to draw this wheel at.
local function drawWheel(position, name, wheelIdx, hueRow, wearColor, side, optBrakeTemp, cursorPos)
  ui.setCursor(cursorPos)
  ui.childWindow(name, position.tires.wheelelement, function()
    ui.drawRectFilled(vec2(0, 0), position.tires.wheelelement, setColorMult(color.black, 50))

    local partSpacing = scale(8)
    ui.setCursor(vec2(position.tires.wheelelement.x / 2 - position.tires.wheelpartsize.x / 2, position.tires.wheelpos))
    ui.drawRectFilled(ui.getCursor(), vec2(ui.getCursorX() + position.tires.wheelpartsize.x, ui.getCursorY() + position.tires.wheelpartsize.y), tiresFound and hueToRgb(hueRow[2]) or color.gray)
    ui.setCursorX(ui.getCursorX() - partSpacing)
    ui.drawRectFilled(ui.getCursor(), vec2(ui.getCursorX() + position.tires.wheelpartsize.x, ui.getCursorY() + position.tires.wheelpartsize.y), tiresFound and hueToRgb(hueRow[3]) or color.gray, scale(5), 5)
    ui.setCursorX(ui.getCursorX() + partSpacing * 2)
    ui.drawRectFilled(ui.getCursor(), vec2(ui.getCursorX() + position.tires.wheelpartsize.x, ui.getCursorY() + position.tires.wheelpartsize.y), tiresFound and hueToRgb(hueRow[1]) or color.gray, scale(5), 10)

    if settings.tiresShowWear then
      ui.setCursorX(ui.getCursorX() + side.wearOffsetX)
      ui.setCursorY(ui.getCursorY() + position.tires.wearsize.y)
      local wearOl = scale(1)
      ui.drawRectFilled(vec2(ui.getCursorX() - wearOl, ui.getCursorY() + wearOl), vec2(ui.getCursorX() + (position.tires.wearsize.x + wearOl), ui.getCursorY() - (position.tires.wearsize.y + wearOl)), color.black)
      ui.drawRectFilled(ui.getCursor(), vec2(ui.getCursorX() + position.tires.wearsize.x, ui.getCursorY() - position.tires.wearsize.y), wearBg)
      ui.drawRectFilled(ui.getCursor(), vec2(ui.getCursorX() + position.tires.wearsize.x, ui.getCursorY() - (position.tires.wearsize.y * (1 - playerCar().wheels[wheelIdx].tyreWear))), wearColor)
      ui.setCursor(vec2(ui.getCursorX() - scale(6), ui.getCursorY() + scale(1)))
      ui.pushDWriteFont(app.font.black)
      local wearTxt = tostring(math.round((1 - playerCar().wheels[wheelIdx].tyreWear) * 100))
      local wearBox = scaleVec2(17, 12)
      local wearFontSize = fitFontSize(wearTxt, app.font.black, scale(9), wearBox)
      ui.dwriteTextAligned(wearTxt, wearFontSize, 0, 0, wearBox, false, color.white)
      ui.popDWriteFont()
    end

    if settings.tiresShowBrakeTemp then
      local brakeHue = math.lerp(240, 0, math.lerpInvSat(math.max(0, (playerCar().wheels[wheelIdx].discTemperature / optBrakeTemp)), 0, 2))
      ui.setCursor(vec2(position.tires.wheelelement.x / 2 + side.brakeSign * position.tires.brakepos.x + side.brakeExtra, position.tires.brakepos.y))
      ui.drawRectFilled(ui.getCursor(), vec2(ui.getCursorX() + position.tires.brakesize.x, ui.getCursorY() + position.tires.brakesize.y), brakesFound and hueToRgb(brakeHue) or color.gray)
    end

    if settings.tiresShowPressure then
      local pressure = playerCar().wheels[wheelIdx].tyrePressure
      local pressureTxt, unitTxt
      if settings.tiresPressureUseBar then
        unitTxt = ' bar'
        pressureTxt = string.format('%.1f', pressure * barMult):gsub('%.', ',')
      else
        unitTxt = ' psi'
        pressureTxt = string.format('%.1f', pressure):gsub('%.', ',')
      end

      local pressColor = color.white
      if settings.tiresPressureColor then pressColor = tiresFound and hueToRgb(math.lerp(240, 0, math.lerpInvSat(math.max(0, (pressure / tireIni.fPressOpt) ^ 10), 0, 2))) or color.gray end

      ui.setCursor(0)
      ui.pushDWriteFont(app.font.black)
      local pressText = pressureTxt .. unitTxt
      local pressBox = vec2(position.tires.wheelelement.x, position.tires.pressurepos)
      local pressFontSize = fitFontSize(pressText, app.font.black, scale(10), pressBox)
      ui.dwriteTextAligned(pressText, pressFontSize, 0, 0, pressBox, false, pressColor)
      ui.popDWriteFont()
    end
  end)
end

function script.tires(dt)
  local position = getPositionTable()
  local vertOffset = math.round(app.padding)

  local sideConfig = {
    left = { brakeSign = 1, brakeExtra = 0, wearOffsetX = -scale(34) },
    right = { brakeSign = -1, brakeExtra = -scale(3), wearOffsetX = scale(18) },
  }

  settings.tiresBrakesConfigured = brakesFound
  settings.tiresTiresConfigured = tiresFound

  if settings.tiresShowPressure and settings.tiresPressureColor and playerCar().compoundIndex ~= currComp then
    currComp = playerCar().compoundIndex
    tireName = playerCar():tyresLongName():gsub('%s?%b()', '')
    tireIni.fPressOpt, tireIni.rPressOpt = getOptPressure()
    if tireIni.fPressOpt == '-1' or tireIni.rPressOpt == '-1' then
      tireIni.fPressOpt, tireIni.rPressOpt = 999, 999
    end
  end

  --[[ LEFT SIDE TEMPS ARE FLIPPED, MEANING tyreInsideTemperature and tyreOutsideTemperature ARE FLIPPED FOR wheels[0] and wheels[2]
    ac.debug('FRONT LEFT OT', ac.getCar(0).wheels[0].tyreOutsideTemperature)
    ac.debug('FRONT LEFT MT', ac.getCar(0).wheels[0].tyreMiddleTemperature)
    ac.debug('FRONT LEFT IT', ac.getCar(0).wheels[0].tyreInsideTemperature)

    ac.debug('REAR LEFT OT', ac.getCar(0).wheels[2].tyreOutsideTemperature)
    ac.debug('REAR LEFT MT', ac.getCar(0).wheels[2].tyreMiddleTemperature)
    ac.debug('REAR LEFT IT', ac.getCar(0).wheels[2].tyreInsideTemperature)
    --]]

  local wearColor = {}
  for i = 0, 3 do
    local tyreWear = playerCar().wheels[i].tyreWear
    wearColor[i] = color.white
    for j = 1, #wearPercent do
      if tyreWear > wearPercent[j] then
        wearColor[i] = wearPercentColors[j]
        break
      end
    end
  end

  for i = 0, 3 do
    local wheel = playerCar().wheels[i]
    tempOptimal[i + 1] = (i < 2) and frontOptTemp or rearOptTemp
    tempSurface[i + 1] = { wheel.tyreOutsideTemperature, wheel.tyreMiddleTemperature, wheel.tyreInsideTemperature }
    tempCore[i + 1] = { wheel.tyreCoreTemperature, wheel.tyreCoreTemperature, wheel.tyreCoreTemperature }
  end

  local tempHue = { [0] = {}, [1] = {}, [2] = {}, [3] = {} }
  if settings.tiresShowTempVis then
    for i = 1, 3 do
      for w = 0, 3 do
        local tempAvg = (tempCore[w + 1][i] * (1 - surfaceWeight)) + (tempSurface[w + 1][i] * surfaceWeight)
        tempHue[w][i] = math.lerp(240, 0, math.lerpInvSat(math.max(0, (tempAvg / tempOptimal[w + 1]) ^ 3), 0, 2))
      end
    end
  end

  if settings.decor then
    ui.setCursor(vec2(0, vertOffset))
    ui.childWindow('tiresDecor', position.tires.decorsize, function()
      ui.drawRectFilled(vec2(0, 0), position.tires.decorsize, color.white)
      ui.setCursorX(scale(15))
      ui.pushDWriteFont(app.font.black)
      ui.dwriteTextAligned('TIRES', scale(14), -1, 0, position.tires.decorsize, false, color.black)
      ui.popDWriteFont()
    end)
    vertOffset = math.round(vertOffset + position.tires.decorsize.y)
  end

  if settings.tiresShowTempVis then
    local frontWheels = {
      { idx = 0, name = 'tiresFL', side = sideConfig.left },
      { idx = 1, name = 'tiresFR', side = sideConfig.right },
    }
    for i, w in ipairs(frontWheels) do
      drawWheel(position, w.name, w.idx, tempHue[w.idx], wearColor[w.idx], w.side, fOptBrakeTemp, vec2((i - 1) * position.tires.wheelelement.x, vertOffset))
    end
    vertOffset = math.floor(vertOffset + position.tires.wheelelement.y)
  end

  if settings.tiresShowTempBar then
    local tempNum = {}
    for w = 0, 3 do
      tempNum[w] = { tempSurface[w + 1][1], tempSurface[w + 1][2], tempSurface[w + 1][3] }
      if settings.tiresTempUseFahrenheit then
        for i = 1, 3 do
          tempNum[w][i] = (tempSurface[w + 1][i] * 1.8) + 32
        end
      end
    end

    local tempTxtL = scaleVec2(4, 0)
    local tempTxtM = scaleVec2(30, 0)
    local tempTxtR = scaleVec2(56, 0)
    local cellW, cellH = position.tires.decorsize.x / 2, position.tires.tempbarheight / 2

    local tempBarCells = {
      { name = 'tempBarFL', wheelIdx = 0, col = 0, row = 0 },
      { name = 'tempBarRL', wheelIdx = 2, col = 0, row = 1 },
      { name = 'tempBarFR', wheelIdx = 1, col = 1, row = 0 },
      { name = 'tempBarRR', wheelIdx = 3, col = 1, row = 1 },
    }
    for _, cell in ipairs(tempBarCells) do
      ui.setCursor(vec2(cell.col * cellW, vertOffset + cell.row * cellH))
      ui.childWindow(cell.name, vec2(cellW, cellH), function()
        ui.drawRectFilled(ui.getCursor(), vec2(cellW, cellH), color.black)
        ui.pushDWriteFont(app.font.black)
        drawTempNum(position, tempTxtL, tempNum[cell.wheelIdx][3])
        drawTempNum(position, tempTxtM, tempNum[cell.wheelIdx][2])
        drawTempNum(position, tempTxtR, tempNum[cell.wheelIdx][1])
        ui.popDWriteFont()
      end)
    end

    vertOffset = math.round(vertOffset + math.floor(position.tires.tempbarheight))
    if vertOffset % 2 ~= 0 then vertOffset = vertOffset - 1 end
  end

  if settings.tiresShowTempVis then
    local rearWheels = {
      { idx = 2, name = 'tiresRL', side = sideConfig.left },
      { idx = 3, name = 'tiresRR', side = sideConfig.right },
    }
    for i, w in ipairs(rearWheels) do
      drawWheel(position, w.name, w.idx, tempHue[w.idx], wearColor[w.idx], w.side, rOptBrakeTemp, vec2((i - 1) * position.tires.wheelelement.x, vertOffset))
    end
  end
end
