function getAppTable()
    local app = {
        scale = 1,
        padding = 22,
        flags = bit.bor(ui.WindowFlags.NoDecoration, ui.WindowFlags.NoBackground, ui.WindowFlags.NoNav, ui.WindowFlags.NoInputs, ui.WindowFlags.NoScrollbar),
        font = {
            medium = 'IBM Plex Sans:.\\fonts;Weight=Medium',
            semi = 'IBM Plex Sans:.\\fonts;Weight=SemiBold',
            bold = 'IBM Plex Sans:.\\fonts;Weight=Bold',
        }
    }

    return app
end

function getPositionTable()
    local position = {
        essentials = {
            elementsize = vec2(325, 121):scale(app.scale),
            rpmbarheight = scale(17),
            speed = {
                num = vec2(106, 28):scale(app.scale),
                txt = vec2(84, 5):scale(app.scale),
            },
            decor = {
                left = vec2(38, 41):scale(app.scale),
                right = vec2(35, 41):scale(app.scale),
                size = vec2(4, 80):scale(app.scale),
            },
            gear = vec2(17, 31):scale(app.scale),
            rpm = {
                num = vec2(46, 28):scale(app.scale),
                txt = vec2(46, 3):scale(app.scale),
            },
            inputbar = {
                pos = vec2(47, 25):scale(app.scale),
                size = vec2(5, 43):scale(app.scale),
                gap = 5,
            }
        },
        inputs = {
            elementsize = vec2(268, 162):scale(app.scale),
            pedalsize = vec2(200, 88):scale(app.scale),
            decorimg = vec2(48, 34):scale(app.scale),
            decorheight = scale(40),
            steeringbar = vec2(6, 16):scale(app.scale),
            pedalheight = scale(18),
            electronics = {
                lightbg = scale(34),
                darkbg = vec2(45, 34):scale(app.scale),
                val = vec2(55, 34):scale(app.scale),
            },
            wheel = {
                padding = scale(15),
                imgsize = scale(52),
            },
        },
        session = {
            padding = scale(15),
            boxheight = scale(64),
            positionwidth = scale(105),
            staticpos = vec2(7, 4):scale(app.scale),
            positiontxt = {
                contentlargepos = vec2(5, 21):scale(app.scale),
                contentlargesize = vec2(68, 34):scale(app.scale),
                contentsmallpos = vec2(72, 36):scale(app.scale),
                contentsmallsize = vec2(26, 18):scale(app.scale),
            },
            lapswidth = scale(60),
            lapstxt = {
                contentpos = vec2(0, 21):scale(app.scale),
                contentsize = vec2(60, 34):scale(app.scale),
            },
            timerwidth = scale(164),
            timertxt = {
                contentpos = vec2(0, 21):scale(app.scale),
                contentsize = scale(34),
            },
        },
    }

    position.essentials.inputbar.gap = scale(position.essentials.inputbar.gap + position.essentials.inputbar.size.x / app.scale)

    return position
end

function getColorTable()
    local colors = {
        white = rgbm.colors.white,
        lightgray = rgbm(0.75, 0.75, 0.75, 1),
        gray = rgbm.colors.gray,
        darkgray = rgbm(0.25, 0.25, 0.25, 1),
        black = rgbm.colors.black,
        red = rgbm.colors.red,
        green = rgbm(0, 1, 0, 1),
        blue = rgbm.colors.blue,
        aqua = rgbm.colors.aqua,
        yellow = rgbm.colors.yellow,
        orange = rgbm.colors.orange,
        purple = rgbm(0.5, 0, 1, 1),
        uigreen = rgbm(0.1, 0.7, 0.4, 1)
    }
    return colors
end
