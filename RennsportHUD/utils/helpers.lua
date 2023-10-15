--Scales a value by the app scale
function scale(value)
    return app.scale * value
end

--Parses the gearInt for Ui use
function parseGear(gearInt)
    if gearInt == 0 then
        return 'N'
    elseif gearInt == -1 then
        return 'R'
    else
        return gearInt
    end
end

--returns the user car or the currently focused car if enabled
function playerCar()
    if ac.getSim().focusedCar > 0 and not settings.ignorefocus then
        return ac.getCar(ac.getSim().focusedCar)
    else
        return ac.getCar(0)
    end
end

--returns color with the wanted percentage of opacity
function setColorMult(oldrgbm, percentage)
    return rgbm(oldrgbm.r, oldrgbm.g, oldrgbm.b, 1 * (percentage / 100))
end

--calculates the number of seconds, minutes and hours from milliseconds
--I know that ac.lapTimeToString exists but this is more flexable
function formatTime(milliseconds, showHours, showMinutes, showSeconds, showSubSecond)
    if milliseconds < 0 then milliseconds = milliseconds * -1 end

    local seconds = math.floor(milliseconds / 1000)
    local minutes = math.floor(seconds / 60)
    local hours = math.floor(minutes / 60)

    minutes = minutes % 60
    seconds = seconds % 60

    local formattedTime = ''
    if showHours then
        formattedTime = string.format('%d:', hours)
    end

    if showMinutes then
        formattedTime = formattedTime .. string.format('%02d:', minutes)
    else
        if showHours then
            formattedTime = formattedTime .. '00:'
        end
    end

    if showSeconds then
        if showSubSecond then
            formattedTime = formattedTime .. string.format('%02d.%03d', seconds, milliseconds % 1000)
        else
            formattedTime = formattedTime .. string.format('%02d', seconds)
        end
    else
        if showHours or showMinutes then
            formattedTime = formattedTime .. '00'
        end
    end

    return formattedTime
end
