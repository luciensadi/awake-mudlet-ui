awake = awake or {}
awake.chat = awake.chat or {}

function awake.chat.setup()
  for keyword, contentsContainer in pairs(awake.layout.lowerRightTabData.contents) do
    awake.chat[keyword] = Geyser.MiniConsole:new({
      x = "1%", y = "1%",
      width = "98%",
      height = "98%",
      autoWrap = false,
      color = "black",
      scrollBar = true,
      font = getFont(),
      fontSize = getFontSize(),
    }, contentsContainer)

  -- Set the wrap at a few characters short of the full width to avoid the scroll bar showing over text
  local charsPerLine = awake.chat[keyword]:getColumnCount()-3
  awake.chat[keyword]:setWrap(charsPerLine)
    awake.setup.registerEventHandler("sysWindowResizeEvent", function()
      local charsPerLine = awake.chat[keyword]:getColumnCount()-3
      awake.chat[keyword]:setWrap(charsPerLine)
    end)
  end
end

function awake.chat.routeMessage(type, skipAllTab)
  selectCurrentLine()
  copy()
  awake.chat[type]:cecho("<reset>"..getTime(true, "hh:mm:ss").." ")
  awake.chat[type]:appendBuffer()

  if not skipAllTab then
    awake.chat.all:cecho("<reset>"..getTime(true, "hh:mm:ss").." ")
    awake.chat.all:appendBuffer()
  end
end
