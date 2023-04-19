function script.inputs(dt)
    local position = getPositionTable()

    local lightbgcolor = setColorMult(color.black, 50)
    local darkbgcolor = setColorMult(color.black, 25)
    local txtcolor = color.lightgray
    local fontBig = scale(12)
    local fontSmall = scale(10)
    local vertOffset = app.padding
    local horiOffset = 0

    local FFBmix = playerCar().ffbFinal
    if FFBmix < 0 then FFBmix = FFBmix * -1 end
    local FFBcolor
    local FFBlerp = math.lerp(0, position.inputs.pedalsize.x, FFBmix)
    if FFBlerp < position.inputs.pedalsize.x then FFBcolor = color.white else FFBcolor = color.red end

    local clutchLerp = math.lerp(position.inputs.pedalsize.x, 0, playerCar().clutch)
    local brakeLerp = math.lerp(0, position.inputs.pedalsize.x, playerCar().brake)
    local gasLerp = math.lerp(0, position.inputs.pedalsize.x, playerCar().gas)
    if FFBlerp >= position.inputs.pedalsize.x then FFBlerp = position.inputs.pedalsize.x end

    local absactive = playerCar().absMode
    local absmax = playerCar().absModes
    local absfinal
    if absmax < 1 or absactive == 0 then absfinal = 'OFF' elseif absmax == 1 and absactive == 1 then absfinal = 'ON' else absfinal = absactive .. '/' .. absmax end

    local tcactive = playerCar().tractionControlMode
    local tcmax = playerCar().tractionControlModes
    local tcfinal
    if tcmax < 1 or tcactive == 0 then tcfinal = 'OFF' elseif tcmax == 1 and tcactive == 1 then tcfinal = 'ON' else tcfinal = tcactive .. '/' .. tcmax end

    local brakebalance = math.round(playerCar().brakeBias * 100)
    local fuelmix = '100' --playerCar().fuelMap exists but is used by like 3 private mods or something. Engine Limiter value (not rpm) doesnt have its own thing in statecar so this is a 'placeholder'.


    if settings.inputsShowWheel then
        local wheelimg
        if playerCar().isRacingCar then wheelimg = '.\\img\\RaceWheel.png' else wheelimg = '.\\img\\StreetWheel.png' end
        local wheelpos = vec2(scale(1), ui.windowHeight() / 2 + vertOffset / 2)
        if settings.decor and settings.inputsShowPedals and ui.windowHeight() >= scale(113) then wheelpos.y = wheelpos.y + position.inputs.decorheight / 2 end
        ui.setCursor(wheelpos)
        ui.beginRotation()
        ui.drawImage(wheelimg, vec2(ui.getCursorX(), ui.getCursorY() - (position.inputs.wheel.imgsize / 2)), vec2(ui.getCursorX() + position.inputs.wheel.imgsize, ui.getCursorY() - (position.inputs.wheel.imgsize / 2) + position.inputs.wheel.imgsize), true)
        ui.endRotation(playerCar().steer * -1 + 90)
        horiOffset = position.inputs.wheel.imgsize + position.inputs.wheel.padding + scale(1)
    end

    if settings.decor then
        ---[[ The window auto resizing breaks when the pedal inputs are disabled without this, I have no idea why its not taking the full drawRectFilled size into account
        ui.setCursor(vec2(horiOffset, vertOffset))
        ui.pushDWriteFont(app.font.bold)
        ui.dwriteTextAligned('', fontBig, ui.Alignment.Center, ui.Alignment.Center, vec2(position.inputs.pedalsize.x, position.inputs.decorheight), false, txtcolor)
        ui.popDWriteFont()
        --]]

        ui.setCursor(vec2(horiOffset, vertOffset))
        ui.drawRectFilled(vec2(ui.getCursorX(), ui.getCursorY()), vec2(ui.getCursorX() + position.inputs.pedalsize.x, ui.getCursorY() + position.inputs.decorheight), color.white)
        ui.setCursor(vec2(math.round(ui.getCursorX() + position.inputs.pedalsize.x / 2 - position.inputs.decorimg.x / 2), math.round(ui.getCursorY() + (position.inputs.decorheight / 2 - position.inputs.decorimg.y / 2))))
        ui.drawImage('.\\img\\RennsportLogo.png', vec2(ui.getCursorX(), ui.getCursorY()), vec2(ui.getCursorX() + position.inputs.decorimg.x, ui.getCursorY() + position.inputs.decorimg.y), true)
        vertOffset = vertOffset + position.inputs.decorheight
    end

    if settings.inputsShowSteering then
        ---[[ The window auto resizing breaks when the pedal inputs are disabled without this, I have no idea why its not taking the full drawRectFilled size into account
        ui.setCursor(vec2(horiOffset, vertOffset))
        ui.pushDWriteFont(app.font.bold)
        ui.dwriteTextAligned('', fontBig, ui.Alignment.Center, ui.Alignment.Center, vec2(position.inputs.pedalsize.x, position.inputs.pedalheight - scale(1)), false, txtcolor)
        ui.popDWriteFont()
        --]]

        local steerLerp = math.lerp(horiOffset, horiOffset + position.inputs.pedalsize.x - position.inputs.steeringbar.x, math.lerpInvSat(playerCar().steer, -playerCar().steerLock, playerCar().steerLock))
        ui.setCursor(vec2(horiOffset, vertOffset))
        ui.drawText('test', vec2(ui.getCursorX(), ui.getCursorY()), color.red)
        ui.drawRectFilled(vec2(ui.getCursorX(), ui.getCursorY()), vec2(ui.getCursorX() + position.inputs.pedalsize.x, ui.getCursorY() + position.inputs.steeringbar.y), color.black)
        ui.setCursor(vec2(steerLerp, vertOffset))
        ui.drawRectFilled(vec2(ui.getCursorX(), ui.getCursorY()), vec2(ui.getCursorX() + position.inputs.steeringbar.x, ui.getCursorY() + position.inputs.steeringbar.y), color.white)
        vertOffset = vertOffset + position.inputs.steeringbar.y
    end

    if settings.inputsShowPedals then
        if settings.inputsShowFFB then
            ui.setCursor(vec2(horiOffset, vertOffset))
            ui.drawRectFilled(vec2(ui.getCursorX(), ui.getCursorY()), vec2(ui.getCursorX() + position.inputs.pedalsize.x, ui.getCursorY() + position.inputs.pedalheight), lightbgcolor)
            ui.drawRectFilled(vec2(ui.getCursorX(), ui.getCursorY()), vec2(ui.getCursorX() + FFBlerp, ui.getCursorY() + position.inputs.pedalheight), FFBcolor)
            ui.pushDWriteFont(app.font.bold)
            ui.dwriteTextAligned('FORCE FEEDBACK', fontBig, ui.Alignment.Center, ui.Alignment.Center, vec2(position.inputs.pedalsize.x, position.inputs.pedalheight - scale(1)), false, txtcolor)
            ui.popDWriteFont()
            vertOffset = vertOffset + position.inputs.pedalheight
        end
        if settings.inputsShowClutch then
            ui.setCursor(vec2(horiOffset, vertOffset))
            ui.drawRectFilled(vec2(ui.getCursorX(), ui.getCursorY()), vec2(ui.getCursorX() + position.inputs.pedalsize.x, ui.getCursorY() + position.inputs.pedalheight), lightbgcolor)
            ui.drawRectFilled(vec2(ui.getCursorX(), ui.getCursorY()), vec2(ui.getCursorX() + clutchLerp, ui.getCursorY() + position.inputs.pedalheight), color.white)
            ui.pushDWriteFont(app.font.bold)
            ui.dwriteTextAligned('CLUTCH', fontBig, ui.Alignment.Center, ui.Alignment.Center, vec2(position.inputs.pedalsize.x, position.inputs.pedalheight - scale(1)), false, txtcolor)
            ui.popDWriteFont()
            vertOffset = vertOffset + position.inputs.pedalheight
        end
        if settings.inputsShowBrake then
            ui.setCursor(vec2(horiOffset, vertOffset))
            ui.drawRectFilled(vec2(ui.getCursorX(), ui.getCursorY()), vec2(ui.getCursorX() + position.inputs.pedalsize.x, ui.getCursorY() + position.inputs.pedalheight), lightbgcolor)
            ui.drawRectFilled(vec2(ui.getCursorX(), ui.getCursorY()), vec2(ui.getCursorX() + brakeLerp, ui.getCursorY() + position.inputs.pedalheight), color.white)
            ui.pushDWriteFont(app.font.bold)
            ui.dwriteTextAligned('BRAKE', fontBig, ui.Alignment.Center, ui.Alignment.Center, vec2(position.inputs.pedalsize.x, position.inputs.pedalheight - scale(1)), false, txtcolor)
            ui.popDWriteFont()
            vertOffset = vertOffset + position.inputs.pedalheight
        end
        if settings.inputsShowGas then
            ui.setCursor(vec2(horiOffset, vertOffset))
            ui.drawRectFilled(vec2(ui.getCursorX(), ui.getCursorY()), vec2(ui.getCursorX() + position.inputs.pedalsize.x, ui.getCursorY() + position.inputs.pedalheight), lightbgcolor)
            ui.drawRectFilled(vec2(ui.getCursorX(), ui.getCursorY()), vec2(ui.getCursorX() + gasLerp, ui.getCursorY() + position.inputs.pedalheight), color.white)
            ui.pushDWriteFont(app.font.bold)
            ui.dwriteTextAligned('THROTTLE', fontBig, ui.Alignment.Center, ui.Alignment.Center, vec2(position.inputs.pedalsize.x, position.inputs.pedalheight - scale(1)), false, txtcolor)
            ui.popDWriteFont()
            vertOffset = vertOffset + position.inputs.pedalheight
        end
    end

    if settings.inputsShowElectronics then
        ui.setCursor(vec2(horiOffset, vertOffset))
        ui.drawRectFilled(vec2(ui.getCursorX(), ui.getCursorY()), vec2(ui.getCursorX() + position.inputs.pedalsize.x, ui.getCursorY() + position.inputs.electronics.lightbg), lightbgcolor)
        ui.drawRectFilled(vec2(ui.getCursorX(), ui.getCursorY()), vec2(ui.getCursorX() + position.inputs.electronics.darkbg.x, ui.getCursorY() + position.inputs.electronics.darkbg.y), darkbgcolor)

        ui.pushDWriteFont(app.font.bold)
        ui.dwriteTextAligned('ABS', fontSmall, ui.Alignment.Center, ui.Alignment.Center, vec2(position.inputs.electronics.darkbg.x, (position.inputs.electronics.darkbg.y / 2)), false, txtcolor)
        ui.popDWriteFont()
        ui.setCursor(vec2(horiOffset + position.inputs.electronics.darkbg.x, vertOffset))
        ui.pushDWriteFont(app.font.bold)
        ui.dwriteTextAligned(absfinal, fontSmall, ui.Alignment.Center, ui.Alignment.Center, vec2(position.inputs.electronics.val.x, (position.inputs.electronics.val.y / 2)), false, txtcolor)
        ui.popDWriteFont()

        ui.setCursor(vec2(horiOffset, vertOffset + position.inputs.electronics.darkbg.y / 2))
        ui.pushDWriteFont(app.font.bold)
        ui.dwriteTextAligned('TC', fontSmall, ui.Alignment.Center, ui.Alignment.Center, vec2(position.inputs.electronics.darkbg.x, (position.inputs.electronics.darkbg.y / 2)), false, txtcolor)
        ui.popDWriteFont()
        ui.setCursor(vec2(horiOffset + position.inputs.electronics.darkbg.x, vertOffset + position.inputs.electronics.darkbg.y / 2))
        ui.pushDWriteFont(app.font.bold)
        ui.dwriteTextAligned(tcfinal, fontSmall, ui.Alignment.Center, ui.Alignment.Center, vec2(position.inputs.electronics.val.x, (position.inputs.electronics.val.y / 2)), false, txtcolor)
        ui.popDWriteFont()

        ui.setCursor(vec2((horiOffset + ui.availableSpaceX()) / 2, vertOffset))
        ui.drawRectFilled(vec2(ui.getCursorX(), ui.getCursorY()), vec2(ui.getCursorX() + position.inputs.electronics.darkbg.x, ui.getCursorY() + position.inputs.electronics.darkbg.y), darkbgcolor)

        ui.pushDWriteFont(app.font.bold)
        ui.dwriteTextAligned('BB', fontSmall, ui.Alignment.Center, ui.Alignment.Center, vec2(position.inputs.electronics.darkbg.x, (position.inputs.electronics.darkbg.y / 2)), false, txtcolor)
        ui.popDWriteFont()
        ui.setCursor(vec2((horiOffset + ui.availableSpaceX()) / 2 + position.inputs.electronics.darkbg.x, vertOffset))
        ui.pushDWriteFont(app.font.bold)
        ui.dwriteTextAligned(brakebalance .. '%', fontSmall, ui.Alignment.Center, ui.Alignment.Center, vec2(position.inputs.electronics.val.x, (position.inputs.electronics.val.y / 2)), false, txtcolor)
        ui.popDWriteFont()

        ui.setCursor(vec2((horiOffset + ui.availableSpaceX()) / 2, vertOffset + position.inputs.electronics.darkbg.y / 2))
        ui.pushDWriteFont(app.font.bold)
        ui.dwriteTextAligned('MIX', fontSmall, ui.Alignment.Center, ui.Alignment.Center, vec2(position.inputs.electronics.darkbg.x, (position.inputs.electronics.darkbg.y / 2)), false, txtcolor)
        ui.popDWriteFont()
        ui.setCursor(vec2((horiOffset + ui.availableSpaceX()) / 2 + position.inputs.electronics.darkbg.x, vertOffset + position.inputs.electronics.darkbg.y / 2))
        ui.pushDWriteFont(app.font.bold)
        ui.dwriteTextAligned(fuelmix .. '%', fontSmall, ui.Alignment.Center, ui.Alignment.Center, vec2(position.inputs.electronics.val.x, (position.inputs.electronics.val.y / 2)), false, txtcolor)
        ui.popDWriteFont()
    end
end
