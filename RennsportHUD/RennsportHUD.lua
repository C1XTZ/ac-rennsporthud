--app made by XTZ

---@diagnostic disable-next-line: lowercase-global
settings = ac.storage {
  changeScale = false,
  scale = 1,

  decor = true,
  ignorefocus = true,

  updateLastCheck = 0,
  updateAutoCheck = false,
  updateInterval = 7,
  updateStatus = 0,
  updateAvailable = false,
  updateURL = '',

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

local updateStatusTable = {
  [0] = 'C1XTZ: You shouldnt be reading this',
  [1] = 'Updated: App successfully updated',
  [2] = 'No Change: Latest version was already installed',
  [3] = 'No Change: A newer version was already installed',
  [4] = 'Error: Something went wrong, aborted update',
  [5] = 'Update Available to Download and Install',
}
local updateStatusColor = {
  [0] = rgbm.colors.white,
  [1] = rgbm.colors.lime,
  [2] = rgbm.colors.white,
  [3] = rgbm.colors.white,
  [4] = rgbm.colors.red,
  [5] = rgbm.colors.lime,
}

local appName = 'RennsportHUD'
local appFolder = ac.getFolder(ac.FolderID.ACApps) .. '/lua/' .. appName .. '/'
local manifest = ac.INIConfig.load(appFolder .. '/manifest.ini', ac.INIFormat.Extended)
local appVersion = manifest:get('ABOUT', 'VERSION', 0.01)
local releaseURL = 'https://api.github.com/repos/C1XTZ/ac-rennsporthud/releases/latest'
local mainFile, assetFile = appName .. '.lua', appName .. '.zip'
--xtz: The ingame updater idea was taken from tuttertep's comfy map app and rewritten to work with my github releases instead of pulling from the entire repository
--xtz: JSON.parse returns a different json on 0.2.0 for some reason, ill do this for now, might bump recommended version to 0.2.1
local function handle2651(latestRelease)
  local tagName, releaseAssets, getDownloadUrl
  if ac.getPatchVersionCode() <= 2651 then
    tagName = latestRelease.author.tag_name
    releaseAssets = latestRelease.author.assets
    getDownloadUrl = function(asset) return asset.uploader.browser_download_url end
  else
    tagName = latestRelease.tag_name
    releaseAssets = latestRelease.assets
    getDownloadUrl = function(asset) return asset.browser_download_url end
  end
  return tagName, releaseAssets, getDownloadUrl
end

local updateApplyUpdate

local function updateCheckVersion(manual)
  settings.updateLastCheck = os.time()

  web.get(releaseURL, function(err, response)
    if err then
      settings.updateStatus = 4
      error(err)
      return
    end

    local latestRelease = JSON.parse(response.body)
    local tagName, releaseAssets, getDownloadUrl = handle2651(latestRelease)

    if not (tagName and tagName:match('^v%d%d?%.%d%d?$')) then
      settings.updateStatus = 4
      error('URL unavailable or no Version recognized, aborted update')
      return
    end
    local version = tonumber(tagName:sub(2))

    if appVersion > version then
      settings.updateStatus = 3
      settings.updateAvailable = false
      return
    elseif appVersion == version then
      settings.updateStatus = 2
      settings.updateAvailable = false
      return
    else
      local downloadUrl
      for _, asset in ipairs(releaseAssets) do
        if asset.name == assetFile then
          downloadUrl = getDownloadUrl(asset)
          break
        end
      end

      if not downloadUrl then
        settings.updateStatus = 4
        error('No matching asset found, aborted update')
        return
      end

      if manual then
        updateApplyUpdate(downloadUrl)
      else
        settings.updateAvailable = true
        settings.updateURL = downloadUrl
        settings.updateStatus = 5
      end
    end
  end)
end

updateApplyUpdate = function(downloadUrl)
  web.get(downloadUrl, function(downloadErr, downloadResponse)
    if downloadErr then
      settings.updateStatus = 4
      error(downloadErr)
      return
    end

    local mainFileContent
    for _, file in ipairs(io.scanZip(downloadResponse.body)) do
      local content = io.loadFromZip(downloadResponse.body, file)
      if content then
        local filePath = file:match('(.*)')
        if filePath then
          filePath = filePath:gsub(appName .. '/', '')
          if filePath == mainFile then
            mainFileContent = content
          else
            local fullPath = appFolder .. filePath
            io.createFileDir(fullPath)
            if io.save(fullPath, content) then print('Updating: ' .. file) end
          end
        end
      end
    end

    if mainFileContent then
      if io.save(appFolder .. mainFile, mainFileContent) then print('Updating: ' .. mainFile) end
    end

    settings.updateStatus = 1
    settings.updateAvailable = false
    settings.updateURL = ''
  end)
end

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

function script.windowMain(dt)
  ui.tabBar('Elements', function()
    if ac.getPatchVersionCode() < 2651 then
      ui.textColored('You are using a version of CSP older than 0.2.0!\nIf anything breaks update to the latest version\n ', rgbm.colors.red)
      ui.newLine(-25)
    end
    if ac.getPatchVersionCode() >= 2651 then
      ui.tabItem('Update', function()
        ui.text('Currrently running version ' .. appVersion)
        if ui.checkbox('Automatically Check for Updates', settings.updateAutoCheck) then
          settings.updateAutoCheck = not settings.updateAutoCheck
          if settings.updateAutoCheck then updateCheckVersion() end
        end
        if settings.updateAutoCheck then
          ui.text('\t')
          ui.sameLine()
          settings.updateInterval = ui.slider('##UpdateInterval', settings.updateInterval, 1, 60, 'Check for Update every ' .. '%.0f days')
        end

        local updateButtonText = settings.updateAvailable and 'Install Update' or 'Check for Update'
        if ui.button(updateButtonText) then
          if settings.updateAvailable then
            updateCheckVersion(true)
          else
            updateCheckVersion(false)
          end
        end
        if settings.updateStatus > 0 then
          ui.textColored(updateStatusTable[settings.updateStatus], updateStatusColor[settings.updateStatus])

          local diff = os.time() - settings.updateLastCheck
          if diff > 600 then settings.updateStatus = 0 end
          local units = { 'seconds', 'minutes', 'hours', 'days' }
          local values = { 1, 60, 3600, 86400 }

          local i = #values
          while i > 1 and diff < values[i] do
            i = i - 1
          end

          local timeAgo = math.floor(diff / values[i])
          ui.text('Last checked ' .. timeAgo .. ' ' .. units[i] .. ' ago')
        end
      end)
    end
    ui.tabItem('General', function()
      settingsCheckbox('Custom App Scaling', 'changeScale')
      if settings.changeScale then
        ui.text('\t')
        ui.sameLine()
        settings.scale = ui.slider('##AppScale', settings.scale, 0.5, 5, 'App Scale: ' .. '%.01f%')
        if settings.changeScale and app.scale ~= settings.scale then app.scale = settings.scale end
      else
        settings.changeScale = 1
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
