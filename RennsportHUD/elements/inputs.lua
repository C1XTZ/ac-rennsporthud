--- Draws one pedal bar
---@param position table @Position table
---@param name string @childWindow name
---@param bgColor rgbm @Background color
---@param fontBig number @Label font size
---@param lerp number @Fill width in px, 0 to pedalsize.x
---@param barColor rgbm @Fill color
---@param label string @Centered label text
---@param textColor rgbm @Label text color
---@param cursorPos vec2 @Top-left corner to draw this bar at.
local function drawPedalBar(position, name, bgColor, fontBig, lerp, barColor, label, textColor, cursorPos)
  ui.setCursor(cursorPos)
  ui.childWindow(name, vec2(position.inputs.pedalsize.x, position.inputs.pedalheight), false, app.flags, function()
    ui.drawRectFilled(vec2(0, 0), vec2(position.inputs.pedalsize.x, position.inputs.pedalheight), bgColor)
    ui.drawRectFilled(vec2(0, 0), vec2(lerp, position.inputs.pedalheight), barColor)
    ui.pushDWriteFont(app.font.bold)
    ui.dwriteTextAligned(label, fontBig, 0, 0, vec2(position.inputs.pedalsize.x, position.inputs.pedalheight - scale(1)), false, textColor)
    ui.popDWriteFont()
  end)
end

--- Draws one electronics block's label + value
---@param position table @Position table
---@param fontSmall number @Font size
---@param txtcolor rgbm @Text color
---@param x number @Left edge X
---@param y number @Top edge Y
---@param label string @Left-side label, e.g. 'ABS'
---@param value any @Right-side value text
local function drawElectronicsBlock(position, fontSmall, txtcolor, x, y, label, value)
  local rowH = position.inputs.electronics.darkbg.y / 2
  ui.setCursor(vec2(x, y))
  ui.pushDWriteFont(app.font.black)
  ui.dwriteTextAligned(label, fontSmall, 0, 0, vec2(position.inputs.electronics.darkbg.x, rowH), false, txtcolor)
  ui.popDWriteFont()

  ui.setCursor(vec2(x + position.inputs.electronics.darkbg.x, y))
  ui.pushDWriteFont(app.font.black)
  local valBox = vec2(position.inputs.electronics.val.x, position.inputs.electronics.val.y / 2)
  local valFontSize = fitFontSize(value, app.font.black, fontSmall, valBox)
  ui.dwriteTextAligned(value, valFontSize, 0, 0, valBox, false, txtcolor)
  ui.popDWriteFont()
end

function script.inputs(dt)
  local position = getPositionTable()
  local bgcolor = setColorMult(color.black, 70)
  local txtcolor = color.lightgray
  local txtcolorinv = rgbm(1 - txtcolor.r, 1 - txtcolor.g, 1 - txtcolor.b, 1)
  local fontBig = scale(12)
  local fontSmall = scale(10)
  local vertOffset = app.padding
  local horiOffset = 0

  if settings.inputsShowWheel then
    local wheelimg
    if playerCar().isRacingCar then
      wheelimg = '.\\img\\RaceWheel.png'
    else
      wheelimg = '.\\img\\StreetWheel.png'
    end
    local wheelpos = vec2(scale(1), (ui.windowHeight() / 2 + vertOffset / 2) - position.inputs.wheel.imgsize / 2)
    if settings.decor and ui.windowHeight() >= scale(130) then wheelpos.y = wheelpos.y + position.inputs.decorheight / 2 end
    ui.setCursor(wheelpos)
    ui.childWindow('Wheel', vec2(position.inputs.wheel.imgsize, position.inputs.wheel.imgsize), false, app.flags, function()
      ui.beginRotation()
      ui.drawImage(wheelimg, vec2(0, 0), vec2(position.inputs.wheel.imgsize, position.inputs.wheel.imgsize))
      ui.endRotation(playerCar().steer * -1 + 90)
    end)
    horiOffset = math.round(position.inputs.wheel.imgsize + position.inputs.wheel.padding + scale(1))
  end

  if settings.decor then
    ui.setCursor(vec2(horiOffset, vertOffset))
    ui.childWindow('Decor', vec2(position.inputs.pedalsize.x, position.inputs.decorheight), false, app.flags, function()
      ui.drawRectFilled(vec2(ui.getCursorX(), ui.getCursorY()), vec2(ui.getCursorX() + position.inputs.pedalsize.x, ui.getCursorY() + position.inputs.decorheight), color.white)
      ui.setCursor(vec2(math.round(ui.getCursorX() + position.inputs.pedalsize.x / 2 - position.inputs.decorimg.x / 2), math.round(ui.getCursorY() + (position.inputs.decorheight / 2 - position.inputs.decorimg.y / 2))))
      ui.drawImage('.\\img\\RennsportLogo.png', vec2(ui.getCursorX(), ui.getCursorY()), vec2(ui.getCursorX() + position.inputs.decorimg.x, ui.getCursorY() + position.inputs.decorimg.y))
    end)
    vertOffset = math.floor(vertOffset + position.inputs.decorheight)
  end

  if settings.inputsShowSteering then
    ui.setCursor(vec2(horiOffset, vertOffset))
    ui.childWindow('Steering', vec2(position.inputs.pedalsize.x, position.inputs.steeringbar.y), false, app.flags, function()
      local steerLerp = math.lerp(ui.getCursorX(), ui.getCursorX() + position.inputs.pedalsize.x - position.inputs.steeringbar.x, math.lerpInvSat(playerCar().steer, -playerCar().steerLock, playerCar().steerLock))
      ui.drawRectFilled(vec2(ui.getCursorX(), ui.getCursorY()), vec2(ui.getCursorX() + position.inputs.pedalsize.x, ui.getCursorY() + position.inputs.steeringbar.y), color.black)
      ui.drawRectFilled(vec2(ui.getCursorX() + steerLerp, ui.getCursorY()), vec2(ui.getCursorX() + steerLerp + position.inputs.steeringbar.x, ui.getCursorY() + position.inputs.steeringbar.y), color.white)
    end)
    vertOffset = math.floor(vertOffset + position.inputs.steeringbar.y)
  end

  if settings.inputsShowPedals then
    local FFBmix = playerCar().ffbFinal
    if FFBmix < 0 then FFBmix = FFBmix * -1 end
    local FFBcolor
    local FFBlerp = math.lerp(0, position.inputs.pedalsize.x, FFBmix)
    if FFBlerp < position.inputs.pedalsize.x then
      FFBcolor = color.white
    else
      FFBcolor = color.red
    end

    local gasColor, brakeColor, clutchColor = color.white, color.white, color.white
    local ffbTextColor, gasTextColor, brakeTextColor, clutchTextColor = txtcolor, txtcolor, txtcolor, txtcolor

    if settings.inputsPedalColors then
      if playerCar().gas == 1 then gasColor = color.green end
      if playerCar().brake == 1 then brakeColor = color.red end
      if playerCar().clutch == 0 then clutchColor = color.aqua end
    end

    if FFBmix >= 0.75 then ffbTextColor = txtcolorinv end
    if playerCar().gas >= 0.65 then gasTextColor = txtcolorinv end
    if playerCar().brake >= 0.6 then brakeTextColor = txtcolorinv end
    if playerCar().clutch <= 0.45 then clutchTextColor = txtcolorinv end

    local clutchLerp = math.lerp(position.inputs.pedalsize.x, 0, playerCar().clutch)
    local brakeLerp = math.lerp(0, position.inputs.pedalsize.x, playerCar().brake)
    local gasLerp = math.lerp(0, position.inputs.pedalsize.x, playerCar().gas)
    if FFBlerp >= position.inputs.pedalsize.x then FFBlerp = position.inputs.pedalsize.x end

    local pedals = {
      { enabled = settings.inputsShowFFB, name = 'FFB', lerp = FFBlerp, color = FFBcolor, label = 'FORCE FEEDBACK', textColor = ffbTextColor },
      { enabled = settings.inputsShowClutch, name = 'Clutch', lerp = clutchLerp, color = clutchColor, label = 'CLUTCH', textColor = clutchTextColor },
      { enabled = settings.inputsShowBrake, name = 'Brake', lerp = brakeLerp, color = brakeColor, label = 'BRAKE', textColor = brakeTextColor },
      { enabled = settings.inputsShowGas, name = 'Gas', lerp = gasLerp, color = gasColor, label = 'THROTTLE', textColor = gasTextColor },
    }
    for _, p in ipairs(pedals) do
      if p.enabled then
        drawPedalBar(position, p.name, bgcolor, fontBig, p.lerp, p.color, p.label, p.textColor, vec2(horiOffset, vertOffset))
        vertOffset = math.floor(vertOffset + position.inputs.pedalheight)
      end
    end
  end

  if settings.inputsShowElectronics then
    local absactive = playerCar().absMode
    local absmax = playerCar().absModes
    local absfinal
    if absactive > 0 and absmax < 1 then absmax = absactive end
    if absactive == 0 then
      absfinal = 'OFF'
    elseif absmax == 1 and absactive == 1 then
      absfinal = 'ON'
    else
      absfinal = absactive .. '/' .. absmax
    end

    local tcactive = playerCar().tractionControlMode
    local tcmax = playerCar().tractionControlModes
    local tcfinal
    if tcactive > 0 and tcmax < 1 then tcmax = tcactive end
    if tcactive == 0 then
      tcfinal = 'OFF'
    elseif tcmax == 1 and tcactive == 1 then
      tcfinal = 'ON'
    else
      tcfinal = tcactive .. '/' .. tcmax
    end

    local brakebalance = math.round(playerCar().brakeBias * 100)
    local boost = playerCar().turboBoost

    local darkbgcolor = setColorMult(color.black, 50)
    local ABScolor, TCcolor = darkbgcolor, darkbgcolor
    if playerCar().absInAction then ABScolor = color.uigreen end
    if playerCar().tractionControlInAction then TCcolor = color.uigreen end

    ui.setCursor(vec2(horiOffset, vertOffset))
    ui.childWindow('Electronics', vec2(position.inputs.pedalsize.x, position.inputs.electronics.lightbg), false, app.flags, function()
      ui.drawRectFilled(vec2(0, 0), vec2(position.inputs.pedalsize.x, position.inputs.electronics.lightbg), bgcolor)

      local rowH = position.inputs.electronics.darkbg.y / 2

      local leftBlocks = {
        { label = 'ABS', value = absfinal, bgColor = ABScolor, y = 0 },
        { label = 'TC', value = tcfinal, bgColor = TCcolor, y = rowH },
      }
      for _, block in ipairs(leftBlocks) do
        ui.drawRectFilled(vec2(0, block.y), vec2(position.inputs.electronics.darkbg.x, block.y + rowH), block.bgColor)
        drawElectronicsBlock(position, fontSmall, txtcolor, 0, block.y, block.label, block.value)
      end

      local rightX = ui.availableSpaceX() / 2
      ui.drawRectFilled(vec2(rightX, 0), vec2(rightX + position.inputs.electronics.darkbg.x, position.inputs.electronics.darkbg.y), darkbgcolor)
      local rightBlocks = {
        { label = 'BB', value = brakebalance .. '%', y = 0 },
        { label = 'TRB', value = string.format('%.2f', math.round(boost, 2)), y = rowH },
      }
      for _, block in ipairs(rightBlocks) do
        drawElectronicsBlock(position, fontSmall, txtcolor, rightX, block.y, block.label, block.value)
      end
    end)
  end
end
