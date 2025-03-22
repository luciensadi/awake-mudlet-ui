awake = awake or {}
awake.infoPanel = awake.infoPanel or {}
awake.infoPanel.conditionStyles = awake.infoPanel.conditionStyles or {}


function awake.infoPanel.setup()
  local basicStatsContainer = Geyser.Label:new({
    h_stretch_factor = 0.9
  }, awake.layout.lowerInfoPanel)
  local combatContainer = Geyser.Label:new({
    h_stretch_factor = 0.9
  }, awake.layout.lowerInfoPanel)

  awake.infoPanel.createBasicStats(basicStatsContainer)
end

function awake.infoPanel.createConditionMonitor(container, x, y, label, varName)
  healthContainer = Geyser.Label:new({
    name = varName .. "Container",
    x = x, y = y, width = "90%", height = 20
  }, container)
  healthContainer:raiseAll()
  
  -- Add the label
  conditionLabel = Geyser.Label:new({
    name = varName .. "Label",
    x = 0, y = 0, width = "60", height = "100%",
  }, healthContainer)
  conditionLabel:raiseAll()

  conditionLabel:echo(label)
  conditionLabel:setStyleSheet([[
    color: white;
    font-weight: bold;
    padding: 0 4px;
  ]])
  
  -- Calculate where the first box should start
  local boxStartX = 66
  local boxWidth = 20
  awake.infoPanel[varName .. "Boxes"] = {}
  local healthBoxes = awake.infoPanel[varName .. "Boxes"]
  
  -- Create 10 health boxes with manual positioning
  for i = 1, 10 do
    local xOffset = boxStartX + (i - 1) * (boxWidth + 2)
    healthBoxes[i] = Geyser.Label:new({
      name = varName .. "Box" .. i,
      x = xOffset, y = 0, width = boxWidth, height = boxWidth,
    }, healthContainer)
    
    healthBoxes[i]:raiseAll()
    healthBoxes[i]:setStyleSheet(awake.infoPanel.conditionStyles.empty)
  end
  
  local function doUpdate()
    if not gmcp or not gmcp.Char or not gmcp.Char.Vitals then
      return  
    end
    local current = (gmcpVarByPath("Char.Vitals." .. varName) or 0) / 100
    local max = (gmcpVarByPath("Char.Vitals." .. varName .. "_max") or 0) / 100
    local filled = math.floor((current / max) * 10 + 0.5)
    local boxes = awake.infoPanel[varName .. "Boxes"]
    for i = 1, 10 do
      local style = (i <= filled) and awake.infoPanel.conditionStyles.filled or awake.infoPanel.conditionStyles.empty
      boxes[i]:setStyleSheet(style)
    end
  end
  awake.setup.registerEventHandler("gmcp.Char.Vitals", doUpdate)
end

function awake.infoPanel.createBasicStats(container)
  -- Shared styles
  local filledStyle = [[
    background-color: red;
    border: 1px solid white;
    margin: 1px;
  ]]
  local emptyStyle = [[
    background-color: black;
    border: 1px solid white;
    margin: 1px;
  ]]
  
  -- Store styles for reuse in update function
  awake.infoPanel.conditionStyles = {
    filled = filledStyle,
    empty = emptyStyle
  }
  
  awake.infoPanel.createConditionMonitor(container, "5%", 3, "Mental", "mental")
  awake.infoPanel.createConditionMonitor(container, "5%", 28, "Physical", "physical")
end