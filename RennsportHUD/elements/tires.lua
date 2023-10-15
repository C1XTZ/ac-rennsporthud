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

--these are taken from the Honda S2000 Turbo GT1 Amuse data since no Kunos car that I tested had working brake temps. probably giga wrong for any other car but im not sure how to handle that lol]]
local brakeTempOptimalF = 550
local brakeTempOptimalR = 500

local flTempHue = { 240, 240, 240 }
local frTempHue = { 240, 240, 240 }
local rlTempHue = { 240, 240, 240 }
local rrTempHue = { 240, 240, 240 }

local flWearColor, frWearColor, rlWearColor, rrWearColor
local wearPercent = { 0.75, 0.50, 0.0 }
local wearPercentColors = { getColorTable().red, getColorTable().orange, getColorTable().white }

function script.tires(dt)
    local position = getPositionTable()
    local vertOffset = math.round(app.padding)
    local horiOffset = 0

    --[[ LEFT SIDE TEMPS ARE FLIPPED, MEANING tyreInsideTemperature and tyreOutsideTemperature ARE FLIPPED FOR wheels[0] and wheels[2] IF THIS IS EVER FIXED I NEED TO ADJUST THE DRAWING ORDER FOR THE LEFT SIDE XD

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

    local tempCurrent = {}
    local tempOptimal = {}

    for i = 0, 3 do
        local wheel = playerCar().wheels[i]
        tempCurrent[i + 1] = { wheel.tyreOutsideTemperature, wheel.tyreMiddleTemperature, wheel.tyreInsideTemperature }
        tempOptimal[i + 1] = wheel.tyreOptimumTemperature
    end

    for i = 1, 3 do
        flTempHue[i] = math.lerp(240, 0, math.lerpInvSat(math.max(0, (tempCurrent[1][i] / tempOptimal[1]) ^ 3.5), 0, 2))
        frTempHue[i] = math.lerp(240, 0, math.lerpInvSat(math.max(0, (tempCurrent[2][i] / tempOptimal[2]) ^ 3.5), 0, 2))
        rlTempHue[i] = math.lerp(240, 0, math.lerpInvSat(math.max(0, (tempCurrent[3][i] / tempOptimal[3]) ^ 3.5), 0, 2))
        rrTempHue[i] = math.lerp(240, 0, math.lerpInvSat(math.max(0, (tempCurrent[4][i] / tempOptimal[4]) ^ 3.5), 0, 2))
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
            ui.drawRectFilled(vec2(0, 0), position.tires.wheelelement, setColorMult(color.black, 50))

            ui.setCursor(vec2(position.tires.wheelelement.x / 2 - position.tires.wheelpartsize.x / 2, position.tires.wheelpos))
            ui.drawRectFilled(ui.getCursor(), vec2(ui.getCursorX() + position.tires.wheelpartsize.x, ui.getCursorY() + position.tires.wheelpartsize.y), hueToRgb(flTempHue[2]))
            ui.setCursorX(ui.getCursorX() - scale(8))
            ui.drawRectFilled(ui.getCursor(), vec2(ui.getCursorX() + position.tires.wheelpartsize.x, ui.getCursorY() + position.tires.wheelpartsize.y), hueToRgb(flTempHue[3]), 5, 5)
            ui.setCursorX(ui.getCursorX() + scale(16))
            ui.drawRectFilled(ui.getCursor(), vec2(ui.getCursorX() + position.tires.wheelpartsize.x, ui.getCursorY() + position.tires.wheelpartsize.y), hueToRgb(flTempHue[1]), 5, 10)
            if settings.tiresShowWear then
                ui.setCursorX(ui.getCursorX() - scale(34))
                ui.setCursorY(ui.getCursorY() + position.tires.wheelpartsize.y)
                ui.drawRectFilled(ui.getCursor(), vec2(ui.getCursorX() + position.tires.wheelpartsize.x, ui.getCursorY() - position.tires.wheelpartsize.y), setColorMult(color.black, 50))
                ui.drawRectFilled(ui.getCursor(), vec2(ui.getCursorX() + position.tires.wheelpartsize.x, ui.getCursorY() - (position.tires.wheelpartsize.y * (1 - playerCar().wheels[0].tyreWear))), flWearColor)
            end

            if settings.tiresShowBrakeTemp then
                local flBrakeTemp = playerCar().wheels[0].discTemperature
                local flBrakeHue = math.lerp(240, 0, math.lerpInvSat(math.max(0, (flBrakeTemp / brakeTempOptimalF)), 0, 2))

                ui.setCursor(vec2(position.tires.wheelelement.x / 2 + position.tires.brakepos.x, position.tires.brakepos.y))
                ui.drawRectFilled(ui.getCursor(), vec2(ui.getCursorX() + position.tires.brakesize.x, ui.getCursorY() + position.tires.brakesize.y), hueToRgb(flBrakeHue))
            end

            if settings.tiresShowPressure then
                local flPressure
                local unitTxt
                if settings.tiresPressureUseBar then
                    unitTxt = ' bar'
                    flPressure = playerCar().wheels[0].tyrePressure * 0.0689475729
                else
                    unitTxt = ' psi'
                    flPressure = playerCar().wheels[0].tyrePressure
                end

                ui.setCursor(0)
                ui.pushDWriteFont(app.font.black)
                ui.dwriteTextAligned(string.format('%.1f', flPressure):gsub('%.', ',') .. unitTxt, scale(10), 0, 0, vec2(position.tires.wheelelement.x, position.tires.pressurepos), false, color.white)
                ui.popDWriteFont()
            end
        end)

        horiOffset = horiOffset + position.tires.wheelelement.x

        ui.setCursor(vec2(horiOffset, vertOffset))
        ui.childWindow('tiresFR', position.tires.wheelelement, function()
            ui.drawRectFilled(vec2(0, 0), position.tires.wheelelement, setColorMult(color.black, 50))

            ui.setCursor(vec2(position.tires.wheelelement.x / 2 - position.tires.wheelpartsize.x / 2, position.tires.wheelpos))
            ui.drawRectFilled(ui.getCursor(), vec2(ui.getCursorX() + position.tires.wheelpartsize.x, ui.getCursorY() + position.tires.wheelpartsize.y), hueToRgb(frTempHue[2]))
            ui.setCursorX(ui.getCursorX() - scale(8))
            ui.drawRectFilled(ui.getCursor(), vec2(ui.getCursorX() + position.tires.wheelpartsize.x, ui.getCursorY() + position.tires.wheelpartsize.y), hueToRgb(frTempHue[3]), 5, 5)
            ui.setCursorX(ui.getCursorX() + scale(16))
            ui.drawRectFilled(ui.getCursor(), vec2(ui.getCursorX() + position.tires.wheelpartsize.x, ui.getCursorY() + position.tires.wheelpartsize.y), hueToRgb(frTempHue[1]), 5, 10)
            if settings.tiresShowWear then
                ui.setCursorX(ui.getCursorX() + scale(18))
                ui.setCursorY(ui.getCursorY() + position.tires.wheelpartsize.y)
                ui.drawRectFilled(ui.getCursor(), vec2(ui.getCursorX() + position.tires.wheelpartsize.x, ui.getCursorY() - position.tires.wheelpartsize.y), setColorMult(color.black, 50))
                ui.drawRectFilled(ui.getCursor(), vec2(ui.getCursorX() + position.tires.wheelpartsize.x, ui.getCursorY() - (position.tires.wheelpartsize.y * (1 - playerCar().wheels[1].tyreWear))), frWearColor)
            end

            if settings.tiresShowBrakeTemp then
                local frBrakeTemp = playerCar().wheels[1].discTemperature
                local frBrakeHue = math.lerp(240, 0, math.lerpInvSat(math.max(0, (frBrakeTemp / brakeTempOptimalF)), 0, 2))

                ui.setCursor(vec2(position.tires.wheelelement.x / 2 - (position.tires.brakepos.x + scale(2)), position.tires.brakepos.y))
                ui.drawRectFilled(ui.getCursor(), vec2(ui.getCursorX() + position.tires.brakesize.x, ui.getCursorY() + position.tires.brakesize.y), hueToRgb(frBrakeHue))
            end

            if settings.tiresShowPressure then
                local unitTxt
                local frPressure
                if settings.tiresPressureUseBar then
                    unitTxt = ' bar'
                    frPressure = playerCar().wheels[1].tyrePressure * 0.0689475729
                else
                    unitTxt = ' psi'
                    frPressure = playerCar().wheels[1].tyrePressure
                end

                ui.setCursor(0)
                ui.pushDWriteFont(app.font.black)
                ui.dwriteTextAligned(string.format('%.1f', frPressure):gsub('%.', ',') .. unitTxt, scale(10), 0, 0, vec2(position.tires.wheelelement.x, position.tires.pressurepos), false, color.white)
                ui.popDWriteFont()
            end
        end)

        vertOffset = math.floor(vertOffset + position.tires.wheelelement.y)
    end

    if settings.tiresShowTempBar then
        local flTempNum = { tempCurrent[1][1], tempCurrent[1][2], tempCurrent[1][3] }
        local frTempNum = { tempCurrent[2][1], tempCurrent[2][2], tempCurrent[2][3] }
        local rlTempNum = { tempCurrent[3][1], tempCurrent[3][2], tempCurrent[3][3] }
        local rrTempNum = { tempCurrent[4][1], tempCurrent[4][2], tempCurrent[4][3] }

        if settings.tiresTempUseFahrenheit then
            for i = 1, 3 do
                flTempNum[i] = (tempCurrent[1][i] * 1.8) + 32
                frTempNum[i] = (tempCurrent[2][i] * 1.8) + 32
                rlTempNum[i] = (tempCurrent[3][i] * 1.8) + 32
                rrTempNum[i] = (tempCurrent[4][i] * 1.8) + 32
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
        if vertOffset % 2 ~= 0 then vertOffset = vertOffset - 1 end --scaling bandaid lole
        horiOffset = 0
        horiOffset = 0
    end

    if settings.tiresShowTempVis then
        ui.setCursor(vec2(0, vertOffset))
        ui.childWindow('tiresRL', position.tires.wheelelement, function()
            ui.drawRectFilled(vec2(0, 0), position.tires.wheelelement, setColorMult(color.black, 50))

            ui.setCursor(vec2(position.tires.wheelelement.x / 2 - position.tires.wheelpartsize.x / 2, position.tires.wheelpos))
            ui.drawRectFilled(ui.getCursor(), vec2(ui.getCursorX() + position.tires.wheelpartsize.x, ui.getCursorY() + position.tires.wheelpartsize.y), hueToRgb(rlTempHue[2]))
            ui.setCursorX(ui.getCursorX() - scale(8))
            ui.drawRectFilled(ui.getCursor(), vec2(ui.getCursorX() + position.tires.wheelpartsize.x, ui.getCursorY() + position.tires.wheelpartsize.y), hueToRgb(rlTempHue[3]), 5, 5)
            ui.setCursorX(ui.getCursorX() + scale(16))
            ui.drawRectFilled(ui.getCursor(), vec2(ui.getCursorX() + position.tires.wheelpartsize.x, ui.getCursorY() + position.tires.wheelpartsize.y), hueToRgb(rlTempHue[1]), 5, 10)
            if settings.tiresShowWear then
                ui.setCursorX(ui.getCursorX() - scale(34))
                ui.setCursorY(ui.getCursorY() + position.tires.wheelpartsize.y)
                ui.drawRectFilled(ui.getCursor(), vec2(ui.getCursorX() + position.tires.wheelpartsize.x, ui.getCursorY() - position.tires.wheelpartsize.y), setColorMult(color.black, 50))
                ui.drawRectFilled(ui.getCursor(), vec2(ui.getCursorX() + position.tires.wheelpartsize.x, ui.getCursorY() - (position.tires.wheelpartsize.y * (1 - playerCar().wheels[2].tyreWear))), rlWearColor)
            end

            if settings.tiresShowBrakeTemp then
                local rlBrakeTemp = playerCar().wheels[2].discTemperature
                local rlBrakeHue = math.lerp(240, 0, math.lerpInvSat(math.max(0, (rlBrakeTemp / brakeTempOptimalR)), 0, 2))

                ui.setCursor(vec2(position.tires.wheelelement.x / 2 + position.tires.brakepos.x, position.tires.brakepos.y))
                ui.drawRectFilled(ui.getCursor(), vec2(ui.getCursorX() + position.tires.brakesize.x, ui.getCursorY() + position.tires.brakesize.y), hueToRgb(rlBrakeHue))
            end

            if settings.tiresShowPressure then
                local rlPressure
                local unitTxt
                if settings.tiresPressureUseBar then
                    unitTxt = ' bar'
                    rlPressure = playerCar().wheels[2].tyrePressure * 0.0689475729
                else
                    unitTxt = ' psi'
                    rlPressure = playerCar().wheels[2].tyrePressure
                end

                ui.setCursor(0)
                ui.pushDWriteFont(app.font.black)
                ui.dwriteTextAligned(string.format('%.1f', rlPressure):gsub('%.', ',') .. unitTxt, scale(10), 0, 0, vec2(position.tires.wheelelement.x, position.tires.pressurepos), false, color.white)
                ui.popDWriteFont()
            end
        end)

        horiOffset = position.tires.wheelelement.x

        ui.setCursor(vec2(horiOffset, vertOffset))
        ui.childWindow('tiresRR', position.tires.wheelelement, function()
            ui.drawRectFilled(vec2(0, 0), position.tires.wheelelement, setColorMult(color.black, 50))

            ui.setCursor(vec2(position.tires.wheelelement.x / 2 - position.tires.wheelpartsize.x / 2, position.tires.wheelpos))
            ui.drawRectFilled(ui.getCursor(), vec2(ui.getCursorX() + position.tires.wheelpartsize.x, ui.getCursorY() + position.tires.wheelpartsize.y), hueToRgb(rrTempHue[2]))
            ui.setCursorX(ui.getCursorX() - scale(8))
            ui.drawRectFilled(ui.getCursor(), vec2(ui.getCursorX() + position.tires.wheelpartsize.x, ui.getCursorY() + position.tires.wheelpartsize.y), hueToRgb(rrTempHue[3]), 5, 5)
            ui.setCursorX(ui.getCursorX() + scale(16))
            ui.drawRectFilled(ui.getCursor(), vec2(ui.getCursorX() + position.tires.wheelpartsize.x, ui.getCursorY() + position.tires.wheelpartsize.y), hueToRgb(rrTempHue[1]), 5, 10)
            if settings.tiresShowWear then
                ui.setCursorX(ui.getCursorX() + scale(18))
                ui.setCursorY(ui.getCursorY() + position.tires.wheelpartsize.y)
                ui.drawRectFilled(ui.getCursor(), vec2(ui.getCursorX() + position.tires.wheelpartsize.x, ui.getCursorY() - position.tires.wheelpartsize.y), setColorMult(color.black, 50))
                ui.drawRectFilled(ui.getCursor(), vec2(ui.getCursorX() + position.tires.wheelpartsize.x, ui.getCursorY() - (position.tires.wheelpartsize.y * (1 - playerCar().wheels[3].tyreWear))), rrWearColor)
            end

            if settings.tiresShowBrakeTemp then
                local rrBrakeTemp = playerCar().wheels[1].discTemperature
                local rrBrakeHue = math.lerp(240, 0, math.lerpInvSat(math.max(0, (rrBrakeTemp / brakeTempOptimalR)), 0, 2))

                ui.setCursor(vec2(position.tires.wheelelement.x / 2 - (position.tires.brakepos.x + scale(2)), position.tires.brakepos.y))
                ui.drawRectFilled(ui.getCursor(), vec2(ui.getCursorX() + position.tires.brakesize.x, ui.getCursorY() + position.tires.brakesize.y), hueToRgb(rrBrakeHue))
            end

            if settings.tiresShowPressure then
                local unitTxt
                local rrPressure
                if settings.tiresPressureUseBar then
                    unitTxt = ' bar'
                    rrPressure = playerCar().wheels[3].tyrePressure * 0.0689475729
                else
                    unitTxt = ' psi'
                    rrPressure = playerCar().wheels[3].tyrePressure
                end

                ui.setCursor(0)
                ui.pushDWriteFont(app.font.black)
                ui.dwriteTextAligned(string.format('%.1f', rrPressure):gsub('%.', ',') .. unitTxt, scale(10), 0, 0, vec2(position.tires.wheelelement.x, position.tires.pressurepos), false, color.white)
                ui.popDWriteFont()
            end
        end)
    end
end
