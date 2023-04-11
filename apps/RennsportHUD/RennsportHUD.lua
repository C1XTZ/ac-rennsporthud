--app made by XTZ

require('elements/essentials')
require('utilities/utilities')

settings = ac.storage {
    decor = true,
    changeScale = false,
    scale = 1,
    compactMode = false,
    ignorefocus = true,

    essentialsRpmBar = true,
    essentialsRpmBarColor = true,
    essentialsRpmBarShiftYellow = 95,
    essentialsRpmBarShiftRed = 98,
    essentialsGears = true,
    essentialsRpmNum = true,
    essentialsSpeedNum = true,
    essentialsSpeedNumMPH = false,
    essentialsInputBars = false,
}

app = {
    ['scale'] = 1,
    ['padding'] = 22,
    ['flags'] = bit.bor(ui.WindowFlags.NoDecoration, ui.WindowFlags.NoBackground, ui.WindowFlags.NoNav, ui.WindowFlags.NoInputs, ui.WindowFlags.NoScrollbar),
    ['fonts'] = {
        ['bold'] = ui.DWriteFont('IBM Plex Sans', '.\\fonts\\IBMPlexSans-Bold.ttf'),
        ['semi'] = ui.DWriteFont('IBM Plex Sans SemiBold', '.\\fonts\\IBMPlexSans-SemiBold.ttf'),
        ['medium'] = ui.DWriteFont('IBM Plex Sans Medium', '.\\fonts\\IBMPlexSans-Medium.ttf'),
    }
}

function script.windowMain(dt)
    ui.tabBar('Elements', function()
        ui.tabItem('General', function()
            if ui.checkbox('Custom App Scaling', settings.changeScale) then settings.changeScale = not settings.changeScale end
            if settings.changeScale then
                ui.text('\t')
                ui.sameLine()
                settings.scale = ui.slider('##AppScale', settings.scale, 1, 5, 'App Scale: ' .. '%.01f%')
                if settings.changeScale and app.scale ~= settings.scale then app.scale = settings.scale end
                ui.text('\t')
                ui.sameLine()
                if ui.checkbox('Enable Compact Mode', settings.compactMode) then settings.compactMode = not settings.compactMode end
            else
                settings.changeScale = 1
            end
            if ui.checkbox('Show Own Stats When Spectating', settings.ignorefocus) then settings.ignorefocus = not settings.ignorefocus end
            if ui.checkbox('Show Decorations', settings.decor) then settings.decor = not settings.decor end
        end)
        ui.tabItem('Tachometer', function()
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
    end)
end
