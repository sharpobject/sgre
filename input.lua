function love.mousepressed(x,y,which)
  print("mouse pressed!")
  if which=="l" then
    mouse_down = true
    mouse_x = x
    mouse_y = y
  end
end

Button = class(function(self,cb,x,y,w,h)
    self.cb = cb
    self.x1 = x
    self.x2 = x + w
    self.y1 = y
    self.y2 = y + h
    self.w = w
    self.h = h
  end)

function Button:contains(x,y)
  return self.x1 <= x and x < self.x2 and self.y1 <= y and y < self.y2
end

function do_input()
  mouse_x = mouse_x or love.mouse.getX()
  mouse_y = mouse_y or love.mouse.getY()
  for _,button in ipairs(buttons) do
    if button:contains(mouse_x, mouse_y) then
      if mouse_down then
        button.cb()
      else
        button:draw_outline()
      end
    end
  end
  mouse_down = false
  mouse_x = nil
  mouse_y = nil
  buttons = {}
end

function make_button(cb, x,y,w,h)
  buttons[#buttons+1] = Button(cb,x,y,w,h)
end
