---@param value number @The value to be scaled.
---@return number @The scaled value.
--- Scales a value by the app scale.
function scale(value)
    return app.scale * value
end

--- Parses the gear number for UI use.
---@param gearNum number @The gear number to be parsed.
---@return string @The parsed gear number as a string.
function parseGear(gearNum)
    if gearNum == 0 then
        return 'N'
    elseif gearNum == -1 then
        return 'R'
    else
        return tostring(gearNum)
    end
end

--- Returns the user car or the currently focused car if enabled.
---@return ac.StateCar @The user car or the currently focused car.
function playerCar()
    if ac.getSim().focusedCar > 0 and not settings.ignorefocus then
        return ac.getCar(ac.getSim().focusedCar)
    else
        return ac.getCar(0)
    end
end

--- Returns color with the desired percentage of opacity.
---@param oldrgb rgb @The original rgb() or rgbm() color.
---@param percentage number @The desired alpha percentage from 0-100.
---@return rgbm @The color with the desired percentage of opacity.
function setColorMult(oldrgb, percentage)
    return rgbm(oldrgb.r, oldrgb.g, oldrgb.b, 1 * (percentage / 100))
end

--- Calculates the number of seconds, minutes, and hours from milliseconds, I know that ac.lapTimeToString exists.
---@param milliseconds ms @The time in milliseconds to be formatted.
---@param showHours boolean @If true, displays hours as HH.
---@param showMinutes boolean @If true, displays minutes as MM.
---@param showSeconds boolean @If true, displays seconds as SS.
---@param showSubSecond boolean @If true, displays milliseconds as sss.
---@return string @The formatted time.
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
