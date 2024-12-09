--app made by XTZ
require('utils/helpers')
require('utils/tables')

require('elements/essentials')
require('elements/inputs')
require('elements/session')
require('elements/delta')
require('elements/sectors')
require('elements/fuel')
require('elements/tires')
require('elements/timing')
require('elements/leaderboard')

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

app = getAppTable()
color = getColorTable()

local updateStatusTable = {
    [0] = 'C1XTZ: You shouldnt be reading this',
    [1] = 'Updated: App successfully updated',
    [2] = 'No Change: Latest version was already installed',
    [3] = 'No Change: A newer version was already installed',
    [4] = 'Error: Something went wrong, aborted update',
    [5] = 'Update Available to Download and Install'
}
local updateStatusColor = {
    [0] = rgbm.colors.white,
    [1] = rgbm.colors.lime,
    [2] = rgbm.colors.white,
    [3] = rgbm.colors.white,
    [4] = rgbm.colors.red,
    [5] = rgbm.colors.lime
}

local appName = 'RennsportHUD'
local appFolder = ac.getFolder(ac.FolderID.ACApps) .. '/lua/' .. appName .. '/'
local manifest = ac.INIConfig.load(appFolder .. '/manifest.ini', ac.INIFormat.Extended)
local appVersion = manifest:get('ABOUT', 'VERSION', 0.01)
local releaseURL = 'https://api.github.com/repos/C1XTZ/ac-rennsporthud/releases/latest'
local doUpdate = (os.time() - settings.updateLastCheck) / 86400 > settings.updateInterval
local mainFile, assetFile = appName .. '.lua', appName .. '.zip'
--xtz: The ingame updater idea was taken from tuttertep's comfy map app and rewritten to work with my github releases instead of pulling from the entire repository
--xtz: JSON.parse returns a different json on 0.2.0 for some reason, ill do this for now, might bump recommended version to 0.2.1
function handle2651(latestRelease)
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

function updateCheckVersion(manual)
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

function updateApplyUpdate(downloadUrl)
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
                        if io.save(appFolder .. filePath, content) then print('Updating: ' .. file) end
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
            if ui.checkbox('Custom App Scaling', settings.changeScale) then settings.changeScale = not settings.changeScale end
            if settings.changeScale then
                ui.text('\t')
                ui.sameLine()
                settings.scale = ui.slider('##AppScale', settings.scale, 1, 5, 'App Scale: ' .. '%.01f%')
                if settings.changeScale and app.scale ~= settings.scale then app.scale = settings.scale end
            else
                settings.changeScale = 1
            end
            if ui.checkbox('Show Own Stats When Spectating', settings.ignorefocus) then settings.ignorefocus = not settings.ignorefocus end
            if ui.checkbox('Show Decorations', settings.decor) then settings.decor = not settings.decor end
        end)
        ui.tabItem('Essentials', function()
            if ui.checkbox('Enable Compact Mode', settings.essentialsCompactMode) then settings.essentialsCompactMode = not settings.essentialsCompactMode end
            if ui.checkbox('Show RPM Bar', settings.essentialsRpmBar) then settings.essentialsRpmBar = not settings.essentialsRpmBar end
            if settings.essentialsRpmBar then
                ui.text('\t')
                ui.sameLine()
                if ui.checkbox('Enable Shift Colors', settings.essentialsRpmBarColor) then settings.essentialsRpmBarColor = not settings.essentialsRpmBarColor end
                if settings.essentialsRpmBarColor then
                    ui.text('\t')
                    ui.sameLine()
                    settings.essentialsRpmBarShiftYellow = ui.slider('##ShiftYellow', settings.essentialsRpmBarShiftYellow, 0, 100, 'Yellow shift at: ' .. '%.0f%%')
                    ui.text('\t')
                    ui.sameLine()
                    settings.essentialsRpmBarShiftRed = ui.slider('##ShiftRed', settings.essentialsRpmBarShiftRed, 0, 100, 'Red shift at: ' .. '%.0f%%')
                end
            end
            if ui.checkbox('Show Indicators', settings.essentialsShowTurnLights) then settings.essentialsShowTurnLights = not settings.essentialsShowTurnLights end
            if ui.checkbox('Show Speed', settings.essentialsSpeedNum) then settings.essentialsSpeedNum = not settings.essentialsSpeedNum end
            if settings.essentialsSpeedNum then
                ui.text('\t')
                ui.sameLine()
                if ui.checkbox('Use MPH Instead', settings.essentialsSpeedNumMPH) then settings.essentialsSpeedNumMPH = not settings.essentialsSpeedNumMPH end
                if settings.essentialsSpeedNumMPH then speedText = 'MP/H' else speedText = 'KM/H' end
            end
            if ui.checkbox('Show Gears', settings.essentialsGears) then settings.essentialsGears = not settings.essentialsGears end

            if ui.checkbox('Show RPM Numbers', settings.essentialsRpmNum) then settings.essentialsRpmNum = not settings.essentialsRpmNum end
            if settings.essentialsRpmNum then
                ui.text('\t')
                ui.sameLine()
                if ui.checkbox('Show Pedal Inputs Instead', settings.essentialsInputBars) then settings.essentialsInputBars = not settings.essentialsInputBars end
            end
        end)
        ui.tabItem('Inputs', function()
            if ui.checkbox('Show Steering Wheel', settings.inputsShowWheel) then settings.inputsShowWheel = not settings.inputsShowWheel end
            if ui.checkbox('Show Steering Bar', settings.inputsShowSteering) then settings.inputsShowSteering = not settings.inputsShowSteering end
            if ui.checkbox('Show Input Bars', settings.inputsShowPedals) then settings.inputsShowPedals = not settings.inputsShowPedals end
            if settings.inputsShowPedals then
                ui.text('\t')
                ui.sameLine()
                if ui.checkbox('Show Force Feedback', settings.inputsShowFFB) then settings.inputsShowFFB = not settings.inputsShowFFB end
                ui.text('\t')
                ui.sameLine()
                if ui.checkbox('Show Clutch', settings.inputsShowClutch) then settings.inputsShowClutch = not settings.inputsShowClutch end
                ui.text('\t')
                ui.sameLine()
                if ui.checkbox('Show Brake', settings.inputsShowBrake) then settings.inputsShowBrake = not settings.inputsShowBrake end
                ui.text('\t')
                ui.sameLine()
                if ui.checkbox('Show Throttle', settings.inputsShowGas) then settings.inputsShowGas = not settings.inputsShowGas end
                ui.text('\t')
                ui.sameLine()
                if ui.checkbox('Color Fully Pressed Pedals', settings.inputsPedalColors) then settings.inputsPedalColors = not settings.inputsPedalColors end
            end

            if ui.checkbox('Show Car Electronics', settings.inputsShowElectronics) then settings.inputsShowElectronics = not settings.inputsShowElectronics end
        end)
        ui.tabItem('Session', function()
            if ui.checkbox('Show Position', settings.sessionShowPosition) then settings.sessionShowPosition = not settings.sessionShowPosition end
            if settings.sessionShowPosition then
                ui.text('\t')
                ui.sameLine()
                if ui.checkbox('Remove Disconnected Cars from Total', settings.sessionHideDisconnected) then settings.sessionHideDisconnected = not settings.sessionHideDisconnected end
                if ui.checkbox('Also Remove Traffic Cars', settings.sessionHideAI) then settings.sessionHideAI = not settings.sessionHideAI end
            end
            if ui.checkbox('Show Laps', settings.sessionShowLaps) then settings.sessionShowLaps = not settings.sessionShowLaps end
            if ui.checkbox('Show Session Timer', settings.sessionShowTimer) then settings.sessionShowTimer = not settings.sessionShowTimer end
            if settings.sessionShowTimer then
                ui.text('\t')
                ui.sameLine()
                if ui.checkbox('Show Session Type', settings.sessionTimerType) then settings.sessionTimerType = not settings.sessionTimerType end
                ui.text('\t')
                ui.sameLine()
                if ui.checkbox('Show Time Since Join Instead', settings.sessionAlwaysShowDuration) then settings.sessionAlwaysShowDuration = not settings.sessionAlwaysShowDuration end
            end
        end)
        ui.tabItem('Delta', function()
            if ui.checkbox('Hide When No Delta Available', settings.deltaHidden) then settings.deltaHidden = not settings.deltaHidden end
            if ui.checkbox('Show Delta', settings.deltaShowTimer) then settings.deltaShowTimer = not settings.deltaShowTimer end
            if ui.checkbox('Show Predicted Laptime', settings.deltaShowPrediction) then settings.deltaShowPrediction = not settings.deltaShowPrediction end
            if ui.checkbox('Show Delta Bar', settings.deltaShowBar) then settings.deltaShowBar = not settings.deltaShowBar end
            if settings.deltaShowBar then
                ui.text('\t')
                ui.sameLine()
                settings.deltaBarTime = ui.slider('##DeltaTime', settings.deltaBarTime, 1, 60, 'Full Bar At: ' .. '%.0f s')
            end
        end)
        ui.tabItem('Sectors', function()
            if #ac.getSim().lapSplits > 0 then
                if ui.checkbox('Show Sectors', settings.sectorsShowSectors) then settings.sectorsShowSectors = not settings.sectorsShowSectors end
                if settings.sectorsShowSectors then
                    ui.text('\t')
                    ui.sameLine()
                    settings.sectorsDisplayDuration = ui.slider('##SectorDisplayDuration', settings.sectorsDisplayDuration, 1, 60, 'Display Last Lap Sectors For: ' .. '%1.0f s')
                end
            end
            if ui.checkbox('Show Pitlane Info', settings.sectorsShowPitInfo) then settings.sectorsShowPitInfo = not settings.sectorsShowPitInfo end
            if settings.sectorsShowPitInfo then
                ui.text('\t')
                ui.sameLine()
                if ui.checkbox('Show Pitlane Speed Limit', settings.sectorsShowSpeedLimit) then settings.sectorsShowSpeedLimit = not settings.sectorsShowSpeedLimit end
            end
            if ui.checkbox('Show Race Flags', settings.sectorsShowRaceFlags) then settings.sectorsShowRaceFlags = not settings.sectorsShowRaceFlags end
        end)
        ui.tabItem('Fuel', function()
            if ui.checkbox('Change Bar Color', settings.fuelChangeBarColor) then settings.fuelChangeBarColor = not settings.fuelChangeBarColor end
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

            if ui.checkbox('Show Remaining Fuel', settings.fuelShowRemaining) then settings.fuelShowRemaining = not settings.fuelShowRemaining end
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
            if ui.checkbox('Show Tire Temperature Visualisation', settings.tiresShowTempVis) then settings.tiresShowTempVis = not settings.tiresShowTempVis end
            if settings.tiresShowTempVis then
                ui.text('\t')
                ui.sameLine()
                if ui.checkbox('Show Tire Pressure', settings.tiresShowPressure) then settings.tiresShowPressure = not settings.tiresShowPressure end
                if settings.tiresShowPressure then
                    ui.text('\t')
                    ui.sameLine()
                    ui.text('\t')
                    ui.sameLine()
                    if ui.checkbox('Use Bar instead', settings.tiresPressureUseBar) then settings.tiresPressureUseBar = not settings.tiresPressureUseBar end
                    ui.text('\t')
                    ui.sameLine()
                    ui.text('\t')
                    ui.sameLine()
                    if ui.checkbox('Color Tire Pressures', settings.tiresPressureColor) then settings.tiresPressureColor = not settings.tiresPressureColor end
                end
                ui.text('\t')
                ui.sameLine()
                if ui.checkbox('Show Tire Wear', settings.tiresShowWear) then settings.tiresShowWear = not settings.tiresShowWear end
                ui.text('\t')
                ui.sameLine()
                if ui.checkbox('Show Brake Temperature', settings.tiresShowBrakeTemp) then settings.tiresShowBrakeTemp = not settings.tiresShowBrakeTemp end
                if settings.tiresShowBrakeTemp then
                    ui.sameLine()
                    if settings.tiresBrakesConfigured then ui.textColored('Brake Temps Found', rgbm.colors.green) else ui.textColored('Brake Temps Not Found', rgbm.colors.red) end
                end
            end
            if ui.checkbox('Show Tire Section Temperature Numbers', settings.tiresShowTempBar) then settings.tiresShowTempBar = not settings.tiresShowTempBar end
            if settings.tiresShowTempBar then
                ui.text('\t')
                ui.sameLine()
                if ui.checkbox('Use Fahrenheit Instead', settings.tiresTempUseFahrenheit) then settings.tiresTempUseFahrenheit = not settings.tiresTempUseFahrenheit end
            end
        end)
        ui.tabItem('Timing', function()
            if ui.checkbox('Show Current Laptime', settings.timingShowCurrentLap) then settings.timingShowCurrentLap = not settings.timingShowCurrentLap end
            if ui.checkbox('Show Lapstats', settings.timingShowLapStats) then settings.timingShowLapStats = not settings.timingShowLapStats end
            if settings.timingShowLapStats then
                ui.text('\t')
                ui.sameLine()
                if ui.checkbox('Show Best Laptime', settings.timingLapStatsBest) then settings.timingLapStatsBest = not settings.timingLapStatsBest end
                ui.text('\t')
                ui.sameLine()
                if ui.checkbox('Show Last Laptime', settings.timingLapStatsLast) then settings.timingLapStatsLast = not settings.timingLapStatsLast end
                ui.text('\t')
                ui.sameLine()
                if ui.checkbox('Show Ideal Laptime', settings.timingLapStatsIdeal) then settings.timingLapStatsIdeal = not settings.timingLapStatsIdeal end
            end
            if ui.checkbox('Show Lap History', settings.timingShowTable) then settings.timingShowTable = not settings.timingShowTable end
        end)
        ui.tabItem('Leaderboard', function()
            ui.text('\t')
            ui.sameLine()
            settings.lbMaxCars = ui.slider('##lbMaxCars', settings.lbMaxCars, 1, 50, 'Show: ' .. '%.0f cars')
            if ui.checkbox('Show Position', settings.lbShowPos) then settings.lbShowPos = not settings.lbShowPos end
            if ui.checkbox('Show Car Number', settings.lbShowNum) then settings.lbShowNum = not settings.lbShowNum end
            if ui.checkbox('Show Driver Name', settings.lbShowName) then settings.lbShowName = not settings.lbShowName end
            if settings.lbShowName then
                ui.text('\t')
                ui.sameLine()
                if ui.checkbox('Manual Name Length', settings.lbManNameLength) then settings.lbManNameLength = not settings.lbManNameLength end
                if settings.lbManNameLength then
                    ui.text('\t')
                    ui.sameLine()
                    settings.lbManNameLengthNum = ui.slider('##lbNameNum', settings.lbManNameLengthNum, 5, 1000, 'Name Length: ' .. '%.0f pixel')
                end
            end
            if ui.checkbox('Show Car Model', settings.lbShowCar) then settings.lbShowCar = not settings.lbShowCar end
            if settings.lbShowCar then
                ui.text('\t')
                ui.sameLine()
                if ui.checkbox('Manual Car Length', settings.lbManCarLength) then settings.lbManCarLength = not settings.lbManCarLength end
                if settings.lbManCarLength then
                    ui.text('\t')
                    ui.sameLine()
                    settings.lbManCarLengthNum = ui.slider('##lbCarNum', settings.lbManCarLengthNum, 5, 1000, 'Name Length: ' .. '%.0f pixel')
                end
            end
            if ui.checkbox('Show Laps Done', settings.lbShowLap) then settings.lbShowLap = not settings.lbShowLap end
            if ui.checkbox('Show Last Laptime', settings.lbShowLast) then settings.lbShowLast = not settings.lbShowLast end
            if ui.checkbox('Show Best Laptime', settings.lbShowBest) then settings.lbShowBest = not settings.lbShowBest end
            if ui.checkbox('Show Interval', settings.lbShowInt) then settings.lbShowInt = not settings.lbShowInt end
        end)
    end)
end
