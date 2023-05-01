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
    local flTempCurrent = { playerCar().wheels[0].tyreOutsideTemperature, playerCar().wheels[0].tyreMiddleTemperature, playerCar().wheels[0].tyreInsideTemperature }
    local flTempOptimal = playerCar().wheels[0].tyreOptimumTemperature

    local frTempCurrent = { playerCar().wheels[1].tyreOutsideTemperature, playerCar().wheels[1].tyreMiddleTemperature, playerCar().wheels[1].tyreInsideTemperature }
    local frTempOptimal = playerCar().wheels[1].tyreOptimumTemperature

    local rlTempCurrent = { playerCar().wheels[2].tyreOutsideTemperature, playerCar().wheels[2].tyreMiddleTemperature, playerCar().wheels[2].tyreInsideTemperature }
    local rlTempOptimal = playerCar().wheels[2].tyreOptimumTemperature

    local rrTempCurrent = { playerCar().wheels[3].tyreOutsideTemperature, playerCar().wheels[3].tyreMiddleTemperature, playerCar().wheels[3].tyreInsideTemperature }
    local rrTempOptimal = playerCar().wheels[3].tyreOptimumTemperature

    for i = 1, 3 do
        flTempHue[i] = math.lerp(240, 0, math.lerpInvSat(math.max(0, (flTempCurrent[i] / flTempOptimal) ^ 3.5), 0, 2))
        frTempHue[i] = math.lerp(240, 0, math.lerpInvSat(math.max(0, (frTempCurrent[i] / frTempOptimal) ^ 3.5), 0, 2))
        rlTempHue[i] = math.lerp(240, 0, math.lerpInvSat(math.max(0, (rlTempCurrent[i] / rlTempOptimal) ^ 3.5), 0, 2))
        rrTempHue[i] = math.lerp(240, 0, math.lerpInvSat(math.max(0, (rrTempCurrent[i] / rrTempOptimal) ^ 3.5), 0, 2))
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
        local flTempNum = { flTempCurrent[1], flTempCurrent[2], flTempCurrent[3] }
        local frTempNum = { frTempCurrent[1], frTempCurrent[2], frTempCurrent[3] }
        local rlTempNum = { rlTempCurrent[1], rlTempCurrent[2], rlTempCurrent[3] }
        local rrTempNum = { rrTempCurrent[1], rrTempCurrent[2], rrTempCurrent[3] }

        if settings.tiresTempUseFahrenheit then
            for i = 1, 3 do
                flTempNum[i] = (flTempCurrent[i] * 1.8) + 32
                frTempNum[i] = (frTempCurrent[i] * 1.8) + 32
                rlTempNum[i] = (rlTempCurrent[i] * 1.8) + 32
                rrTempNum[i] = (rrTempCurrent[i] * 1.8) + 32
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
        if vertOffset % 2 ~= 0 then vertOffset = vertOffset -1 end --scaling bandaid lole
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
