--app made by XTZ

local settings = ac.storage {
    decor = true,
    rpmBar = true,
    rpmBarColor = true,
    rpmBarShiftYellow = 95,
    rpmBarShiftRed = 98,
    gears = true,
    rpmNum = true,
    speedNum = true,
    speedNumMPH = false,
    inputBars = false,
}

local app = {
    ['flags'] = bit.bor(ui.WindowFlags.NoDecoration, ui.WindowFlags.NoBackground, ui.WindowFlags.NoNav, ui.WindowFlags.NoInputs, ui.WindowFlags.NoScrollbar),
    ['font'] = ui.DWriteFont('IBM Plex Sans', '.')
}

--currently only shows your own values even when spectating someone else
--to see the values of other players while spectating use the line below instead
--local player = ac.getCar(ac.getSim().focusedCar)
local player = ac.getCar(0)
local rpmBarColor = rgbm(1, 1, 1, 1)
local speedText = "KM/H"
if settings.speedNumMPH then speedText = "MP/H" end

function parseGear(gearInt)
    if gearInt == 0 then
        gear = "N"
    elseif gearInt == -1 then
        gear = "R"
    else
        gear = gearInt
    end
    return gear
end

function script.windowMainSettings(dt)
    ui.tabBar('TabBar', function()
        ui.tabItem('Settings', function()
            if ui.checkbox('Show Decorations', settings.decor) then settings.decor = not settings.decor end
            if ui.checkbox('Show RPM Bar', settings.rpmBar) then settings.rpmBar = not settings.rpmBar end
            if settings.rpmBar then
                ui.text('\t')
                ui.sameLine()
                if ui.checkbox("Enable Shift Colors", settings.rpmBarColor) then settings.rpmBarColor = not settings.rpmBarColor end
                if settings.rpmBarColor then
                    ui.text('\t')
                    ui.sameLine()
                    settings.rpmBarShiftYellow = ui.slider('##ShiftYellow', settings.rpmBarShiftYellow, 0, 100, 'Yellow shift at: ' .. '%.0f%')
                    ui.text('\t')
                    ui.sameLine()
                    settings.rpmBarShiftRed = ui.slider('##ShiftRed', settings.rpmBarShiftRed, 0, 100, 'Red shift at: ' .. '%.0f%')
                end
            end
            if ui.checkbox('Show gears', settings.gears) then settings.gears = not settings.gears end
            if ui.checkbox('Show Speed', settings.speedNum) then settings.speedNum = not settings.speedNum end
            if settings.speedNum then
                ui.text('\t')
                ui.sameLine()
                if ui.checkbox("Use MPH instead", settings.speedNumMPH) then settings.speedNumMPH = not settings.speedNumMPH end
                if settings.speedNumMPH then speedText = "MP/H" else speedText = "KM/H" end
            end
            if ui.checkbox('Show RPM Numbers', settings.rpmNum) then settings.rpmNum = not settings.rpmNum end
            if settings.rpmNum then
                ui.text('\t')
                ui.sameLine()
                if ui.checkbox('Show pedal input bars instead', settings.inputBars) then settings.inputBars = not settings.inputBars end
            end
        end)
    end)
end

function script.windowMain(dt)
    local rpmMix = player.rpm / player.rpmLimiter
    local rpmPercentage = math.round(rpmMix * 100)
    local speedNumber = math.round(player.speedKmh)
    if settings.speedNumMPH then speedNumber = math.round(player.speedKmh / 1.6093440006147) end

    if settings.decor then
        ui.setCursor(vec2(125, 43))
        ui.childWindow('Decor', vec2(92, 64), app.flags, function()
            ui.drawRectFilled(vec2(0, 0), vec2(14, 63), rgbm(1, 1, 1, 1))
            ui.drawRectFilled(vec2(78, 0), vec2(82, 63), rgbm(1, 1, 1, 1))
        end)
    end

    if settings.rpmBar then
        ui.setCursor(vec2(0, 21))
        ui.childWindow('rpmBar', vec2(341, 22), app.flags, function()
            if settings.rpmBarColor and rpmPercentage > settings.rpmBarShiftYellow - 1 and rpmPercentage < settings.rpmBarShiftRed then
                rpmBarColor = rgbm(1, 1, 0, 1)
            elseif settings.rpmBarColor and rpmPercentage > settings.rpmBarShiftRed - 1 then
                rpmBarColor = rgbm(1, 0, 0, 1)
            else
                rpmBarColor = rgbm(1, 1, 1, 1)
            end
            ui.drawRectFilled(vec2(0, 0), vec2(341, 22), rgbm(0, 0, 0, 0.5))
            ui.drawRectFilled(vec2(0, 0), vec2(math.lerp(0, 341, rpmMix), 22), rpmBarColor)
        end)
    end

    if settings.gears then
        ui.setCursor(vec2(134, 39))
        ui.childWindow('GearNumber', vec2(63, 63), app.flags, function()
            ui.pushDWriteFont(app.font:weight(ui.DWriteFont.Weight.Bold))
            ui.dwriteTextAligned(parseGear(player.gear), 60, ui.Alignment.Center, ui.Alignment.Center, vec2(33, 47), rgbm.colors.white)
            ui.popDWriteFont()
        end)
    end

    if settings.rpmNum and not settings.inputBars then
        ui.setCursor(vec2(196, 42))
        ui.childWindow('RPM Numbers', vec2(150, 50), app.flags, function()
            ui.pushDWriteFont(app.font:weight(ui.DWriteFont.Weight.Bold))
            ui.dwriteTextAligned(math.round(player.rpm), 33, ui.Alignment.Start, ui.Alignment.Center, vec2(150, 24), rgbm.colors.white)
            ui.popDWriteFont()

            ui.setCursor(vec2(20, 33))
            ui.pushDWriteFont(app.font:weight(ui.DWriteFont.Weight.SemiBold))
            ui.dwriteText('RPM', 14, rgbm.colors.white)
            ui.popDWriteFont()
        end)
    end

    if settings.speedNum then
        ui.setCursor(vec2(46, 42))
        ui.childWindow('Speed', vec2(150, 60), app.flags, function()
            ui.pushDWriteFont(app.font:weight(ui.DWriteFont.Weight.Bold))
            ui.dwriteTextAligned(speedNumber, 33, ui.Alignment.End, ui.Alignment.Center, vec2(60, 24), rgbm.colors.white)
            ui.popDWriteFont()

            ui.setCursor(vec2(42, 37))
            ui.pushDWriteFont(app.font:weight(ui.DWriteFont.Weight.SemiBold))
            ui.dwriteTextAligned(speedText, 14, ui.Alignment.End, ui.Alignment.Center, vec2(38, 10), rgbm.colors.white)
            ui.popDWriteFont()
        end)
    end

    if settings.inputBars and settings.rpmNum then
        local FFBmix = player.ffbFinal
        if FFBmix < 0 then FFBmix = FFBmix * -1 end
        ui.setCursor(vec2(208, 50))
        ui.childWindow('inputBars', vec2(55, 43), app.flags, function()
            ui.drawRectFilled(vec2(0, 0), vec2(15, 42), rgbm(0, 0, 0, 0.5))
            ui.drawRectFilled(vec2(15, 42), vec2(0, math.lerp(0, 42, player.clutch)), rgbm(0, 1, 1, 1))

            ui.drawRectFilled(vec2(20, 0), vec2(25, 42), rgbm(0, 0, 0, 0.5))
            ui.drawRectFilled(vec2(25, 42), vec2(20, math.lerp(42, 0, player.brake)), rgbm(1, 0, 0, 1))

            ui.drawRectFilled(vec2(30, 0), vec2(35, 42), rgbm(0, 0, 0, 0.5))
            ui.drawRectFilled(vec2(30, 42), vec2(35, math.lerp(42, 0, player.gas)), rgbm(0, 1, 0, 1))

            ui.drawRectFilled(vec2(40, 0), vec2(45, 42), rgbm(0, 0, 0, 0.5))
            ui.drawRectFilled(vec2(40, 42), vec2(45, math.lerp(42, 0, FFBmix)), rgbm(0.65, 0.65, 0.65, 1))
        end)
    end
end
