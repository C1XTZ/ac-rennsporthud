local doThisOnce = false
local previouslastTimedSector = 1
local lastTimedSector = 1
local sectorTimeCurrent = {}
local sectorTimePrevious = {}
local timedSectorColor = {}
local bestSectorTime = {}
local totalSectors = math.max(#ac.getSim().lapSplits, 2)
for i = 1, totalSectors do
    timedSectorColor[i] = setColorMult(getColorTable().black, 50)
end

ac.onSessionStart(function(sessionIndex, restarted)
    if restarted then
        restarted = false
        sectorTimeCurrent = {}
        timedSectorColor = {}
        bestSectorTime = {}
        for i = 1, totalSectors do
            timedSectorColor[i] = setColorMult(getColorTable().black, 50)
        end
    end
end)

function script.sectors(dt)
    local vertOffset = app.padding
    local horiOffset = 0
    local position = getPositionTable()
    local playerSession = ac.getSim()
    if #ac.getSim().lapSplits > 0 and settings.sectorsDisable then
        settings.sectorsDisable = false
    elseif #ac.getSim().lapSplits < 1 and not settings.sectorsDisable then
        settings.sectorsDisable = true
    end

    if settings.sectorsShowSectors and not settings.sectorsDisable then
        local newSectorIndex = playerCar().currentSector + 1
        if newSectorIndex ~= previouslastTimedSector then
            lastTimedSector = previouslastTimedSector
            previouslastTimedSector = newSectorIndex

            if #playerCar().bestSplits > 0 then
                for i = 1, #playerCar().bestSplits do
                    bestSectorTime[i] = playerCar().bestSplits[i - 1]
                end
            end

            if playerCar().previousSectorTime > 0 then
                if sectorTimeCurrent[lastTimedSector] then
                    sectorTimePrevious[lastTimedSector] = sectorTimeCurrent[lastTimedSector]
                    sectorTimeCurrent[lastTimedSector] = playerCar().previousSectorTime
                else
                    table.insert(sectorTimeCurrent, lastTimedSector, playerCar().previousSectorTime)
                end
            else
                local sumSectors = 0
                for i = 1, totalSectors - 1 do
                    sumSectors = sumSectors + sectorTimeCurrent[i]
                end

                if sectorTimeCurrent[lastTimedSector] then
                    sectorTimePrevious[lastTimedSector] = sectorTimeCurrent[lastTimedSector]
                    sectorTimeCurrent[lastTimedSector] = playerCar().previousLapTimeMs - sumSectors
                else
                    table.insert(sectorTimeCurrent, lastTimedSector, playerCar().previousLapTimeMs - sumSectors)
                end
            end

            if #sectorTimeCurrent > 0 then
                if #bestSectorTime == 0 or sectorTimeCurrent[lastTimedSector] <= bestSectorTime[lastTimedSector] then
                    timedSectorColor[lastTimedSector] = setColorMult(color.purple, 100)
                elseif #sectorTimePrevious > 0 and sectorTimeCurrent[lastTimedSector] > sectorTimePrevious[lastTimedSector] then
                    timedSectorColor[lastTimedSector] = setColorMult(color.uired, 100)
                elseif #sectorTimePrevious > 0 and sectorTimeCurrent[lastTimedSector] > bestSectorTime[lastTimedSector] and sectorTimeCurrent[lastTimedSector] <= sectorTimePrevious[lastTimedSector] then
                    timedSectorColor[lastTimedSector] = setColorMult(color.uigreen, 100)
                end
            end

            if lastTimedSector == #playerSession.lapSplits and not doThisOnce then
                doThisOnce = true
            end
        end

        if playerCar().lapTimeMs > settings.sectorsDisplayDuration * 1000 and timedSectorColor[lastTimedSector] ~= color.black and doThisOnce then
            doThisOnce = false
            for i = 1, totalSectors do
                timedSectorColor[i] = setColorMult(color.black, 50)
            end
        end

        for i = 1, #playerSession.lapSplits do
            ui.setCursor(vec2(horiOffset, vertOffset))
            ui.childWindow('Sector' .. i, vec2(position.sectors.sectorwidth, position.sectors.sectorheight), function()
                ui.drawRectFilled(vec2(0, 0), vec2(position.sectors.sectorwidth, position.sectors.sectorheight), timedSectorColor[i])
                ui.setCursor(0, 0)
                ui.pushDWriteFont(app.font.black)
                ui.dwriteTextAligned('S' .. i, scale(14), 0, 0, vec2(position.sectors.sectorwidth, position.sectors.sectorheight), false, color.white)
                ui.popDWriteFont()
            end)
            horiOffset = horiOffset + math.floor(position.sectors.sectorwidth)
        end
        vertOffset = vertOffset + position.sectors.sectorheight
    end

    if settings.sectorsShowPitInfo then
        local playerSpeed = math.round(playerCar().speedKmh)
        local pitColor = color.uigreen
        local speedLimit = ''
        if playerSpeed > playerSession.pitsSpeedLimit then pitColor = color.uired end
        if settings.sectorsShowSpeedLimit then speedLimit = '/' .. playerSession.pitsSpeedLimit end

        ui.setCursor(vec2(0, vertOffset))
        ui.childWindow('PitLane', vec2(position.sectors.sectorwidth * totalSectors, position.sectors.pitheight), function()
            if playerCar().isInPitlane then
                ui.drawRectFilled(vec2(0, 0), vec2(ui.availableSpaceX(), position.sectors.pitheight), pitColor)
                ui.setCursor(0, 0)
                ui.pushDWriteFont(app.font.black)
                ui.dwriteTextAligned('IN PIT LANE. CURRENT SPEED: ' .. playerSpeed .. speedLimit, scale(14), 0, 0, vec2(position.sectors.sectorwidth * totalSectors, position.sectors.sectorheight), false, color.black)
                ui.popDWriteFont()
            end
        end)
        vertOffset = math.round(vertOffset + position.sectors.pitheight)
    end

    if playerSession.raceFlagType then
        local flagTxt = ''
        local flagTxtSize = scale(14)
        local flagColor = rgbm.colors.fuchsia
        local txtColor = rgbm.colors.fuchsia
        if playerSession.raceFlagType == ac.FlagType.Caution then
            flagTxt = 'CAUTION, YELLOW FLAG'
            flagColor = color.yellow
            txtColor = color.black
        elseif playerSession.raceFlagType == ac.FlagType.FasterCar then
            flagTxt = 'FASTER CAR APPROACHING'
            flagColor = color.blue
            txtColor = color.black
        elseif playerSession.raceFlagType == ac.FlagType.ReturnToPits then
            flagTxt = 'YOU HAVE A PENALTY, RETURN TO PITS'
            flagColor = color.white
            txtColor = color.black
        elseif playerSession.raceFlagType == ac.FlagType.OneLapLeft then
            flagTxt = 'LAST LAP'
            flagColor = color.white
            txtColor = color.black
        elseif playerSession.raceFlagType == ac.FlagType.Stop then
            flagTxt = 'YOU HAVE BEEN BLACK FLAGGED'
            flagColor = color.black
            txtColor = color.white
        elseif playerSession.raceFlagType == ac.FlagType.Finished then
            flagTxt = 'RACE FINISHED'
            flagColor = color.black
            txtColor = color.white
        end

        ui.setCursor(vec2(0, vertOffset))
        ui.childWindow('PitLane', vec2(position.sectors.sectorwidth * totalSectors, position.sectors.pitheight), function()
            if string.len(flagTxt) > 0 then
                if playerSession.raceFlagType == ac.FlagType.ReturnToPits then
                    ui.drawRectFilled(vec2(0, 0), vec2(ui.availableSpaceX() / 1, position.sectors.pitheight), color.black)
                    ui.drawRectFilled(vec2(ui.availableSpaceX() - ui.availableSpaceX() / 5, 0), vec2(ui.availableSpaceX() / 5, position.sectors.pitheight), color.white)
                elseif playerSession.raceFlagType == ac.FlagType.Finished then
                    ui.drawImage('./img/CequeredFlag.png', vec2(0, 0), vec2(position.sectors.sectorwidth * totalSectors, position.sectors.pitheight), true)
                    ui.drawRectFilled(vec2(ui.availableSpaceX() - ui.availableSpaceX() / 3, 0), vec2(ui.availableSpaceX() / 3, position.sectors.pitheight), color.black)
                else
                    ui.drawRectFilled(vec2(0, 0), vec2(ui.availableSpaceX(), position.sectors.pitheight), flagColor)
                end
                ui.setCursor(0, 0)
                ui.pushDWriteFont(app.font.black)
                ui.dwriteTextAligned(flagTxt, flagTxtSize, 0, 0, vec2(position.sectors.sectorwidth * totalSectors, position.sectors.pitheight), false, txtColor)
                ui.popDWriteFont()
            end
        end)
    end
end
