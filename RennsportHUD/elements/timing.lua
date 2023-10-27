local totalSectors = #ac.getSim().lapSplits
function IdealLaptime(doOnce)
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

ac.onSessionStart(function(sessionIndex, restarted)
    if restarted then
        restarted = false
        resetTiming(true)
    end
end)

resetTiming(true)

function script.timing(dt)
    local position = getPositionTable()
    local playerSession = ac.getSim()
    local vertOffset = app.padding
    local horiOffset = 0
    local fontSizeSmall = scale(14)
    if not playerCar().isLapValid then timeColor = color.uired end

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
            if lastTimedSector then
                currentLap.sectors[lastTimedSector] = playerCar().previousLapTimeMs - sumSectors
            end
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

        table.insert(previousLaps, currentLap)

        if #previousLaps > 5 then
            table.remove(previousLaps, 1)
        end

        resetTiming(false)
        idealLap = formatTime(IdealLaptime(true), false, true, true, true)
    end
    if settings.timingShowCurrentLap then
        ui.setCursor(vec2(0, vertOffset))
        ui.childWindow('CurrentTime', position.timing.currentLap, function()
            ui.drawRectFilled(vec2(0, 0), position.timing.currentLap, setColorMult(color.black, 50))
            ui.setCursor(position.timing.pos.currentLapTxt)
            ui.pushDWriteFont(app.font.black)
            ui.dwriteTextAligned('CURRENT TIME', fontSizeSmall, 0, 0, vec2(104, 16):scale(app.scale), false, color.white)
            ui.popDWriteFont()
            ui.pushDWriteFont(app.font.medium)
            ui.setCursor(position.timing.pos.currentLapContent)
            ui.dwriteTextAligned(formatTime(playerCar().lapTimeMs, false, true, true, true), scale(42), 0, 0, vec2(204, 34):scale(app.scale), false, timeColor)
            ui.popDWriteFont()
        end)
        vertOffset = math.floor(vertOffset + position.timing.currentLap.y + scale(8))
    end

    if settings.timingShowLapStats then
        if settings.timingLapStatsBest then
            local contentTxt = emptyTimeString
            local bestColor = color.black
            if playerCar().bestLapTimeMs == playerCar().bestLapTimeMs and playerCar().bestLapTimeMs ~= 0 then bestColor = color.purple end
            if playerCar().bestLapTimeMs > 0 then contentTxt = formatTime(playerCar().bestLapTimeMs, false, true, true, true) end
            ui.setCursor(vec2(0, vertOffset))
            ui.childWindow('StatsBest', position.timing.lapStats, function()
                ui.drawRectFilled(vec2(0, 0), vec2(position.timing.lapStats.x * 0.4, position.timing.lapStats.y), setColorMult(bestColor, 65))
                ui.drawRectFilled(vec2(position.timing.lapStats.x * 0.4, 0), vec2(position.timing.lapStats.x, position.timing.lapStats.y), setColorMult(bestColor, 50))
                ui.setCursorX(scale(6))
                ui.pushDWriteFont(app.font.black)
                ui.dwriteTextAligned('BEST', fontSizeSmall, -1, 0, vec2(scale(36), position.timing.lapStats.y), false, color.white)
                ui.popDWriteFont()
                ui.setCursor(vec2(position.timing.lapStats.x * 0.44, 0))
                ui.pushDWriteFont(app.font.black)
                ui.dwriteTextAligned(contentTxt, fontSizeSmall, -1, 0, vec2(position.timing.lapStats.x * 0.66, position.timing.lapStats.y), false, color.white)
                ui.popDWriteFont()
            end)
            vertOffset = math.floor(vertOffset + position.timing.lapStats.y)
        end
        if settings.timingLapStatsLast then
            local contentTxt = emptyTimeString
            if playerCar().previousLapTimeMs > 0 then contentTxt = formatTime(playerCar().previousLapTimeMs, false, true, true, true) end
            ui.setCursor(vec2(0, vertOffset))
            ui.childWindow('StatsLast', position.timing.lapStats, function()
                ui.drawRectFilled(vec2(0, 0), vec2(position.timing.lapStats.x * 0.4, position.timing.lapStats.y), setColorMult(color.black, 80))
                ui.drawRectFilled(vec2(position.timing.lapStats.x * 0.4, 0), vec2(position.timing.lapStats.x, position.timing.lapStats.y), setColorMult(color.black, 65))
                ui.setCursorX(scale(6))
                ui.pushDWriteFont(app.font.black)
                ui.dwriteTextAligned('LAST', fontSizeSmall, -1, 0, vec2(scale(36), position.timing.lapStats.y), false, color.white)
                ui.popDWriteFont()
                ui.setCursor(vec2(position.timing.lapStats.x * 0.44, 0))
                ui.pushDWriteFont(app.font.black)
                ui.dwriteTextAligned(contentTxt, fontSizeSmall, -1, 0, vec2(position.timing.lapStats.x * 0.66, position.timing.lapStats.y), false, timeColor)
                ui.popDWriteFont()
            end)
            vertOffset = math.floor(vertOffset + position.timing.lapStats.y)
        end
        if settings.timingLapStatsIdeal then
            local contentTxt = emptyTimeString
            if idealLap ~= 0 then contentTxt = idealLap end
            ui.setCursor(vec2(0, vertOffset))
            ui.childWindow('StatsIdeal', position.timing.lapStats, function()
                ui.drawRectFilled(vec2(0, 0), vec2(position.timing.lapStats.x * 0.4, position.timing.lapStats.y), setColorMult(color.black, 80))
                ui.drawRectFilled(vec2(position.timing.lapStats.x * 0.4, 0), vec2(position.timing.lapStats.x, position.timing.lapStats.y), setColorMult(color.black, 65))
                ui.setCursorX(scale(6))
                ui.pushDWriteFont(app.font.black)
                ui.dwriteTextAligned('IDEAL', fontSizeSmall, -1, 0, vec2(scale(44), position.timing.lapStats.y), false, color.white)
                ui.popDWriteFont()
                ui.setCursor(vec2(position.timing.lapStats.x * 0.44, 0))
                ui.pushDWriteFont(app.font.black)
                ui.dwriteTextAligned(contentTxt, fontSizeSmall, -1, 0, vec2(position.timing.lapStats.x * 0.66, position.timing.lapStats.y), false, color.white)
                ui.popDWriteFont()
            end)
            vertOffset = vertOffset + position.timing.lapStats.y
        end
        vertOffset = math.floor(vertOffset + scale(45))
    end

    --TODO: reverse drawing from fixed pos downwards to start at lowest point and work upwards
    if settings.timingShowTable then
        local columSpace = scale(4)
        ui.setCursor(vec2(0, vertOffset))
        ui.childWindow('TimingTableHeader', position.timing.table.header, function()
            ui.drawRectFilled(vec2(0, 0), position.timing.table.header, setColorMult(color.black, 80))
            ui.pushDWriteFont(app.font.black)
            ui.dwriteTextAligned('Lap', fontSizeSmall, 0, 0, vec2(position.timing.table.lap, position.timing.table.header.y), false, color.white)
            horiOffset = 0 + position.timing.table.lap + columSpace
            ui.setCursor(vec2(horiOffset, 0))
            ui.dwriteTextAligned('Time', fontSizeSmall, -1, 0, vec2(position.timing.table.time, position.timing.table.header.y), false, color.white)
            horiOffset = horiOffset + position.timing.table.time + columSpace
            ui.setCursor(vec2(horiOffset, 0))
            ui.dwriteTextAligned('Delta Best', fontSizeSmall, -1, 0, vec2(position.timing.table.time, position.timing.table.header.y), false, color.white)
            horiOffset = horiOffset + position.timing.table.time + columSpace
            ui.popDWriteFont()
        end)
        ui.setCursor(vec2(math.round(horiOffset), vertOffset))
        ui.childWindow('TimingTableHeaderSectors', vec2((position.timing.table.time + columSpace) * totalSectors, position.timing.table.header.y), function()
            ui.drawRectFilled(vec2(0, 0), vec2((position.timing.table.time + columSpace) * totalSectors, position.timing.table.header.y), setColorMult(color.black, 80))
            secPos = columSpace
            for i = 1, totalSectors do
                ui.setCursorY(0)
                ui.setCursorX(secPos)
                ui.pushDWriteFont(app.font.black)
                ui.dwriteTextAligned('S' .. i, fontSizeSmall, -1, 0, vec2(position.timing.table.time, position.timing.table.header.y), false, color.white)
                ui.popDWriteFont()
                secPos = (position.timing.table.time + columSpace) * i
            end
        end)
        vertOffset = math.floor(vertOffset + position.timing.table.header.y)

        ui.setCursor(vec2(0, vertOffset))
        ui.childWindow('TimingTableContentCurrent', vec2(position.timing.table.header.x, position.timing.table.contentheight), function()
            local currLapTime = emptyTimeString
            local currLapDelta = ''
            if currentLap.lapTime > 0 then currLapTime = formatTime(currentLap.lapTime, false, true, true, true) end
            if currentLap.delta > 0 then currLapDelta = formatTime(currentLap.delta, false, true, true, true) end
            ui.drawRectFilled(vec2(0, 0), vec2(position.timing.table.header.x, position.timing.table.contentheight), setColorMult(color.black, 50))
            ui.pushDWriteFont(app.font.black)
            ui.dwriteTextAligned(lapCount + 1, fontSizeSmall, 0, 0, vec2(position.timing.table.lap, position.timing.table.contentheight), false, color.white)
            horiOffset = 0 + position.timing.table.lap + columSpace
            ui.setCursor(vec2(horiOffset, 0))
            ui.dwriteTextAligned(currLapTime, fontSizeSmall, -1, 0, vec2(position.timing.table.time, position.timing.table.contentheight), false, timeColor)
            horiOffset = horiOffset + position.timing.table.time + columSpace
            ui.setCursor(vec2(horiOffset, 0))
            ui.dwriteTextAligned(currLapDelta, fontSizeSmall, -1, 0, vec2(position.timing.table.time, position.timing.table.contentheight), false, color.white)
            horiOffset = horiOffset + position.timing.table.time + columSpace
            ui.popDWriteFont()
        end)
        ui.setCursor(vec2(math.round(horiOffset), vertOffset))
        ui.childWindow('TimingTableContentSectors', vec2((position.timing.table.time + columSpace) * totalSectors, position.timing.table.contentheight), function()
            ui.drawRectFilled(vec2(0, 0), vec2((position.timing.table.time + columSpace) * totalSectors, position.timing.table.contentheight), setColorMult(color.black, 50))
            secPos = columSpace
            for i = 1, totalSectors do
                local currLapSector = emptyTimeString
                if currentLap.sectors[i] > 0 then currLapSector = formatTime(currentLap.sectors[i], false, true, true, true) end
                ui.setCursor(vec2(secPos, 0))
                ui.pushDWriteFont(app.font.black)
                ui.dwriteTextAligned(currLapSector, fontSizeSmall, -1, 0, vec2(position.timing.table.time, position.timing.table.contentheight), false, color.white)
                ui.popDWriteFont()
                secPos = (position.timing.table.time + columSpace) * i
            end
        end)
        vertOffset = vertOffset + position.timing.table.contentheight

        for p = #previousLaps, 1, -1 do
            local reverseIndex = #previousLaps - p + 1
            ui.setCursor(vec2(0, vertOffset + position.timing.table.contentheight * (reverseIndex - 1)))
            ui.childWindow('TimingTableContentPrev' .. reverseIndex, vec2(position.timing.table.header.x, position.timing.table.contentheight), function()
                local prevLapTime = emptyTimeString
                local prevLapDelta = ''
                if previousLaps[p].lapTime > 0 then prevLapTime = formatTime(previousLaps[p].lapTime, false, true, true, true) end
                if previousLaps[p].delta > 0 then prevLapDelta = '+' .. formatTime(previousLaps[p].delta, false, true, true, true) end
                ui.drawRectFilled(vec2(0, 0), vec2(position.timing.table.header.x, position.timing.table.contentheight), setColorMult(color.black, 50))
                ui.pushDWriteFont(app.font.black)
                ui.dwriteTextAligned(previousLaps[p].lapNum, fontSizeSmall, 0, 0, vec2(position.timing.table.lap, position.timing.table.contentheight), false, color.white)
                horiOffset = 0 + position.timing.table.lap + columSpace
                ui.setCursor(vec2(horiOffset, 0))
                ui.dwriteTextAligned(prevLapTime, fontSizeSmall, -1, 0, vec2(position.timing.table.time, position.timing.table.contentheight), false, timeColor)
                horiOffset = horiOffset + position.timing.table.time + columSpace
                ui.setCursor(vec2(horiOffset, 0))
                ui.dwriteTextAligned(prevLapDelta, fontSizeSmall, -1, 0, vec2(position.timing.table.time, position.timing.table.contentheight), false, color.uired)
                horiOffset = horiOffset + position.timing.table.time + columSpace
                ui.popDWriteFont()
            end)

            ui.setCursor(vec2(math.round(horiOffset), vertOffset + position.timing.table.contentheight * (reverseIndex - 1)))
            ui.childWindow('TimingTableContentSectorsPrev' .. reverseIndex, vec2((position.timing.table.time + columSpace) * totalSectors, position.timing.table.contentheight), function()
                ui.drawRectFilled(vec2(0, 0), vec2((position.timing.table.time + columSpace) * totalSectors, position.timing.table.contentheight), setColorMult(color.black, 50))
                secPos = columSpace
                for i = 1, totalSectors do
                    local currLapSector = emptyTimeString
                    if previousLaps[p].sectors[i] > 0 then currLapSector = formatTime(previousLaps[p].sectors[i], false, true, true, true) end
                    ui.setCursor(vec2(secPos, 0))
                    ui.pushDWriteFont(app.font.black)
                    ui.dwriteTextAligned(currLapSector, fontSizeSmall, -1, 0, vec2(position.timing.table.time, position.timing.table.contentheight), false, color.white)
                    ui.popDWriteFont()
                    secPos = (position.timing.table.time + columSpace) * i
                end
            end)
        end
    end
end
