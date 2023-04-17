function getAppTable()
    local app = {
        ['scale'] = 1,
        ['padding'] = 22,
        ['flags'] = bit.bor(ui.WindowFlags.NoDecoration, ui.WindowFlags.NoBackground, ui.WindowFlags.NoNav, ui.WindowFlags.NoInputs, ui.WindowFlags.NoScrollbar),
        ['font'] = {
            ['medium'] = 'IBM Plex Sans:.\\fonts;Weight=Medium',
            ['semi'] = 'IBM Plex Sans:.\\fonts;Weight=SemiBold',
            ['bold'] = 'IBM Plex Sans:.\\fonts;Weight=Bold',
        }
    }

    return app
end

function getPositionTable()
    local position = {
        ['essentials'] = {
            ['elementsize'] = vec2(325, 121):scale(app.scale),
            ['rpmbarheight'] = scale(17),
            ['speed'] = {
                ['num'] = vec2(106, 28):scale(app.scale),
                ['txt'] = vec2(84, 5):scale(app.scale),
            },
            ['decor'] = {
                ['left'] = vec2(38, 41):scale(app.scale),
                ['right'] = vec2(35, 41):scale(app.scale),
                ['size'] = vec2(4, 80):scale(app.scale),
            },
            ['gear'] = vec2(17, 31):scale(app.scale),
            ['rpm'] = {
                ['num'] = vec2(46, 28):scale(app.scale),
                ['txt'] = vec2(46, 3):scale(app.scale),
            },
            ['inputbar'] = {
                ['pos'] = vec2(47, 25):scale(app.scale),
                ['size'] = vec2(5, 43):scale(app.scale),
                ['gap'] = 5,
            }
        },
        ['inputs'] = {
            ['elementsize'] = vec2(200, 162):scale(app.scale),
            ['decorimg'] = vec2(48, 34):scale(app.scale),
            ['decorheight'] = scale(40),
            ['bgheight'] = scale(145),
            ['steeringheight'] = scale(16),
            ['steeringwidth'] = scale(6),
            ['pedalheight'] = scale(20),

        }
    }

    position.essentials.inputbar.gap = scale(position.essentials.inputbar.gap + position.essentials.inputbar.size.x / app.scale)

    if settings.compactMode and settings.changeScale then
        position.essentials.elementsize = vec2(297, 85):scale(app.scale)
        position.essentials.rpmbarheight = scale(10)
        position.essentials.decor.left = vec2(38, 30):scale(app.scale)
        position.essentials.decor.right = vec2(35, 30):scale(app.scale)
        position.essentials.decor.size = vec2(4, 51):scale(app.scale)
    end

    return position
end

function getColorTable()
    local colors = {
        ['white'] = rgbm.colors.white,
        ['lightgray'] = rgbm(0.75, 0.75, 0.75, 1),
        ['gray'] = rgbm.colors.gray,
        ['darkgray'] = rgbm(0.25, 0.25, 0.25, 1),
        ['black'] = rgbm.colors.black,
        ['red'] = rgbm.colors.red,
        ['green'] = rgbm(0, 1, 0, 1),
        ['blue'] = rgbm.colors.blue,
        ['aqua'] = rgbm.colors.aqua,
        ['yellow'] = rgbm.colors.yellow,
        ['orange'] = rgbm.colors.orange,
        ['purple'] = rgbm(0.5, 0, 1, 1),
    }
    return colors
end
