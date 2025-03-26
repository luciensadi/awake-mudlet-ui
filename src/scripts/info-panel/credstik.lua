awake = awake or {}
awake.infoPanel = awake.infoPanel or {}
awake.infoPanel.credstik = awake.infoPanel.credstik or {}

-- function awake.infoPanel.credstik.setSizeOnResize()
  -- if awake.layout.lowerInfoPanel == nil then
    -- return
  -- end
-- end

function awake.infoPanel.credstik.setup()
  local credstik = Geyser.Label:new({
    name = "credstick",
    x = "22px", y = "4px",
    width = "184px", height = "24px",
  }, awake.layout.lowerInfoPanel)
  -- Makes it transparent
  credstik:setStyleSheet([[
    background-color: rgba(0,0,0,0%);
  ]])
  credstik:setBackgroundImage(getMudletHomeDir() .. "/awake-ui/credstik.png")
  credstik:raiseAll()
  awake.infoPanel.credstik.container = credstik
  
  local credstikAmount = Geyser.Label:new({
    x = "40px", y = "0px",
    width = "104px", height = "20px",
    fgColor = "green", -- default text colour
  }, credstik)
  -- Makes it transparent
  credstikAmount:setStyleSheet([[
    background-color: rgba(0,0,0,0%); 
  ]])
  credstikAmount:setFontSize(14)
  credstikAmount:setAlignment("right")
  credstikAmount:setFont("Fixedsys")
  credstikAmount:echo("NIL")
  credstikAmount:raiseAll()
  awake.infoPanel.credstik.label = credstikAmount
  
  local function doUpdate()
    if not gmcp or not gmcp.Char or not gmcp.Char.Vitals then
      return  
    end
    credstikAmount:echo(gmcpVarByPath("Char.Vitals.nuyen"))
  end
  awake.setup.registerEventHandler("gmcp.Char.Vitals", doUpdate)
end