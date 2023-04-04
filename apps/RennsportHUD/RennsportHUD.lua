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
    changeScale = false,
    scale = 1
}

local app = {
    ['flags'] = bit.bor(ui.WindowFlags.NoDecoration, ui.WindowFlags.NoBackground, ui.WindowFlags.NoNav, ui.WindowFlags.NoInputs, ui.WindowFlags.NoScrollbar),
    ['font'] = ui.DWriteFont('IBM Plex Sans', '.'),
    ['scale'] = 1
}

--currently only shows your own values even when spectating someone else
--to see the values of other players while spectating use the line below instead
--local player = ac.getCar(ac.getSim().focusedCar)
local player = ac.getCar(0)
local rpmBarColor = rgbm(1, 1, 1, 1)
local speedText = 'KM/H'
if settings.speedNumMPH then speedText = 'MP/H' end

function scale(value)
    return app.scale * value
end

function scaleVec2(valueX, valueY)
    return vec2(app.scale * valueX, app.scale * valueY)
end

function parseGear(gearInt)
    if gear == 0 then
        gear = 'N'
    elseif gear == -1 then
        gear = 'R'
    else
        gear = gearInt
    end
    return gear
end

function script.windowMainSettings(dt)
    ui.tabBar('TabBar', function()
        ui.tabItem('Settings', function()
            if ui.checkbox('Custom App Scaling', settings.changeScale) then settings.changeScale = not settings.changeScale end
            if settings.changeScale then
                ui.text('\t')
                ui.sameLine()
                settings.scale = ui.slider('##AppScale', settings.scale, 0.69, 5, 'App Scale: ' .. '%.02f%')
                if app.scale ~= settings.scale then app.scale = settings.scale end
            else
                app.scale = 1
            end
            if ui.checkbox('Show RPM Bar', settings.rpmBar) then settings.rpmBar = not settings.rpmBar end
            if settings.rpmBar then
                ui.text('\t')
                ui.sameLine()
                if ui.checkbox('Enable Shift Colors', settings.rpmBarColor) then settings.rpmBarColor = not settings.rpmBarColor end
                if settings.rpmBarColor then
                    ui.text('\t')
                    ui.sameLine()
                    settings.rpmBarShiftYellow = ui.slider('##ShiftYellow', settings.rpmBarShiftYellow, 0, 100, 'Yellow shift at: ' .. '%.0f%')
                    ui.text('\t')
                    ui.sameLine()
                    settings.rpmBarShiftRed = ui.slider('##ShiftRed', settings.rpmBarShiftRed, 0, 100, 'Red shift at: ' .. '%.0f%')
                end
            end
            if ui.checkbox('Show Speed', settings.speedNum) then settings.speedNum = not settings.speedNum end
            if settings.speedNum then
                ui.text('\t')
                ui.sameLine()
                if ui.checkbox('Use MPH Instead', settings.speedNumMPH) then settings.speedNumMPH = not settings.speedNumMPH end
                if settings.speedNumMPH then speedText = 'MP/H' else speedText = 'KM/H' end
            end
            if ui.checkbox('Show Decorations', settings.decor) then settings.decor = not settings.decor end
            if ui.checkbox('Show Gears', settings.gears) then settings.gears = not settings.gears end

            if ui.checkbox('Show RPM Numbers', settings.rpmNum) then settings.rpmNum = not settings.rpmNum end
            if settings.rpmNum then
                ui.text('\t')
                ui.sameLine()
                if ui.checkbox('Show Pedal Inputs Instead', settings.inputBars) then settings.inputBars = not settings.inputBars end
            end
        end)
    end)
end

function script.windowMain(dt)
    ui.setCursor(0, 22)
    ui.childWindow('main', scaleVec2(342, 106), function()
        local centerx = ui.availableSpaceX() / 2
        local centery = ui.availableSpaceY() / 2 + 22 -- +22 because the apps top bar is that thick
        local rpmMix = player.rpm / player.rpmLimiter
        local rpmPercentage = math.round(rpmMix * 100)
        local speedNumber = math.round(player.speedKmh)
        if settings.speedNumMPH then speedNumber = math.round(player.speedKmh / 1.6093440006147) end

        if settings.rpmBar then
            ui.setCursor(vec2(0, 22))
            if settings.rpmBarColor and rpmPercentage > settings.rpmBarShiftYellow - 1 and rpmPercentage < settings.rpmBarShiftRed then
                rpmBarColor = rgbm(1, 1, 0, 1)
            elseif settings.rpmBarColor and rpmPercentage > settings.rpmBarShiftRed - 1 then
                rpmBarColor = rgbm(1, 0, 0, 1)
            else
                rpmBarColor = rgbm(1, 1, 1, 1)
            end
            ui.drawRectFilled(vec2(0, ui.getCursorY()), vec2(ui.availableSpaceX(), ui.getCursorY() + scale(20)), rgbm(0, 0, 0, 0.5))
            ui.drawRectFilled(vec2(0, ui.getCursorY()), vec2(math.lerp(0, ui.availableSpaceX(), rpmMix), ui.getCursorY() + scale(20)), rpmBarColor)
        end

        if settings.speedNum then
            ui.setCursor(vec2(centerx - scale(105), centery - scale(25)))
            ui.pushDWriteFont(app.font:weight(ui.DWriteFont.Weight.Bold))
            ui.dwriteTextAligned(speedNumber, scale(33), ui.Alignment.End, ui.Alignment.Center, scaleVec2(60, 26), false, rgbm.colors.white)
            ui.popDWriteFont()

            ui.setCursor(vec2(centerx - scale(83), centery + scale(5)))
            ui.pushDWriteFont(app.font:weight(ui.DWriteFont.Weight.SemiBold))
            ui.dwriteTextAligned(speedText, scale(14), ui.Alignment.End, ui.Alignment.Center, scaleVec2(38, 10), false, rgbm.colors.white)
            ui.popDWriteFont()
        end

        if settings.decor then
            ui.setCursor(vec2(centerx - scale(36), centery - scale(31)))
            ui.drawRectFilled(vec2(ui.getCursorX(), ui.getCursorY()), vec2(ui.getCursorX() + scale(4), ui.getCursorY() + scale(62)), rgbm(1, 1, 1, 1))
            ui.drawRectFilled(vec2(ui.getCursorX() + scale(68), ui.getCursorY()), vec2(ui.getCursorX() + scale(72), ui.getCursorY() + scale(62)), rgbm(1, 1, 1, 1))
        end

        if settings.rpmNum and not settings.inputBars then
            ui.setCursor(vec2(centerx + scale(45), centery - scale(25)))
            ui.pushDWriteFont(app.font:weight(ui.DWriteFont.Weight.Bold))
            ui.dwriteTextAligned(math.round(player.rpm), scale(33), ui.Alignment.Start, ui.Alignment.Center, scaleVec2(150, 26), false, rgbm.colors.white)
            ui.popDWriteFont()

            ui.setCursor(vec2(centerx + scale(45), centery + scale(1)))
            ui.pushDWriteFont(app.font:weight(ui.DWriteFont.Weight.SemiBold))
            ui.dwriteText('RPM', scale(14), rgbm.colors.white)
            ui.popDWriteFont()
        end

        if settings.gears then
            ui.setCursor(vec2(centerx - scale(17), centery - scale(28)))
            ui.pushDWriteFont(app.font:weight(ui.DWriteFont.Weight.Bold))
            ui.dwriteTextAligned(parseGear(player.gear), scale(60), ui.Alignment.Center, ui.Alignment.Center, scaleVec2(34, 48), rgbm.colors.white)
            ui.popDWriteFont()
        end

        if settings.inputBars and settings.rpmNum then
            local FFBmix = player.ffbFinal
            local barheight = scale(38)
            local barwidth = scale(5)
            local barposy = centery - scale(23)
            if FFBmix < 0 then FFBmix = FFBmix * -1 end
            ui.setCursor(vec2(centerx + scale(46), barposy))
            ui.drawRectFilled(vec2(ui.getCursorX(), ui.getCursorY()), vec2(ui.getCursorX() + barwidth, ui.getCursorY() + barheight), rgbm(0, 0, 0, 0.5))
            ui.drawRectFilled(vec2(ui.getCursorX(), ui.getCursorY() + barheight), vec2(ui.getCursorX() + barwidth, ui.getCursorY() + barheight - math.lerp(barheight, 0, player.clutch)), rgbm(0, 1, 1, 1))

            ui.setCursor(vec2(centerx + scale(56), barposy))
            ui.drawRectFilled(vec2(ui.getCursorX(), ui.getCursorY()), vec2(ui.getCursorX() + barwidth, ui.getCursorY() + barheight), rgbm(0, 0, 0, 0.5))
            ui.drawRectFilled(vec2(ui.getCursorX(), ui.getCursorY() + barheight), vec2(ui.getCursorX() + barwidth, ui.getCursorY() + barheight - math.lerp(0, barheight, player.brake)), rgbm(1, 0, 0, 1))

            ui.setCursor(vec2(centerx + scale(66), barposy))
            ui.drawRectFilled(vec2(ui.getCursorX(), ui.getCursorY()), vec2(ui.getCursorX() + barwidth, ui.getCursorY() + barheight), rgbm(0, 0, 0, 0.5))
            ui.drawRectFilled(vec2(ui.getCursorX(), ui.getCursorY() + barheight), vec2(ui.getCursorX() + barwidth, ui.getCursorY() + barheight - math.lerp(0, barheight, player.gas)), rgbm(0, 1, 0, 1))

            ui.setCursor(vec2(centerx + scale(76), barposy))
            ui.drawRectFilled(vec2(ui.getCursorX(), ui.getCursorY()), vec2(ui.getCursorX() + barwidth, ui.getCursorY() + barheight), rgbm(0, 0, 0, 0.5))
            ui.drawRectFilled(vec2(ui.getCursorX(), ui.getCursorY() + barheight), vec2(ui.getCursorX() + barwidth, ui.getCursorY() + barheight - math.lerp(0, barheight, FFBmix)), rgbm(0.65, 0.65, 0.65, 1))
        end
    end)
end
