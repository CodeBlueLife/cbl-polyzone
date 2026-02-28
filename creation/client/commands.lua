RegisterCommand("pzcreate", function(src, args)
  local zoneType = args[1]
  if zoneType == nil then
    TriggerEvent('chat:addMessage', {
      color = { 255, 0, 0},
      multiline = true,
      args = {"Me", "Please add zone type to create (poly, circle, box)!"}
    })
    return
  end
  if zoneType ~= 'poly' and zoneType ~= 'circle' and zoneType ~= 'box' then
    TriggerEvent('chat:addMessage', {
      color = { 255, 0, 0},
      multiline = true,
      args = {"Me", "Zone type must be one of: poly, circle, box"}
    })
    return
  end
  local name = nil
  if #args >= 2 then name = args[2]
  else name = GetUserInput("Enter name of zone:") end
  if name == nil or name == "" then
    TriggerEvent('chat:addMessage', {
      color = { 255, 0, 0},
      multiline = true,
      args = {"Me", "Please add a name!"}
    })
    return
  end
  TriggerEvent("polyzone:pzcreate", zoneType, name, args)
end)

local zoneCommands = {
    pzadd = "polyzone:pzadd",
    pzundo = "polyzone:pzundo",
    pzfinish = "polyzone:pzfinish",
    pzlast = "polyzone:pzlast",
    pzcancel = "polyzone:pzcancel",
    pzcomboinfo = "polyzone:pzcomboinfo",
}

for cmd, eventName in pairs(zoneCommands) do
    RegisterCommand(cmd, function(src, args)
        TriggerEvent(eventName)
    end)
end

local suggestions = {
    {
        cmd = "pzcreate",
        help = "Creates a new zone of the specified type (circle, box, poly)",
        args = {
            {name = "zoneType", help = "The type of zone to create (poly, circle, box)"},
        }
    },
    {
        cmd = "pzadd",
        help = "Adds a point to the current zone being created",
        args = {{}}
    },
    {
        cmd = "pzundo",
        help = "Undoes the last point added to the current zone",
        args = {{}}
    },
    {
        cmd = "pzfinish",
        help = "Finishes and prints the current zone being created",
        args = {{}}
    },
    {
        cmd = "pzlast",
        help = "Re-creates the last zone you finished (only works on BoxZone and CircleZone)",
        args = {{}}
    },
    {
        cmd = "pzcancel",
        help = "Cancels creation of the current zone",
        args = {{}}
    },
    {
        cmd = "pzcomboinfo",
        help = "Prints useful info for all created ComboZones",
        args = {{}}
    }
}

Citizen.CreateThread(function()
    for _, s in ipairs(suggestions) do
        TriggerEvent('chat:addSuggestion', '/' .. s.cmd, s.help, s.args)
    end
end)
