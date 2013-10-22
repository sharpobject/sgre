function wait(n)
  n = n or 1
  for i=1,n do
    coroutine.yield()
  end
end

local main_select_boss, main_play, main_go_hard
local main_mxm

function fmainloop()
  local func, arg = main_mxm, nil
  while true do
    func,arg = func(unpack(arg or {}))
    collectgarbage("collect")
  end
end

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

local file_to_deck = function(s)
  local file, err = io.open(ABSOLUTE_PATH.."decks"..PATH_SEP..s..".txt", "r")
  if file then
    s = file:read("*a")
    file:close()
  else
    file = love.filesystem.newFile("decks/"..s..".txt")
    file:open("r")
    s = file:read(file:getSize())
  end
  return str_to_deck(s)
end

local char_ids = {}
local norm_ids = {}
for k,v in pairs(id_to_canonical_card) do
  if v.type == "spell" or v.type == "follower" then
    norm_ids[#norm_ids+1] = k
  end
end
for k,_ in pairs(characters_func) do
  char_ids[#char_ids+1] = k
end

local function get_deck()
  local t = {}
  t[1] = uniformly(char_ids)
  for i=2,31 do
    t[i] = uniformly(norm_ids)
  end
  return t
end

local function go_hard()
  Player.user_act = Player.ai_act
  GO_HARD = true
  wait = function() end
  game = Game(get_deck(), get_deck())
end

function main_go_hard()
  while true do
    gfx_q:clear()
    go_hard()
    game:run()
  end
end

function main_select_boss()
  local which = nil
  local mk_cb = function(n)
    return function()
      which = n
    end
  end
  local cbs = {}
  for i=1,40 do
    cbs[i]=mk_cb(i)
  end
  while true do
    for i=1,4 do
      for j=1,10 do
        if i < 4 or j ~= 7 then
          local floor = (i-1)*10+j
          gprint(floor.."F", 400 + (j-5.5)*50 - 10, 190 + i * 50)
          make_button(cbs[floor], 400 + (j-5.5)*50 - 20, 185 + i * 50, 40, 40, true)
        end
      end
    end
    gprint("whoa dude", 250, 40)
    wait()
    if which then
      if (""..which):len() == 1 then
        which = "0"..which
      end
      return main_play, {""..which}
    end
  end
end

function main_play(which)
  local player = file_to_deck("player")
  local npc = file_to_deck("floor"..which)
  game = Game(player, npc)
  game:run()
end

function main_mxm()
  network_init()
  game = Game(nil, nil, true)
  game:client_run()
end
