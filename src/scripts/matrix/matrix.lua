awake = awake or {}
awake.matrix = awake.matrix or {
  data = {
  }
}

local dataFileName = getMudletHomeDir().."/matrix"
function awake.matrix.setup()
  awake.matrix.container = Geyser.Label:new({
    name = "matrix",
    x = 0, y = 0,
    width = "100%",
    height = "100%",
  }, awake.layout.upperContainer)
  awake.matrix.container:setBackgroundImage(getMudletHomeDir().."/@PKGNAME@/matrix.jpg")
  -- This seems necessary when recreating the UI after upgrading the package.
  awake.matrix.container:raiseAll()
  
  awake.matrix.nodeLabel = Geyser.Label:new({
    name = "nodeLabel",
    x = "0%", y = "0%",
    width = "100%", height="20%"
  }, awake.matrix.container)
  awake.matrix.nodeLabel:echo("<center>Seattle LTG</center>")
  
  -- This grid container holds the addresses 
  awake.matrix.gridContainer = Geyser.Label:new({
    name = "matrixGrid",
    x = "0%", y = "20%",
    width = "100%",
    height = "80%"
  }, awake.matrix.container)
  
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
    local xPos = spacingX + col * (buttonWidth + spacingX)
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
    btn:setStyleSheet("background-color: rgba(255, 255, 255, 0.5);")
  end
  
  if io.exists(dataFileName) then
    table.load(dataFileName, awake.matrix.data)
    awake.matrix.log("Loaded map data.")
    awake.matrix.drawSystems()
  end
  
  awake.matrix.container:hide()
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

