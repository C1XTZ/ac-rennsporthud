--- Scales a value by the app scale and rounds to even values.
---@param value number @The value to be scaled.
---@return number @The scaled value, rounded to nearest even pixel.
---@diagnostic disable-next-line: lowercase-global
function scale(value)
  local scaled = app.scale * value
  return math.round(scaled / 2) * 2
end

--- Scales a vec2 by the app scale and rounds to even values.
---@param x number
---@param y number
---@return vec2 @Scaled vec2, both components via scale().
---@diagnostic disable-next-line: lowercase-global
function scaleVec2(x, y) return vec2(scale(x), scale(y)) end

--- Returns the user car or the currently focused car if enabled.
---@return ac.StateCar? @The user car or the currently focused car.
---@diagnostic disable-next-line: lowercase-global
function playerCar()
  if ac.getSim().focusedCar > 0 and not settings.ignorefocus then
    return ac.getCar(ac.getSim().focusedCar)
  else
    return ac.getCar(0)
  end
end

--- Returns color with the desired percentage of opacity.
---@param oldrgb rgb|rgbm @The original rgb() or rgbm() color.
---@param percentage number @The desired alpha percentage from 0-100.
---@return rgbm @The color with the desired percentage of opacity.
---@diagnostic disable-next-line: lowercase-global
function setColorMult(oldrgb, percentage) return rgbm(oldrgb.r, oldrgb.g, oldrgb.b, 1 * (percentage / 100)) end

--- Calculates the number of seconds, minutes, and hours from milliseconds, I know that ac.lapTimeToString exists.
---@param milliseconds integer @The time in milliseconds to be formatted.
---@param showHours? boolean @If true, displays hours as HH.
---@param showMinutes? boolean @If true, displays minutes as MM.
---@param showSeconds? boolean @If true, displays seconds as SS.
---@param showSubSecond? boolean @If true, displays milliseconds as sss.
---@return string @The formatted time.
---@diagnostic disable-next-line: lowercase-global
function formatTime(milliseconds, showHours, showMinutes, showSeconds, showSubSecond)
  if milliseconds < 0 then milliseconds = milliseconds * -1 end

  local seconds = math.floor(milliseconds / 1000)
  local minutes = math.floor(seconds / 60)
  local hours = math.floor(minutes / 60)

  minutes = minutes % 60
  seconds = seconds % 60

  local formattedTime = ''
  if showHours then formattedTime = string.format('%d:', hours) end

  if showMinutes then
    formattedTime = formattedTime .. string.format('%02d:', minutes)
  else
    if showHours then formattedTime = formattedTime .. '00:' end
  end

  if showSeconds then
    if showSubSecond then
      formattedTime = formattedTime .. string.format('%02d.%03d', seconds, milliseconds % 1000)
    else
      formattedTime = formattedTime .. string.format('%02d', seconds)
    end
  else
    if showHours or showMinutes then formattedTime = formattedTime .. '00' end
  end

  return formattedTime
end
