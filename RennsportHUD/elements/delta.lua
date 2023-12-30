---@param deltaLerp number
---@return number
function scaleWidth(deltaLerp)
    local scaledWidth = (((math.abs(deltaLerp) ^ 0.3) / 1000) * getPositionTable().delta.elementsize.x / 2) * 1000
    if deltaLerp < 0 then
        return scaledWidth * -1
    else
        return scaledWidth
    end
end

function script.delta(dt)
    local position = getPositionTable()
    local childOffset = app.padding
    if (settings.deltaHidden and playerCar().estimatedLapTimeMs > 0) or not settings.deltaHidden then
        local playerSession = ac.getSim()
        local vertOffset = 0
        local fontsize = scale(14)
        local deltaColor = color.white
        local deltaBestTxt = '00.000'
        local predictionTxt = '0:00.000'

        if playerCar().performanceMeter > 0 then
            deltaBestTxt = string.format('+%.3f', playerCar().performanceMeter)
            deltaColor = color.uired
        elseif playerCar().performanceMeter < 0 then
            deltaBestTxt = string.format('%.3f', playerCar().performanceMeter)
            deltaColor = color.uigreen
        end

        if playerCar().estimatedLapTimeMs > 600000 then
            predictionTxt = formatTime(playerCar().estimatedLapTimeMs, false, true, true, true)
        else
            predictionTxt = formatTime(playerCar().estimatedLapTimeMs, false, true, true, true):sub(2)
        end

        if settings.deltaShowTimer then
            vertOffset = position.delta.txtpos.y
            ui.setCursor(vec2(0, childOffset))
            ui.childWindow('DeltaTimer', vec2(position.delta.elementsize.x, position.delta.contentheight / 2 + vertOffset), false, app.flags, function()
                ui.drawRectFilled(vec2(0, 0), vec2(position.delta.elementsize.x, position.delta.contentheight / 2 + position.delta.txtpos.y), setColorMult(color.black, 40))
                ui.setCursor(vec2(position.delta.txtpos.x, position.delta.txtpos.y))
                ui.pushDWriteFont(app.font.black)
                ui.dwriteTextAligned('Delta Best', fontsize, -1, 0, vec2(position.delta.elementsize.x, position.delta.contentheight / 2), false, txtcolor)
                ui.setCursor(vec2(ui.availableSpaceX() / 2 + position.delta.timepos.x, position.delta.txtpos.y))
                ui.dwriteTextAligned(deltaBestTxt, fontsize, 1, 0, vec2(ui.windowSize().x / 3, position.delta.contentheight / 2), false, deltaColor)
                ui.popDWriteFont()
            end)
            childOffset = childOffset + position.delta.contentheight / 2 + vertOffset
        end

        if settings.deltaShowPrediction then
            if settings.deltaShowTimer then vertOffset = -position.delta.txtpos.y else vertOffset = position.delta.txtpos.y end
            ui.setCursor(vec2(0, childOffset))
            ui.childWindow('LapPrediction', vec2(position.delta.elementsize.x, position.delta.contentheight / 2 + vertOffset), false, app.flags, function()
                ui.drawRectFilled(vec2(0, 0), vec2(position.delta.elementsize.x, position.delta.contentheight / 2 + position.delta.txtpos.y), setColorMult(color.black, 40))
                ui.setCursor(vec2(position.delta.txtpos.x, vertOffset))
                ui.pushDWriteFont(app.font.black)
                ui.dwriteTextAligned('Predicted', fontsize, -1, 0, vec2(position.delta.elementsize.x, position.delta.contentheight / 2 - position.delta.txtpos.y), false, txtcolor)
                ui.setCursor(vec2(ui.availableSpaceX() / 2 + position.delta.timepos.x, vertOffset))
                ui.dwriteTextAligned(predictionTxt, fontsize, 1, 0, vec2((ui.windowSize().x / 3) + scale(3), position.delta.contentheight / 2) - position.delta.txtpos.y, false, txtcolor)
                ui.popDWriteFont()
            end)
            childOffset = childOffset + position.delta.contentheight / 2 + vertOffset
        end

        if settings.deltaShowBar then
            local deltaClamp = math.clampN(playerCar().performanceMeter, -settings.deltaBarTime, settings.deltaBarTime)
            local deltaLerp = 0
            if deltaClamp > 0 then
                deltaLerp = math.lerpInvSat(deltaClamp, 0, settings.deltaBarTime)
            elseif deltaClamp < 0 then
                deltaLerp = -math.lerpInvSat(deltaClamp, 0, -settings.deltaBarTime)
            end
            local deltaWidth = scaleWidth(deltaLerp)
            ui.setCursor(vec2(0, childOffset))
            ui.childWindow('Deltabar', vec2(position.delta.elementsize.x, position.delta.barheight), false, app.flags, function()
                ui.setCursor(vec2(position.delta.elementsize.x / 2, vertOffset))
                ui.drawRectFilled(vec2(0, 0), vec2(position.delta.elementsize.x, position.delta.barheight), setColorMult(color.black, 60))
                ui.drawRectFilled(vec2(ui.getCursorX(), 0), vec2(ui.getCursorX() + deltaWidth, position.delta.barheight), deltaColor)
            end)
        end
    else
        ui.setCursor(vec2(0, childOffset))
        ui.childWindow('EmptySpace', position.delta.elementsize, false, app.flags, function()
        end)
    end
end
