awake = awake or {}
awake.layout = awake.layout or {}

local rightPanelWidthPct = 35
local upperRightHeightPct = 50

local inactiveTabStyle = [[
  background-color: #333333;
  border: 1px solid #00aaaa;
  margin: 3px 3px 0px 3px;
  font-family: "Bitstream Vera Sans Mono";
]]

local activeTabStyle = [[
  background-color: #336666;
  border: 1px solid #00aaaa;
  border-bottom: none;
  margin: 3px 3px 0px 3px;
  font-family: "Bitstream Vera Sans Mono";
]]


local function createTabbedPanel(tabData, container, tabList)
  tabData.tabs = {}
  tabData.contents = {}

  local tabContainerHeight = getFontSize()*2+4
  local tabContainer = Geyser.HBox:new({
    x = "2%", y = 0,
    width = "96%", height = tabContainerHeight,
  }, container)

  local contentsContainer = Geyser.Label:new({
    x = 0, y = tabContainerHeight,
    width = "100%",
  }, container)

  awake.layout.resizeTabContents(container, tabContainer, contentsContainer)
  awake.setup.registerEventHandler("sysWindowResizeEvent", function()
    awake.layout.resizeTabContents(container, tabContainer, contentsContainer)
  end)

  local totalSpace = 0
  for _, tabInfo in ipairs(tabList) do
    totalSpace = totalSpace + #tabInfo.label + 4 -- Account for 2 characters on either side as padding
  end

  for _, tabInfo in ipairs(tabList) do
    local keyword = tabInfo.keyword
    local label = tabInfo.label
    
    tabData.tabs[keyword] = Geyser.Label:new({
      h_stretch_factor = (#tabInfo.label + 4) / totalSpace,
    }, tabContainer)
    tabData.tabs[keyword]:setClickCallback("awake.layout.selectTab", tabData, keyword)
    tabData.tabs[keyword]:setFontSize(getFontSize())
    tabData.tabs[keyword]:echo("<center>"..label)
    
    tabData.contents[keyword] = Geyser.Label:new({
      x = 0, y = 0,
      width = "100%",
      height = "100%",
    }, contentsContainer)
  end
end

function awake.layout.selectTab(tabData, tabName)
  for _, tab in pairs(tabData.tabs) do
    tab:setStyleSheet(inactiveTabStyle)
    tab:setBold(false)
  end
  for _, contents in pairs(tabData.contents) do
    contents:hide()
  end

  tabData.tabs[tabName]:setStyleSheet(activeTabStyle)
  tabData.tabs[tabName]:setBold(true)
  tabData.contents[tabName]:show()
end

function awake.layout.resizeTabContents(parentContainer, tabContainer, contentsContainer)
  local newHeight = parentContainer:get_height()-tabContainer:get_height()
  contentsContainer:resize(nil, newHeight)
end

function setSizeOnResize()
  local newBorder = math.floor(awake.layout.rightPanel:get_width())
  if getBorderRight() ~= newBorder then
    setBorderRight(newBorder)
    -- We could do this following line if we want the main window to set its text wrapping automatically.
    -- As-is, players will need to edit their mudlet settings to control this.
    -- setWindowWrap("main", getColumnCount("main")-3)
  end
end

function awake.layout.setup()
  if awake.layout.drawn then return end

  awake.layout.rightPanel = Geyser.Container:new({
    width = rightPanelWidthPct.."%",
    x = (100-rightPanelWidthPct).."%",
    y = 0, height = "100%",
  })
  awake.setup.registerEventHandler("sysWindowResizeEvent", function()
    setSizeOnResize()
  end)
  setSizeOnResize()


  -- Upper-right pane, for maps
  awake.layout.upperContainer = Geyser.Container:new({
    x = 0, y = 0,
    width = "100%",
    height = upperRightHeightPct.."%",
  }, awake.layout.rightPanel)

  -- Lower-right panel, for chat history
  awake.layout.lowerContainer = Geyser.Container:new({
    x = 0, y = upperRightHeightPct.."%",
    width = "100%",
    height = (100-upperRightHeightPct).."%",
  }, awake.layout.rightPanel)

  local lowerTabList = {}
  table.insert(lowerTabList, {keyword = "all", label = "All"})
  table.insert(lowerTabList, {keyword = "local", label = "Local"})
  table.insert(lowerTabList, {keyword = "radio", label = "Radio"})
  table.insert(lowerTabList, {keyword = "ooc", label = "OOC"})
  table.insert(lowerTabList, {keyword = "tell", label = "Tell"})

  awake.layout.lowerRightTabData = {}
  createTabbedPanel(awake.layout.lowerRightTabData, awake.layout.lowerContainer, lowerTabList)


  -- Lower info panel, for prompt hp/move gauges and other basic status
  awake.layout.lowerInfoPanelHeight = getFontSize() * 6
  -- Have to use a label as the master container as HBOX cannot be styled
  awake.layout.lowerInfoPanel = Geyser.Label:new({
    x = 0, y = -awake.layout.lowerInfoPanelHeight,
    width = (100-rightPanelWidthPct).."%",
    height = awake.layout.lowerInfoPanelHeight,
  })
  awake.layout.lowerInfoPanel:setStyleSheet([[
    background-color: qlineargradient(spread:pad, x1:0, y1:0, x2:0.681, y2:0.778, stop:0.29902 rgba(99, 114, 137, 255), stop:1 rgba(71, 79, 98, 255));
  ]])
  setBorderBottom(awake.layout.lowerInfoPanelHeight)
end

function awake.layout.teardown()
  awake.layout.rightPanel:hide()
  awake.layout.upperContainer:hide()
  awake.layout.lowerContainer:hide()
  awake.layout.lowerInfoPanel:hide()
  setBorderRight(0)
  setBorderBottom(0)
end
