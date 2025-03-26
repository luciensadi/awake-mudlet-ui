awake = awake or {}
awake.infoPanel = awake.infoPanel or {}
awake.infoPanel.bolts = awake.infoPanel.bolts or {}
awake.infoPanel.conditionStyles = awake.infoPanel.conditionStyles or {}

function awake.infoPanel.setSizeOnResize()
  if awake.layout.lowerInfoPanel == nil then
    return
  end
  
  local x = assert(awake.layout.lowerInfoPanel.get_x)()
  local y = assert(awake.layout.lowerInfoPanel.get_y)()
  local w = assert(awake.layout.lowerInfoPanel.get_width)()
  local h = assert(awake.layout.lowerInfoPanel.get_height)()
  
  awake.infoPanel.bolts[2]:move((w - 18).."px", "0px")
  awake.infoPanel.bolts[3]:move((w - 18).."px", (h - 18).."px")
  awake.infoPanel.bolts[4]:move("0px", (h - 18).."px")
end

function awake.infoPanel.setup()
  awake.setup.registerEventHandler("sysWindowResizeEvent", function()
    awake.infoPanel.setSizeOnResize()
  end)
  
  awake.infoPanel.bolts[1] = Geyser.Label:new({
    x = 0, y = 0,
    width = 18, height = 18,
  }, awake.layout.lowerInfoPanel)
  awake.infoPanel.bolts[1]:setStyleSheet([[
    background-color: rgba(0,0,0,0%);
  ]])
  awake.infoPanel.bolts[1]:setBackgroundImage(getMudletHomeDir() .. "/awake-ui/bolt-tl.png")
  awake.infoPanel.bolts[1]:raiseAll()
  
  
  awake.infoPanel.bolts[2] = Geyser.Label:new({
    y = 0,
    width = 18, height = 18,
  }, awake.layout.lowerInfoPanel)
  awake.infoPanel.bolts[2]:setStyleSheet([[
    background-color: rgba(0,0,0,0%);
  ]])
  awake.infoPanel.bolts[2]:setBackgroundImage(getMudletHomeDir() .. "/awake-ui/bolt-tr.png")
  awake.infoPanel.bolts[2]:raiseAll()
  
  awake.infoPanel.bolts[3] = Geyser.Label:new({
    width = 18, height = 18,
  }, awake.layout.lowerInfoPanel)
  awake.infoPanel.bolts[3]:setStyleSheet([[
    background-color: rgba(0,0,0,0%);
  ]])
  awake.infoPanel.bolts[3]:setBackgroundImage(getMudletHomeDir() .. "/awake-ui/bolt-br.png")
  awake.infoPanel.bolts[3]:raiseAll()
  
  awake.infoPanel.bolts[4] = Geyser.Label:new({
    width = 18, height = 18,
  }, awake.layout.lowerInfoPanel)
  awake.infoPanel.bolts[4]:setStyleSheet([[
    background-color: rgba(0,0,0,0%);
  ]])
  awake.infoPanel.bolts[4]:setBackgroundImage(getMudletHomeDir() .. "/awake-ui/bolt-bl.png")
  awake.infoPanel.bolts[4]:raiseAll()
  
  awake.infoPanel.setSizeOnResize()
  
  awake.infoPanel.credstik.setup()
  awake.infoPanel.condition.setup()
end