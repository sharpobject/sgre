function love.conf(t)
  t.title = "FakeSG"
  t.author = "sharpobject@gmail.com"
  (t.window or t.screen).width = 800
  (t.window or t.screen).height = 600
  t.identity = "FakeSG"
  t.modules.physics = false

  -- DEFAULTS FROM HERE DOWN
  t.version = "0.9.0"         -- The LÖVE version this game was made for (string)
  t.console = false           -- Attach a console (boolean, Windows only)
  t.release = false           -- Enable release mode (boolean)
  (t.window or t.screen).fullscreen = false -- Enable fullscreen (boolean)
  (t.window or t.screen).vsync = true       -- Enable vertical sync (boolean)
  (t.window or t.screen).fsaa = 0           -- The number of FSAA-buffers (number)
  t.modules.joystick = true   -- Enable the joystick module (boolean)
  t.modules.audio = true      -- Enable the audio module (boolean)
  t.modules.keyboard = true   -- Enable the keyboard module (boolean)
  t.modules.event = true      -- Enable the event module (boolean)
  t.modules.image = true      -- Enable the image module (boolean)
  t.modules.graphics = true   -- Enable the graphics module (boolean)
  t.modules.timer = true      -- Enable the timer module (boolean)
  t.modules.mouse = true      -- Enable the mouse module (boolean)
  t.modules.sound = true      -- Enable the sound module (boolean)
end
