require "gradient"

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
  local asset_map = {}
  function load_asset(s)
    local orig_s = s
    if asset_map[s] then return unpack(asset_map[s]) end
    if not pcall(function() s = love.image.newImageData("sg_assets/"..s) end) then
      local file, err = io.open(ABSOLUTE_PATH.."sg_assets"..PATH_SEP..s, "rb")
      if not file then
        error(err)
      end
      local contents = file:read("*a")
      file:close()
      local data = love.filesystem.newFileData(contents, "foo.png", "file")
      s = love.image.newImageData(data)
    end
    local w, h = s:getWidth(), s:getHeight()
    local ret = love.graphics.newImage(s)
    asset_map[orig_s] = {ret, w, h}
    return ret,w,h
  end
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
local card_scale = .25
local card_width, card_height

local function yolo()
--  local foo = gfx_q[gfx_q.last]
--  foo[1](unpack(foo[2]))
end

function draw(img, x, y, rot, x_scale,y_scale)
  rot = rot or 0
  x_scale = x_scale or 1
  y_scale = y_scale or 1
  --print("DRAW AN IMAGE")
  gfx_q:push({love.graphics.draw, {img, x*GFX_SCALE, y*GFX_SCALE,
    rot, x_scale*GFX_SCALE, y_scale*GFX_SCALE}})
  yolo()
end

function grectangle(mode,x,y,w,h)
  gfx_q:push({love.graphics.rectangle, {mode, x, y, w, h}})
  yolo()
end

function gprint(str, x, y)
  gfx_q:push({love.graphics.print, {str, x, y}})
  yolo()
end

function gprintf(...)
  gfx_q:push({love.graphics.printf, {...}})
  yolo()
end

local fonts = {}

function gfontsize(...)
  local func = function(size)
    local font = fonts[size]
    if not font then
      font = love.graphics.newFont(size)
      fonts[size] = font
    end
    love.graphics.setFont(font)
  end
  gfx_q:push({func, {...}})
  yolo()
end

local _r, _g, _b, _a = nil, nil, nil, nil
function set_color(r, g, b, a)
  a = a or 255
  -- only do it if this color isn't the same as the previous one...
  if _r~=r or _g~=g or _b~=b or _a~=a then
      _r,_g,_b,_a = r,g,b,a
      --print("SET COLOR TO "..r..", "..g..", "..b)
      gfx_q:push({love.graphics.setColor, {r, g, b, a}})
      yolo()
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

function draw_hover_card(card)
  set_color(255, 255, 255)
  local id = card.id
  if not IMG_card[id] then
    IMG_card[id], IMG_gray_card[id] = load_img(id.."L.jpg")
  end
  local x,y = 591,30
  draw(IMG_card[id], x, y, 0, 0.5, 0.5)
  local card_width = card_width*2
  local card_height = card_height*2
  local gray_shit_height = (card_height - 200)/2
  local gray_shit_dx = math.floor(card_width*2/3)
  local gray_shit_x = x + gray_shit_dx
  local gray_shit_width = card_width - gray_shit_dx
  local middle = y+(card_height-gray_shit_height)/2
  if card.type == "follower" then
    set_color(28,28,28)
    grectangle("fill",x,y + card_height - gray_shit_height,
      card_width, gray_shit_height)
    set_color(255, 255, 255)
  end
  draw(load_asset("m-"..card.type..".png"), x, y)
  if card.type == "character" then
    gprintf(card.life, gray_shit_x+4, y+212, gray_shit_width, "center")
  elseif card.type == "follower" then
    gprintf(card.atk, x, y+223, card_width/3, "center")
    gprintf(card.def, x+card_width/3, y+223, card_width/3, "center")
    gprintf(card.sta, x+2*card_width/3, y+223, card_width/3, "center")
  end
  if card.size then
    gprintf(card.size, gray_shit_x+5, y+15, gray_shit_width, "center")
  end
  if card.faction then
    draw_faction(card.faction, x+3, y+3, 0, 1, 1)
  end
  set_color(28 ,28 ,28)
  gfontsize(11)
  local text = skill_text[card.id]
  if card.type == "follower" then
    text = ""
    local skills = card.skills or {}
    for i=1,3 do
      if skills[i] then
        if skill_text[skills[i]] then
          text = text .. skill_text[skills[i]] .. "\n\n"
        else
          text = text .. "Unknown skill with id " .. skills[i] .. "\n\n"
        end
      else
        text = text .. "-\n\n"
      end
    end
  end
  gprintf(text, x, y+card_height+10, card_width, "left")
  gfontsize(12)
end

local bkg_grad, bkg_quad = nil, nil
function draw_background()
  bkg_grad = bkg_grad or gradient({direction="horizontal", {254, 248, 164, 0}, {254, 248, 164}})
  local bkg, bkg_width, bkg_height = load_asset("background.png")
  bkg:setWrap('repeat','repeat')
  if not bkg_quad then
    local window_width = love.graphics.getWidth()
    local window_height = love.graphics.getHeight()
    bkg_quad = love.graphics.newQuad(0, 0, window_width, window_height, bkg_width, bkg_height)
  end
  gfx_q:push({love.graphics.draw, {bkg, bkg_quad, 0, 0}})
  yolo()
  gfx_q:push({love.graphics.draw, {bkg_grad, 0, -love.graphics.getHeight()/2, 0, love.graphics.getWidth()/bkg_grad:getWidth(), love.graphics.getHeight()*2/bkg_grad:getHeight()}})
  yolo()
end

local field_quad = nil
function draw_field()
  local field_img, field_w, field_h = load_asset("field.png")
  draw(field_img, 27, 17)
  draw(load_asset("field_hud.png"), 31, 357)
end

function draw_faction(faction, x, y, rot, x_scale, y_scale)
  rot = rot or 0
  x_scale = x_scale or 1
  y_scale = y_scale or 1
  local faction_gfx = {['E'] = "empire.png",
    ['D'] = "darklore.png",
    ['N'] = "sg.png",
    ['V'] = "vita.png",
    ['C'] = "crux.png",
    ['A'] = "academy.png"}
  local faction_img = load_asset(faction_gfx[faction])
  draw(faction_img, x, y, rot, x_scale, y_scale)
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
  local gray_shit_height = card_height - 100
  local gray_shit_dx = math.floor(card_width*2/3)
  local gray_shit_x = x + gray_shit_dx
  local gray_shit_width = card_width - gray_shit_dx
  local middle = y+(card_height-gray_shit_height)/2
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
      gprintf(card.atk, x, y+103, card_width/3, "center")
      gprintf(card.def, x+card_width/3, y+103, card_width/3, "center")
      gprintf(card.sta, x+2*card_width/3, y+103, card_width/3, "center")
    end
    draw(load_asset("s-"..card.type..".png"), x, y)
    if card.size then
      gprintf(card.size, gray_shit_x + 2, y+4, gray_shit_width, "center")
    end
    if card.type == "character" then
      gprintf(card.life, gray_shit_x + 2, y+102, gray_shit_width, "center")
    end
    if card.faction then
      draw_faction(card.faction, x+1, y+1, 0, 0.5, 0.5)
    end
  end
end

local slot_to_dxdy = {
  left={[0]={34,136},
            {11,8},
            {99,8},
            {122,136},
            {99,264},
            {11,264}},
  right={[0]={449,136},
            {472,8},
            {384,8},
            {361,136},
            {384,264},
            {472,264}}}

function Player:draw()
  local y_anchor = 17
  local x_anchor = 27
  for i=0,5 do
    local text = nil
    if self.game.print_attack_info then
      if self==self.game.attacker[1] and i==self.game.attacker[2] then
        text = "attack"
      elseif self==self.game.defender[1] and i==self.game.defender[2] then
        text = "defend"
      end
    end
    if self.field[i] and self.field[i].trigger then
      text = "trigger"
    end
    local dx,dy = unpack(slot_to_dxdy[self.side][i])
    if self.field[i] then
      local x, y, w, h = x_anchor+dx, y_anchor+dy, card_width, card_height
      draw_card(self.field[i], x, y, text)
      if not self.field[i].hidden then
        make_button(function()
            game.hover_card = deepcpy(self.field[i])
          end, x, y, w, h, false, true)
      end
    end
  end
  if self.side == "left" then
    for i=1,#self.hand do
      local img = IMG_card[self.hand[i].id]
      local w,h = card_width, card_height
      local x,y = 25+85*(i-1), 450
      local idx = i
      draw_card(self.hand[i], x, y)
      make_button(function()
          game.hover_card = deepcpy(self.hand[idx])
        end, x, y, w, h, false, true)
      if self.game.act_buttons then
        make_button(function()
            --print("trying to play card at idx "..idx)
            if self.client then
              net_send({type="play",index=idx})
              self.game.act_buttons = false
            elseif self:can_play_card(idx) then
              self:play_card(idx)
            end
          end, x, y, w, h)
      end
    end
  end
end

function Game:draw()
  draw_background()
  draw_field()
  self.P1:draw()
  self.P2:draw()

  local left, right = self.P1, self.P2
  if self.P1.side ~= "left" then
    left, right = right, left
  end

  local ldeck, rdeck, lgrave, rgrave = left.deck, right.deck, left.grave, right.grave
  if type(ldeck) == "table" then
    ldeck, rdeck, lgrave, rgrave = #ldeck, #rdeck, #lgrave, #rgrave
  end
  set_color(28, 28, 28)
  --gprint("deck "..ldeck.."    grave "..lgrave, 45, 425)
  --gprint("turn "..self.turn, 260, 425)
  --gprint("deck "..rdeck.."    grave "..rgrave, 405, 425)
  local field_hud_left_start_x, field_hud_y = 162, 417
  local field_hud_right_start_x = 399
  gprint(ldeck, field_hud_left_start_x, field_hud_y)
  gprint(lgrave, field_hud_left_start_x + 38, field_hud_y)
  gprint(left.shuffles, field_hud_left_start_x + 70, field_hud_y)
  gprint(rdeck, field_hud_right_start_x, field_hud_y)
  gprint(rgrave, field_hud_right_start_x + 38, field_hud_y)
  gprint(right.shuffles, field_hud_right_start_x + 70, field_hud_y)
  gprint(self.turn, 308, 383)
  gprint("ready", 397+60, 425+50)
  gprint("shuffle", 395+60, 468+50)
  gprint(self.time_remaining.."s", 465+55, 467 - 30 + 50)
  gprint("size "..left:field_size().."/10", 450+55, 467 - 2 * 30 + 50)
  if self.act_buttons then
    make_button(function()
      if self.client then
        net_send({type="ready"})
        self.act_buttons = false
      else
        self.ready = true
      end
    end, 395+55, 400+50, 50, 60, true)
    make_button(function()
      if self.client then
        net_send({type="shuffle"})
        self.act_buttons = false
      else
        left:attempt_shuffle()
      end
    end, 395+55, 465+50, 50, 20, true)
  end
  if self.hover_card then
    draw_hover_card(self.hover_card)
  end
end

function Button:draw_outline(...)
  set_color(...)
  grectangle("line", self.x1, self.y1, self.w, self.h)
end
