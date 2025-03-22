awake = awake or {}
awake.matrix = awake.matrix or {
  debug = true,
  hostTable = {},
  lastConnectAddress = ""
}

local MAX_BUTTONS = 32

local dataFileName = getMudletHomeDir().."/matrix.db"
function awake.matrix.setup()
  awake.matrix.container = Geyser.Label:new({
    name = "matrix",
    x = 0, y = 0,
    width = "100%",
    height = "100%",
  }, awake.layout.upperContainer)
  awake.matrix.container:setBackgroundImage(getMudletHomeDir() .. "/awake-ui/matrix.jpg")
  -- This seems necessary when recreating the UI after upgrading the package.
  awake.matrix.container:raiseAll()
  
  awake.matrix.nodeLabel = Geyser.Label:new({
    name = "nodeLabel",
    x = "0%", y = "0%",
    width = "100%", height="10%"
  }, awake.matrix.container)
  awake.matrix.nodeLabel:echo("<center>Seattle LTG</center>")
  awake.matrix.nodeLabel:setStyleSheet([[
    background-color: rgba(0,0,0,60%);
  ]])
  
  -- This grid container holds the addresses 
  awake.matrix.gridContainer = Geyser.Label:new({
    name = "matrixGrid",
    x = "0%", y = "15%",
    width = "100%",
    height = "85%"
  }, awake.matrix.container)
  awake.matrix.gridContainer:setStyleSheet([[
    background-color: rgba(0,0,0, 0%);
  ]])
  
  -- You can't delete GUI elements once they're created AFAIK
  -- So we'll create all our buttons now.
  local columns = 5               -- number of columns in the grid
  local buttonWidth = 100         -- width in pixels (adjust as needed)
  local buttonHeight = 32         -- height in pixels (adjust as needed)
  local spacingX = 10             -- horizontal spacing between buttons
  local spacingY = 10             -- vertical spacing between buttons

  -- Calculate number of rows and container dimensions
  local rows = math.ceil(MAX_BUTTONS / columns)
  
  -- Loop through the objects and create a button for each
  awake.matrix.buttons = {}
  for i = 1, MAX_BUTTONS do
    local row = math.floor((i - 1) / columns)
    local col = (i - 1) % columns
    local xPos = (spacingX * 3) + col * (buttonWidth + spacingX)
    local yPos = row * (buttonHeight + spacingY)

    local btnName = "gridButton" .. i
    local btn = Geyser.Button:new({
      name = btnName,
      x = tostring(xPos) .. "px",
      y = tostring(yPos) .. "px",
      width = tostring(buttonWidth) .. "px",
      height = tostring(buttonHeight) .. "px",
      msg = "<center>Addr#" .. i .. "</center>"
    }, awake.matrix.gridContainer)

    -- Apply semi-transparent style (white with 50% opacity)
    btn:setStyleSheet([[
      background-color: rgba(0,0,0, 80%);
      border: 1px solid #00aaaa;
      font-family: "Bitstream Vera Sans Mono";
    ]])
    
    btn:hide()    
    awake.matrix.buttons[btnName] = btn
  end
  
  if io.exists(dataFileName) then
    table.load(dataFileName, awake.matrix.data)
    awake.matrix.log("Loaded map data.")
    awake.matrix.drawSystems()
  end
  
  awake.matrix.container:hide()
  
  local function doUpdate()
    if not gmcp or not gmcp.Matrix or tostring(gmcp.Matrix.Info) == "null" then
      -- gmcp.Matrix.Info is equal to {} when we're not in the matrix
      -- the mud will send that on logoff or dumpshock
      awake.mapper.activate()
      return
    elseif awake.matrix.currentHost ~= nil and awake.matrix.currentHost.vnum == gmcpVarByPath("Matrix.Info.vnum") then
      -- Sometimes we get double messages; just discard
      return
    end
    -- Set up some variables we'll need later
    local hostName = gmcpVarByPath("Matrix.Info.name")
    local hostVnum = gmcpVarByPath("Matrix.Info.vnum")
    local lastVnum = nil
    local lastName = nil
    if awake.matrix.currentHost ~= nil then
      lastVnum = awake.matrix.currentHost.vnum
      lastName = awake.matrix.currentHost.name
    end
    
    -- Safe to call this multiple times
    awake.matrix.activate()
    awake.matrix.nodeLabel:echo("<center>"..hostName.."</center>")
    awake.matrix.lastHost = awake.matrix.currentHost
    awake.matrix.currentHost = {
      ["vnum"] = hostVnum, 
      ["name"] = hostName
    }
    awake.matrix.logDebug("Entered new host <yellow>"..hostName.."<reset>.")
    
    -- When we encounter a host for the first time we add it to the hostTable
    -- This is our local 'address book'
    if not awake.matrix.hostTable[hostVnum] then
      awake.matrix.logDebug("Adding new host <yellow>"..hostName.."<reset>")
      awake.matrix.hostTable[hostVnum] = {
        ["vnum"] = hostVnum, 
        ["name"] = hostName,
        ["addresses"] = {}
      }
    end
    
    -- The code that handles discovering addresses
    if awake.matrix.lastConnectAddress ~= "" then
      if lastVnum ~= nil and not awake.matrix.hostTable[lastVnum].addresses[awake.matrix.lastConnectAddress] then
        -- Add this as an address connection to our host
        awake.matrix.logDebug("Registering address <yellow>"..awake.matrix.lastConnectAddress.."<reset> to host <yellow>"..hostName.."<reset>.")
        awake.matrix.hostTable[lastVnum].addresses[awake.matrix.lastConnectAddress] = hostVnum
      end
      awake.matrix.lastConnectAddress = ""
      disableTrigger("connect-host")
    end
    
    -- Hide all the buttons
    for i = 1, MAX_BUTTONS do
      local btnName = "gridButton" .. i
      local btn = awake.matrix.buttons[btnName]
      btn:hide()
    end
    
    -- The code that renders our current addresses
    local curHost = awake.matrix.hostTable[hostVnum]
    local count = 0
    for key, value in pairs(curHost.addresses) do
      count = count + 1
      local btnName = "gridButton" .. count
      local btn = awake.matrix.buttons[btnName]
      
      btn:show()
      btn:raiseAll()
      btn:echo("<center>"..key.."</center>")
      btn:setToolTip("Connect to "..awake.matrix.hostTable[value].name, "10")
      btn:setClickCallback("awake.matrix.handleDoConnect", key)
    end
  end
  awake.setup.registerEventHandler("gmcp.Matrix.Info", doUpdate)
  awake.setup.registerEventHandler("sysDataSendRequest", awake.matrix.handleSentCommand)
end

function awake.matrix.handleDoConnect(address)
   send("connect "..address, false)
end

-- Track the most recent connect command so we know which direction we moved when automapping
function awake.matrix.handleSentCommand(event, cmd)
  -- If we're not connected to the matrix, don't bother
  if not gmcp or not gmcp.Matrix or tostring(gmcp.Matrix.Info) == "null" then
    return
  end
  
  local host = rex.match(cmd, [[co(?:n(?:n(?:e(?:c(?:t)?)?)?)?)? (.+)]])
  if host ~= nil then
    awake.matrix.logDebug("User is trying to connect to a host named <yellow>"..host.."<reset>")
    awake.matrix.lastConnectAddress = trim(host)
    enableTrigger("connect-host")
  end
end

function awake.matrix.activate()
  geyserMapper:hide()
  awake.matrix.container:show()
  awake.matrix.container:raiseAll()
end

function awake.matrix.log(text)
  cecho("[<cyan>Awake Matrix Map<reset>] "..text.."\n")
end

function awake.matrix.logDebug(text)
  -- if awake.matrix.debug then
    awake.matrix.log("<green>Debug:<reset> "..text)
  -- end
end

function awake.matrix.logError(text)
  awake.matrix.log("<red>Error:<reset> "..text)
end

function awake.matrix.resetData()
end

