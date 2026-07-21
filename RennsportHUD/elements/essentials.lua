local indicatorState = {
  left = { progress = 0, active = false },
  right = { progress = 0, active = false },
  phase = { time = nil, accumulator = 0 },
  animDuration = 0.1,
  minWidthPercent = 0.2,
}

--- Parses the gear number for UI use.
---@param gearNum number @The gear number to be parsed.
---@return string @The parsed gear number as a string.
---@diagnostic disable-next-line: lowercase-global
function parseGear(gearNum)
  if gearNum == 0 then
    return 'N'
  elseif gearNum == -1 then
    return 'R'
  else
    return tostring(gearNum)
  end
end

--- Draws one turn indicator (left or right), animating its width in/out over animDuration.
---@param position table @Position table
---@param centerx number @Horizontal center of the essentials window.
---@param isRight boolean @true for the right indicator, false for left.
---@param dt number @Frame delta time.
local function drawIndicator(position, centerx, isRight, dt)
  local side = isRight and 'right' or 'left'
  local state = indicatorState[side]
  local baseWidth = position.essentials.indicators.size.x
  local isLightOn = isRight and playerCar().turningRightLights or playerCar().turningLeftLights
  local phaseDuration = indicatorState.phase.time or (indicatorState.animDuration + 0.15)

  if isLightOn and not state.active then
    state.progress = 0
    indicatorState.phase.accumulator = 0
  end
  state.active = isLightOn

  if (playerCar().turningLightsActivePhase and isLightOn) or (state.progress > 0 and state.progress < 1) then
    state.progress = math.min(1, state.progress + dt / phaseDuration)

    if not indicatorState.phase.time and playerCar().turningLightsActivePhase and isLightOn then
      indicatorState.phase.accumulator = indicatorState.phase.accumulator + dt
      if state.progress >= 1 then indicatorState.phase.time = indicatorState.phase.accumulator end
    end

    local width = baseWidth * (indicatorState.minWidthPercent + (2 - indicatorState.minWidthPercent) * state.progress)
    local xPosition = isRight and (centerx * 2 - baseWidth) or (baseWidth - width)

    ui.setCursor(vec2(xPosition, 12))
    ui.drawRectFilled(ui.getCursor(), ui.getCursor() + vec2(width, position.essentials.indicators.size.y), color.yellow)
  elseif state.progress >= 1 then
    state.progress = 0
    if indicatorState.left.progress == 0 and indicatorState.right.progress == 0 then indicatorState.phase = { time = nil, accumulator = 0 } end
  end
end

--- Draws one input bar (Clutch/Brake/Gas/FFB) inside the RPM display.
---@param position table @Position table
---@param cursorPos vec2 @Top-left corner to draw this bar at.
---@param lerp number @Fill height in px, 0 to inputbar.size.y
---@param barColor rgbm @Fill color
local function drawInputBar(position, cursorPos, lerp, barColor)
  ui.setCursor(cursorPos)
  ui.drawRectFilled(vec2(ui.getCursorX(), ui.getCursorY()), vec2(ui.getCursorX() + position.essentials.inputbar.size.x, ui.getCursorY() + position.essentials.inputbar.size.y), setColorMult(color.black, 50))
  ui.drawRectFilled(vec2(ui.getCursorX(), ui.getCursorY() + position.essentials.inputbar.size.y), vec2(ui.getCursorX() + position.essentials.inputbar.size.x, ui.getCursorY() + position.essentials.inputbar.size.y - lerp), barColor)
end

function script.essentials(dt)
  local position = getPositionTable()

  if settings.essentialsCompactMode then
    local essentials = {}
    for k, v in pairs(position.essentials) do
      essentials[k] = v
    end
    essentials.elementsize = scaleVec2(297, 85)
    essentials.rpmbarheight = scale(10)
    essentials.decor = { left = scaleVec2(38, 30), right = scaleVec2(35, 30), size = scaleVec2(4, 51) }
    position = { essentials = essentials }
  end

  ui.setCursor(vec2(0, app.padding))
  ui.childWindow('main', position.essentials.elementsize, function()
    local centerx = ui.availableSpaceX() / 2
    local centery = ui.availableSpaceY() / 2

    if settings.essentialsRpmBar then
      local rpmMix = playerCar().rpm / playerCar().rpmLimiter
      local rpmPercentage = math.round(rpmMix * 100)
      local rpmBarColor
      if settings.essentialsRpmBarColor and rpmPercentage >= settings.essentialsRpmBarShiftYellow - 1 and rpmPercentage <= settings.essentialsRpmBarShiftRed then
        rpmBarColor = color.yellow
      elseif settings.essentialsRpmBarColor and rpmPercentage >= settings.essentialsRpmBarShiftRed - 1 then
        rpmBarColor = color.red
      else
        rpmBarColor = color.white
      end

      ui.setCursor(vec2(0, 0))
      ui.drawRectFilled(vec2(0, ui.getCursorY()), vec2(ui.availableSpaceX(), ui.getCursorY() + position.essentials.rpmbarheight), setColorMult(color.black, 50))
      ui.drawRectFilled(vec2(0, ui.getCursorY()), vec2(math.lerp(0, ui.availableSpaceX(), rpmMix), ui.getCursorY() + position.essentials.rpmbarheight), rpmBarColor)
    end

    if settings.essentialsSpeedNum then
      local speedText
      local speedNumber
      if not settings.essentialsSpeedNumMPH then
        speedText = 'KM/H'
        speedNumber = math.round(playerCar().speedKmh)
      else
        speedText = 'MP/H'
        speedNumber = math.round(playerCar().speedKmh / 1.6093440006147)
      end

      ui.setCursor(vec2(centerx - position.essentials.speed.num.x, centery - position.essentials.speed.num.y))
      ui.pushDWriteFont(app.font.bold)
      local speedBox = scaleVec2(60, 28)
      local speedFontSize = fitFontSize(speedNumber, app.font.bold, scale(34), speedBox)
      ui.dwriteTextAligned(tostring(speedNumber), speedFontSize, 1, 0, speedBox, false, color.white)
      ui.popDWriteFont()

      ui.setCursor(vec2(centerx - position.essentials.speed.txt.x, centery + position.essentials.speed.txt.y))
      ui.pushDWriteFont(app.font.black)
      ui.dwriteTextAligned(speedText, scale(14), 1, 0, scaleVec2(38, 14), false, color.white)
      ui.popDWriteFont()
    end

    if settings.decor then
      ui.setCursor(vec2(centerx - position.essentials.decor.left.x, centery - position.essentials.decor.left.y))
      ui.drawRectFilled(vec2(ui.getCursorX(), ui.getCursorY()), vec2(ui.getCursorX() + position.essentials.decor.size.x, ui.getCursorY() + position.essentials.decor.size.y), color.white)
      ui.setCursor(vec2(centerx + position.essentials.decor.right.x, centery - position.essentials.decor.left.y))
      ui.drawRectFilled(vec2(ui.getCursorX(), ui.getCursorY()), vec2(ui.getCursorX() + position.essentials.decor.size.x, ui.getCursorY() + position.essentials.decor.size.y), color.white)
    end

    if settings.essentialsGears then
      ui.setCursor(vec2(centerx - position.essentials.gear.x, centery - position.essentials.gear.y))
      ui.pushDWriteFont(app.font.bold)
      local gearTxt = parseGear(playerCar().gear)
      local gearBox = scaleVec2(70, 50)
      local gearFontSize = fitFontSize(gearTxt, app.font.bold, scale(60), gearBox)
      ui.dwriteTextAligned(gearTxt, gearFontSize, 0, 0, gearBox, false, color.white)
      ui.popDWriteFont()
    end

    if settings.essentialsRpmNum and not settings.essentialsInputBars then
      ui.setCursor(vec2(centerx + position.essentials.rpm.num.x, centery - position.essentials.rpm.num.y))
      ui.pushDWriteFont(app.font.bold)
      local rpmTxt = math.round(playerCar().rpm)
      local rpmBox = scaleVec2(150, 28)
      local rpmFontSize = fitFontSize(rpmTxt, app.font.bold, scale(34), rpmBox)
      ui.dwriteTextAligned(tostring(rpmTxt), rpmFontSize, -1, 0, rpmBox, false, color.white)
      ui.popDWriteFont()

      ui.setCursor(vec2(centerx + position.essentials.rpm.txt.x, centery + position.essentials.rpm.txt.y))
      ui.pushDWriteFont(app.font.black)
      ui.dwriteText('RPM', scale(14), color.white)
      ui.popDWriteFont()
    end

    if settings.essentialsInputBars and settings.essentialsRpmNum then
      local FFBmix = playerCar().ffbFinal
      if FFBmix < 0 then FFBmix = FFBmix * -1 end
      local FFBcolor
      local FFBlerp = math.lerp(0, position.essentials.inputbar.size.y, FFBmix)
      if FFBlerp <= position.essentials.inputbar.size.y then
        FFBcolor = color.gray
      else
        FFBcolor = color.red
      end

      local clutchLerp = math.lerp(position.essentials.inputbar.size.y, 0, playerCar().clutch)
      local brakeLerp = math.lerp(0, position.essentials.inputbar.size.y, playerCar().brake)
      local gasLerp = math.lerp(0, position.essentials.inputbar.size.y, playerCar().gas)

      if FFBlerp > position.essentials.inputbar.size.y then FFBlerp = position.essentials.inputbar.size.y end

      local inputBars = {
        { lerp = clutchLerp, color = color.aqua },
        { lerp = brakeLerp, color = color.red },
        { lerp = gasLerp, color = color.green },
        { lerp = FFBlerp, color = FFBcolor },
      }
      for i, bar in ipairs(inputBars) do
        local cursorPos = vec2(centerx + position.essentials.inputbar.pos.x + position.essentials.inputbar.gap * (i - 1), centery - position.essentials.inputbar.pos.y)
        drawInputBar(position, cursorPos, bar.lerp, bar.color)
      end
    end

    if playerCar().hasTurningLights then
      if playerCar().turningLeftLights or indicatorState.left.progress > 0 then drawIndicator(position, centerx, false, dt) end
      if playerCar().turningRightLights or indicatorState.right.progress > 0 then drawIndicator(position, centerx, true, dt) end
    end
  end)
end
