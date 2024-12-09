function getAppTable()
    local app = {
        scale = 1, --on 1920x1080, at >3.6 scale, some of the app windows reach a maximum size (mostly width) that I cant change. Ill file this under "non-issues"
        padding = 22,
        flags = bit.bor(ui.WindowFlags.NoDecoration, ui.WindowFlags.NoBackground, ui.WindowFlags.NoNav, ui.WindowFlags.NoInputs, ui.WindowFlags.NoScrollbar),
        font = {
            medium = 'IBM Plex Sans:.\\fonts;Weight=Medium',
            semi = 'IBM Plex Sans:.\\fonts;Weight=SemiBold',
            bold = 'IBM Plex Sans:.\\fonts;Weight=Bold',
            black = 'IBM Plex Sans:.\\fonts;Weight=Black',
        }
    }

    if settings.changeScale and app.scale ~= settings.scale then app.scale = settings.scale end

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
            gear = vec2(34, 31):scale(app.scale),
            rpm = {
                num = vec2(46, 28):scale(app.scale),
                txt = vec2(46, 3):scale(app.scale),
            },
            inputbar = {
                pos = vec2(47, 25):scale(app.scale),
                size = vec2(5, 43):scale(app.scale),
                gap = 5,
            },
            indicators = {
                size = vec2(55, 2)
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
        delta = {
            elementsize = vec2(250, 60):scale(app.scale),
            txtpos = vec2(14, 2):scale(app.scale),
            timepos = vec2(27, 4):scale(app.scale),
            contentheight = scale(44),
            barheight = scale(16),
        },
        sectors = {
            sectorwidth = math.round(scale(170)),
            sectorheight = scale(18),
            pitheight = scale(20),
        },
        fuel = {
            barsize = vec2(150, 16):scale(app.scale),
            valueheight = scale(54),
            txtpos = vec2(5, 5):scale(app.scale),
            valuepos = scale(20),
            unitpos = vec2(55, 25):scale(app.scale),
        },
        tires = {
            decorsize = vec2(164, 18):scale(app.scale),
            wheelelement = vec2(82, 74):scale(app.scale),
            wheelpos = scale(24),
            wheelpartsize = vec2(6, 40):scale(app.scale),
            brakesize = vec2(3, 20):scale(app.scale),
            brakepos = vec2(13, 34):scale(app.scale),
            tempbarheight = scale(28),
            tempbartxt = vec2(22, 11):scale(app.scale),
            pressurepos = scale(28),
            wearsize = vec2(6, 31):scale(app.scale),
            wearpos = vec2(6, 55):scale(app.scale)
        },
        timing = {
            pos = {
                currentLapTxt = vec2(8, 4):scale(app.scale),
                currentLapContent = vec2(4, 22):scale(app.scale),
            },
            currentLap = vec2(211, 62):scale(app.scale),
            lapStats = vec2(150, 20):scale(app.scale),
            table = {
                header = vec2(226, 18):scale(app.scale),
                contentheight = scale(20),
                lap = scale(54),
                time = scale(80),
            },
        },
        leaderboard = {
            height = scale(20),
            pnl = scale(45),
            time = scale(72),
            int = scale(56),
            ends = scale(10),
            lap = scale(28),
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
        uigreen = rgbm(0.02, 0.65, 0.4, 1),
        uired = rgbm(0.85, 0.2, 0.2, 1),
    }
    return colors
end
