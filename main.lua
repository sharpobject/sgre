socket = require("socket")
json = require("dkjson")
require("stridx")
require("util")
require("class")
require("queue")
require("globals")
require("engine")
require("cards")
cards_init()
require("buff")
groups_init()
require("skills")
require("spells")
require("characters")
require("input")
require("graphics")
require("mainloop")

local N_FRAMES = 0
local min = math.min

function love.load(arg)
  local min_k = 99
  for k,v in pairs(arg) do
    if k < min_k then
      min_k = k
    end
    print(k,v)
  end
  PATH_SEP = "/"
  if love._os == "Windows" then
    PATH_SEP = "\\"
  end
  local path = arg[min_k]
  local last_sep = nil
  for i=1,path:len() do
    if path[i] == PATH_SEP then
      last_sep = i
    end
  end
  if last_sep then
    path = path:sub(1,last_sep)
    print(path)
  else
    error("found no sepi "..love._os)
  end
  ABSOLUTE_PATH = path
  for k,v in pairs(love) do
    print(k,v)
  end



  math.randomseed(os.time())
  for i=1,4 do math.random() end
  graphics_init() -- load images and set up stuff
  mainloop = coroutine.create(fmainloop)

  local t = {}
  for k,v in pairs(skill_func) do
    if (not rawget(skill_id_to_type, k)) then
      t[#t+1] = k
    end
  end
  table.sort(t)
  for _,k in ipairs(t) do
    print(k)
  end
  if #t > 0 then
    error("some skills lack types")
  end
end

--[[local char_ids = {}
local norm_ids = {}
for k,v in pairs(id_to_canonical_card) do
  if v.type == "character" then
    char_ids[#char_ids+1] = k
  elseif v.type == "spell" or v.type == "follower" then
    norm_ids[#norm_ids+1] = k
  end
end

function get_deck()
  local t = {}
  t[1] = uniformly(char_ids)
  for i=2,31 do
    t[i] = uniformly(norm_ids)
  end
  return t
end

function go_hard()
  Player.user_act = Player.ai_act
  game = Game(get_deck(), get_deck())
end--]]

function love.update()
  gfx_q:clear()
  --print("FRAME BEGIN")
  local status, err = coroutine.resume(mainloop)
  if not status then
    error(err..'\n'..debug.traceback(mainloop))
  end
  if game then
    game:update()
    game:draw()
  end
  do_input()
end

function love.draw()
  set_color(255,255,255)
  for i=gfx_q.first,gfx_q.last do
    gfx_q[i][1](unpack(gfx_q[i][2]))
  end
  love.graphics.print("FPS: "..love.timer.getFPS(),315,115)
end
