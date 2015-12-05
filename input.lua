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
  if key == "f6" then
    RIP_IMAGEFONTS = not RIP_IMAGEFONTS
  end
  if key == "f7" then
    load_img = load_image_on_main_thread
  end
  if key == "f8" then
    SUPPORTS_MIPMAPS = false
  end
  loveframes.keypressed(key, unicode)
end

function love.keyreleased(key)
  loveframes.keyreleased(key)
end

function love.textinput(text)
  loveframes.textinput(text)
end
