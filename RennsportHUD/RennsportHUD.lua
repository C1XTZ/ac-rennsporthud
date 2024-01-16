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
    tiresUseCore = false,

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

function script.windowMain(dt)
    ui.tabBar('Elements', function()
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
                if ui.checkbox('Visualize Core instead of Surface Temperatures', settings.tiresUseCore) then settings.tiresUseCore = not settings.tiresUseCore end
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
