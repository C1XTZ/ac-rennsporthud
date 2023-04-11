--Scales a value by the app scale
function scale(value)
    return app.scale * value
end

--Parses the gearInt for Ui use
function parseGear(gearInt)
    local gear
    if gearInt == 0 then
        gear = 'N'
    elseif gearInt == -1 then
        gear = 'R'
    else
        gear = gearInt
    end
    return gear
end

--returns the user car or the currently focused car if enabled
function playerCar()
    local playercar
    if ac.getSim().focusedCar > 0 and not settings.ignorefocus then
        playercar = ac.getCar(ac.getSim().focusedCar)
    else
        playercar = ac.getCar(0)
    end
    return playercar
end
