function script.essentials(dt)
    local appsize = vec2(325, 121):scale(app.scale)
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
        appsize = vec2(297, 85):scale(app.scale)
        rpmBarHeight = scale(10)
        decorCursory = scale(30)
        decorBarHeight = scale(51)
    end

    ui.setCursor(vec2(0, app.padding))
    ui.childWindow('main', appsize, function()
        local centerx = ui.availableSpaceX() / 2
        local centery = ui.availableSpaceY() / 2

        if settings.essentialsRpmBar then
            local rpmMix = playerCar().rpm / playerCar().rpmLimiter
            local rpmPercentage = math.round(rpmMix * 100)
            local rpmBarColor
            if settings.essentialsRpmBarColor and rpmPercentage > settings.essentialsRpmBarShiftYellow - 1 and rpmPercentage < settings.essentialsRpmBarShiftRed then
                rpmBarColor = rgbm(1, 1, 0, 1)
            elseif settings.essentialsRpmBarColor and rpmPercentage > settings.essentialsRpmBarShiftRed - 1 then
                rpmBarColor = rgbm(1, 0, 0, 1)
            else
                rpmBarColor = rgbm(1, 1, 1, 1)
            end
            ui.setCursor(vec2(0, 0))
            ui.drawRectFilled(vec2(0, ui.getCursorY()), vec2(ui.availableSpaceX(), ui.getCursorY() + rpmBarHeight), rgbm(0, 0, 0, 0.5))
            ui.drawRectFilled(vec2(0, ui.getCursorY()), vec2(math.lerp(0, ui.availableSpaceX(), rpmMix), ui.getCursorY() + rpmBarHeight), rpmBarColor)
        end

        if settings.essentialsSpeedNum then
            local speedText
            local speedNumber
            if not settings.essentialsSpeedNumMPH then
                speedText = 'KM/H'
                speedNumber = math.round(playerCar().speedKmh)
            else
                speedText = 'MP/H'
                speedNumber = math.round(playerCar().speedKmh / 1.6093440006147)
            end

            ui.setCursor(vec2(centerx - speedNumBoldCursorx, centery - speedNumBoldCursory))
            ui.pushDWriteFont(app.fonts.bold)
            ui.dwriteTextAligned(speedNumber, scale(34), ui.Alignment.End, ui.Alignment.Center, vec2(60, 28):scale(app.scale), false, rgbm.colors.white)
            ui.popDWriteFont()

            ui.setCursor(vec2(centerx - speedNumSemiCursorx, centery + speedNumSemiCursory))
            ui.pushDWriteFont(app.fonts.bold)
            ui.dwriteTextAligned(speedText, scale(14), ui.Alignment.End, ui.Alignment.Center, vec2(38, 14):scale(app.scale), false, rgbm.colors.white)
            ui.popDWriteFont()
        end

        if settings.decor then
            ui.setCursor(vec2(centerx - decorCursorLeftx, centery - decorCursory))
            ui.drawRectFilled(vec2(ui.getCursorX(), ui.getCursorY()), vec2(ui.getCursorX() + decorBarWidth, ui.getCursorY() + decorBarHeight), rgbm(1, 1, 1, 1))
            ui.setCursor(vec2(centerx + decorCursorRightx, centery - decorCursory))
            ui.drawRectFilled(vec2(ui.getCursorX(), ui.getCursorY()), vec2(ui.getCursorX() + decorBarWidth, ui.getCursorY() + decorBarHeight), rgbm(1, 1, 1, 1))
        end

        if settings.essentialsGears then
            ui.setCursor(vec2(centerx - gearsCursorx, centery - gearsCursory))
            ui.pushDWriteFont(app.fonts.bold)
            ui.dwriteTextAligned(parseGear(playerCar().gear), scale(60), ui.Alignment.Center, ui.Alignment.Center, vec2(36, 50):scale(app.scale), rgbm.colors.white)
            ui.popDWriteFont()
        end

        if settings.essentialsRpmNum and not settings.essentialsInputBars then
            ui.setCursor(vec2(centerx + rpmNumCursorx, centery - rpmNumBoldCursory))
            ui.pushDWriteFont(app.fonts.bold)
            ui.dwriteTextAligned(math.round(playerCar().rpm), scale(34), ui.Alignment.Start, ui.Alignment.Center, vec2(150, 28):scale(app.scale), false, rgbm.colors.white)
            ui.popDWriteFont()

            ui.setCursor(vec2(centerx + rpmNumCursorx, centery + rpmNumSemiCursory))
            ui.pushDWriteFont(app.fonts.bold)
            ui.dwriteText('RPM', scale(14), rgbm.colors.white)
            ui.popDWriteFont()
        end

        if settings.essentialsInputBars and settings.essentialsRpmNum then
            local FFBmix = playerCar().ffbFinal
            if FFBmix < 0 then FFBmix = FFBmix * -1 end
            local FFBcolor
            if FFBlerp ~= inputBarHeight then FFBcolor = rgbm(0.65, 0.65, 0.65, 1) else FFBcolor = rgbm(1, 0, 0, 1) end

            local clutchLerp = math.lerp(inputBarHeight, 0, playerCar().clutch)
            local brakeLerp = math.lerp(0, inputBarHeight, playerCar().brake)
            local gasLerp = math.lerp(0, inputBarHeight, playerCar().gas)
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
