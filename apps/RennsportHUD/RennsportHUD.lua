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
    scale = 1,
    compactMode = false
}

local app = {
    ['flags'] = bit.bor(ui.WindowFlags.NoDecoration, ui.WindowFlags.NoBackground, ui.WindowFlags.NoNav, ui.WindowFlags.NoInputs, ui.WindowFlags.NoScrollbar),
    ['font'] = ui.DWriteFont('IBM Plex Sans', '.'),
    ['scale'] = 1
}

--#region Shamelessly stolen from Rhizix's GT7 HUD, https://www.racedepartment.com/downloads/gt7-hud.56420/
function scale(value)
    return app.scale * value
end

function scaleVec2(valueX, valueY)
    return vec2(app.scale * valueX, app.scale * valueY)
end
--#endregion

function parseGear(gearInt)
    if gearInt == 0 then
        gear = 'N'
    elseif gearInt == -1 then
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
                settings.scale = ui.slider('##AppScale', settings.scale, 1, 5, 'App Scale: ' .. '%.01f%')
                ui.text('\t')
                ui.sameLine()
                if ui.checkbox('Enable Compact Mode', settings.compactMode) then settings.compactMode = not settings.compactMode end
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
                    settings.rpmBarShiftYellow = ui.slider('##ShiftYellow', settings.rpmBarShiftYellow, 0, 100, 'Yellow shift at: ' .. '%.0f%%')
                    ui.text('\t')
                    ui.sameLine()
                    settings.rpmBarShiftRed = ui.slider('##ShiftRed', settings.rpmBarShiftRed, 0, 100, 'Red shift at: ' .. '%.0f%%')
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
    local focusedCar = ac.getSim().focusedCar
    local player
    if focusedCar > 0 then player = ac.getCar(focusedCar) else player = ac.getCar(0) end

    if settings.changeScale and app.scale ~= settings.scale then app.scale = settings.scale end

    local appsize = scaleVec2(325, 121)
    local rpmBarHeight = scale(17)
    local speedNumBoldCursorx = scale(106)
    local speedNumBoldCursory = scale(28)
    local speedNumSemiCursorx = scale(84)
    local speedNumSemiCursory = scale(5)
    local decorCursorLeftx = scale(38)
    local decorCursorRightx = scale(35)
    local decorCursory = scale(41)
    local decorBarWidth = scale(4)
    local decorBarHeight = scale(80)
    local gearsCursorx = scale(17)
    local gearsCursory = scale(31)
    local rpmNumCursorx = scale(46)
    local rpmNumBoldCursory = scale(28)
    local rpmNumSemiCursory = scale(3)
    local inputBarCursory = scale(25)
    local inputBarCursorx = scale(47)
    local inputBarHeight = scale(43)
    local inputBarWidth = scale(5)
    local inputBarGap = scale(5 + inputBarWidth / app.scale)

    if settings.compactMode and settings.changeScale then
        appsize = scaleVec2(297, 85)
        rpmBarHeight = scale(10)
        decorCursory = scale(30)
        decorBarHeight = scale(51)
    end

    ui.setCursor(0, 22)
    ui.childWindow('main', appsize, function()
        local centerx = ui.availableSpaceX() / 2
        local centery = ui.availableSpaceY() / 2 + 22 -- +22 because the apps top bar is that thick

        if settings.rpmBar then
            local rpmMix = player.rpm / player.rpmLimiter
            local rpmPercentage = math.round(rpmMix * 100)
            local rpmBarColor
            if settings.rpmBarColor and rpmPercentage > settings.rpmBarShiftYellow - 1 and rpmPercentage < settings.rpmBarShiftRed then
                rpmBarColor = rgbm(1, 1, 0, 1)
            elseif settings.rpmBarColor and rpmPercentage > settings.rpmBarShiftRed - 1 then
                rpmBarColor = rgbm(1, 0, 0, 1)
            else
                rpmBarColor = rgbm(1, 1, 1, 1)
            end
            ui.setCursor(vec2(0, 22))
            ui.drawRectFilled(vec2(0, ui.getCursorY()), vec2(ui.availableSpaceX(), ui.getCursorY() + rpmBarHeight), rgbm(0, 0, 0, 0.5))
            ui.drawRectFilled(vec2(0, ui.getCursorY()), vec2(math.lerp(0, ui.availableSpaceX(), rpmMix), ui.getCursorY() + rpmBarHeight), rpmBarColor)
        end

        if settings.speedNum then
            local speedText
            local speedNumber
            if not settings.speedNumMPH then
                speedText = 'KM/H'
                speedNumber = math.round(player.speedKmh)
            else
                speedText = 'MP/H'
                speedNumber = math.round(player.speedKmh / 1.6093440006147)
            end

            ui.setCursor(vec2(centerx - speedNumBoldCursorx, centery - speedNumBoldCursory))
            ui.pushDWriteFont(app.font)
            ui.dwriteTextAligned(speedNumber, scale(34), ui.Alignment.End, ui.Alignment.Center, scaleVec2(60, 28), false, rgbm.colors.white)
            ui.popDWriteFont()

            ui.setCursor(vec2(centerx - speedNumSemiCursorx, centery + speedNumSemiCursory))
            ui.pushDWriteFont(app.font)
            ui.dwriteTextAligned(speedText, scale(14), ui.Alignment.End, ui.Alignment.Center, scaleVec2(38, 13), false, rgbm.colors.white)
            ui.popDWriteFont()
        end

        if settings.decor then
            ui.setCursor(vec2(centerx - decorCursorLeftx, centery - decorCursory))
            ui.drawRectFilled(vec2(ui.getCursorX(), ui.getCursorY()), vec2(ui.getCursorX() + decorBarWidth, ui.getCursorY() + decorBarHeight), rgbm(1, 1, 1, 1))
            ui.setCursor(vec2(centerx + decorCursorRightx, centery - decorCursory))
            ui.drawRectFilled(vec2(ui.getCursorX(), ui.getCursorY()), vec2(ui.getCursorX() + decorBarWidth, ui.getCursorY() + decorBarHeight), rgbm(1, 1, 1, 1))
        end

        if settings.gears then
            ui.setCursor(vec2(centerx - gearsCursorx, centery - gearsCursory))
            ui.pushDWriteFont(app.font)
            ui.dwriteTextAligned(parseGear(player.gear), scale(60), ui.Alignment.Center, ui.Alignment.Center, scaleVec2(36, 50), rgbm.colors.white)
            ui.popDWriteFont()
        end

        if settings.rpmNum and not settings.inputBars then
            ui.setCursor(vec2(centerx + rpmNumCursorx, centery - rpmNumBoldCursory))
            ui.pushDWriteFont(app.font)
            ui.dwriteTextAligned(math.round(player.rpm), scale(34), ui.Alignment.Start, ui.Alignment.Center, scaleVec2(150, 28), false, rgbm.colors.white)
            ui.popDWriteFont()

            ui.setCursor(vec2(centerx + rpmNumCursorx, centery + rpmNumSemiCursory))
            ui.pushDWriteFont(app.font)
            ui.dwriteText('RPM', scale(14), rgbm.colors.white)
            ui.popDWriteFont()
        end

        if settings.inputBars and settings.rpmNum then
            local FFBmix = player.ffbFinal
            if FFBmix < 0 then FFBmix = FFBmix * -1 end
            local FFBcolor
            if FFBlerp ~= inputBarHeight then FFBcolor = rgbm(0.65, 0.65, 0.65, 1) else FFBcolor = rgbm(1, 0, 0, 1) end

            local clutchLerp = math.lerp(inputBarHeight, 0, player.clutch)
            local brakeLerp = math.lerp(0, inputBarHeight, player.brake)
            local gasLerp = math.lerp(0, inputBarHeight, player.gas)
            local FFBlerp = math.lerp(0, inputBarHeight, FFBmix)

            ui.setCursor(vec2(centerx + inputBarCursorx, centery - inputBarCursory))
            ui.drawRectFilled(vec2(ui.getCursorX(), ui.getCursorY()), vec2(ui.getCursorX() + inputBarWidth, ui.getCursorY() + inputBarHeight), rgbm(0, 0, 0, 0.5))
            ui.drawRectFilled(vec2(ui.getCursorX(), ui.getCursorY() + inputBarHeight), vec2(ui.getCursorX() + inputBarWidth, ui.getCursorY() + inputBarHeight - clutchLerp), rgbm(0, 1, 1, 1))

            ui.setCursor(vec2(centerx + inputBarCursorx + inputBarGap, centery - inputBarCursory))
            ui.drawRectFilled(vec2(ui.getCursorX(), ui.getCursorY()), vec2(ui.getCursorX() + inputBarWidth, ui.getCursorY() + inputBarHeight), rgbm(0, 0, 0, 0.5))
            ui.drawRectFilled(vec2(ui.getCursorX(), ui.getCursorY() + inputBarHeight), vec2(ui.getCursorX() + inputBarWidth, ui.getCursorY() + inputBarHeight - brakeLerp), rgbm(1, 0, 0, 1))

            ui.setCursor(vec2(centerx + inputBarCursorx + inputBarGap * 2, centery - inputBarCursory))
            ui.drawRectFilled(vec2(ui.getCursorX(), ui.getCursorY()), vec2(ui.getCursorX() + inputBarWidth, ui.getCursorY() + inputBarHeight), rgbm(0, 0, 0, 0.5))
            ui.drawRectFilled(vec2(ui.getCursorX(), ui.getCursorY() + inputBarHeight), vec2(ui.getCursorX() + inputBarWidth, ui.getCursorY() + inputBarHeight - gasLerp), rgbm(0, 1, 0, 1))

            ui.setCursor(vec2(centerx + inputBarCursorx + inputBarGap * 3, centery - inputBarCursory))
            ui.drawRectFilled(vec2(ui.getCursorX(), ui.getCursorY()), vec2(ui.getCursorX() + inputBarWidth, ui.getCursorY() + inputBarHeight), rgbm(0, 0, 0, 0.5))
            ui.drawRectFilled(vec2(ui.getCursorX(), ui.getCursorY() + inputBarHeight), vec2(ui.getCursorX() + inputBarWidth, ui.getCursorY() + inputBarHeight - FFBlerp), FFBcolor)
        end
    end)
end
