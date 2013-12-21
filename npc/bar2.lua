require "util"
json = require"dkjson"
games = json.decode(file_contents("arse"))
res = {}
for k,v in pairs(games) do
  k = k:sub(5)
  res[k] = {}
  for _,game in ipairs(v) do
    res[k][#res[k]+1] = game
  end
end
print(json.encode(res))