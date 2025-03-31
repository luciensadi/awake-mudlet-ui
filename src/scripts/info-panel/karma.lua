awake = awake or {}
awake.infoPanel = awake.infoPanel or {}
awake.infoPanel.karma = awake.infoPanel.karma or {}

function awake.infoPanel.karma.setup()
local karmaLabel = Geyser.Label:new({
  x = "22px", y = "30px",
  width = "184px", height = "14px",
  -- fgColor = "green",
}, awake.layout.lowerInfoPanel)
-- Makes it transparent
karmaLabel:setStyleSheet([[
  background-color: rgba(0,0,0,0%); 
]])
karmaLabel:setFontSize(10)
karmaLabel:setAlignment("left")
karmaLabel:echo("KARMA")
karmaLabel:raiseAll()

local karmaAmount = Geyser.Label:new({
  x = "22px", y = "46px",
  width = "184px", height = "20px",
  fgColor = "yellow",
}, awake.layout.lowerInfoPanel)
karmaAmount:setStyleSheet([[
  background-color: rgba(0, 0, 0, 100%); 
]])
karmaAmount:setFontSize(10)
karmaAmount:setAlignment("center")
karmaAmount:setFont("Fixedsys")
karmaAmount:echo("-0- / -0-")

local function doUpdate()
  if not gmcp or not gmcp.Char or not gmcp.Char.Vitals then
    return  
  end
  karmaAmount:echo((gmcpVarByPath("Char.Vitals.karma")/100).." / "..gmcpVarByPath("Char.Info.tke"))
end
awake.setup.registerEventHandler("gmcp.Char.Vitals", doUpdate)
end