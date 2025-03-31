awake = awake or {}
awake.mapper = awake.mapper or {}

------------------------------------------------------------------------------
-- Command Handlers
------------------------------------------------------------------------------

-- Main "map" command handler
function awake.mapper.mapCommand(input)
  input = trim(input)
  if #input == 0 then
    awake.mapper.printMainMenu()
    return
  end

  _, _, cmd, args = string.find(input, "([^%s]+)%s*(.*)")
  cmd = string.lower(cmd)

  if cmd == "help" then
    awake.mapper.printHelp()
  elseif cmd == "start" then
    awake.mapper.startMapping(args)
  elseif cmd == "stop" then
    awake.mapper.stopMapping()
  elseif cmd == "search" then
    awake.mapper.search(args)
  elseif cmd == "delete" then
    _, _, subcmd, args = string.find(args, "([^%s]+)%s*(.*)")
    subcmd = string.lower(subcmd)
    
    if subcmd == "area" then
      awake.mapper.deleteArea(args)
    elseif subcmd == "room" then
      awake.mapper.deleteRoom(args)
    elseif subcmd == "map" then
      awake.mapper.resetMap(args)
    else
      awake.mapper.logError("Unknown map delete command. Try <yellow>map help<reset>.")
    end
  elseif cmd == "shift" then
    awake.mapper.shiftCurrentRoom(args)
  elseif cmd == "save" then
    awake.mapper.saveMap()
  else
    awake.mapper.logError("Unknown map command. Try <yellow>map help<reset>.")
  end
end

function awake.mapper.shiftCurrentRoom(direction)
  direction = trim(direction)
  if #direction == 0 then
    awake.mapper.log("Syntax: map shift <yellow><direction><reset>")
    return
  end

  local dir = dirObj(direction)
  if dir == nil then
    awake.mapper.logError("Direction unknown: <yellow>"..direction.."<reset>")
    return
  end

  local vnum = awake.mapper.current.vnum
  local room = awake.mapper.getRoomByVnum(vnum)
  if room ~= nil then
    currentX, currentY, currentZ = getRoomCoordinates(vnum)
    dx, dy, dz = unpack(dir.xyzDiff)
    setRoomCoordinates(vnum, currentX+dx, currentY+dy, currentZ+dz)
    updateMap()
    centerview(vnum)
  end
end


function awake.mapper.printMainMenu()
  awake.mapper.log("Mapper Introduction and Status")
  cecho([[

The AwakeMUD Mapper plugin tracks movement using GMCP variables. To begin, try <yellow>map start <current area><reset>.
Once mapping is started, move <red>slowly<reset> between rooms to map them. Moving too quickly will cause the
mapper to skip rooms. You should wait for the map to reflect your movements before moving again
whenever you are in mapping mode.

When you are finished mapping, use <yellow>map stop<reset> to stop recording your movements, and be sure to
<yellow>map save<reset>! Map data will not be saved automatically.

Other commands are available to adjust mapping as you go. <yellow>map shift <direction><reset>, for example,
will move your current room. See <yellow>map help<reset> for a full list of available commands.

The map GUI also offers editing functionality and is ideal for moving groups of rooms, deleting
or coloring rooms, etc.

]])

  if awake.mapper.mapping then
    cecho("Mapper status: <green>Mapping<reset> in <yellow>"..awake.mapper.mappingArea.."<reset>\n")
  else
    cecho("Mapper status: <red>Off<reset>\n")
  end
end


function awake.mapper.printHelp()
  awake.mapper.log("Mapper Command List")
  cecho([[

Syntax:  <yellow>map start [area_name]  <reset>=> Starts mapping an existing or new area
         <yellow>map stop               <reset>=> Stops mapping
         <yellow>map save               <reset>=> Saves map changes to disk
         <yellow>map shift <dir>        <reset>=> Shifts the current room in the map in the direction specified
         <yellow>map delete room        <reset>=> Deletes the current room from the map/area
         <yellow>map delete area <name> <reset>=> Deletes a specific area by name
         <yellow>map delete map         <reset>=> Deletes the ENTIRE map and resets EVERYTHING
         <yellow>map search <word>      <reset>=> Searches the map for a room containing <word>
         

<yellow>Note:<reset> Arguments surrounded by [brackets] are optional.
]])

end

local function rightPad(str, len, char)
    char = char or ' ' -- default padding is space if not provided
    return string.rep(char, len - #str) .. str
end

function awake.mapper.search(searchTerm)
  awake.mapper.log("Searching for rooms containing '"..searchTerm.."'...")
  
  -- Normalize the search term for case-insensitive matching
  local searchTermLower = string.lower(searchTerm)

  -- Iterate over each room in the global rooms table.
  local found = 0
  for aName, aNum in pairs(getAreaTable()) do
    local printedArea = false
    for _, rNum in ipairs(getAreaRooms(aNum)) do
      local roomName = getRoomName(rNum)
      if string.find(string.lower(roomName), searchTermLower) then
        if not printedArea then
          cecho("Area: <yellow>"..aName.."<reset>\n")
          printedArea = true
        end
        cecho("  [<green>"..rightPad(tostring(rNum), 8).."<reset>] "..roomName.."\n")
        found = found + 1
      end
    end
  end
  
  if found <= 0 then
    awake.mapper.log("No results found; sorry!")
  else
    awake.mapper.log("Found "..found.." rooms containing that search term.")
  end
end

function awake.mapper.startMapping(areaName)
  areaName = trim(areaName)
  if #areaName == 0 then
    awake.mapper.log("Syntax: map start <yellow><area name><reset>")
    return
  elseif awake.mapper.mappingArea ~= nil then
    awake.mapper.logError("Mapper already running in <yellow>"..awake.mapper.mappingArea.."<reset>.")
    return
  end
  
  local areaTable = getAreaTable()
  if areaTable[areaName] == nil then
    addAreaName(areaName)
    awake.mapper.log("Mapping in new area <yellow>"..areaName.."<reset>.")
  else
    awake.mapper.log("Mapping in existing area <yellow>"..areaName.."<reset>.")
  end
  
  awake.mapper.mappingArea = areaName
  awake.mapper.lastMoveDirs = {}
  awake.mapper.processCurrentRoom()
end


function awake.mapper.stopMapping()
  if awake.mapper.mappingArea == nil then
    awake.mapper.logError("Mapper not running.")
    return
  end
  
  awake.mapper.mappingArea = nil
  awake.mapper.lastMoveDirs = nil
  awake.mapper.log("Mapping <red>stopped<reset>. Don't forget to <yellow>map save<reset>!")
end

function awake.mapper.resetMap()
  for name, id in pairs(getAreaTable()) do
    deleteArea(name)
    awake.mapper.log("Area <yellow>"..name.."<reset> deleted.")
  end
  awake.mapper.log("Map has been reset.")
end

function awake.mapper.deleteRoom()
  if awake.mapper.mappingArea == nil then
    awake.mapper.logError("Mapper not running.")
    return
  end
  
  deleteRoom(awake.mapper.current.vnum)
  awake.mapper.log("Room <yellow>"..awake.mapper.current.name.."<reset> deleted.")
end

function awake.mapper.deleteArea(areaName)
  areaName = trim(areaName)
  if #areaName == 0 then
    awake.mapper.log("Syntax: map delete area <yellow><area name><reset>")
    return
  end

  local areaTable = getAreaTable()
  if areaTable[areaName] == nil then
    awake.mapper.logError("Area <yellow>"..areaName.."<reset> does not exist.")
    return
  end
  
  if awake.mapper.mappingArea == areaName then
    awake.mapper.stopMapping()
  end

  deleteArea(areaName)
  awake.mapper.log("Area <yellow>"..areaName.."<reset> deleted.")
end

function awake.mapper.saveMap()
  saveJsonMap(getMudletHomeDir() .. "/map.json")
  awake.mapper.log("Map saved.")
end