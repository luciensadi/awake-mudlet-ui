awake = awake or {}
awake.mapper = awake.mapper or {}

function awake.mapper.log(text)
  cecho("[<cyan>Awake Mapper<reset>] "..text.."\n")
end

function awake.mapper.logDebug(text)
  if awake.mapper.debug then
    awake.mapper.log("<green>Debug:<reset> "..text)
  end
end

function awake.mapper.logError(text)
  awake.mapper.log("<red>Error:<reset> "..text)
end