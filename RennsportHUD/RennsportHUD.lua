--app made by XTZ

---@diagnostic disable-next-line: lowercase-global
settings = ac.storage {
  applySettingsOnLoad = true,
  includeSettingsOnSave = true,

  changeScale = false,
  scale = 1,

  decor = true,
  ignorefocus = true,

  lastUsedPreset = '',
  lastUsedRes = vec2(0, 0),

  essentialsCompactMode = false,
  essentialsRpmBar = true,
  essentialsRpmBarColor = true,
  essentialsRpmBarShiftYellow = 95,
  essentialsRpmBarShiftRed = 98,
  essentialsGears = true,
  essentialsRpmNum = true,
  essentialsSpeedNum = true,
  essentialsSpeedNumMPH = false,
  essentialsInputBars = false,
  essentialsShowTurnLights = true,

  inputsShowWheel = true,
  inputsShowSteering = true,
  inputsShowPedals = true,
  inputsShowFFB = true,
  inputsShowClutch = true,
  inputsShowBrake = true,
  inputsShowGas = true,
  inputsShowElectronics = true,
  inputsPedalColors = false,

  sessionShowPosition = true,
  sessionHideDisconnected = false,
  sessionHideAI = true,
  sessionShowLaps = true,
  sessionShowTimer = true,
  sessionTimerType = true,
  sessionAlwaysShowDuration = false,

  deltaHidden = false,
  deltaShowTimer = true,
  deltaShowPrediction = true,
  deltaShowBar = true,
  deltaBarTime = 10,

  sectorsShowSectors = true,
  sectorsDisplayDuration = 5,
  sectorsShowPitInfo = true,
  sectorsShowSpeedLimit = true,
  sectorsShowRaceFlags = true,
  sectorsDisable = false,

  fuelShowRemaining = true,
  fuelGallons = false,
  fuelLaps = false,
  fuelChangeBarColor = true,
  fuelYellowBar = 5,
  fuelRedBar = 1,

  tiresShowPressure = true,
  tiresPressureUseBar = false,
  tiresShowTempVis = true,
  tiresShowBrakeTemp = true,
  tiresShowTempBar = true,
  tiresTempUseFahrenheit = false,
  tiresShowWear = false,
  tiresPressureColor = false,
  tiresBrakesConfigured = false,
  tiresTiresConfigured = false,

  timingShowCurrentLap = true,
  timingShowLapStats = true,
  timingLapStatsBest = true,
  timingLapStatsLast = true,
  timingLapStatsIdeal = true,
  timingShowTable = true,

  lbShowPos = true,
  lbShowNum = true,
  lbShowName = true,
  lbShowCar = true,
  lbShowBrand = false,
  lbShowLap = true,
  lbShowLast = true,
  lbShowBest = true,
  lbShowInt = true,
  lbMaxCars = 10,
  lbManNameLength = false,
  lbManNameLengthNum = 125,
  lbManCarLength = false,
  lbManCarLengthNum = 125,
}

require('utils/helpers')
require('utils/tables')
require('utils/layout')
require('utils/presets')

---@diagnostic disable-next-line: lowercase-global
app = getAppTable()
---@diagnostic disable-next-line: lowercase-global
color = getColorTable()

require('elements/essentials')
require('elements/inputs')
require('elements/session')
require('elements/delta')
require('elements/sectors')
require('elements/fuel')
require('elements/tires')
require('elements/timing')
require('elements/leaderboard')

---@diagnostic disable-next-line: lowercase-global
Updater = require('updater/universal')

--- Toggles a boolean settings field when its checkbox is clicked.
---@param label string @Checkbox label shown in the UI.
---@param key string @settings field name to read/toggle.
local function settingsCheckbox(label, key)
  if
    ui.checkbox(label, settings[key] --[[@as boolean]])
  then
    settings[key] = not settings[key]
  end
end

--- Draws one preset row: name, then load button, then optionally a delete button.
---@param rowKey string @Unique ID for this row.
---@param name string @Display name.
---@param buttonOffset number @Horizontal offset for the buttons.
---@param onLoad fun() @Called when the load button is pressed.
---@param onDelete? fun() @If set, adds a delete button. Omit for the default preset.
local function presetRow(rowKey, name, buttonOffset, onLoad, onDelete)
  ui.pushID(rowKey)
  ui.offsetCursorY(3)
  ui.text(name)
  ui.sameLine(buttonOffset)
  ui.offsetCursorY(-3)
  if ui.iconButton(ui.Icons.Undo) then onLoad() end
  if ui.itemHovered() then ui.tooltip(function() ui.text('Load preset') end) end

  if onDelete then
    ui.sameLine()
    if ui.iconButton(ui.Icons.Cancel) then onDelete() end
    if ui.itemHovered() then ui.tooltip(function() ui.text('Delete preset') end) end
  end
  ui.popID()
end

function script.update(dt)
  --- Reapplies the last used preset if the resolution changes to correct positioning.
  if settings.lastUsedPreset == '' then return end

  local currentRes = ac.getUI().windowSize
  if currentRes.x <= 0 or currentRes.y <= 0 then return end

  if currentRes.x ~= settings.lastUsedRes.x or currentRes.y ~= settings.lastUsedRes.y then setTimeout(function() loadPreset(settings.lastUsedPreset) end, 1, 'FixPos') end
end

local newPresetName = ''
function script.windowMain(dt)
  ui.tabBar('Elements', function()
    if ac.getPatchVersionCode() < 2651 then
      ui.textColored('You are using a CSP version older than 0.2.0!\nIf anything breaks, please update Custom Shaders Patch in Content Manager!', rgbm.colors.red)
      ui.separator()
    end
    ui.tabItem('Update', function()
      Updater.drawUI()
    end)
    ui.tabItem('Preset', function()
      if ac.getPatchVersionCode() >= 3044 then
        settingsCheckbox('Save user settings to preset', 'includeSettingsOnSave')
        if ui.itemHovered() then ui.tooltip(function() ui.text('If disabled only saves window positions\nSaves your app settings to the preset') end) end
        settingsCheckbox('Load user settings from preset', 'applySettingsOnLoad')
        if ui.itemHovered() then ui.tooltip(function() ui.text('If disabled only loads window positions\nOnly works if the preset was saved with settings included') end) end
        ui.separator()

        local customPresets = listCustomPresets()
        local buttonOffset = 193
        for _, preset in ipairs(customPresets) do
          local width = ui.measureText(preset.name).x + 53
          if width > buttonOffset then buttonOffset = width end
        end
        local inputTextWidth = 165

        presetRow('default', 'Default', buttonOffset, function() loadPreset('default', settings.applySettingsOnLoad) end)

        for _, preset in ipairs(customPresets) do
          presetRow(preset.key, preset.name, buttonOffset, function() loadPreset(preset.key, settings.applySettingsOnLoad) end, function() deletePreset(preset.key) end)
        end

        ui.newLine(0)
        ui.setNextItemWidth(inputTextWidth)
        newPresetName = ui.inputText('Preset name...', newPresetName, ui.InputTextFlags.Placeholder)

        ui.sameLine()
        if ui.iconButton(ui.Icons.Save) then
          if savePreset(newPresetName, settings.includeSettingsOnSave) then newPresetName = '' end
        end
        if ui.itemHovered() then ui.tooltip(function() ui.text('Save preset') end) end

        ui.sameLine()
        if ui.iconButton(ui.Icons.Folder) then os.openInExplorer(ac.getFolder(ac.FolderID.ScriptOrigin) .. '/presets') end
        if ui.itemHovered() then ui.tooltip(function() ui.text('Open preset folder') end) end

        ui.sameLine()
        if ui.iconButton(ui.Icons.Reset) then rescanPresets() end
        if ui.itemHovered() then ui.tooltip(function() ui.text('Rescan preset folder') end) end
      else
        ui.textColored('This feature is only available on CSP version 0.2.3 and newer!\nUpdate Custom Shaders Patch in Content Manager if you want to use it.', rgbm.colors.red)
      end
    end)
    ui.tabItem('General', function()
      settingsCheckbox('Custom App Scaling', 'changeScale')
      if settings.changeScale then
        ui.text('\t')
        ui.sameLine()
        settings.scale = ui.slider('##AppScale', settings.scale, 0.5, 5, 'App Scale: ' .. '%.01f%')
        if settings.changeScale and app.scale ~= settings.scale then app.scale = settings.scale end
      else
        settings.scale = 1
      end
      settingsCheckbox('Show Own Stats When Spectating', 'ignorefocus')
      settingsCheckbox('Show Decorations', 'decor')
    end)
    ui.tabItem('Essentials', function()
      settingsCheckbox('Enable Compact Mode', 'essentialsCompactMode')
      settingsCheckbox('Show RPM Bar', 'essentialsRpmBar')
      if settings.essentialsRpmBar then
        ui.text('\t')
        ui.sameLine()
        settingsCheckbox('Enable Shift Colors', 'essentialsRpmBarColor')
        if settings.essentialsRpmBarColor then
          ui.text('\t')
          ui.sameLine()
          settings.essentialsRpmBarShiftYellow = ui.slider('##ShiftYellow', settings.essentialsRpmBarShiftYellow, 0, 100, 'Yellow shift at: ' .. '%.0f%%')
          ui.text('\t')
          ui.sameLine()
          settings.essentialsRpmBarShiftRed = ui.slider('##ShiftRed', settings.essentialsRpmBarShiftRed, 0, 100, 'Red shift at: ' .. '%.0f%%')
        end
      end
      settingsCheckbox('Show Indicators', 'essentialsShowTurnLights')
      settingsCheckbox('Show Speed', 'essentialsSpeedNum')
      if settings.essentialsSpeedNum then
        ui.text('\t')
        ui.sameLine()
        settingsCheckbox('Use MPH Instead', 'essentialsSpeedNumMPH')
      end
      settingsCheckbox('Show Gears', 'essentialsGears')
      settingsCheckbox('Show RPM Numbers', 'essentialsRpmNum')
      if settings.essentialsRpmNum then
        ui.text('\t')
        ui.sameLine()
        settingsCheckbox('Show Pedal Inputs Instead', 'essentialsInputBars')
      end
    end)
    ui.tabItem('Inputs', function()
      settingsCheckbox('Show Steering Wheel', 'inputsShowWheel')
      settingsCheckbox('Show Steering Bar', 'inputsShowSteering')
      settingsCheckbox('Show Input Bars', 'inputsShowPedals')
      if settings.inputsShowPedals then
        ui.text('\t')
        ui.sameLine()
        settingsCheckbox('Show Force Feedback', 'inputsShowFFB')
        ui.text('\t')
        ui.sameLine()
        settingsCheckbox('Show Clutch', 'inputsShowClutch')
        ui.text('\t')
        ui.sameLine()
        settingsCheckbox('Show Brake', 'inputsShowBrake')
        ui.text('\t')
        ui.sameLine()
        settingsCheckbox('Show Throttle', 'inputsShowGas')
        ui.text('\t')
        ui.sameLine()
        settingsCheckbox('Color Fully Pressed Pedals', 'inputsPedalColors')
      end

      settingsCheckbox('Show Car Electronics', 'inputsShowElectronics')
    end)
    ui.tabItem('Session', function()
      settingsCheckbox('Show Position', 'sessionShowPosition')
      if settings.sessionShowPosition then
        ui.text('\t')
        ui.sameLine()
        settingsCheckbox('Remove Disconnected Cars from Total', 'sessionHideDisconnected')
        settingsCheckbox('Also Remove Traffic Cars', 'sessionHideAI')
      end
      settingsCheckbox('Show Laps', 'sessionShowLaps')
      settingsCheckbox('Show Session Timer', 'sessionShowTimer')
      if settings.sessionShowTimer then
        ui.text('\t')
        ui.sameLine()
        settingsCheckbox('Show Session Type', 'sessionTimerType')
        ui.text('\t')
        ui.sameLine()
        settingsCheckbox('Show Time Since Join Instead', 'sessionAlwaysShowDuration')
      end
    end)
    ui.tabItem('Delta', function()
      settingsCheckbox('Hide When No Delta Available', 'deltaHidden')
      settingsCheckbox('Show Delta', 'deltaShowTimer')
      settingsCheckbox('Show Predicted Laptime', 'deltaShowPrediction')
      settingsCheckbox('Show Delta Bar', 'deltaShowBar')
      if settings.deltaShowBar then
        ui.text('\t')
        ui.sameLine()
        settings.deltaBarTime = ui.slider('##DeltaTime', settings.deltaBarTime, 1, 60, 'Full Bar At: ' .. '%.0f s')
      end
    end)
    ui.tabItem('Sectors', function()
      if #ac.getSim().lapSplits > 0 then
        settingsCheckbox('Show Sectors', 'sectorsShowSectors')
        if settings.sectorsShowSectors then
          ui.text('\t')
          ui.sameLine()
          settings.sectorsDisplayDuration = ui.slider('##SectorDisplayDuration', settings.sectorsDisplayDuration, 1, 60, 'Display Last Lap Sectors For: ' .. '%1.0f s')
        end
      end
      settingsCheckbox('Show Pitlane Info', 'sectorsShowPitInfo')
      if settings.sectorsShowPitInfo then
        ui.text('\t')
        ui.sameLine()
        settingsCheckbox('Show Pitlane Speed Limit', 'sectorsShowSpeedLimit')
      end
      settingsCheckbox('Show Race Flags', 'sectorsShowRaceFlags')
    end)
    ui.tabItem('Fuel', function()
      settingsCheckbox('Change Bar Color', 'fuelChangeBarColor')
      if settings.fuelChangeBarColor then
        ui.text('\t')
        ui.sameLine()
        ui.text('Will display at 20% and 5% if fuelPerLap isnt calculated')
        ui.text('\t')
        ui.sameLine()
        settings.fuelYellowBar = ui.slider('##FuelYellowBar', settings.fuelYellowBar, settings.fuelRedBar + 1, settings.fuelRedBar + 10, 'Yellow When Under: ' .. '%1.0f Laps')
        ui.text('\t')
        ui.sameLine()
        settings.fuelRedBar = ui.slider('##FuelRedBar', settings.fuelRedBar, 1, 10, 'Red When Under: ' .. '%1.0f Laps')
        if settings.fuelYellowBar <= settings.fuelRedBar then settings.fuelYellowBar = settings.fuelRedBar + 1 end
      end

      settingsCheckbox('Show Remaining Fuel', 'fuelShowRemaining')
      if settings.fuelShowRemaining then
        ui.text('\t')
        ui.sameLine()
        if ui.checkbox('Use Gallons Instead', settings.fuelGallons) then
          settings.fuelGallons = not settings.fuelGallons
          settings.fuelLaps = false
        end
        ui.text('\t')
        ui.sameLine()
        if ui.checkbox('Use Laps Instead If Available', settings.fuelLaps) then
          settings.fuelLaps = not settings.fuelLaps
          settings.fuelGallons = false
        end
      end
    end)
    ui.tabItem('Tires', function()
      settingsCheckbox('Show Tire Temperature Visualisation', 'tiresShowTempVis')
      if settings.tiresShowTempVis then
        ui.sameLine()
        if settings.tiresTiresConfigured then
          ui.textColored('Tire Information Found', rgbm.colors.green)
        else
          ui.textColored('Tire Information Not Found', rgbm.colors.red)
        end
        ui.text('\t')
        ui.sameLine()
        settingsCheckbox('Show Tire Pressure', 'tiresShowPressure')
        if settings.tiresShowPressure then
          ui.text('\t')
          ui.sameLine()
          ui.text('\t')
          ui.sameLine()
          settingsCheckbox('Use Bar instead', 'tiresPressureUseBar')
          ui.text('\t')
          ui.sameLine()
          ui.text('\t')
          ui.sameLine()
          settingsCheckbox('Color Tire Pressures', 'tiresPressureColor')
        end
        ui.text('\t')
        ui.sameLine()
        settingsCheckbox('Show Tire Wear', 'tiresShowWear')
        ui.text('\t')
        ui.sameLine()
        settingsCheckbox('Show Brake Temperature', 'tiresShowBrakeTemp')
        if settings.tiresShowBrakeTemp then
          ui.sameLine()
          if settings.tiresBrakesConfigured then
            ui.textColored('Brake Temps Found', rgbm.colors.green)
          else
            ui.textColored('Brake Temps Not Found', rgbm.colors.red)
          end
        end
      end
      settingsCheckbox('Show Tire Section Temperature Numbers', 'tiresShowTempBar')
      if settings.tiresShowTempBar then
        ui.text('\t')
        ui.sameLine()
        settingsCheckbox('Use Fahrenheit Instead', 'tiresTempUseFahrenheit')
      end
    end)
    ui.tabItem('Timing', function()
      settingsCheckbox('Show Current Laptime', 'timingShowCurrentLap')
      settingsCheckbox('Show Lapstats', 'timingShowLapStats')
      if settings.timingShowLapStats then
        ui.text('\t')
        ui.sameLine()
        settingsCheckbox('Show Best Laptime', 'timingLapStatsBest')
        ui.text('\t')
        ui.sameLine()
        settingsCheckbox('Show Last Laptime', 'timingLapStatsLast')
        ui.text('\t')
        ui.sameLine()
        settingsCheckbox('Show Ideal Laptime', 'timingLapStatsIdeal')
      end
      settingsCheckbox('Show Lap History', 'timingShowTable')
    end)
    ui.tabItem('Leaderboard', function()
      ui.text('\t')
      ui.sameLine()
      settings.lbMaxCars = ui.slider('##lbMaxCars', settings.lbMaxCars, 1, 50, 'Show: ' .. '%.0f cars')
      settingsCheckbox('Show Position', 'lbShowPos')
      settingsCheckbox('Show Car Number', 'lbShowNum')
      settingsCheckbox('Show Driver Name', 'lbShowName')
      if settings.lbShowName then
        ui.text('\t')
        ui.sameLine()
        settingsCheckbox('Manual Name Length', 'lbManNameLength')
        if settings.lbManNameLength then
          ui.text('\t')
          ui.sameLine()
          settings.lbManNameLengthNum = ui.slider('##lbNameNum', settings.lbManNameLengthNum, 5, 1000, 'Name Length: ' .. '%.0f pixel')
        end
      end
      settingsCheckbox('Show Car Model', 'lbShowCar')
      if settings.lbShowCar then
        ui.text('\t')
        ui.sameLine()
        settingsCheckbox('Show Brand Names', 'lbShowBrand')
        ui.text('\t')
        ui.sameLine()
        settingsCheckbox('Manual Car Length', 'lbManCarLength')
        if settings.lbManCarLength then
          ui.text('\t')
          ui.sameLine()
          settings.lbManCarLengthNum = ui.slider('##lbCarNum', settings.lbManCarLengthNum, 5, 1000, 'Name Length: ' .. '%.0f pixel')
        end
      end
      settingsCheckbox('Show Laps Done', 'lbShowLap')
      settingsCheckbox('Show Last Laptime', 'lbShowLast')
      settingsCheckbox('Show Best Laptime', 'lbShowBest')
      settingsCheckbox('Show Interval', 'lbShowInt')
    end)
  end)
end
