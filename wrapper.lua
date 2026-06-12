local characterLoaded = false
local addedZones = {}
local wCombozone

RegisterNetEvent('cbl:setActiveCharacter', function()
    characterLoaded = true
    print("[TRACE] [Polyzone] Player loaded. Initializing wrapper zones.")
    InitWrapperZones()
end)

RegisterNetEvent('cbl:playerLogout', function()
    characterLoaded = false
    print("[TRACE] [Polyzone] Player logout triggered. Cleaning up zones.")

    for k, v in pairs(addedZones) do
        print("[TRACE] [Polyzone] Forcing exit for zone: " .. k)
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
        print("[TRACE] [Polyzone] Creating circle zone: " .. id)
        return CircleZone:Create(data.center, data.radius, options)
    elseif data.type == 'poly' then
        print("[TRACE] [Polyzone] Creating poly zone: " .. id)
        return PolyZone:Create(data.points, options)
    elseif data.type == 'box' then
        print("[TRACE] [Polyzone] Creating box zone: " .. id)
        return BoxZone:Create(data.center, data.length, data.width, options)
    end

    print("[TRACE] [Polyzone] Failed to create zone: unknown type for id " .. id)
end

function InitWrapperZones()
    if wCombozone then return end

    local createdZones = {}

    for k, v in pairs(addedZones) do
        print("[TRACE] [Polyzone] Adding zone to wrapper: " .. k)
        local zone = CreateZoneForCombo(k, v)
        if zone then
            table.insert(createdZones, zone)
        end
    end

    wCombozone = ComboZone:Create(createdZones, { name = 'wrapper_combo' })
    print("[TRACE] [Polyzone] ComboZone created successfully.")

    wCombozone:onPlayerInOutExhaustive(function(isPointInside, testedPoint, insideZones, enteredZones, leftZones)
        if not characterLoaded then return end

        if enteredZones and #enteredZones > 0 then
            for _, zone in ipairs(enteredZones) do
                if zone.data and zone.data.id then
                    print("[TRACE] [Polyzone] Entered zone: " .. zone.data.id)
                    TriggerEvent('Polyzone:Enter', zone.data.id, testedPoint, insideZones, zone.data)
                end
            end
        end

        if leftZones and #leftZones > 0 then
            for _, zone in ipairs(leftZones) do
                if zone.data and zone.data.id then
                    print("[TRACE] [Polyzone] Exited zone: " .. zone.data.id)
                    TriggerEvent('Polyzone:Exit', zone.data.id, testedPoint, insideZones, zone.data)
                end
            end
        end
    end)
end

function AddZoneAfterCreation(id, zoneData)
    if not wCombozone then
        print("[TRACE] [Polyzone] Attempted to add zone before ComboZone exists: " .. id)
        return
    end

    print("[TRACE] [Polyzone] Adding zone to ComboZone dynamically: " .. id)
    local zone = CreateZoneForCombo(id, zoneData)

    if zone then
        wCombozone:addZone(zone)
        print("[TRACE] [Polyzone] Zone added to ComboZone: " .. id)
    else
        print("[TRACE] [Polyzone] Zone creation failed during dynamic add: " .. id)
    end
end

-- POLYZONE API
_POLYZONE = {
    Create = {
        Box = function(self, id, center, length, width, options, data)
            print("[TRACE] [Polyzone] Creating BOX zone: " .. id)
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
            print("[TRACE] [Polyzone] Creating POLY zone: " .. id)
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
            print("[TRACE] [Polyzone] Creating CIRCLE zone: " .. id)
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
            print("[TRACE] [Polyzone] Removing zone: " .. id)
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