local sessionTypes = {
  [0] = 'SESSION',
  [1] = 'PRACTICE',
  [2] = 'QUALIFYING',
  [3] = 'RACE',
  [4] = 'HOTLAP',
  [5] = 'TIME ATTACK',
  [6] = 'DRIFT',
  [7] = 'DRAG',
}

--- Converts a session type to a string.
---@param sessionType ac.SessionType @The session type to be converted.
---@return string @The name of the session as a string.
local function getSessionTypeString(sessionType)
  if not settings.sessionTimerType then return sessionTypes[0] end

  local sessionTypeString = sessionTypes[sessionType] or sessionTypes[0]
  return sessionTypeString
end

function script.session(dt)
  local position = getPositionTable()
  local playerSession = ac.getSim()
  local vertOffset = app.padding
  local horiOffset = 0
  local bgcolor = setColorMult(color.black, 50)
  local smallTxt = scale(14)
  local bigTxt = scale(42)

  if settings.sessionShowPosition then
    local playerRacePosition = string.format('%02d', playerCar().racePosition) .. '/'
    local sessionCarsTotal = string.format('%02d', playerSession.carsCount)
    if settings.sessionHideDisconnected then sessionCarsTotal = string.format('%02d', playerSession.connectedCars) end
    if settings.sessionHideAI and settings.sessionHideDisconnected then
      local hiddenCars = 0
      for i = playerSession.carsCount - 1, 0, -1 do
        local car = ac.getCar(i)
        if not car then return end
        if car.isConnected and car.isHidingLabels then hiddenCars = hiddenCars + 1 end
      end
      sessionCarsTotal = string.format('%02d', playerSession.connectedCars - hiddenCars)
    end

    local largeContentSize = measureBox(playerRacePosition, app.font.semi, bigTxt, position.session.positiontxt.contentlargesize)
    local smallContentSize = measureBox(sessionCarsTotal, app.font.bold, scale(22), position.session.positiontxt.contentsmallsize)
    local sessionPositionDynamicWidth =
      math.round(math.max(position.session.positionwidth, position.session.positiontxt.contentlargepos.x * 2 + largeContentSize.x, position.session.positiontxt.contentsmallpos.x + smallContentSize.x + position.session.positiontxt.contentlargepos.x))

    ui.setCursor(vec2(horiOffset, vertOffset))
    ui.childWindow('Position', vec2(sessionPositionDynamicWidth, position.session.boxheight), false, app.flags, function()
      ui.drawRectFilled(vec2(0, 0), vec2(sessionPositionDynamicWidth, position.session.boxheight), bgcolor)
      ui.setCursor(position.session.staticpos)
      ui.pushDWriteFont(app.font.black)
      ui.dwriteText('POSITION', smallTxt, color.white)
      ui.popDWriteFont()
      ui.setCursor(position.session.positiontxt.contentlargepos)
      ui.pushDWriteFont(app.font.semi)
      ui.dwriteTextAligned(playerRacePosition, bigTxt, 0, 0, largeContentSize, false, color.white)
      ui.popDWriteFont()
      ui.setCursor(position.session.positiontxt.contentsmallpos)
      ui.pushDWriteFont(app.font.bold)
      ui.dwriteTextAligned(sessionCarsTotal, scale(22), 0, 0, smallContentSize, false, color.white)
      ui.popDWriteFont()
    end)
    horiOffset = horiOffset + sessionPositionDynamicWidth + position.session.padding
  end

  if settings.sessionShowLaps then
    local sessionLapString = string.format('%02d', playerCar().lapCount)
    local lapContentSize = measureBox(sessionLapString, app.font.semi, bigTxt, position.session.lapstxt.contentsize)
    local sessionLapsDynamicWidth = math.round(math.max(position.session.lapswidth, position.session.lapstxt.contentpos.x * 2 + lapContentSize.x))

    ui.setCursor(vec2(horiOffset, vertOffset))
    ui.childWindow('Laps', vec2(sessionLapsDynamicWidth, position.session.boxheight), false, app.flags, function()
      ui.drawRectFilled(vec2(0, 0), vec2(sessionLapsDynamicWidth, position.session.boxheight), bgcolor)
      ui.setCursor(position.session.staticpos)
      ui.pushDWriteFont(app.font.black)
      ui.dwriteText('LAPS', smallTxt, color.white)
      ui.popDWriteFont()
      ui.setCursor(position.session.lapstxt.contentpos)
      ui.pushDWriteFont(app.font.semi)
      ui.dwriteTextAligned(sessionLapString, bigTxt, 0, 0, lapContentSize, false, color.white)
      ui.popDWriteFont()
    end)
    horiOffset = horiOffset + sessionLapsDynamicWidth + position.session.padding
  end

  if settings.sessionShowTimer then
    local sessionTypeString = getSessionTypeString(playerSession.raceSessionType)
    local sessionTimeString
    if settings.sessionAlwaysShowDuration then
      sessionTimeString = formatTime(playerSession.time, true, true, true)
    else
      sessionTimeString = formatTime(playerSession.sessionTimeLeft, true, true, true)
    end

    local labelSize = measureText(sessionTypeString, app.font.black, smallTxt)
    local timeContentSize = measureBox(sessionTimeString, app.font.semi, bigTxt, vec2(position.session.timerwidth, position.session.timertxt.contentsize))
    local sessionTimerDynamicWidth = math.round(math.max(position.session.timerwidth, position.session.staticpos.x * 2 + labelSize.x, position.session.timertxt.contentpos.x * 2 + timeContentSize.x))

    ui.setCursor(vec2(horiOffset, vertOffset))
    ui.childWindow('Timer', vec2(sessionTimerDynamicWidth, position.session.boxheight), false, app.flags, function()
      ui.drawRectFilled(vec2(0, 0), vec2(sessionTimerDynamicWidth, position.session.boxheight), bgcolor)
      ui.setCursor(position.session.staticpos)
      ui.pushDWriteFont(app.font.black)
      ui.dwriteText(sessionTypeString, smallTxt, color.white)
      ui.popDWriteFont()
      ui.setCursor(position.session.timertxt.contentpos)
      ui.pushDWriteFont(app.font.semi)
      ui.dwriteTextAligned(sessionTimeString, bigTxt, 0, 0, timeContentSize, false, color.white)
      ui.popDWriteFont()
    end)
  end
end
