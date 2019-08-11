local args = {...}

-- URL from which the file should be loaded; should only contain text
local sourceurl = args[1]
-- Destination relative to this file in the file system; do not include
-- the .lua extension
local destination = args[2]

--- Load the given file and save it to the destination as a lua file.
function loadfile(url, savelocation)
  local filetext = textfromurl(url)
  print(filetext)
  print(type(filetext))
end

--- Send a request to the given URL and return the result as a string.
function textfromurl(url)
  local output = ""
  for section in internet.request(url) do
    output = output .. section
  end
  return output
end

loadfile(sourceurl, destination)
