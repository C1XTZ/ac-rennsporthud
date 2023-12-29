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

---@param sessionType ac.SessionType
---@return string
--takes ac.SessionType and returns the session name as a string
function getSessionTypeString(sessionType)
    if not settings.sessionTimerType then
        return sessionTypes[0]
    end

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
                if car.isConnected and car.isHidingLabels then
                    hiddenCars = hiddenCars + 1
                end
            end
            sessionCarsTotal = string.format('%02d', playerSession.connectedCars - hiddenCars)
        end

        ui.setCursor(vec2(horiOffset, vertOffset))
        ui.childWindow('Position', vec2(position.session.positionwidth, position.session.boxheight), false, app.flags, function()
            ui.drawRectFilled(vec2(0, 0), vec2(position.session.positionwidth, position.session.boxheight), bgcolor)
            ui.setCursor(position.session.staticpos)
            ui.pushDWriteFont(app.font.black)
            ui.dwriteText('POSITION', smallTxt, color.white)
            ui.popDWriteFont()
            ui.setCursor(position.session.positiontxt.contentlargepos)
            ui.pushDWriteFont(app.font.semi)
            ui.dwriteTextAligned(playerRacePosition, bigTxt, 0, 0, position.session.positiontxt.contentlargesize, false, color.white)
            ui.popDWriteFont()
            ui.setCursor(position.session.positiontxt.contentsmallpos)
            ui.pushDWriteFont(app.font.bold)
            ui.dwriteTextAligned(sessionCarsTotal, scale(22), 0, 0, position.session.positiontxt.contentsmallsize, false, color.white)
            ui.popDWriteFont()
        end)
        horiOffset = horiOffset + position.session.positionwidth + position.session.padding
    end

    if settings.sessionShowLaps then
        local sessionLapString = string.format('%02d', playerCar().lapCount)
        ui.setCursor(vec2(horiOffset, vertOffset))
        ui.childWindow('Laps', vec2(position.session.lapswidth, position.session.boxheight), false, app.flags, function()
            ui.drawRectFilled(vec2(0, 0), vec2(position.session.lapswidth, position.session.boxheight), bgcolor)
            ui.setCursor(position.session.staticpos)
            ui.pushDWriteFont(app.font.black)
            ui.dwriteText('LAPS', smallTxt, color.white)
            ui.popDWriteFont()
            ui.setCursor(position.session.lapstxt.contentpos)
            ui.pushDWriteFont(app.font.semi)
            ui.dwriteTextAligned(sessionLapString, bigTxt, 0, 0, position.session.lapstxt.contentsize, false, color.white)
            ui.popDWriteFont()
        end)
        horiOffset = horiOffset + position.session.lapswidth + position.session.padding
    end

    if settings.sessionShowTimer then
        local sessionTypeString = getSessionTypeString(playerSession.raceSessionType)
        local sessionTimeString, displayedSessionTimeMs
        if settings.sessionAlwaysShowDuration then
            sessionTimeString = formatTime(playerSession.time, true, true, true)
            displayedSessionTimeMs = playerSession.time
        else
            sessionTimeString = formatTime(playerSession.sessionTimeLeft, true, true, true)
            displayedSessionTimeMs = playerSession.sessionTimeLeft
        end

        local sessionTimerDynamicWidth = position.session.timerwidth
        if displayedSessionTimeMs > 35999999 then
            sessionTimerDynamicWidth = sessionTimerDynamicWidth + scale(25)
        end

        ui.setCursor(vec2(horiOffset, vertOffset))
        ui.childWindow('Timer', vec2(sessionTimerDynamicWidth, position.session.boxheight), false, app.flags, function()
            ui.drawRectFilled(vec2(0, 0), vec2(sessionTimerDynamicWidth, position.session.boxheight), bgcolor)
            ui.setCursor(position.session.staticpos)
            ui.pushDWriteFont(app.font.black)
            ui.dwriteText(sessionTypeString, smallTxt, color.white)
            ui.popDWriteFont()
            ui.setCursor(position.session.timertxt.contentpos)
            ui.pushDWriteFont(app.font.semi)
            ui.dwriteTextAligned(sessionTimeString, bigTxt, 0, 0, vec2(sessionTimerDynamicWidth, position.session.timertxt.contentsize), false, color.white)
            ui.popDWriteFont()
        end)
    end
end
