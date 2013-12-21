require"util"
json = require"dkjson"
lines = {}
games = {}

function toid(t)
  local ret = t.dungeon..""
  if ret:len() < 2 then ret = "0"..ret end
  local s = t.floor..""
  if s:len() < 2 then s = "0"..s end
  return ret..s..t.npc
end

for line in io.open("out"):lines() do
  if not json.decode(line) then
    print "I have aids :("
    return
  end
  line = json.decode(line)
  if line.dungeon then
    id = toid(line)
    --print(id)
    games[id] = games[id] or {}
    game = {}
    games[id][#games[id]+1] = game
  else
    game[#game+1] = line["enemy hand"]
  end
end
print(json.encode(games))