dirs = {}
-- The order of these is important. The indices of the directions must match
-- https://github.com/Mudlet/Mudlet/blob/9c13f8f946f5b82c0c2e817dab5f42588cee17e0/src/TRoom.h#L38
table.insert(dirs, {short="n",  long="north",     rev="s",  xyzDiff = { 0, 1, 0}})
table.insert(dirs, {short="ne", long="northeast", rev="sw", xyzDiff = { 1, 1, 0}})
table.insert(dirs, {short="nw", long="northwest", rev="se", xyzDiff = {-1, 1, 0}})
table.insert(dirs, {short="e",  long="east",      rev="w",  xyzDiff = { 1, 0, 0}})
table.insert(dirs, {short="w",  long="west",      rev="e",  xyzDiff = {-1, 0, 0}})
table.insert(dirs, {short="s",  long="south",     rev="n",  xyzDiff = { 0,-1, 0}})
table.insert(dirs, {short="se", long="southeast", rev="nw", xyzDiff = { 1,-1, 0}})
table.insert(dirs, {short="sw", long="southwest", rev="ne", xyzDiff = {-1,-1, 0}})
table.insert(dirs, {short="u",  long="up",        rev="d",  xyzDiff = { 0, 0, 1}})
table.insert(dirs, {short="d",  long="down",      rev="u",  xyzDiff = { 0, 0,-1}})

-- Given a direction short or long name, or a direction number, return an object representing it.
function dirObj(arg)
  if dirs[arg] ~= nil then
    return dirs[arg]
  end

  for _, dir in ipairs(dirs) do
    if arg == dir.short or arg == dir.long then
      return dir
    end
  end
  return nil
end

-- Given a direction short or long name, or a direction number, return an object representing its opposite
function revDirObj(arg)
  local dir = dirObj(arg)
  if dir ~= nil then
    return dirObj(dir.rev)
  end
  return nil
end