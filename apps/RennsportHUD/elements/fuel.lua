function script.fuel(dt)
    local position = getPositionTable()
    local vertOffset = app.padding

    local fuelLerp = math.lerp(0, ui.windowWidth(), playerCar().fuel / playerCar().maxFuel)
    local fuelBarColor = color.uigreen


    ui.setCursor(vec2(0, vertOffset))
    ui.childWindow('FuelBar', position.fuel.barsize, function()
        ui.drawRectFilled(vec2(0, 0), vec2(ui.windowWidth(), position.fuel.barsize.y), color.black)
        ui.drawRectFilled(vec2(0, 0), vec2(fuelLerp, position.fuel.barsize.y), fuelBarColor)
        vertOffset = vertOffset + position.fuel.barsize.y
    end)

    if settings.fuelShowRemaining then
        local fuelMaxLevel = math.round(playerCar().maxFuel, 1)
        local fuelLevel = math.round(playerCar().fuel, 1)
        local fuelPerLap = math.round(playerCar().fuelPerLap, 1)
        local fuelText = 'L'
        local fuelValue = fuelLevel

        if settings.fuelChangeBarColor then
            if fuelPerLap > 0 then
                if fuelLevel <= fuelPerLap * settings.fuelRedBar then
                    fuelBarColor = color.uired
                elseif fuelLevel <= fuelPerLap * settings.fuelYellowBar then
                    fuelBarColor = color.yellow
                end
            else
                if math.round(fuelLevel / fuelMaxLevel, 2) <= 0.05 then
                    fuelBarColor = color.uired
                elseif math.round(fuelLevel / fuelMaxLevel, 2) <= 0.20 then
                    fuelBarColor = color.yellow
                end
            end
        end

        if settings.fuelGallons and not settings.fuelLaps then
            fuelLevel = math.round(playerCar().fuel * 0.264172, 1)
            fuelMaxLevel = math.round(playerCar().maxFuel * 0.264172, 1)
            fuelText = 'gal'
            fuelValue = fuelLevel
        end

        if settings.fuelLaps and fuelPerLap > 0 then
            fuelText = 'Laps'
            fuelValue = math.round(fuelLevel / fuelPerLap, 1)
        end

        ui.setCursor(vec2(0, vertOffset))
        ui.childWindow('FuelValue', vec2(scale(150), position.fuel.valueheight), function()
            ui.drawRectFilled(vec2(0, 0), vec2(ui.windowWidth(), position.fuel.valueheight), setColorMult(color.black, 50))
            ui.pushDWriteFont(app.font.black)
            ui.dwriteDrawText('FUEL REMAINING', scale(10), position.fuel.txtpos)
            ui.popDWriteFont()

            ui.setCursor(vec2(position.fuel.txtpos.x, position.fuel.valuepos))
            ui.pushDWriteFont(app.font.bold)
            ui.dwriteTextAligned(string.format('%.1f', fuelValue):gsub('%.', ','):gsub('^(%d),', '0%1,'), scale(22), -1, 0, vec2(50, 25):scale(app.scale), false, color.white)
            ui.popDWriteFont()

            ui.setCursor(vec2(position.fuel.txtpos.x, position.fuel.valuepos))
            ui.pushDWriteFont(app.font.bold)
            ui.dwriteDrawText(fuelText, scale(16), position.fuel.unitpos)
            ui.popDWriteFont()
        end)
    end
end
