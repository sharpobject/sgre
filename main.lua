socket = require("socket")
json = require("dkjson")
require("stridx")
require("util")
require("class")
require("queue")
require("globals")
require("engine")
require("cards")
require("buff")
require("skills")
require("spells")
require("input")
require("graphics")
require("mainloop")

local N_FRAMES = 0
local min = math.min

function love.load()
  math.randomseed(os.time())
  for i=1,4 do math.random() end
  cards_init()
  groups_init()
  graphics_init() -- load images and set up stuff
  mainloop = coroutine.create(fmainloop)
end

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
