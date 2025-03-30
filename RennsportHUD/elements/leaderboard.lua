local onlineVersionCheck = ac.getSim().isOnlineRace and ac.getPatchVersionCode() < 3045

---@param car ac.StateCar @The car from which the brand is to be removed.
---@return string @The name of the car without the brand.
--- Takes an ac.StateCar and retuns car name with the brand removed.
function removeBrand(car)
    local brand = car:brand()
    local name = car:name()
    local brandParts = brand:split('-')
    for _, part in ipairs(brandParts) do
        local escapedPart = part:gsub('([%^%$%(%)%%%.%[%]%*%+%-%?])', '%%%1')
        name = name:gsub('^' .. escapedPart .. '[%s%-]*', '')
    end
    return name:match('^%s*(.-)%s*$')
end

---@param timeMs integer @The lap time in milliseconds.
---@return string @The formatted lap time.
--- Formats lap time from milliseconds to MM:SS.sss, returns --:--.--- when 0.
function formatLapTime(timeMs)
    local formattedTime = formatTime(timeMs, false, true, true, true)
    if formattedTime == '00:00.000' then
        return '--:--.---'
    else
        return formattedTime
    end
end

---@param car ac.StateCar @The car to be updated.
---@param i integer @The index of the car.
--- Writes and updates car data.
function updateCar(car, i)
    if not onlineVersionCheck then
        lbTable[i + 1] = {
            dex = car.index,
            num = car:driverNumber(),
            name = car:driverName(),
            car = removeBrand(car),
            lap = car.lapCount,
            pit = car.isInPitlane,
            dnf = car.currentPenaltyType == ac.PenaltyType.BlackFlag,
            last = formatLapTime(car.previousLapTimeMs),
            lastMs = car.previousLapTimeMs,
            bestMs = car.bestLapTimeMs,
            best = formatLapTime(car.bestLapTimeMs)
        }
    else
        lbTable[i + 1] = {
            dex = car.index,
            num = car:driverNumber(),
            name = car:driverName(),
            car = removeBrand(car),
            pit = car.isInPitlane,
            pos = car.racePosition
        }
    end
end

local carCount = 0
for i = 1, ac.getSim().carsCount do
    if ac.getCar(i - 1).isConnected and not ac.getCar(i - 1).isHidingLabels then carCount = carCount + 1 end
end

--- Updates the leaderboard.
--- A custom sorting function because the default session.leaderboard does not work like I want it to.
function updateLeaderboard()
    if not lbTable then lbTable = {} end
    carCount = 0
    for i = 0, sim.carsCount - 1 do
        local car = ac.getCar(i)
        updateCar(car, i)
        if car.isConnected and not car.isHidingLabels then carCount = carCount + 1 end
    end

    for i = #lbTable, 1, -1 do
        local car = ac.getCar(lbTable[i].dex)
        if car.isHidingLabels or not car.isConnected then
            table.remove(lbTable, i)
        end
    end

    if not onlineVersionCheck then
        if session.type == ac.SessionType.Race then
            for i = 1, #lbTable do
                lbTable[i].pos = ac.getCar(lbTable[i].dex).racePosition
            end

            table.sort(lbTable, function(a, b)
                return a.pos < b.pos
            end)
        else
            table.sort(lbTable, function(a, b)
                if a.bestMs == 0 then
                    return false
                elseif b.bestMs == 0 then
                    return true
                else
                    return a.bestMs < b.bestMs
                end
            end)

            for i = 1, #lbTable do
                lbTable[i].pos = i
            end
        end
    else
        table.sort(lbTable, function(a, b)
            return a.pos < b.pos
        end)
    end

    for i = 1, #lbTable do
        if not onlineVersionCheck then
            local dex = (session.type == ac.SessionType.Race and i > 1) and lbTable[i - 1].dex or lbTable[1].dex
            local gap = ac.getGapBetweenCars(lbTable[i].dex, dex)

            if lbTable[i].pos ~= 1 and (lbTable[i].lap > 0 or session.type == ac.SessionType.Race) then
                if gap >= 99.999 then
                    lbTable[i].int = '+99.999'
                elseif gap < 99.999 and gap > 0 then
                    lbTable[i].int = string.format('+%06.3f', math.max(gap, 0))
                elseif gap < 0 then
                    lbTable[i].int = string.format('%07.3f', math.min(gap, 0))
                end
            else
                lbTable[i].int = '--.---'
            end
        end
    end
end

local maxNameLength = 0
local maxCarLength = 0
function onShowLeaderboard()
    updateLeaderboard()
    updateInterval = setInterval(function()
        updateLeaderboard()
    end, 1, 'LB')
end

function onHideLeaderboard()
    clearInterval(updateInterval)
    updateInterval = nil
    lbTable = nil
end

local settingsToTable = {
    lbShowPos = 'pos',
    lbShowNum = 'num',
    lbShowName = 'name',
    lbShowCar = 'car',
    lbShowLap = 'lap',
    lbShowLast = 'last',
    lbShowBest = 'best',
    lbShowInt = 'int',
}

local displayOrder = { 'lbShowPos', 'lbShowNum', 'lbShowName', 'lbShowCar', 'lbShowLap', 'lbShowLast', 'lbShowBest', 'lbShowInt' }

if onlineVersionCheck then
    local itemsToRemove = { 'lbShowLap', 'lbShowLast', 'lbShowBest', 'lbShowInt' }
    for _, item in ipairs(itemsToRemove) do
        for i, v in ipairs(displayOrder) do
            if v == item then
                table.remove(displayOrder, i)
                break
            end
        end
    end
end

function script.leaderboard(dt)
    local position = getPositionTable()
    sim = ac.getSim()
    session = ac.getSession(sim.currentSessionIndex)

    local fontSizeSmall = scale(14)
    local prevFontSizeSmall = nil
    local columSpace = scale(6)
    local signWidth = scale(30)
    local horiOffset, vertOffset = 0, app.padding
    headerTotalWidth = (position.leaderboard.ends * 2) + signWidth


    if fontSizeSmall ~= prevFontSizeSmall and lbTable then
        maxNameLength = 0
        maxCarLength = 0
        ui.pushDWriteFont(app.font.black)
        for i = 1, #lbTable do
            local currentNameLength = math.round(ui.measureDWriteText(lbTable[i].name, fontSizeSmall).x)
            if currentNameLength > maxNameLength then
                maxNameLength = math.round(ui.measureDWriteText(lbTable[i].name, fontSizeSmall).x)
            end
            local currentCarLength = math.round(ui.measureDWriteText(lbTable[i].car, fontSizeSmall).x)
            if currentCarLength > maxCarLength then
                maxCarLength = math.round(ui.measureDWriteText(lbTable[i].car, fontSizeSmall).x)
            end
        end
        ui.popDWriteFont()
    end

    prevFontSizeSmall = fontSizeSmall


    local displayData = {
        lbShowPos = { width = position.leaderboard.pnl, str = 'Pos.' },
        lbShowNum = { width = position.leaderboard.pnl, str = 'Num' },
        lbShowName = { width = (settings.lbManNameLength and settings.lbManNameLengthNum or maxNameLength), str = 'Name' },
        lbShowCar = { width = (settings.lbManCarLength and settings.lbManCarLengthNum or maxCarLength), str = 'Car' },
        lbShowLap = { width = position.leaderboard.lap, str = 'Lap' },
        lbShowLast = { width = position.leaderboard.time, str = 'Last' },
        lbShowBest = { width = position.leaderboard.time, str = 'Best' },
        lbShowInt = { width = position.leaderboard.int, str = 'Interval' },
    }

    for i, setting in ipairs(displayOrder) do
        local data = displayData[setting]
        if settings[setting] == true then
            headerTotalWidth = headerTotalWidth + data.width + columSpace
        end
    end

    ui.setCursor(vec2(0, vertOffset))
    ui.childWindow('LeaderboardHeader', vec2(headerTotalWidth, position.leaderboard.height), function()
        ui.drawRectFilled(vec2(0, 0), vec2(headerTotalWidth, position.leaderboard.height), setColorMult(color.black, 80))
        horiOffset = horiOffset + position.leaderboard.ends

        for i, setting in ipairs(displayOrder) do
            local data = displayData[setting]
            if settings[setting] == true then
                ui.setCursor(vec2(horiOffset + columSpace, 0))
                ui.pushDWriteFont(app.font.black)
                ui.dwriteTextAligned(data.str, fontSizeSmall, -1, 0, vec2(data.width, position.leaderboard.height), false, color.white)
                ui.popDWriteFont()
                horiOffset = horiOffset + data.width + columSpace
            end
        end
    end)

    ui.setCursor(vec2(0, position.leaderboard.height))
    ui.childWindow('LeaderboardEntries', vec2(headerTotalWidth, (position.leaderboard.height * (math.max(1, math.min(carCount, settings.lbMaxCars)) + 3))), function()
        if lbTable then
            local maxCars = math.min(#lbTable, settings.lbMaxCars)
            for i = 1, maxCars do
                local lbValue = lbTable[i]
                horiOffset = 0
                ui.setCursor(vec2(horiOffset, vertOffset))
                horiOffset = horiOffset + position.leaderboard.ends
                ui.childWindow('Entry' .. lbValue.dex, vec2(headerTotalWidth, position.leaderboard.height), function()
                    ui.drawRectFilled(vec2(0, 0), vec2(headerTotalWidth, position.leaderboard.height), setColorMult(color.black, 50))

                    for _, setting in ipairs(displayOrder) do
                        if lbValue['dex'] == playerCar().index then
                            ui.drawRectFilled(vec2(0, 0), vec2(position.leaderboard.ends, position.leaderboard.height), color.uired)
                        end
                        if lbValue['dnf'] then
                            ui.setCursor(vec2(headerTotalWidth - signWidth, 0))
                            ui.drawRectFilled(ui.getCursor(), vec2(ui.getCursorX() + signWidth, ui.getCursorY() + position.leaderboard.height), color.black)
                            ui.pushDWriteFont(app.font.black)
                            ui.dwriteTextAligned('DNF', fontSizeSmall, 0, 0, vec2(signWidth, position.leaderboard.height), false, color.white)
                            ui.popDWriteFont()
                        elseif lbValue['pit'] then
                            ui.setCursor(vec2(headerTotalWidth - signWidth, 0))
                            ui.drawRectFilled(ui.getCursor(), vec2(ui.getCursorX() + signWidth, ui.getCursorY() + position.leaderboard.height), color.white)
                            ui.pushDWriteFont(app.font.black)
                            ui.dwriteTextAligned('PIT', fontSizeSmall, 0, 0, vec2(signWidth, position.leaderboard.height), false, color.black)
                            ui.popDWriteFont()
                        end
                        local data = displayData[setting]
                        if settings[setting] == true then
                            local displayValue = lbValue[settingsToTable[setting]]
                            displayValue = (setting == 'lbShowPos') and displayValue .. '.' or displayValue
                            ui.setCursor(vec2(horiOffset + columSpace, 0))
                            ui.pushDWriteFont(app.font.black)
                            ui.dwriteTextAligned(displayValue, fontSizeSmall, -1, 0, vec2(data.width, position.leaderboard.height), false, color.white)
                            ui.popDWriteFont()
                            horiOffset = horiOffset + data.width + columSpace
                        end
                    end
                end)
                vertOffset = vertOffset + position.leaderboard.height
            end
        end
    end)
end
