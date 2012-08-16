function wait(n)
  n = n or 1
  for i=1,n do
    coroutine.yield()
  end
end

local main_select_boss, main_play, main_gogogo

function fmainloop()
  local func, arg = main_gogogo, nil
  while true do
    func,arg = func(unpack(arg or {}))
    collectgarbage("collect")
  end
end

local str_to_deck = function(s)
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
  local player_file = love.filesystem.newFile("decks/player.txt")
  player_file:open("r")
  local player = str_to_deck(player_file:read(player_file:getSize()))
  local npc_file = love.filesystem.newFile("decks/floor01.txt")
  npc_file:open("r")
  local npc = str_to_deck(npc_file:read(npc_file:getSize()))
  game = Game(player, npc)
  game:run()
  --[[while true do
    go_hard()
    game:run()
  end--]]
end
