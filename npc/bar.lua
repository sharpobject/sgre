require "util"
json = require"dkjson"
games = json.decode(file_contents("butt"))
for k,v in spairs(games) do
  print(k)
end