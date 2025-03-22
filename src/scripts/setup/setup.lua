awake = awake or {}
awake.setup = awake.setup or {}
awake.setup.eventHandlerKillIds = awake.setup.eventHandlerKillIds or {}
awake.setup.gmcpEventHandlerFuncs = awake.setup.gmcpEventHandlerFuncs or {}

function awake.setup.registerEventHandler(eventName, func)
  local killId = registerAnonymousEventHandler(eventName, func)
  table.insert(awake.setup.eventHandlerKillIds, killId)

  -- A little bit hacky, but we want to run all GMCP event handlers when we finish
  -- doing initial setup to populate the UI.
  if eventName:find("gmcp\.") then
   table.insert(awake.setup.gmcpEventHandlerFuncs, func)
  end
end

local function setup()
  -- Layout has to be created first
  awake.layout.setup()

  -- Then everything else in no particular order
  awake.chat.setup()
  awake.infoPanel.setup()
  awake.mapper.setup()
  awake.matrix.setup()

  -- Then set our UI default view
  awake.layout.selectTab(awake.layout.lowerRightTabData, "all")

  -- Manually kick off all GMCP event handlers, since GMCP data would not have changed
  -- since loading the UI.
  for _, func in ipairs(awake.setup.gmcpEventHandlerFuncs) do
   func()
  end

  raiseEvent("awakeUiLoaded")
end

awake.setup.registerEventHandler("sysLoadEvent", function()
  setup()
end)

awake.setup.registerEventHandler("sysInstallPackage", function(_, pkgName)
  --Check if the generic_mapper package is installed and if so uninstall it
  if table.contains(getPackages(),"generic_mapper") then
    uninstallPackage("generic_mapper")
  end
  
  if pkgName ~= "awake-ui" then return end
  setup()
end)

local function teardown()
  for _, killId in ipairs(awake.setup.eventHandlerKillIds) do
   killAnonymousEventHandler(killId)
  end

  awake.mapper.teardown()
  awake.layout.teardown()
  awake = nil
end

awake.setup.registerEventHandler("sysUninstallPackage", function(_, pkgName)
  if pkgName ~= "awake-ui" then return end
  teardown()
end)

awake.setup.registerEventHandler("sysProtocolEnabled", function(_, protocol)
  if protocol == "GMCP" then
    sendGMCP("Core.Supports.Set", "[\"Ship 1\"]")
  end
end)
