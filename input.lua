function love.mousepressed(x,y,which)
  --print("mouse pressed!")
  if which=="l" then
    mouse_down = true
    mouse_x = x
    mouse_y = y
  end
  loveframes.mousepressed(x, y, which)
end

function love.mousereleased(x, y, which)
  loveframes.mousereleased(x, y, which)
end

function love.keypressed(key, unicode)
  loveframes.keypressed(key, unicode)
end

function love.keyreleased(key)
  loveframes.keyreleased(key)
end

function love.textinput(text)
  loveframes.textinput(text)
end
