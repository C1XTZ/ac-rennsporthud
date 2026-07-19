---@meta
---@diagnostic disable: lowercase-global

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
    },
  }

  if settings.changeScale and app.scale ~= settings.scale then app.scale = settings.scale end

  return app
end

function getPositionTable()
  local position = {
    essentials = {
      elementsize = scaleVec2(325, 121),
      rpmbarheight = scale(17),
      speed = {
        num = scaleVec2(106, 28),
        txt = scaleVec2(84, 5),
      },
      decor = {
        left = scaleVec2(38, 41),
        right = scaleVec2(35, 41),
        size = scaleVec2(4, 80),
      },
      gear = scaleVec2(34, 31),
      rpm = {
        num = scaleVec2(46, 28),
        txt = scaleVec2(46, 3),
      },
      inputbar = {
        pos = scaleVec2(47, 25),
        size = scaleVec2(5, 43),
        gap = 5,
      },
      indicators = {
        size = vec2(55, 2),
      },
    },
    inputs = {
      elementsize = scaleVec2(268, 162),
      pedalsize = scaleVec2(200, 88),
      decorimg = scaleVec2(48, 34),
      decorheight = scale(40),
      steeringbar = scaleVec2(6, 16),
      pedalheight = math.floor(scale(18)),
      electronics = {
        lightbg = scale(34),
        darkbg = scaleVec2(45, 34),
        val = scaleVec2(55, 34),
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
      staticpos = scaleVec2(7, 4),
      positiontxt = {
        contentlargepos = scaleVec2(5, 21),
        contentlargesize = scaleVec2(68, 34),
        contentsmallpos = scaleVec2(72, 36),
        contentsmallsize = scaleVec2(26, 18),
      },
      lapswidth = scale(60),
      lapstxt = {
        contentpos = scaleVec2(0, 21),
        contentsize = scaleVec2(60, 34),
      },
      timerwidth = scale(164),
      timertxt = {
        contentpos = scaleVec2(0, 21),
        contentsize = scale(34),
      },
    },
    delta = {
      elementsize = scaleVec2(250, 60),
      txtpos = scaleVec2(14, 2),
      timepos = scaleVec2(27, 4),
      contentheight = scale(44),
      barheight = scale(16),
    },
    sectors = {
      sectorwidth = math.round(scale(170)),
      sectorheight = scale(18),
      pitheight = scale(20),
    },
    fuel = {
      barsize = scaleVec2(150, 16),
      valueheight = scale(54),
      txtpos = scaleVec2(5, 5),
      valuepos = scale(20),
      unitpos = scaleVec2(55, 25),
    },
    tires = {
      decorsize = scaleVec2(164, 18),
      wheelelement = scaleVec2(82, 74),
      wheelpos = scale(24),
      wheelpartsize = scaleVec2(6, 40),
      brakesize = scaleVec2(3, 20),
      brakepos = scaleVec2(13, 34),
      tempbarheight = scale(28),
      tempbartxt = scaleVec2(22, 11),
      pressurepos = scale(28),
      wearsize = scaleVec2(6, 31),
      wearpos = scaleVec2(6, 55),
    },
    timing = {
      pos = {
        currentLapTxt = scaleVec2(8, 4),
        currentLapContent = scaleVec2(4, 22),
      },
      currentLap = scaleVec2(211, 62),
      lapStats = scaleVec2(150, 20),
      table = {
        header = scaleVec2(226, 18),
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
  position.tires.decorsize.x = position.tires.wheelelement.x * 2

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
