local internet = require "internet"
local computer = require "computer"

local args = {...}

-- URL from which the file should be loaded; should only contain text
local sourceurl = args[1]
-- Destination relative to this file in the file system; do not include
-- the .lua extension
local destination = args[2]

--- Load the file, along with any dependencies it points to, from the
-- given URL to the local file system.
function loadfilesystem(srcpath, dstpath)
  local loadedfiles = {}
  local queuedfiles = {srcpath:export() = true}

  print("Loading file system...")

  while #queuedfiles > 0 do
    local filetoload = pop(queuedfiles)
    loadedfiles[filetoload] = true
    local dependencies = loadfile(
      srcpath:copy():navigate(filetoload), dstpath:copy():navigate(filetoload)
    )
    for _, dependency in ipairs(dependencies) do
      if loadedfiles[dependency] == nil then
        queuedfiles[dependency] = true
      end
    end
  end

  print("Finished loading file system.")
end

--- Load the given file and save it to the destination as a lua file.
-- The source and destination paths (where the source refers to a URL
-- and destination refers to a local file) should both be given in the
-- form of navigators.  Returns a list of dependencies, specified by
-- their paths relative to the root file.
function loadfile(srcpath, dstpath)
  print("  Loading from " .. srcpath:export())
  local filetext = textfromurl(srcpath)
  print("  Writing to " .. dstpath:export())
  writefile(dstpath:export() .. ".lua", filetext)
  local dependencies = getdependencies(filetext)
  print("Found " .. #dependencies  .. " dependencies")
  return dependencies
end

--- Send a request to the given URL and return the result as a string.  The
-- URL is assumed to be specified in the form of a navigator object.
function textfromurl(urlpath)
  local output = ""
  local response = internet.request(urlpath:export())

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

--- Return paths - as strings - pointing to the dependencies of the given
-- file from the root file.
function getdependencies(filetext)
  local dependencies = {}
  local lines = splitstring(filetext, "\n")
  local hascommand = startswith("-- gerald:dependency")

  for _, line in ipairs(lines) do
    if hascommand(line) then
      local absolutepath = splitstring(line, " ")[3]
      table.insert(dependencies, absolutepath)
    end
  end

  return dependencies
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

--- Given a table consisting of key-value pairs, in which the values
-- are assumed to be irrelevant, remove a key-value pair from the table
-- and return its key.  The order in which keys are removed is undefined.
function pop(keytable)
  local firstkey
  for key, _ in pairs(keytable) do
    firstkey = key
    break
  end
  keytable[firstkey] = nil
  return firstkey
end

loadfilesystem(navigator(sourceurl), navigator(destination))
computer.shutdown(true)
