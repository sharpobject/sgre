require "util"
json = require"dkjson"
games = json.decode(file_contents("arse"))
other_games = json.decode(file_contents("arse2"))
for k,v in spairs(other_games) do
  games[k] = v
end
for k,v in spairs(games) do
  print(k)
end