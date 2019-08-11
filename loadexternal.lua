local internet = require "internet"
local computer = require "computer"

local args = {...}

-- URL from which the file should be loaded; should only contain text
local sourceurl = args[1]
-- Destination relative to this file in the file system; do not include
-- the .lua extension
local destination = args[2]

--- Load the given file and save it to the destination as a lua file.
function loadfile(url, savelocation)
  local filetext = textfromurl(url)
  print("Writing to " .. savelocation)
  writefile(savelocation .. ".lua", filetext)
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

loadfile(sourceurl, destination)
computer.shutdown(true)
