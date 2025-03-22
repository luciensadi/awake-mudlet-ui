awake = awake or {}
awake.matrix = awake.matrix or {
  debug = false,
  hostTable = {
    
  },
  temp = {
    lastConnectAddress = ""
  }
}

local dataFileName = getMudletHomeDir().."/matrix"
function awake.matrix.setup()
  awake.matrix.log(dataFileName)
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
  local maxButtons = 32
  local columns = 5               -- number of columns in the grid
  local buttonWidth = 100         -- width in pixels (adjust as needed)
  local buttonHeight = 32         -- height in pixels (adjust as needed)
  local spacingX = 10             -- horizontal spacing between buttons
  local spacingY = 10             -- vertical spacing between buttons

  -- Calculate number of rows and container dimensions
  local rows = math.ceil(maxButtons / columns)
  
  -- Loop through the objects and create a button for each
  for i = 1, maxButtons do
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
    end
    
    -- Safe to call this multiple times
    awake.matrix.activate()
    awake.matrix.nodeLabel:echo("<center>" .. gmcpVarByPath("Matrix.Info.name") .. "</center>")
    awake.matrix.temp.lastHost = awake.matrix.temp.currentHost
    awake.matrix.temp.currentHost = {
      ["vnum"] = gmcpVarByPath("Matrix.Info.vnum"), 
      ["name"] = gmcpVarByPath("Matrix.Info.name")
    }
    
    if not awake.matrix.hostTable[gmcpVarByPath("Matrix.Info.vnum")] then
      awake.matrix.logDebug("Adding new host <yellow>"..gmcpVarByPath("Matrix.Info.name").."</yellow>")
      awake.matrix.hostTable[gmcpVarByPath("Matrix.Info.vnum")] = {
        ["vnum"] = gmcpVarByPath("Matrix.Info.vnum"), 
        ["name"] = gmcpVarByPath("Matrix.Info.name"),
        ["addresses"] = {}
      }
    end
    
    if awake.matrix.lastConnectAddress ~= "" then
      if awake.matrix.temp.lastHost ~= nil then
        -- Add this as an address connection to our host
        awake.matrix.hostTable[awake.matrix.temp.lastHost.vnum][awake.matrix.lastConnectAddress] = awake.matrix.temp.currentHost.vnum
      end
      awake.matrix.lastConnectAddress = ""
      disableTrigger("connect-host")
    end
  end
  awake.setup.registerEventHandler("gmcp.Matrix.Info", doUpdate)
  awake.setup.registerEventHandler("sysDataSendRequest", awake.matrix.handleSentCommand)
end

-- Track the most recent connect command so we know which direction we moved when automapping
function awake.matrix.handleSentCommand(event, cmd)
  -- If we're not connected to the matrix, don't bother
  if not gmcp or not gmcp.Matrix or tostring(gmcp.Matrix.Info) == "null" then
    return
  end

  local host = cmd:match("^co(n(n(e(c(t)?)?)?)?)? (.+)$")
  if host then
    awake.matrix.logDebug("User is trying to connect to a host named <yellow>"..host.."</yellow>")
    awake.matrix.temp.lastConnectAddress = host
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

function awake.matrix.resetData()
end

