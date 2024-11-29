function script.inputs(dt)
    local position = getPositionTable()
    local bgcolor = setColorMult(color.black, 70)
    local txtcolor = color.lightgray
    local txtcolorinv = rgbm(1 - txtcolor.r, 1 - txtcolor.g, 1 - txtcolor.b, 1)
    local fontBig = scale(12)
    local fontSmall = scale(10)
    local vertOffset = app.padding
    local horiOffset = 0

    if settings.inputsShowWheel then
        local wheelimg
        if playerCar().isRacingCar then wheelimg = '.\\img\\RaceWheel.png' else wheelimg = '.\\img\\StreetWheel.png' end
        local wheelpos = vec2(scale(1), (ui.windowHeight() / 2 + vertOffset / 2) - position.inputs.wheel.imgsize / 2)
        if settings.decor and ui.windowHeight() >= scale(130) then wheelpos.y = wheelpos.y + position.inputs.decorheight / 2 end
        ui.setCursor(wheelpos)
        ui.childWindow('Wheel', vec2(position.inputs.wheel.imgsize, position.inputs.wheel.imgsize), false, app.flags, function()
            ui.beginRotation()
            ui.drawImage(wheelimg, vec2(0, 0), vec2(position.inputs.wheel.imgsize, position.inputs.wheel.imgsize))
            ui.endRotation(playerCar().steer * -1 + 90)
        end)
        horiOffset = math.round(position.inputs.wheel.imgsize + position.inputs.wheel.padding + scale(1))
    end

    if settings.decor then
        ui.setCursor(vec2(horiOffset, vertOffset))
        ui.childWindow('Decor', vec2(position.inputs.pedalsize.x, position.inputs.decorheight), false, app.flags, function()
            ui.drawRectFilled(vec2(ui.getCursorX(), ui.getCursorY()), vec2(ui.getCursorX() + position.inputs.pedalsize.x, ui.getCursorY() + position.inputs.decorheight), color.white)
            ui.setCursor(vec2(math.round(ui.getCursorX() + position.inputs.pedalsize.x / 2 - position.inputs.decorimg.x / 2), math.round(ui.getCursorY() + (position.inputs.decorheight / 2 - position.inputs.decorimg.y / 2))))
            ui.drawImage('.\\img\\RennsportLogo.png', vec2(ui.getCursorX(), ui.getCursorY()), vec2(ui.getCursorX() + position.inputs.decorimg.x, ui.getCursorY() + position.inputs.decorimg.y))
        end)
        vertOffset = math.floor(vertOffset + position.inputs.decorheight)
    end

    if settings.inputsShowSteering then
        ui.setCursor(vec2(horiOffset, vertOffset))
        ui.childWindow('Steering', vec2(position.inputs.pedalsize.x, position.inputs.steeringbar.y), false, app.flags, function()
            local steerLerp = math.lerp(ui.getCursorX(), ui.getCursorX() + position.inputs.pedalsize.x - position.inputs.steeringbar.x, math.lerpInvSat(playerCar().steer, -playerCar().steerLock, playerCar().steerLock))
            ui.drawRectFilled(vec2(ui.getCursorX(), ui.getCursorY()), vec2(ui.getCursorX() + position.inputs.pedalsize.x, ui.getCursorY() + position.inputs.steeringbar.y), color.black)
            ui.drawRectFilled(vec2(ui.getCursorX() + steerLerp, ui.getCursorY()), vec2(ui.getCursorX() + steerLerp + position.inputs.steeringbar.x, ui.getCursorY() + position.inputs.steeringbar.y), color.white)
        end)
        vertOffset = math.floor(vertOffset + position.inputs.steeringbar.y)
    end

    if settings.inputsShowPedals then
        local FFBmix = playerCar().ffbFinal
        if FFBmix < 0 then FFBmix = FFBmix * -1 end
        local FFBcolor
        local FFBlerp = math.lerp(0, position.inputs.pedalsize.x, FFBmix)
        if FFBlerp < position.inputs.pedalsize.x then FFBcolor = color.white else FFBcolor = color.red end

        local gasColor, brakeColor, clutchColor = color.white, color.white, color.white
        local ffbTextColor, gasTextColor, brakeTextColor, clutchTextColor = txtcolor, txtcolor, txtcolor, txtcolor

        if settings.inputsPedalColors then
            if playerCar().gas == 1 then gasColor = color.green end
            if playerCar().brake == 1 then brakeColor = color.red end
            if playerCar().clutch == 0 then clutchColor = color.aqua end
        end

        if FFBmix >= 0.75 then ffbTextColor = txtcolorinv end
        if playerCar().gas >= 0.65 then gasTextColor = txtcolorinv end
        if playerCar().brake >= 0.6 then brakeTextColor = txtcolorinv end
        if playerCar().clutch <= 0.45 then clutchTextColor = txtcolorinv end

        local clutchLerp = math.lerp(position.inputs.pedalsize.x, 0, playerCar().clutch)
        local brakeLerp = math.lerp(0, position.inputs.pedalsize.x, playerCar().brake)
        local gasLerp = math.lerp(0, position.inputs.pedalsize.x, playerCar().gas)
        if FFBlerp >= position.inputs.pedalsize.x then FFBlerp = position.inputs.pedalsize.x end

        if settings.inputsShowFFB then
            ui.setCursor(vec2(horiOffset, vertOffset))
            ui.childWindow('FFB', vec2(position.inputs.pedalsize.x, position.inputs.pedalheight), false, app.flags, function()
                ui.drawRectFilled(vec2(0, 0), vec2(position.inputs.pedalsize.x, position.inputs.pedalheight), bgcolor)
                ui.drawRectFilled(vec2(0, 0), vec2(FFBlerp, position.inputs.pedalheight), FFBcolor)
                ui.pushDWriteFont(app.font.bold)
                ui.dwriteTextAligned('FORCE FEEDBACK', fontBig, 0, 0, vec2(position.inputs.pedalsize.x, position.inputs.pedalheight - scale(1)), false, ffbTextColor)
                ui.popDWriteFont()
            end)
            vertOffset = math.floor(vertOffset + position.inputs.pedalheight)
        end
        if settings.inputsShowClutch then
            ui.setCursor(vec2(horiOffset, vertOffset))
            ui.childWindow('Clutch', vec2(position.inputs.pedalsize.x, position.inputs.pedalheight), false, app.flags, function()
                ui.drawRectFilled(vec2(0, 0), vec2(position.inputs.pedalsize.x, position.inputs.pedalheight), bgcolor)
                ui.drawRectFilled(vec2(0, 0), vec2(clutchLerp, position.inputs.pedalheight), clutchColor)
                ui.pushDWriteFont(app.font.bold)
                ui.dwriteTextAligned('CLUTCH', fontBig, 0, 0, vec2(position.inputs.pedalsize.x, position.inputs.pedalheight - scale(1)), false, clutchTextColor)
                ui.popDWriteFont()
            end)
            vertOffset = math.floor(vertOffset + position.inputs.pedalheight)
        end
        if settings.inputsShowBrake then
            ui.setCursor(vec2(horiOffset, vertOffset))
            ui.childWindow('Brake', vec2(position.inputs.pedalsize.x, position.inputs.pedalheight), false, app.flags, function()
                ui.drawRectFilled(vec2(0, 0), vec2(position.inputs.pedalsize.x, position.inputs.pedalheight), bgcolor)
                ui.drawRectFilled(vec2(0, 0), vec2(brakeLerp, position.inputs.pedalheight), brakeColor)
                ui.pushDWriteFont(app.font.bold)
                ui.dwriteTextAligned('BRAKE', fontBig, 0, 0, vec2(position.inputs.pedalsize.x, position.inputs.pedalheight - scale(1)), false, brakeTextColor)
                ui.popDWriteFont()
            end)
            vertOffset = math.floor(vertOffset + position.inputs.pedalheight)
        end
        if settings.inputsShowGas then
            ui.setCursor(vec2(horiOffset, vertOffset))
            ui.childWindow('Gas', vec2(position.inputs.pedalsize.x, position.inputs.pedalheight), false, app.flags, function()
                ui.drawRectFilled(vec2(0, 0), vec2(position.inputs.pedalsize.x, position.inputs.pedalheight), bgcolor)
                ui.drawRectFilled(vec2(0, 0), vec2(gasLerp, position.inputs.pedalheight), gasColor)
                ui.pushDWriteFont(app.font.bold)
                ui.dwriteTextAligned('THROTTLE', fontBig, 0, 0, vec2(position.inputs.pedalsize.x, position.inputs.pedalheight - scale(1)), false, gasTextColor)
                ui.popDWriteFont()
            end)
            vertOffset = math.floor(vertOffset + position.inputs.pedalheight)
        end
    end

    if settings.inputsShowElectronics then
        local absactive = playerCar().absMode
        local absmax = playerCar().absModes
        local absfinal
        if absactive > 0 and absmax < 1 then absmax = absactive end
        if absactive == 0 then absfinal = 'OFF' elseif absmax == 1 and absactive == 1 then absfinal = 'ON' else absfinal = absactive .. '/' .. absmax end

        local tcactive = playerCar().tractionControlMode
        local tcmax = playerCar().tractionControlModes
        local tcfinal
        if tcactive > 0 and tcmax < 1 then tcmax = tcactive end
        if tcactive == 0 then tcfinal = 'OFF' elseif tcmax == 1 and tcactive == 1 then tcfinal = 'ON' else tcfinal = tcactive .. '/' .. tcmax end

        local brakebalance = math.round(playerCar().brakeBias * 100)
        local boost = playerCar().turboBoost

        local darkbgcolor = setColorMult(color.black, 50)
        local ABScolor, TCcolor = darkbgcolor, darkbgcolor
        if playerCar().absInAction then ABScolor = color.uigreen end
        if playerCar().tractionControlInAction then TCcolor = color.uigreen end

        ui.setCursor(vec2(horiOffset, vertOffset))
        ui.childWindow('Electronics', vec2(position.inputs.pedalsize.x, position.inputs.electronics.lightbg), false, app.flags, function()
            ui.drawRectFilled(vec2(0, 0), vec2(position.inputs.pedalsize.x, position.inputs.electronics.lightbg), bgcolor)

            ui.drawRectFilled(vec2(0, 0), vec2(position.inputs.electronics.darkbg.x, position.inputs.electronics.darkbg.y / 2), ABScolor)
            ui.pushDWriteFont(app.font.black)
            ui.dwriteTextAligned('ABS', fontSmall, 0, 0, vec2(position.inputs.electronics.darkbg.x, (position.inputs.electronics.darkbg.y / 2)), false, txtcolor)
            ui.popDWriteFont()
            ui.setCursor(vec2(position.inputs.electronics.darkbg.x, 0))
            ui.pushDWriteFont(app.font.black)
            ui.dwriteTextAligned(absfinal, fontSmall, 0, 0, vec2(position.inputs.electronics.val.x, (position.inputs.electronics.val.y / 2)), false, txtcolor)
            ui.popDWriteFont()

            ui.setCursor(vec2(0, position.inputs.electronics.darkbg.y / 2))
            ui.pushDWriteFont(app.font.black)
            ui.drawRectFilled(vec2(0, position.inputs.electronics.darkbg.y / 2), vec2(position.inputs.electronics.darkbg.x, position.inputs.electronics.darkbg.y), TCcolor)
            ui.dwriteTextAligned('TC', fontSmall, 0, 0, vec2(position.inputs.electronics.darkbg.x, (position.inputs.electronics.darkbg.y / 2)), false, txtcolor)
            ui.popDWriteFont()
            ui.setCursor(vec2(position.inputs.electronics.darkbg.x, position.inputs.electronics.darkbg.y / 2))
            ui.pushDWriteFont(app.font.black)
            ui.dwriteTextAligned(tcfinal, fontSmall, 0, 0, vec2(position.inputs.electronics.val.x, (position.inputs.electronics.val.y / 2)), false, txtcolor)
            ui.popDWriteFont()

            ui.setCursor(vec2(ui.availableSpaceX() / 2, 0))
            ui.drawRectFilled(vec2(ui.getCursorX(), ui.getCursorY()), vec2(ui.getCursorX() + position.inputs.electronics.darkbg.x, ui.getCursorY() + position.inputs.electronics.darkbg.y), darkbgcolor)

            ui.pushDWriteFont(app.font.black)
            ui.dwriteTextAligned('BB', fontSmall, 0, 0, vec2(position.inputs.electronics.darkbg.x, position.inputs.electronics.darkbg.y / 2), false, txtcolor)
            ui.popDWriteFont()
            ui.setCursor(vec2(ui.availableSpaceX() / 2 + position.inputs.electronics.darkbg.x, 0))
            ui.pushDWriteFont(app.font.black)
            ui.dwriteTextAligned(brakebalance .. '%', fontSmall, 0, 0, vec2(position.inputs.electronics.val.x, position.inputs.electronics.val.y / 2), false, txtcolor)
            ui.popDWriteFont()

            ui.setCursor(vec2(ui.availableSpaceX() / 2, position.inputs.electronics.darkbg.y / 2))
            ui.pushDWriteFont(app.font.black)
            ui.dwriteTextAligned('TRB', fontSmall, 0, 0, vec2(position.inputs.electronics.darkbg.x, position.inputs.electronics.darkbg.y / 2), false, txtcolor)
            ui.popDWriteFont()
            ui.setCursor(vec2(ui.availableSpaceX() / 2 + position.inputs.electronics.darkbg.x, position.inputs.electronics.darkbg.y / 2))
            ui.pushDWriteFont(app.font.black)
            ui.dwriteTextAligned(string.format('%.2f', math.round(boost, 2)), fontSmall, 0, 0, vec2(position.inputs.electronics.val.x, position.inputs.electronics.val.y / 2), false, txtcolor)
            ui.popDWriteFont()
        end)
    end
end
