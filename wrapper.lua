local playerLoaded = false
local addedZones = {}
local wCombozone

AddEventHandler('cbl:playerLoaded', function()
    playerLoaded = true
    InitWrapperZones()
end)

RegisterNetEvent('cbl:playerLogout', function()
    playerLoaded = false
    for k, v in pairs(addedZones) do
        TriggerEvent('Polyzone:Exit', k, false, false, v.data or {})
    end

    if wCombozone then
        wCombozone:destroy()
        wCombozone = nil
        print("[TRACE] [Polyzone] Destroyed ComboZone on logout.")
    end
end)

function CreateZoneForCombo(id, data)
    local options = data.options or {}
    options.name = id
    options.data = (type(data.data) == 'table' and data.data or {})
    options.data.id = id

    if data.type == 'circle' then
        return CircleZone:Create(data.center, data.radius, options)
    elseif data.type == 'poly' then
        return PolyZone:Create(data.points, options)
    elseif data.type == 'box' then
        return BoxZone:Create(data.center, data.length, data.width, options)
    end
end

function InitWrapperZones()
    if wCombozone then return end

    local createdZones = {}

    for k, v in pairs(addedZones) do
        local zone = CreateZoneForCombo(k, v)
        if zone then
            table.insert(createdZones, zone)
        end
    end

    wCombozone = ComboZone:Create(createdZones, { name = 'wrapper_combo' })
    print(("[TRACE] [Polyzone] Initialized %d Simple Polyzones"):format(#createdZones))

    wCombozone:onPlayerInOutExhaustive(function(isPointInside, testedPoint, insideZones, enteredZones, leftZones)
        if not playerLoaded then return end

        if enteredZones and #enteredZones > 0 then
            for _, zone in ipairs(enteredZones) do
                if zone.data and zone.data.id then
                    TriggerEvent('Polyzone:Enter', zone.data.id, testedPoint, insideZones, zone.data)
                end
            end
        end

        if leftZones and #leftZones > 0 then
            for _, zone in ipairs(leftZones) do
                if zone.data and zone.data.id then
                    TriggerEvent('Polyzone:Exit', zone.data.id, testedPoint, insideZones, zone.data)
                end
            end
        end
    end)
end

function AddZoneAfterCreation(id, zoneData)
    if not wCombozone then return end

    local zone = CreateZoneForCombo(id, zoneData)

    if zone then
        wCombozone:addZone(zone)
    end
end

-- POLYZONE API
_POLYZONE = {
    Create = {
        Box = function(self, id, center, length, width, options, data)
            addedZones[id] = {
                id = id,
                type = 'box',
                center = center,
                width = width,
                length = length,
                options = options,
                data = data,
            }
            AddZoneAfterCreation(id, addedZones[id])
        end,
        Poly = function(self, id, points, options, data)
            addedZones[id] = {
                id = id,
                type = 'poly',
                points = points,
                options = options,
                data = data,
            }
            AddZoneAfterCreation(id, addedZones[id])
        end,
        Circle = function(self, id, center, radius, options, data)
            addedZones[id] = {
                id = id,
                type = 'circle',
                center = center,
                radius = radius,
                options = options,
                data = data
            }
            AddZoneAfterCreation(id, addedZones[id])
        end
    },
    Remove = function(self, id)
        if addedZones[id] then
            addedZones[id] = nil
        end
        return false
    end,
    Get = function(self, id)
        return addedZones[id]
    end,
    GetZoneAtCoords = function(self, coords)
        if not wCombozone then return false end
        local isInside, insideZone = wCombozone:isPointInside(coords)
        if isInside and insideZone and insideZone.data then
            return insideZone.data
        end
        return false
    end,
    GetAllZonesAtCoords = function(self, coords)
        local withinZonesData = {}
        if not wCombozone then return withinZonesData end
        local isInside, insideZones = wCombozone:isPointInsideExhaustive(coords)
        if isInside and insideZones and #insideZones > 0 then
            for _, v in ipairs(insideZones) do
                table.insert(withinZonesData, v.data)
            end
        end
        return withinZonesData
    end,
    IsCoordsInZone = function(self, coords, id, key, val)
        if not wCombozone then return false end
        local isInside, insideZones = wCombozone:isPointInsideExhaustive(coords)
        if isInside and insideZones and #insideZones > 0 then
            for _, v in ipairs(insideZones) do
                if (not id or v.data.id == id) and (not key or ((val == nil and v.data[key]) or (val ~= nil and v.data[key] == val))) then
                    return v.data
                end
            end
        end
        return false
    end,
}

-- Exports
exports('CreateBox', function(id, center, length, width, options, data)
    return _POLYZONE.Create.Box(_POLYZONE, id, center, length, width, options, data)
end)

exports('CreatePoly', function(id, points, options, data)
    return _POLYZONE.Create.Poly(_POLYZONE, id, points, options, data)
end)

exports('CreateCircle', function(id, center, radius, options, data)
    return _POLYZONE.Create.Circle(_POLYZONE, id, center, radius, options, data)
end)

exports('RemoveZone', function(id)
    return _POLYZONE.Remove(id)
end)

exports('GetZone', function(id)
    return _POLYZONE.Get(id)
end)

exports('GetZoneAtCoords', function(coords)
    return _POLYZONE.GetZoneAtCoords(coords)
end)

exports('GetAllZonesAtCoords', function(coords)
    return _POLYZONE.GetAllZonesAtCoords(coords)
end)

exports('IsCoordsInZone', function(coords, id, key, val)
    return _POLYZONE.IsCoordsInZone(coords, id, key, val)
end)