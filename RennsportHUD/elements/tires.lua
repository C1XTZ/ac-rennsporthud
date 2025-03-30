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
        if yValue > yHighest then
            yHighest = yValue
        end
    end

    if yHighest == -1 then
        return 0
    end

    local xHighest = {}
    for i, y in ipairs(yTable) do
        if y == yHighest then
            table.insert(xHighest, xTable[i])
        end
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
        else
            return '-1'
        end
    end
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

    if frontCurve == -1 or rearCurve == -1 then
        return -1, -1
    end

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

    if frontOptTemp == -1 or rearOptTemp == -1 then
        return -1, -1
    end

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

local flTempHue = { 240, 240, 240 }
local frTempHue = { 240, 240, 240 }
local rlTempHue = { 240, 240, 240 }
local rrTempHue = { 240, 240, 240 }

local flWearColor, frWearColor, rlWearColor, rrWearColor, rlPressure, unitTxt
local currComp = -1
local wearBg = rgbm(0.4, 0.4, 0.4, 1)

local wearPercent = { 0.50, 0.25, 0.0 }
local wearPercentColors = { getColorTable().red, getColorTable().yellow, getColorTable().white }

local tempSurface = {}
local tempOptimal = {}
local tempCore = {}
local surfaceWeight = 0.2

function script.tires(dt)
    local position = getPositionTable()
    local vertOffset = math.round(app.padding)
    local horiOffset = 0
    local wearOl = scale(1)

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
    for i = 0, 3 do
        local wheel = playerCar().wheels[i]
        local tyreWear = wheel.tyreWear

        local wearColor = color.white
        for j = 1, #wearPercent do
            if tyreWear > wearPercent[j] then
                wearColor = wearPercentColors[j]
                break
            end
        end
        if i == 0 then
            flWearColor = wearColor
        elseif i == 1 then
            frWearColor = wearColor
        elseif i == 2 then
            rlWearColor = wearColor
        elseif i == 3 then
            rrWearColor = wearColor
        end
    end

    for i = 0, 3 do
        local wheel = playerCar().wheels[i]
        tempOptimal[i + 1] = (i < 2) and frontOptTemp or rearOptTemp
        tempSurface[i + 1] = { wheel.tyreOutsideTemperature, wheel.tyreMiddleTemperature, wheel.tyreInsideTemperature }
        tempCore[i + 1] = { wheel.tyreCoreTemperature, wheel.tyreCoreTemperature, wheel.tyreCoreTemperature }
    end

    if settings.tiresShowTempVis then
        for i = 1, 3 do
            local flTempAvg = (tempCore[1][i] * (1 - surfaceWeight)) + (tempSurface[1][i] * surfaceWeight)
            local frTempAvg = (tempCore[2][i] * (1 - surfaceWeight)) + (tempSurface[2][i] * surfaceWeight)
            local rlTempAvg = (tempCore[3][i] * (1 - surfaceWeight)) + (tempSurface[3][i] * surfaceWeight)
            local rrTempAvg = (tempCore[4][i] * (1 - surfaceWeight)) + (tempSurface[4][i] * surfaceWeight)

            flTempHue[i] = math.lerp(240, 0, math.lerpInvSat(math.max(0, (flTempAvg / tempOptimal[1]) ^ 3), 0, 2))
            frTempHue[i] = math.lerp(240, 0, math.lerpInvSat(math.max(0, (frTempAvg / tempOptimal[2]) ^ 3), 0, 2))
            rlTempHue[i] = math.lerp(240, 0, math.lerpInvSat(math.max(0, (rlTempAvg / tempOptimal[3]) ^ 3), 0, 2))
            rrTempHue[i] = math.lerp(240, 0, math.lerpInvSat(math.max(0, (rrTempAvg / tempOptimal[4]) ^ 3), 0, 2))
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
        ui.setCursor(vec2(0, vertOffset))
        ui.childWindow('tiresFL', position.tires.wheelelement, function()
            ui.drawRectFilled(vec2(0, 0), vec2(math.floor(position.tires.wheelelement.x), position.tires.wheelelement.y), setColorMult(color.black, 50))

            ui.setCursor(vec2(position.tires.wheelelement.x / 2 - position.tires.wheelpartsize.x / 2, position.tires.wheelpos))
            ui.drawRectFilled(ui.getCursor(), vec2(ui.getCursorX() + position.tires.wheelpartsize.x, ui.getCursorY() + position.tires.wheelpartsize.y), tiresFound and hueToRgb(flTempHue[2]) or color.gray)
            ui.setCursorX(ui.getCursorX() - scale(8))
            ui.drawRectFilled(ui.getCursor(), vec2(ui.getCursorX() + position.tires.wheelpartsize.x, ui.getCursorY() + position.tires.wheelpartsize.y), tiresFound and hueToRgb(flTempHue[3]) or color.gray, scale(5), 5)
            ui.setCursorX(ui.getCursorX() + scale(16))
            ui.drawRectFilled(ui.getCursor(), vec2(ui.getCursorX() + position.tires.wheelpartsize.x, ui.getCursorY() + position.tires.wheelpartsize.y), tiresFound and hueToRgb(flTempHue[1]) or color.gray, scale(5), 10)
            if settings.tiresShowWear then
                ui.setCursorX(ui.getCursorX() - scale(34))
                ui.setCursorY(ui.getCursorY() + position.tires.wearsize.y)
                ui.drawRectFilled(vec2(ui.getCursorX() - wearOl, ui.getCursorY() + wearOl), vec2(ui.getCursorX() + (position.tires.wearsize.x + wearOl), ui.getCursorY() - (position.tires.wearsize.y + wearOl)), color.black)
                ui.drawRectFilled(ui.getCursor(), vec2(ui.getCursorX() + position.tires.wearsize.x, ui.getCursorY() - position.tires.wearsize.y), wearBg)
                ui.drawRectFilled(ui.getCursor(), vec2(ui.getCursorX() + position.tires.wearsize.x, ui.getCursorY() - (position.tires.wearsize.y * (1 - playerCar().wheels[0].tyreWear))), flWearColor)
                ui.setCursor(vec2(ui.getCursorX() - scale(6), ui.getCursorY() + scale(1)))
                ui.pushDWriteFont(app.font.black)
                ui.dwriteTextAligned(math.round((1 - playerCar().wheels[0].tyreWear) * 100), scale(9), 0, 0, vec2(17, 12):scale(app.scale), false, color.white)
                ui.popDWriteFont()
            end

            if settings.tiresShowBrakeTemp then
                local flBrakeHue = math.lerp(240, 0, math.lerpInvSat(math.max(0, (playerCar().wheels[0].discTemperature / fOptBrakeTemp)), 0, 2))

                ui.setCursor(vec2(position.tires.wheelelement.x / 2 + position.tires.brakepos.x, position.tires.brakepos.y))
                ui.drawRectFilled(ui.getCursor(), vec2(ui.getCursorX() + position.tires.brakesize.x, ui.getCursorY() + position.tires.brakesize.y), brakesFound and hueToRgb(flBrakeHue) or color.gray)
            end

            if settings.tiresShowPressure then
                if settings.tiresPressureUseBar then
                    unitTxt = ' bar'
                    flPressure = playerCar().wheels[0].tyrePressure * 0.0689475729
                else
                    unitTxt = ' psi'
                    flPressure = playerCar().wheels[0].tyrePressure
                end

                local flPressColor = color.white
                if settings.tiresPressureColor then
                    flPressColor = tiresFound and hueToRgb(math.lerp(240, 0, math.lerpInvSat(math.max(0, (flPressure / tireIni.fPressOpt) ^ 10), 0, 2))) or color.gray
                end

                ui.setCursor(0)
                ui.pushDWriteFont(app.font.black)
                ui.dwriteTextAligned(string.format('%.1f', flPressure):gsub('%.', ',') .. unitTxt, scale(10), 0, 0, vec2(position.tires.wheelelement.x, position.tires.pressurepos), false, flPressColor)
                ui.popDWriteFont()
            end
        end)

        horiOffset = horiOffset + position.tires.wheelelement.x

        ui.setCursor(vec2(horiOffset, vertOffset))
        ui.childWindow('tiresFR', position.tires.wheelelement, function()
            ui.drawRectFilled(vec2(0, 0), position.tires.wheelelement, setColorMult(color.black, 50))

            ui.setCursor(vec2(position.tires.wheelelement.x / 2 - position.tires.wheelpartsize.x / 2, position.tires.wheelpos))
            ui.drawRectFilled(ui.getCursor(), vec2(ui.getCursorX() + position.tires.wheelpartsize.x, ui.getCursorY() + position.tires.wheelpartsize.y), tiresFound and hueToRgb(frTempHue[2]) or color.gray)
            ui.setCursorX(ui.getCursorX() - scale(8))
            ui.drawRectFilled(ui.getCursor(), vec2(ui.getCursorX() + position.tires.wheelpartsize.x, ui.getCursorY() + position.tires.wheelpartsize.y), tiresFound and hueToRgb(frTempHue[3]) or color.gray, scale(5), 5)
            ui.setCursorX(ui.getCursorX() + scale(16))
            ui.drawRectFilled(ui.getCursor(), vec2(ui.getCursorX() + position.tires.wheelpartsize.x, ui.getCursorY() + position.tires.wheelpartsize.y), tiresFound and hueToRgb(frTempHue[1]) or color.gray, scale(5), 10)
            if settings.tiresShowWear then
                ui.setCursorX(ui.getCursorX() + scale(18))
                ui.setCursorY(ui.getCursorY() + position.tires.wearsize.y)
                ui.drawRectFilled(vec2(ui.getCursorX() - wearOl, ui.getCursorY() + wearOl), vec2(ui.getCursorX() + (position.tires.wearsize.x + wearOl), ui.getCursorY() - (position.tires.wearsize.y + wearOl)), color.black)
                ui.drawRectFilled(ui.getCursor(), vec2(ui.getCursorX() + position.tires.wearsize.x, ui.getCursorY() - position.tires.wearsize.y), wearBg)
                ui.drawRectFilled(ui.getCursor(), vec2(ui.getCursorX() + position.tires.wearsize.x, ui.getCursorY() - (position.tires.wearsize.y * (1 - playerCar().wheels[1].tyreWear))), frWearColor)
                ui.setCursor(vec2(ui.getCursorX() - scale(6), ui.getCursorY() + scale(1)))
                ui.pushDWriteFont(app.font.black)
                ui.dwriteTextAligned(math.round((1 - playerCar().wheels[1].tyreWear) * 100), scale(9), 0, 0, vec2(17, 12):scale(app.scale), false, color.white)
                ui.popDWriteFont()
            end

            if settings.tiresShowBrakeTemp then
                local frBrakeHue = math.lerp(240, 0, math.lerpInvSat(math.max(0, (playerCar().wheels[1].discTemperature / fOptBrakeTemp)), 0, 2))

                ui.setCursor(vec2(position.tires.wheelelement.x / 2 - (position.tires.brakepos.x + scale(3)), position.tires.brakepos.y))
                ui.drawRectFilled(ui.getCursor(), vec2(ui.getCursorX() + position.tires.brakesize.x, ui.getCursorY() + position.tires.brakesize.y), brakesFound and hueToRgb(frBrakeHue) or color.gray)
            end

            if settings.tiresShowPressure then
                if settings.tiresPressureUseBar then
                    unitTxt = ' bar'
                    frPressure = playerCar().wheels[1].tyrePressure * 0.0689475729
                else
                    unitTxt = ' psi'
                    frPressure = playerCar().wheels[1].tyrePressure
                end

                local frPressColor = color.white
                if settings.tiresPressureColor then
                    frPressColor = tiresFound and hueToRgb(math.lerp(240, 0, math.lerpInvSat(math.max(0, (frPressure / tireIni.fPressOpt) ^ 10), 0, 2))) or color.gray
                end

                ui.setCursor(0)
                ui.pushDWriteFont(app.font.black)
                ui.dwriteTextAligned(string.format('%.1f', frPressure):gsub('%.', ',') .. unitTxt, scale(10), 0, 0, vec2(position.tires.wheelelement.x, position.tires.pressurepos), false, frPressColor)
                ui.popDWriteFont()
            end
        end)

        vertOffset = math.floor(vertOffset + position.tires.wheelelement.y)
    end

    if settings.tiresShowTempBar then
        local flTempNum = { tempSurface[1][1], tempSurface[1][2], tempSurface[1][3] }
        local frTempNum = { tempSurface[2][1], tempSurface[2][2], tempSurface[2][3] }
        local rlTempNum = { tempSurface[3][1], tempSurface[3][2], tempSurface[3][3] }
        local rrTempNum = { tempSurface[4][1], tempSurface[4][2], tempSurface[4][3] }

        if settings.tiresTempUseFahrenheit then
            for i = 1, 3 do
                flTempNum[i] = (tempSurface[1][i] * 1.8) + 32
                frTempNum[i] = (tempSurface[2][i] * 1.8) + 32
                rlTempNum[i] = (tempSurface[3][i] * 1.8) + 32
                rrTempNum[i] = (tempSurface[4][i] * 1.8) + 32
            end
        end

        local tempTxtL = vec2(4, 0):scale(app.scale)
        local tempTxtM = vec2(30, 0):scale(app.scale)
        local tempTxtR = vec2(56, 0):scale(app.scale)

        ui.setCursor(vec2(0, vertOffset))
        ui.childWindow('tempBarFL', vec2(position.tires.decorsize.x / 2, position.tires.tempbarheight / 2), function()
            ui.drawRectFilled(ui.getCursor(), vec2(position.tires.decorsize.x / 2, position.tires.tempbarheight / 2), color.black)
            ui.pushDWriteFont(app.font.black)
            ui.setCursor(tempTxtL)
            ui.dwriteTextAligned(string.format('%1.f', flTempNum[3]), position.tires.tempbartxt.y, 0, -1, vec2(position.tires.tempbartxt.x, position.tires.tempbarheight / 2), false, color.white)
            ui.setCursor(tempTxtM)
            ui.dwriteTextAligned(string.format('%1.f', flTempNum[2]), position.tires.tempbartxt.y, 0, -1, vec2(position.tires.tempbartxt.x, position.tires.tempbarheight / 2), false, color.white)
            ui.setCursor(tempTxtR)
            ui.dwriteTextAligned(string.format('%1.f', flTempNum[1]), position.tires.tempbartxt.y, 0, -1, vec2(position.tires.tempbartxt.x, position.tires.tempbarheight / 2), false, color.white)
            ui.popDWriteFont()
        end)

        ui.setCursor(vec2(0, vertOffset + position.tires.tempbarheight / 2))
        ui.childWindow('tempBarRL', vec2(position.tires.decorsize.x / 2, position.tires.tempbarheight / 2), function()
            ui.drawRectFilled(ui.getCursor(), vec2(position.tires.decorsize.x / 2, position.tires.tempbarheight / 2), color.black)
            ui.pushDWriteFont(app.font.black)
            ui.setCursor(tempTxtL)
            ui.dwriteTextAligned(string.format('%1.f', rlTempNum[3]), position.tires.tempbartxt.y, 0, -1, vec2(position.tires.tempbartxt.x, position.tires.tempbarheight / 2), false, color.white)
            ui.setCursor(tempTxtM)
            ui.dwriteTextAligned(string.format('%1.f', rlTempNum[2]), position.tires.tempbartxt.y, 0, -1, vec2(position.tires.tempbartxt.x, position.tires.tempbarheight / 2), false, color.white)
            ui.setCursor(tempTxtR)
            ui.dwriteTextAligned(string.format('%1.f', rlTempNum[1]), position.tires.tempbartxt.y, 0, -1, vec2(position.tires.tempbartxt.x, position.tires.tempbarheight / 2), false, color.white)
            ui.popDWriteFont()
        end)

        horiOffset = position.tires.decorsize.x / 2

        ui.setCursor(vec2(horiOffset, vertOffset))
        ui.childWindow('tempBarFR', vec2(position.tires.decorsize.x / 2, position.tires.tempbarheight / 2), function()
            ui.drawRectFilled(ui.getCursor(), vec2(position.tires.decorsize.x / 2, position.tires.tempbarheight / 2), color.black)
            ui.pushDWriteFont(app.font.black)
            ui.setCursor(tempTxtL)
            ui.dwriteTextAligned(string.format('%1.f', frTempNum[3]), position.tires.tempbartxt.y, 0, -1, vec2(position.tires.tempbartxt.x, position.tires.tempbarheight / 2), false, color.white)
            ui.setCursor(tempTxtM)
            ui.dwriteTextAligned(string.format('%1.f', frTempNum[2]), position.tires.tempbartxt.y, 0, -1, vec2(position.tires.tempbartxt.x, position.tires.tempbarheight / 2), false, color.white)
            ui.setCursor(tempTxtR)
            ui.dwriteTextAligned(string.format('%1.f', frTempNum[1]), position.tires.tempbartxt.y, 0, -1, vec2(position.tires.tempbartxt.x, position.tires.tempbarheight / 2), false, color.white)
            ui.popDWriteFont()
        end)

        ui.setCursor(vec2(horiOffset, vertOffset + position.tires.tempbarheight / 2))
        ui.childWindow('tempBarRR', vec2(position.tires.decorsize.x / 2, position.tires.tempbarheight / 2), function()
            ui.drawRectFilled(ui.getCursor(), vec2(position.tires.decorsize.x / 2, position.tires.tempbarheight / 2), color.black)
            ui.pushDWriteFont(app.font.black)
            ui.setCursor(tempTxtL)
            ui.dwriteTextAligned(string.format('%1.f', rrTempNum[3]), position.tires.tempbartxt.y, 0, -1, vec2(position.tires.tempbartxt.x, position.tires.tempbarheight / 2), false, color.white)
            ui.setCursor(tempTxtM)
            ui.dwriteTextAligned(string.format('%1.f', rrTempNum[2]), position.tires.tempbartxt.y, 0, -1, vec2(position.tires.tempbartxt.x, position.tires.tempbarheight / 2), false, color.white)
            ui.setCursor(tempTxtR)
            ui.dwriteTextAligned(string.format('%1.f', rrTempNum[1]), position.tires.tempbartxt.y, 0, -1, vec2(position.tires.tempbartxt.x, position.tires.tempbarheight / 2), false, color.white)
            ui.popDWriteFont()
        end)

        vertOffset = math.round(vertOffset + math.floor(position.tires.tempbarheight))
        if vertOffset % 2 ~= 0 then vertOffset = vertOffset - 1 end
        horiOffset = 0
        horiOffset = 0
    end

    if settings.tiresShowTempVis then
        ui.setCursor(vec2(0, vertOffset))
        ui.childWindow('tiresRL', position.tires.wheelelement, function()
            ui.drawRectFilled(vec2(0, 0), vec2(math.floor(position.tires.wheelelement.x), position.tires.wheelelement.y), setColorMult(color.black, 50))

            ui.setCursor(vec2(position.tires.wheelelement.x / 2 - position.tires.wheelpartsize.x / 2, position.tires.wheelpos))
            ui.drawRectFilled(ui.getCursor(), vec2(ui.getCursorX() + position.tires.wheelpartsize.x, ui.getCursorY() + position.tires.wheelpartsize.y), tiresFound and hueToRgb(rlTempHue[2]) or color.gray)
            ui.setCursorX(ui.getCursorX() - scale(8))
            ui.drawRectFilled(ui.getCursor(), vec2(ui.getCursorX() + position.tires.wheelpartsize.x, ui.getCursorY() + position.tires.wheelpartsize.y), tiresFound and hueToRgb(rlTempHue[3]) or color.gray, scale(5), 5)
            ui.setCursorX(ui.getCursorX() + scale(16))
            ui.drawRectFilled(ui.getCursor(), vec2(ui.getCursorX() + position.tires.wheelpartsize.x, ui.getCursorY() + position.tires.wheelpartsize.y), tiresFound and hueToRgb(rlTempHue[1]) or color.gray, scale(5), 10)
            if settings.tiresShowWear then
                ui.setCursorX(ui.getCursorX() - scale(34))
                ui.setCursorY(ui.getCursorY() + position.tires.wearsize.y)
                ui.drawRectFilled(vec2(ui.getCursorX() - wearOl, ui.getCursorY() + wearOl), vec2(ui.getCursorX() + (position.tires.wearsize.x + wearOl), ui.getCursorY() - (position.tires.wearsize.y + wearOl)), color.black)
                ui.drawRectFilled(ui.getCursor(), vec2(ui.getCursorX() + position.tires.wearsize.x, ui.getCursorY() - position.tires.wearsize.y), wearBg)
                ui.drawRectFilled(ui.getCursor(), vec2(ui.getCursorX() + position.tires.wearsize.x, ui.getCursorY() - (position.tires.wearsize.y * (1 - playerCar().wheels[2].tyreWear))), rlWearColor)
                ui.setCursor(vec2(ui.getCursorX() - scale(6), ui.getCursorY() + scale(1)))
                ui.pushDWriteFont(app.font.black)
                ui.dwriteTextAligned(math.round((1 - playerCar().wheels[2].tyreWear) * 100), scale(9), 0, 0, vec2(17, 12):scale(app.scale), false, color.white)
                ui.popDWriteFont()
            end

            if settings.tiresShowBrakeTemp then
                local rlBrakeHue = math.lerp(240, 0, math.lerpInvSat(math.max(0, (playerCar().wheels[2].discTemperature / rOptBrakeTemp)), 0, 2))
                ui.setCursor(vec2(position.tires.wheelelement.x / 2 + position.tires.brakepos.x, position.tires.brakepos.y))
                ui.drawRectFilled(ui.getCursor(), vec2(ui.getCursorX() + position.tires.brakesize.x, ui.getCursorY() + position.tires.brakesize.y), brakesFound and hueToRgb(rlBrakeHue) or color.gray)
            end

            if settings.tiresShowPressure then
                if settings.tiresPressureUseBar then
                    unitTxt = ' bar'
                    rlPressure = playerCar().wheels[2].tyrePressure * 0.0689475729
                else
                    unitTxt = ' psi'
                    rlPressure = playerCar().wheels[2].tyrePressure
                end

                local rlPressColor = color.white
                if settings.tiresPressureColor then
                    rlPressColor = tiresFound and hueToRgb(math.lerp(240, 0, math.lerpInvSat(math.max(0, (rlPressure / tireIni.fPressOpt) ^ 10), 0, 2))) or color.gray
                end

                ui.setCursor(0)
                ui.pushDWriteFont(app.font.black)
                ui.dwriteTextAligned(string.format('%.1f', rlPressure):gsub('%.', ',') .. unitTxt, scale(10), 0, 0, vec2(position.tires.wheelelement.x, position.tires.pressurepos), false, rlPressColor)
                ui.popDWriteFont()
            end
        end)

        horiOffset = position.tires.wheelelement.x

        ui.setCursor(vec2(horiOffset, vertOffset))
        ui.childWindow('tiresRR', position.tires.wheelelement, function()
            ui.drawRectFilled(vec2(0, 0), position.tires.wheelelement, setColorMult(color.black, 50))

            ui.setCursor(vec2(position.tires.wheelelement.x / 2 - position.tires.wheelpartsize.x / 2, position.tires.wheelpos))
            ui.drawRectFilled(ui.getCursor(), vec2(ui.getCursorX() + position.tires.wheelpartsize.x, ui.getCursorY() + position.tires.wheelpartsize.y), tiresFound and hueToRgb(rrTempHue[2]) or color.gray)
            ui.setCursorX(ui.getCursorX() - scale(8))
            ui.drawRectFilled(ui.getCursor(), vec2(ui.getCursorX() + position.tires.wheelpartsize.x, ui.getCursorY() + position.tires.wheelpartsize.y), tiresFound and hueToRgb(rrTempHue[3]) or color.gray, scale(5), 5)
            ui.setCursorX(ui.getCursorX() + scale(16))
            ui.drawRectFilled(ui.getCursor(), vec2(ui.getCursorX() + position.tires.wheelpartsize.x, ui.getCursorY() + position.tires.wheelpartsize.y), tiresFound and hueToRgb(rrTempHue[1]) or color.gray, scale(5), 10)
            if settings.tiresShowWear then
                ui.setCursorX(ui.getCursorX() + scale(18))
                ui.setCursorY(ui.getCursorY() + position.tires.wearsize.y)
                ui.drawRectFilled(vec2(ui.getCursorX() - wearOl, ui.getCursorY() + wearOl), vec2(ui.getCursorX() + (position.tires.wearsize.x + wearOl), ui.getCursorY() - (position.tires.wearsize.y + wearOl)), color.black)
                ui.drawRectFilled(ui.getCursor(), vec2(ui.getCursorX() + position.tires.wearsize.x, ui.getCursorY() - position.tires.wearsize.y), wearBg)
                ui.drawRectFilled(ui.getCursor(), vec2(ui.getCursorX() + position.tires.wearsize.x, ui.getCursorY() - (position.tires.wearsize.y * (1 - playerCar().wheels[3].tyreWear))), rrWearColor)
                ui.setCursor(vec2(ui.getCursorX() - scale(6), ui.getCursorY() + scale(1)))
                ui.pushDWriteFont(app.font.black)
                ui.dwriteTextAligned(math.round((1 - playerCar().wheels[3].tyreWear) * 100), scale(9), 0, 0, vec2(17, 12):scale(app.scale), false, color.white)
                ui.popDWriteFont()
            end

            if settings.tiresShowBrakeTemp then
                local rrBrakeHue = math.lerp(240, 0, math.lerpInvSat(math.max(0, (playerCar().wheels[3].discTemperature / rOptBrakeTemp)), 0, 2))
                ui.setCursor(vec2(position.tires.wheelelement.x / 2 - (position.tires.brakepos.x + scale(3)), position.tires.brakepos.y))
                ui.drawRectFilled(ui.getCursor(), vec2(ui.getCursorX() + position.tires.brakesize.x, ui.getCursorY() + position.tires.brakesize.y), brakesFound and hueToRgb(rrBrakeHue) or color.gray)
            end

            if settings.tiresShowPressure then
                if settings.tiresPressureUseBar then
                    unitTxt = ' bar'
                    rrPressure = playerCar().wheels[3].tyrePressure * 0.0689475729
                else
                    unitTxt = ' psi'
                    rrPressure = playerCar().wheels[3].tyrePressure
                end

                local rrPressColor = color.white
                if settings.tiresPressureColor then
                    rrPressColor = tiresFound and hueToRgb(math.lerp(240, 0, math.lerpInvSat(math.max(0, (rrPressure / tireIni.fPressOpt) ^ 10), 0, 2))) or color.gray
                end

                ui.setCursor(0)
                ui.pushDWriteFont(app.font.black)
                ui.dwriteTextAligned(string.format('%.1f', rrPressure):gsub('%.', ',') .. unitTxt, scale(10), 0, 0, vec2(position.tires.wheelelement.x, position.tires.pressurepos), false, rrPressColor)
                ui.popDWriteFont()
            end
        end)
    end
end
