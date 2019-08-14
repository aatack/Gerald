local internet = require "internet"
local computer = require "computer"

local args = {...}

-- URL from which the file should be loaded; should only contain text
local sourceurl = args[1]
-- Destination relative to this file in the file system; do not include
-- the .lua extension
local destination = args[2]

local dependencies = {}

--- Load the given file and save it to the destination as a lua file.
function loadfile(url, savelocation, existingdependencies)
  if existingdependencies[savelocation] ~= nil then
    existingdependencies[savelocation] = true
    print("Loading from " .. url)
    local filetext = textfromurl(url)
    print("Writing to " .. savelocation)
    writefile(savelocation .. ".lua", filetext)
    loaddependencies(filetext, existingdependencies)
  else
    print("Dependency " .. savelocation .. " already loaded")
  end
end

--- Send a request to the given URL and return the result as a string.
function textfromurl(url)
  local output = ""
  local response = internet.request(url)

  for section in response do
    output = output .. section
  end
  return output
end

--- Write text to the given file.  The extension should be included in
-- the file's location.
function writefile(location, text)
  file = io.open(location, "w")
  file:write(text)
  file:close()
end

--- Load the files upon which the target file depends.
function loaddependencies(filetext, existingdependencies)
  local lines = splitstring(filetext, "\n")
  local hascommand = startswith("-- gerald:dependency")
  for _, line in ipairs(lines) do
    if hascommand(line) then
      local location = splitstring(line, " ")[3]
      error "NYI"
    end
  end
end

--- Split a string at each instance of a separator.
function splitstring(string, separator)
  local segments = {}
  local start = 1
  for i = 1, #string do
    local c = string:sub(i, i)
    if c == separator then
      table.insert(segments, string:sub(start, i - 1))
      start = i + 1
    end
  end
  table.insert(segments, string:sub(start, #string))
  return segments
end

--- Join an array of strings with a delimiter.
function joinstring(segments, delimiter)
  if #segments == 0 then
    return ""
  end
  local result = segments[1]
  if #segments == 1 then
    return result
  end

  for i = 2, #segments do
    result = result .. delimiter .. segments[i]
  end
  return result
end

--- Return a function that determines whether a string starts
-- with a given substring.
function startswith(substring)
  local length = string.len(substring)
  function apply(outerstring)
    return (
      string.len(outerstring) >= length and
      string.sub(outerstring) == substring
    )
  end
  return apply
end

--- Return an object with a number of functions for editing URLs.
function navigator(basepath)
  local path = basepath
  if type(path) == "string" then
    path = splitstring(path, "/")
  end

  return {
    _path = path,

    copy = function(_)
      return navigator(basepath)
    end,

    navigate = function(self, subpath)
      local segments = subpath
      if type(subpath) == "string" then
        segments = splitstring(segments, "/")
      end

      for _, segment in ipairs(segments) do
        self:_navigatesegment(segment)
      end
    end,

    export = function(self)
      return joinstring(self._path, "/")
    end,

    _navigatesegment = function(self, segment)
      if segment == ".." then
        table.remove(self._path, #self._path)
      elseif segment == "." or string.len(segment) == 0 then
        -- Do nothing
      else
        table.insert(self._path, segment)
      end
    end
  }
end

loadfile(sourceurl, destination)
computer.shutdown(true)
