function load_img(s)
  if not pcall(function() s = love.image.newImageData("swordgirlsimages/"..s) end) then
    local file, err = io.open(ABSOLUTE_PATH.."swordgirlsimages"..PATH_SEP..s, "rb")
    if not file then
      error(err)
    end
    local contents = file:read("*a")
    file:close()
    local data = love.filesystem.newFileData(contents, "foo.jpg", "file")
    s = love.image.newImageData(data)
  end
  local w, h = s:getWidth(), s:getHeight()
  local wp = math.pow(2, math.ceil(math.log(w)/math.log(2)))
  local hp = math.pow(2, math.ceil(math.log(h)/math.log(2)))
  if wp ~= w or hp ~= h then
    local padded = love.image.newImageData(wp, hp)
    padded:paste(s, 0, 0)
    s = padded
  end
  local ret = love.graphics.newImage(s)
  s:mapPixel(function(x,y,r,g,b,a)
      local ret = (r+g+b)/3
      return ret,ret,ret,a
    end)
  local gray = love.graphics.newImage(s)
  ret:setFilter("linear","linear")
  return ret,gray,w,h
end

do
  local real_load_img = load_img
  load_img = function(s)
    status,a,b,c,d = pcall(function()
        return real_load_img(s)
      end)
    if status then
      return a,b,c,d
    end
    return real_load_img("200033L.jpg")
  end
end

local GFX_SCALE = 1
local card_scale = .2
local card_width, card_height

function draw(img, x, y, rot, x_scale,y_scale)
  rot = rot or 0
  x_scale = x_scale or 1
  y_scale = y_scale or 1
  --print("DRAW AN IMAGE")
  gfx_q:push({love.graphics.draw, {img, x*GFX_SCALE, y*GFX_SCALE,
    rot, x_scale*GFX_SCALE, y_scale*GFX_SCALE}})
end

function grectangle(mode,x,y,w,h)
  gfx_q:push({love.graphics.rectangle, {mode, x, y, w, h}})
end

function gprint(str, x, y)
  gfx_q:push({love.graphics.print, {str, x, y}})
end

function gprintf(...)
  gfx_q:push({love.graphics.printf, {...}})
end

local _r, _g, _b, _a = nil, nil, nil, nil
function set_color(r, g, b, a)
  a = a or 255
  -- only do it if this color isn't the same as the previous one...
  if _r~=r or _g~=g or _b~=b or _a~=a then
      _r,_g,_b,_a = r,g,b,a
      --print("SET COLOR TO "..r..", "..g..", "..b)
      gfx_q:push({love.graphics.setColor, {r, g, b, a}})
  end
end

function graphics_init()
  IMG_card = {}
  IMG_gray_card = {}
  for _,v in ipairs({300249}) do
    IMG_card[v], IMG_gray_card[v], card_width, card_height =
      load_img(v.."L.jpg")
  end
  card_width = card_width * card_scale
  card_height = card_height * card_scale
end

function draw_card(card, x, y, text)
  local id = card.id
  if card.hidden then
    id = 200099
  end
  if not IMG_card[id] then
    IMG_card[id], IMG_gray_card[id] = load_img(id.."L.jpg")
  end
  if card.type == "character" or card.active then
    draw(IMG_card[id], x, y, 0, card_scale, card_scale)
  else
    draw(IMG_gray_card[id], x, y, 0, card_scale, card_scale)
  end
  local card_width = card_width
  local card_height = card_height
  local gray_shit_height = card_height - 78
  local gray_shit_x = x+40
  local gray_shit_width = card_width - 40
  local middle = y+(card_height-gray_shit_height)/2
  if card.size and not card.hidden then
    set_color(28,28,28)
    grectangle("fill",gray_shit_x,y,
      gray_shit_width, gray_shit_height)
    set_color(255,255,255)
    gprintf(card.size, gray_shit_x, y+3, gray_shit_width, "center")
  end
  if text then
    set_color(28,28,28)
    grectangle("fill",x,middle,
      card_width, gray_shit_height)
    set_color(255,255,255)
    gprintf(text, x, middle+3, card_width, "center")
  end
  if not card.hidden then
    if card.type == "follower" then
      set_color(28,28,28)
      grectangle("fill",x,y + card_height - gray_shit_height,
        card_width, gray_shit_height)
      set_color(255, 255, 255)
      gprintf(card.atk, x, y+80, card_width/3, "center")
      gprintf(card.def, x+card_width/3, y+80, card_width/3, "center")
      gprintf(card.sta, x+2*card_width/3, y+80, card_width/3, "center")
      set_color(255,50,50)
    elseif card.type == "spell" then
      set_color(50,50,255)
    else
      set_color(28,28,28)
      grectangle("fill",gray_shit_x,y + card_height - gray_shit_height,
        gray_shit_width, gray_shit_height)
      set_color(255,255,255)
      gprintf(card.life, gray_shit_x, y+80, gray_shit_width, "center")
      set_color(180,50,180)
    end
    grectangle("line",x,y,card_width, card_height)
  end
  set_color(255,255,255)
end

local slot_to_dxdy = {left={[0]={0,1},{0,0},{1,0},{1,1},{1,2},{0,2}},
                   right={[0]={1,1},{1,0},{0,0},{0,1},{0,2},{1,2}}}

function Player:draw()
  local leftcol, rightcol = {},{}
  local y_anchor = 50
  local x_anchor = 50
  if self.side == "left" then
    leftcol = {self.field[1], self.character, self.field[5]}
    rightcol = {self.field[2], self.field[3], self.field[4]}
  else
    rightcol = {self.field[1], self.character, self.field[5]}
    leftcol = {self.field[2], self.field[3], self.field[4]}
    x_anchor = x_anchor +  400
  end
  for i=0,5 do
    local text = nil
    if self.game.print_attack_info then
      if self==self.game.attacker[1] and i==self.game.attacker[2] then
        text = "attacking"
      elseif self==self.game.defender[1] and i==self.game.defender[2] then
        text = "defending"
      end
    end
    local dx,dy = unpack(slot_to_dxdy[self.side][i])
    if self.field[i] then
      draw_card(self.field[i], x_anchor+80*dx, y_anchor+100*dy, text)
    end
  end
  if self.side == "left" then
    for i=1,#self.hand do
      local img = IMG_card[self.hand[i].id]
      local w,h = card_width, card_height
      local x,y = 50+70*(i-1), 400
      local idx = i
      draw_card(self.hand[i], x, y)
      if self.game.act_buttons then
        make_button(function()
            print("trying to play card at idx "..idx)
            if self:can_play_card(idx) then
              self:play_card(idx)
            end
          end, x, y, w, h)
      end
    end
  end
end

function Game:draw()
  self.P1:draw()
  self.P2:draw()
  gprint("deck "..#self.P1.deck.."    grave "..#self.P1.grave, 60, 370)
  gprint("turn "..self.turn, 280, 370)
  gprint("deck "..#self.P2.deck.."    grave "..#self.P2.grave, 470, 370)
  gprint("ready", 420, 430)
  gprint("shuffle ("..self.P1.shuffles..")", 420, 467)
  gprint(self.time_remaining.."s", 490, 467 - 1 * 30)
  gprint("size "..self.P1:field_size().."/10", 475, 467 - 2 * 30)
  if self.act_buttons then
    make_button(function() self.ready = true end, 415, 400, 50, 60, true)
    make_button(function() self.P1:attempt_shuffle() end, 415, 465, 50, 20, true)
  end
end

function Button:draw_outline(...)
  set_color(...)
  grectangle("line", self.x1, self.y1, self.w, self.h)
end
