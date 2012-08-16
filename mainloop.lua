function wait(n)
  n = n or 1
  for i=1,n do
    coroutine.yield()
  end
end

local main_select_boss, main_play, main_gogogo

function fmainloop()
  local func, arg = main_select_boss, nil
  while true do
    func,arg = func(unpack(arg or {}))
    collectgarbage("collect")
  end
end

local str_to_deck = function(s)
  local file, err = io.open(ABSOLUTE_PATH.."decks"..PATH_SEP..s..".txt", "r")
  if file then
    s = file:read("*a")
    file:close()
  else
    file = love.filesystem.newFile("decks"..PATH_SEP..s..".txt")
    file:open("r")
    s = file:read(file:getSize())
  end

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

function main_select_boss()
  local which = nil
  local mk_cb = function(n)
    return function()
      which = n
    end
  end
  local cbs = {}
  for i=1,5 do
    cbs[i]=mk_cb(i)
  end
  while true do
    for i=1,5 do
      gprint(i.."F", 400 + (i-3)*50 - 10, 265)
      make_button(cbs[i], 400 + (i-3)*50 - 20, 260, 40, 40, true)
    end
    wait()
    if which then
      return main_play, {"0"..which}
    end
  end
end

function main_play(which)
  local player = str_to_deck("player")
  local npc = str_to_deck("floor"..which)
  game = Game(player, npc)
  game:run()
  --[[while true do
    go_hard()
    game:run()
  end--]]
end
