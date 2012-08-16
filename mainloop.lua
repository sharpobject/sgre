function wait(n)
  n = n or 1
  for i=1,n do
    coroutine.yield()
  end
end

local main_gogogo

function fmainloop()
  local func, arg = main_gogogo, nil
  while true do
    func,arg = func(unpack(arg or {}))
    collectgarbage("collect")
  end
end

local vr = {
"Cook Club Student",
"Cook Club Student",
"Cook Club Student",
"Military Knight Sillit",
"Military Knight Sillit",
"Military Knight Sillit",
300055,
300055,
300055,
300056,
300056,
300056,
300122,
300122,
300122,
300063,
"Seeker Lynn",
"Seeker Lynn",
"Seeker Lynn",
"GS Fighter",
"GS Fighter",
"GS Fighter",
"GS Fighter",
"GS Fighter",
"GS Fighter",
"Game Starter",
"Coin Girl",
"Vampiric Rites",
"Vampiric Rites",
"Vampiric Rites",
"Newbie Guide Rico"
}

local nold = {
300026,
300026,
300026,
300021,
300021,
300021,
300024,
300024,
300024,
300022,

300022,
300022,
300023,
300023,
300023,
300025,
300025,
300029,
300029,
200015,

200015,
200015,
200025,
200025,
200025,
200023,
200023,
200017,
200017,
200017,
120001
}

assert(#vr == 31)

function str_to_deck(s)
  s = s:sub(s:find("[%dDPC]+")):split("DPC")
  local t = {}
  t[1] = s[1] + 0
  for i=2,#s,2 do
    for j=1,s[i]+0 do
      t[#t+1] = s[i+1]+0
    end
  end
  return t
end

function main_gogogo()
  local func = function(s)
      if not name_to_ids[s] then return s end
      table.sort(name_to_ids[s])
      return name_to_ids[s][1]
    end
  local vrids = map(func,vr)
  local noldids = map(func,nold)
  for i=1,31 do print(vrids[i]) end
  local player_file = love.filesystem.newFile("decks/player.txt")
  player_file:open("r")
  local player = str_to_deck(player_file:read(player_file:getSize()))
  local npc_file = love.filesystem.newFile("decks/npc.txt")
  npc_file:open("r")
  local npc = str_to_deck(npc_file:read(npc_file:getSize()))
  game = Game(player, npc)
  game:run()
  --[[while true do
    go_hard()
    game:run()
  end--]]
end
