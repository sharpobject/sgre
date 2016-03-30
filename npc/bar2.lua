require "util"
json = require"dkjson"
games = json.decode(file_contents("arse"))
other_games = json.decode(file_contents("arse2"))
for k,v in pairs(other_games) do
  assert(not games[k])
  games[k] = v
end
res = {}
good_dungeons = arr_to_set({"01", "02", "03", "04", "05", "06",
    "07", "08", "09", "10", "11", "12", "13", "14", "16", "17",
    "18", "21", "22", "23", "24", "25", "28", "33", "34", "35",})
good_npcs = {}
for k,v in pairs(games) do
  if good_dungeons[k:sub(1,2)] then
    good_npcs[k:sub(5)]=true
  end
end
for k,v in pairs(games) do
  k = k:sub(5)
  if good_npcs[k] then
    res[k] = {}
    for _,game in ipairs(v) do
      res[k][#res[k]+1] = game
    end
  end
end
print(json.encode(res))