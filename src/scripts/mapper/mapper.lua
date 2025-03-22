mudlet = mudlet or {}; mudlet.mapper_script = true
awake = awake or {}
awake.mapper = awake.mapper or {}


local dirs = {}
-- The order of these is important. The indices of the directions must match
-- https://github.com/Mudlet/Mudlet/blob/9c13f8f946f5b82c0c2e817dab5f42588cee17e0/src/TRoom.h#L38
table.insert(dirs, {short="n",  long="north",     rev="s",  xyzDiff = { 0, 1, 0}})
table.insert(dirs, {short="ne", long="northeast", rev="sw", xyzDiff = { 1, 1, 0}})
table.insert(dirs, {short="nw", long="northwest", rev="se", xyzDiff = {-1, 1, 0}})
table.insert(dirs, {short="e",  long="east",      rev="w",  xyzDiff = { 1, 0, 0}})
table.insert(dirs, {short="w",  long="west",      rev="e",  xyzDiff = {-1, 0, 0}})
table.insert(dirs, {short="s",  long="south",     rev="n",  xyzDiff = { 0,-1, 0}})
table.insert(dirs, {short="se", long="southeast", rev="nw", xyzDiff = { 1,-1, 0}})
table.insert(dirs, {short="sw", long="southwest", rev="ne", xyzDiff = {-1,-1, 0}})
table.insert(dirs, {short="u",  long="up",        rev="d",  xyzDiff = { 0, 0, 1}})
table.insert(dirs, {short="d",  long="down",      rev="u",  xyzDiff = { 0, 0,-1}})

-- Given a direction short or long name, or a direction number, return an object representing it.
local function dirObj(arg)
  if dirs[arg] ~= nil then
    return dirs[arg]
  end

  for _, dir in ipairs(dirs) do
    if arg == dir.short or arg == dir.long then
      return dir
    end
  end
  return nil
end

-- Given a direction short or long name, or a direction number, return an object representing its opposite
local function revDirObj(arg)
  local dir = dirObj(arg)
  if dir ~= nil then
    return dirObj(dir.rev)
  end
  return nil
end

local function trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end


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
  elseif cmd == "deletearea" then
    awake.mapper.deleteArea(args)
  elseif cmd == "shift" then
    awake.mapper.shiftCurrentRoom(args)
  elseif cmd == "save" then
    awake.mapper.saveMap()
  elseif cmd == "setroomcoords" then
    awake.mapper.setRoomCoords(args)
  elseif cmd == "reset" then
    awake.mapper.resetMap()
  else
    awake.mapper.logError("Unknown map command. Try <yellow>map help<reset>.")
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
    cecho("Mapper status: <green>Mapping<reset> in zone <yellow>"..awake.mapper.mapping.."<reset>\n")
  else
    cecho("Mapper status: <red>Off<reset>\n")
  end
end


function awake.mapper.printHelp()
  awake.mapper.log("Mapper Command List")
  cecho([[

<yellow>map start [<area name>]<reset>

Begin mapping. Any new rooms you enter while mapping will be added to this area name, so you
should be sure to stop mapping before entering a ship or moving to a different planet. No area
name argument is required if you're on a planet, as we'll default to the planet name.

Some tips to remember:
 - Use a light while mapping. Entering a dark room where you can't see will not update the map.
 - Use <yellow>map shift<reset> to adjust room positioning, especially after going through turbolifts or
   voice-activated doors. It's faster to click-and-drag with the GUI to move large blocks of
   rooms, though.
 - Rooms in ships are all unique, even if they are the same model. In practice, mapping ships
   really isn't supported yet, although platforms or ships you use frequently may be worth it.

<yellow>map stop<reset>

Stop editing the map based on your movements.

<yellow>map save<reset>

Save the map to the map.dat file in your Mudlet profile's directory.

<yellow>map deletearea <area name><reset>

Deletes all data for an area. There's no confirmation and no undo!

<yellow>map reset<reset>

Deletes ALL map data!!!
]])

end


function awake.mapper.startMapping(areaName)
  if awake.mapper.mapping then
    awake.mapper.log("The mapping system is already active.")
    return
  end
  
  awake.mapper.mapping = true
  awake.mapper.lastMoveDirs = {}
  awake.mapper.processCurrentZone()
  awake.mapper.processCurrentRoom()
end


function awake.mapper.stopMapping()
  if not awake.mapper.mapping then
    awake.mapper.logError("Mapper not running.")
    return
  end
  awake.mapper.mapping = false
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

function awake.mapper.deleteArea(areaName)
  areaName = trim(areaName)
  if #areaName == 0 then
    awake.mapper.log("Syntax: map deletearea <yellow><area name><reset>")
    return
  end

  local areaTable = getAreaTable()
  if areaTable[areaName] == nil then
    awake.mapper.logError("Area <yellow>"..areaName.."<reset> does not exist.")
    return
  end

  deleteArea(areaName)
  awake.mapper.log("Area <yellow>"..areaName.."<reset> deleted.")
end


function awake.mapper.saveMap()
  saveMap(getMudletHomeDir() .. "/map.dat")
  awake.mapper.log("Map saved.")
end


function awake.mapper.setRoomCoords(areaName)
  if not gmcp.Char.Info.immLevel or gmcp.Char.Info.immLevel < 102 then
    awake.mapper.logError("This command only works for imm characters.")
    return
  end
  
  local areaId = getAreaTable()[areaName]
  if not areaId then
    awake.mapper.logError("Area not found by name "..areaName)
    return
  end
  
  for _, roomId in ipairs(getAreaRooms(areaId)) do
    local x, y, z = getRoomCoordinates(roomId)
    send("at "..roomId.." redit xyz "..x.." "..y.." "..z)
  end
end  


------------------------------------------------------------------------------
-- Event Handlers
------------------------------------------------------------------------------


function awake.mapper.setup()
  if not geyserMapper then
    -- Preserve this as a global. We can only create one mapper in a profile, so if we
    -- unload and reload this UI, we need to reuse what was created before.
    geyserMapper = Geyser.Mapper:new({
      x = 0, y = 0,
      width = "100%",
      height = "100%",
    }, awake.layout.upperContainer)
  else
    -- awake.layout.upperRightTabData.contents["map"]:add(geyserMapper)
    geyserMapper:raiseAll()
  end
  setMapZoom(15)

  -- local hasAnyAreas = false
  -- for name, id in pairs(getAreaTable()) do
    -- if name ~= "Default Area" then
      -- hasAnyAreas = true
    -- end
  -- end
  -- if not hasAnyAreas then
    -- loadMap(getMudletHomeDir().."/awake-ui/starter-map.dat")
  -- end

  awake.setup.registerEventHandler("sysDataSendRequest", awake.mapper.handleSentCommand)
  awake.setup.registerEventHandler("gmcp.Room.Info", awake.mapper.onEnterRoom)
end

function awake.mapper.teardown()
  awake.layout.upperContainer:remove(geyserMapper)
  geyserMapper:hide()
end


-- Track the most recent movement command so we know which direction we moved when automapping
function awake.mapper.handleSentCommand(event, cmd)
  -- If we're not mapping, don't bother
  if not awake.mapper.mapping then
    return
  end

  local dir = dirObj(trim(cmd))
  if dir ~= nil then
    awake.mapper.lastMoveDirs = awake.mapper.lastMoveDirs or {}
    table.insert(awake.mapper.lastMoveDirs, dir)
    awake.mapper.logDebug("Pushed movement dir: "..dir.long)
  end
end


function awake.mapper.popMoveDir()
  if not awake.mapper.lastMoveDirs or #awake.mapper.lastMoveDirs == 0 then
    awake.mapper.logDebug("Popped movement dir: nil")
    return nil
  end
  local result = table.remove(awake.mapper.lastMoveDirs, 1)
  awake.mapper.logDebug("Popped movement dir: "..result.long)
  return result
end

function awake.mapper.findExitByDirection(room, direction)
  if not room or not room.exits then
    return nil
  end

  for _, exit in ipairs(room.exits) do
    if exit.direction == direction then
      return exit
    end
  end

  return nil
end

function awake.mapper.processCurrentZone()
  if not awake.mapper.mapping then
    return
  end
  
  areaName = trim(awake.mapper.current.zone.name)

  local areaTable = getAreaTable()
  if areaTable[areaName] == nil then
    addAreaName(areaName)
    awake.mapper.logDebug("Mapping in new area <yellow>"..areaName.."<reset>.")
  else
    awake.mapper.logDebug("Mapping in existing area <yellow>"..areaName.."<reset>.")
  end
end

-- Function used to handle a room that we've moved into. This will use the data on
-- awake.mapper.current, compared with awake.mapper.last, to potentially create a new room and
-- link it with an exit on the previous room.
function awake.mapper.processCurrentRoom()
  local vnum = awake.mapper.current.vnum
  local moveDir = awake.mapper.popMoveDir() -- This is the direction we typed to get here
  local room = awake.mapper.getRoomByVnum(vnum)

  if not awake.mapper.mapping and room == nil then
    awake.mapper.logDebug("Room not found, but mapper not running.")
    return
  end

  local lastRoom = nil
  if awake.mapper.last ~= nil then
    lastRoom = awake.mapper.getRoomByVnum(awake.mapper.last.vnum)
    awake.mapper.logDebug("Found last room " .. awake.mapper.last.vnum)
  end

  -- Create the room if we don't have it yet
  if room == nil then
    awake.mapper.logDebug("Added new room: <yellow>"..awake.mapper.current.name.."<reset>")
    addRoom(vnum)
    local areaTable = getAreaTable()
    setRoomArea(vnum, areaTable[trim(awake.mapper.current.zone.name)])
    setRoomCoordinates(vnum, 0, 0, 0)
    setRoomName(vnum, awake.mapper.current.name)
    room = awake.mapper.getRoomByVnum(vnum)

    -- Create stub exits in any known direction we see
    -- for dir, state in pairs(awake.mapper.current.exits) do
    for _, exit in ipairs(awake.mapper.current.exits) do
      local exitDir = dirObj(exit.direction)
      if exitDir ~= nil then
        -- First check if we have the opposing room
        local oppositeRoom = awake.mapper.getRoomByVnum(exit.to)
        if not oppositeRoom then
          -- Stub rooms we don't have in the mapper
          setExitStub(vnum, exitDir.short, true)
        else
          -- If we have the room we can set the exit instead
          setExit(vnum, exit.to, exitDir.short)
          setExit(exit.to, vnum, revDirObj(exit.direction).short)
          setExitStub(exit.to, revDirObj(exit.direction).short, false) -- This clears the stub
        end
        if exit.state == "CLOSED" or exit.state == "INACCESSIBLE" then
          setDoor(vnum, exitDir.short, 2)
        elseif (exit.state == "LOCKED") then
          setDoor(vnum, exitDir.short, 3)
        else
          setDoor(vnum, exitDir.short, 0)
        end
      end
    end
    
    -- Position the room relative to the room we came from
    local lastX, lastY, lastZ = getRoomCoordinates(awake.mapper.last.vnum)
    
    -- If we recorded a valid movement command, use that direction to position this room
    if moveDir ~= nil then
      local dx, dy, dz = unpack(moveDir.xyzDiff)
      awake.mapper.log("Positioning new room "..moveDir.long.." of the previous room based on movement command.")
      setRoomCoordinates(vnum, lastX+dx, lastY+dy, lastZ+dz)
    end
  else
    awake.mapper.logDebug("Found existing room: <yellow>"..getRoomName(vnum).."<reset>")
  end
  
  -- Recalculate all room exits;
  -- AwakeMUD GMCPs include 'to' in exit objects so we can reverse-validate all room exits
  for _, exit in ipairs(awake.mapper.current.exits) do
    local exitDir = dirObj(exit.direction)
    
  end

  centerview(vnum)
end

function awake.mapper.onEnterRoom()
  if not gmcp or not gmcp.Room or not gmcp.Room.Info then
    return
  end
  
  awake.mapper.logDebug("Handling entered room, vnum "..gmcp.Room.Info.vnum)
  if awake.mapper.current ~= nil then
    awake.mapper.last = awake.mapper.current
  end
  
  awake.mapper.current = {
    vnum = gmcp.Room.Info.vnum,
    name = gmcp.Room.Info.name,
    exits = gmcp.Room.Info.exits or {},
    zone = gmcp.Room.Info.zone
  }
  
  awake.mapper.processCurrentZone()
  awake.mapper.processCurrentRoom()
end


------------------------------------------------------------------------------
-- Utility Functions
------------------------------------------------------------------------------


function awake.mapper.log(text)
  cecho("[<cyan>awake Mapper<reset>] "..text.."\n")
end

function awake.mapper.logDebug(text)
  -- if awake.mapper.debug then
    awake.mapper.log("<green>Debug:<reset> "..text)
  -- end
end

function awake.mapper.logError(text)
  awake.mapper.log("<red>Error:<reset> "..text)
end

function awake.mapper.getRoomByVnum(vnum)
  return getRooms()[vnum]
end

function awake.mapper.getRoomByCoords(areaName, x, y, z)
  local areaRooms = getAreaRooms(getAreaTable()[areaName]) or {}
  for _, roomId in pairs(areaRooms) do
    local roomX, roomY, roomZ = getRoomCoordinates(roomId)
    if roomX == x and roomY == y and roomZ == z then
      return roomId
    end
  end
  return nil
end

function doSpeedWalk()
  awake.mapper.log("Speedwalking using these directions: " .. table.concat(speedWalkDir, ", ") .. "\n")
  for _, dir in ipairs(speedWalkDir) do
    send(dir, false)
  end
end
