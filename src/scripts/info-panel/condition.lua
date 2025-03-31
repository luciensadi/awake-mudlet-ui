awake = awake or {}
awake.infoPanel = awake.infoPanel or {}
awake.infoPanel.condition = awake.infoPanel.condition or {}
awake.infoPanel.condition.styles = awake.infoPanel.condition.styles or {}

function awake.infoPanel.condition.setup()
  -- Shared styles
  local filledStyle = [[
    background-color: red;
    border: 1px solid white;
    margin: 1px;
  ]]
  local altFilledStyle = [[
    background-color: blue;
    border: 1px solid white;
    margin: 1px;
  ]]
  local emptyStyle = [[
    background-color: black;
    border: 1px solid white;
    margin: 1px;
  ]]
  
  -- Store styles for reuse in update function
  awake.infoPanel.condition.styles = {
    filled = filledStyle,
    altFilled = altFilledStyle,
    empty = emptyStyle
  }
  
  awake.infoPanel.condition.createMonitor(awake.layout.lowerInfoPanel, "230px", 6, "MENTAL", "mental")
  awake.infoPanel.condition.createMonitor(awake.layout.lowerInfoPanel, "230px", 40, "PHYSICAL", "physical")
end

function awake.infoPanel.condition.createMonitor(container, x, y, label, varName)
  healthContainer = Geyser.Label:new({
    name = varName .. "Container",
    x = x, y = y, width = "90%", height = 20
  }, container)
    -- Makes it transparent
  healthContainer:setStyleSheet([[
    background-color: rgba(0,0,0,0%); 
  ]])
  healthContainer:raiseAll()
  
  -- Add the label
  local conditionLabel = Geyser.Label:new({
    name = varName .. "Label",
    x = 0, y = 0, width = "60", height = "100%",
  }, healthContainer)
  -- Makes it transparent
  conditionLabel:setStyleSheet([[
    background-color: rgba(0,0,0,0%); 
  ]])
  conditionLabel:setFontSize(10)
  conditionLabel:setAlignment("left")
  conditionLabel:raiseAll()
  conditionLabel:echo(label)
  
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
    -- Makes it transparent
    healthBoxes[i]:setStyleSheet([[
      background-color: rgba(0,0,0,0%); 
    ]])
    healthBoxes[i]:raiseAll()
    healthBoxes[i]:setStyleSheet(awake.infoPanel.condition.styles.empty)
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
      local style = awake.infoPanel.condition.styles.empty
      if i <= filled and varName == "mental" then
        style = awake.infoPanel.condition.styles.altFilled
      elseif i <= filled then
        style = awake.infoPanel.condition.styles.filled
      end
      boxes[i]:setStyleSheet(style)
    end
  end
  awake.setup.registerEventHandler("gmcp.Char.Vitals", doUpdate)
end