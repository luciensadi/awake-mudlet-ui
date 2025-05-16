mudlet = mudlet or {}; mudlet.mapper_script = true
awake = awake or {}
awake.mapper = awake.mapper or {}

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
    geyserMapper:raiseAll()
  end
  setMapZoom(15)

  local hasAnyAreas = false
  for name, id in pairs(getAreaTable()) do
    if name ~= "Default Area" then
      hasAnyAreas = true
    end
  end
  if not hasAnyAreas then
    -- Reset the map just in case
    awake.mapper.resetMap()
    -- Load the JSON file
    loadJsonMap(getMudletHomeDir().."/awake-ui/starter-map.json")
  end

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
  if awake.mapper.mappingArea == nil then
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

-- Function used to handle a room that we've moved into. This will use the data on
-- awake.mapper.current, compared with awake.mapper.last, to potentially create a new room and
-- link it with an exit on the previous room.
function awake.mapper.processCurrentRoom()
  local vnum = awake.mapper.current.vnum
  local moveDir = awake.mapper.popMoveDir() -- This is the direction we typed to get here
  local room = awake.mapper.getRoomByVnum(vnum)

  if awake.mapper.mappingArea == nil and room == nil then
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
    setRoomArea(vnum, areaTable[trim(awake.mapper.mappingArea)])
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
    awake.mapper.lastMoveDirs = {}
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
    exits = gmcp.Room.Info.exits or {}
  }
  
  awake.mapper.processCurrentRoom()
end


------------------------------------------------------------------------------
-- Utility Functions
------------------------------------------------------------------------------
function awake.mapper.activate()
  awake.matrix.container:hide()
  geyserMapper:show()
  geyserMapper:raiseAll()
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
