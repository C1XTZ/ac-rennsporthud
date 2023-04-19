--Scales a value by the app scale
function scale(value)
    return app.scale * value
end

--Parses the gearInt for Ui use
function parseGear(gearInt)
    if gearInt == 0 then
        return 'N'
    elseif gearInt == -1 then
        return 'R'
    else
        return gearInt
    end
end

--returns the user car or the currently focused car if enabled
function playerCar()
    if ac.getSim().focusedCar > 0 and not settings.ignorefocus then
        return ac.getCar(ac.getSim().focusedCar)
    else
        return ac.getCar(0)
    end
end

--returns color with the wanted percentage of opacity
function setColorMult(oldrgbm, percentage)
    return rgbm(oldrgbm.r, oldrgbm.g, oldrgbm.b, 1 * (percentage / 100))
end
