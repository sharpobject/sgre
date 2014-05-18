function love.mousepressed(x,y,which)
  loveframes.mousepressed(x, y, which)
end

function love.mousereleased(x, y, which)
  loveframes.mousereleased(x, y, which)
end

function love.keypressed(key, unicode)
  if key == "f12" then
    DISPLAY_FRAMERATE = not DISPLAY_FRAMERATE
  end
  loveframes.keypressed(key, unicode)
end

function love.keyreleased(key)
  loveframes.keyreleased(key)
end

function love.textinput(text)
  loveframes.textinput(text)
end
