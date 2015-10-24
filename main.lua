socket = require("socket")
json = require("dkjson")
async = require("async")
require("stridx")
require("util")
require("class")
require("queue")
loveframes = require("loveframes")
require("network")
require("engine")
require("cards")
require("buff")
require("skills")
require("spells")
require("characters")
require("input")
require("graphics")
require("mainloop")
require("validate")
require("giftable")
require("filters")
require("xmutable")
require("animation")
require("sounds")
require("options")
--require("imagedata-ffi")

local N_FRAMES = 0
local min = math.min
local mainloop

function love.load(arg)
  arg = arg or {}
  GLOBAL_EMAIL, GLOBAL_PASSWORD = arg[2], arg[3]

  leftover_time = 1/120

  async.load()
  async.ensure.exactly(4)

  if GLOBAL_EMAIL == "--server" then
    require("server")
  end

  math.randomseed(os.time())
  for i=1,4 do math.random() end
  graphics_init() -- load images and set up stuff
  mainloop = coroutine.create(fmainloop)

  local t,s={},{}
  for k,v in pairs(skill_func) do
    if (not rawget(skill_id_to_type, k)) then
      t[#t+1] = k
    end
    if not skill_text[k] then
      s[#s+1] = k
    end
  end
  table.sort(t)
  for _,k in ipairs(t) do
    --print(tostring(k).." lacks a type")
  end
  for _,k in ipairs(s) do
    --print(tostring(k).." lacks a description")
  end
  if #t > 0 then
    error("some skills lack types")
  end
  if #s > 0 then
  --  error("some skills lack descriptions")
  end
end

function love.update(dt)
  --print("FRAME BEGIN")
  async.update()
  leftover_time = leftover_time + dt
  for i=1,3 do
    if leftover_time >= 1/60 then
      local status, err = coroutine.resume(mainloop)
      if not status then
        error(err..'\n'..debug.traceback(mainloop))
      end
      if game then
        game:update()
      end
      do_messages()
      loveframes.update((1/60)/3)
      loveframes.update((1/60)/3)
      loveframes.update((1/60)/3)
      leftover_time = leftover_time - 1/60
    end
  end
end

local hover_states = arr_to_set({"playing", "decks", "craft", "cafe", "xmute"})

function love.draw()
  love.graphics.setColor(255,255,255)
  draw_background()
  if game then game:draw() end
  local state = loveframes.GetState()
  if hover_states[state] then
    draw_hover_card(frames[state].card_text)
  end
  if state == "select_faction" then
    love.graphics.draw(load_asset("select_faction.png"), 153, 58)
  end
  --love.graphics.print("FPS: "..love.timer.getFPS(),315,15)
  loveframes.draw()
  if DISPLAY_FRAMERATE then
    love.graphics.print(tostring(love.timer.getFPS()), 0, 0)
  end
end