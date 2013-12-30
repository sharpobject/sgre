require "gradient"

do
  local font_map = {}
  local font_to_str = {
    ["sg_assets/fonts/dgnwan.png"] = "0123456789",
    ["sg_assets/fonts/dmgwan.png"] = "0123456789",
    ["sg_assets/fonts/equalwan_s.png"] = "=0123456789",
    ["sg_assets/fonts/equalwan.png"] = "=0123456789",
    ["sg_assets/fonts/lifewan_s.png"] = "0123456789",
    ["sg_assets/fonts/lifewan.png"] = "?0123456789",
    ["sg_assets/fonts/minuswan_s.png"] = "-0123456789",
    ["sg_assets/fonts/minuswan.png"] = "-0123456789",
    ["sg_assets/fonts/pluswan_s.png"] = "+0123456789",
    ["sg_assets/fonts/pluswan.png"] = "+0123456789",
    ["sg_assets/fonts/sizewan_s.png"] = "0123456789",
    ["sg_assets/fonts/sizewan.png"] = "0123456789",
    ["sg_assets/fonts/statwan_s.png"] = "-0123456789",
    ["sg_assets/fonts/statwan.png"] = "-0123456789",
    ["sg_assets/fonts/timewan.png"] = "0123456789",
  }

  function load_font(name)
    if font_map[name] then return font_map[name] end
    assert(font_to_str[name])
    local ret = love.graphics.newImageFont(name, font_to_str[name])
    font_map[name] = ret
    return ret
  end
end

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

function set_font(...)
  gfx_q:push({love.graphics.setFont, {...}})
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

function draw_hover_card(card, text_obj)
  draw_hover_frame()
  set_color(255, 255, 255)
  local id = card.id
  if not IMG_card[id] then
    IMG_card[id], IMG_gray_card[id] = load_img(id.."L.jpg")
  end
  local x,y = 612,15
  draw(IMG_card[id], x, y, 0, 0.5, 0.5)
  local card_width = card_width*2
  local card_height = card_height*2
  local gray_shit_height = (card_height - 200)/2
  local gray_shit_dx = math.floor(card_width*2/3)
  local gray_shit_x = x + gray_shit_dx
  local gray_shit_width = card_width - gray_shit_dx
  local middle = y+(card_height-gray_shit_height)/2
  draw(load_asset("m-"..card.type..".png"), x, y)
  if card.type == "character" then
    set_font(load_font("sg_assets/fonts/lifewan.png"))
    gprintf(card.life, gray_shit_x+4, y+208, gray_shit_width, "center")
  elseif card.type == "follower" then
    set_font(load_font("sg_assets/fonts/statwan.png"))
    gprintf(card.atk, x, y+208, card_width/3, "center")
    gprintf(card.def, x+card_width/3, y+208, card_width/3, "center")
    gprintf(card.sta, x+2*card_width/3, y+208, card_width/3, "center")
  end
  if card.size then
    set_font(load_font("sg_assets/fonts/sizewan.png"))
    gprintf(card.size, gray_shit_x+5, y+11, gray_shit_width, "center")
  end
  if card.faction then
    draw_faction(card.faction, x+3, y+3, 0, 1, 1)
  end
  set_color(28 ,28 ,28)
  local text = skill_text[card.id]
  if card.type == "follower" then
    text = ""
    local skills = card.skills or {}
    for i=1,3 do
      if skills[i] then
        if skill_text[skills[i]] then
          text = text .. skill_text[skills[i]]
        else
          text = text .. "Unknown skill with id " .. skills[i]
        end
      else
        text = text .. "-"
      end
      if i < 3 then
        text = text .. " \n \n "
      end
    end
  end
  -- TODO: scrub the json file instead of scrubbing here
  text = table.concat(filter(function(x) return string.byte(x) < 128 end,procat(text)))
  text_obj:SetText(text)
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
  gfx_q:push({love.graphics.drawq or love.graphics.draw, {bkg, bkg_quad, 0, 0}})
  yolo()
  gfx_q:push({love.graphics.draw, {bkg_grad, 0, -love.graphics.getHeight()/2, 0, love.graphics.getWidth()/bkg_grad:getWidth(), love.graphics.getHeight()*2/bkg_grad:getHeight()}})
  yolo()
end

function draw_border(x,y,w,h)
  set_color(255, 255, 255)
  local cx, cy = 3+4,2+4
  local c, cw, ch = load_asset("border-1.png")
  draw(load_asset("border-left.png"), x-4, y, 0, 1, h)
  draw(load_asset("border-right.png"), x+w, y, 0, 1, h)
  draw(load_asset("border-top.png"), x, y-4, 0, w, 1)
  draw(load_asset("border-bottom.png"), x, y+h, 0, w, 1)
  draw(load_asset("border-1.png"), x-cx, y-cy)
  draw(load_asset("border-2.png"), x+w+cx-cw, y-cy)
  draw(load_asset("border-3.png"), x-cx, y+h+cy-ch)
  draw(load_asset("border-4.png"), x+w+cx-cw, y+h+cy-ch)
end

local field_x, field_y = 16, 10
function Game:draw_field()
  local field_img, fw, fh = load_asset("field.png")
  local fx, fy = field_x, field_y
  draw(field_img, fx, fy)
  draw(load_asset("field_hud.png"), fx+4, fy+340)
  local p1_name, p2_name, nw, nh =
      load_asset("name-red.png"), load_asset("name-blue.png")
  local left_text, right_text = self.P1.name, self.P2.name
  if self.P1.side ~= "left" then
    p1_name, p2_name = p2_name, p1_name
    left_text, right_text = right_text, left_text
  end
  draw(p1_name, fx+7, fy+fh-6-nh)
  draw(p2_name, fx+fw-7-nw, fy+fh-6-nh)
  set_font(default_font)
  gprintf(left_text, fx+7+4, fy+fh-6-nh+2, nw-8, "left")
  gprintf(right_text, fx+fw-7-nw+4, fy+fh-6-nh+2, nw-8, "right")
  draw_border(fx, fy, fw, fh)
end

function draw_hover_frame()
  local junk, fw = load_asset("field.png")
  local x = field_x+fw+4+13+4
  local y = field_y
  local w, h = 800 - field_x - x, 600 - field_y - y
  set_color(254, 226, 106)
  grectangle("fill", x, y, w, h)
  draw_border(x, y, w, h)
end

function draw_hand_frame()
  local junk, fw, fh = load_asset("field.png")
  local x = field_x
  local y = field_y+fh+4+6+4
  local w, h = fw, 600 - field_y - y
  set_color(254, 226, 106)
  grectangle("fill", x, y, w, h)
  draw_border(x, y, w, h)
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

function draw_faction_loveframe(faction, x, y, rot, x_scale, y_scale, suffix)
  rot = rot or 0
  x_scale = x_scale or 1
  y_scale = y_scale or 1
  local faction_gfx = {['E'] = "empire",
    ['D'] = "darklore",
    ['N'] = "sg",
    ['V'] = "vita",
    ['C'] = "crux",
    ['A'] = "academy"}
  local faction_img = load_asset(faction_gfx[faction]..suffix..".png")
  love.graphics.draw(faction_img, x, y, rot, x_scale, y_scale)
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
            {472,264}},
  hand = {{25,450},
          {110,450},
          {195,450},
          {280,450},
          {365,450}}}

function draw_card_loveframe(card, x, y, hover_frame, text)
  local id = card.id
  if card.hidden then
    id = 200099
  end
  if not IMG_card[id] then
    IMG_card[id], IMG_gray_card[id] = load_img(id.."L.jpg")
  end
  if card.type == "character" or card.active then
    love.graphics.draw(IMG_card[id], x, y, 0, card_scale, card_scale)
  else
    love.graphics.draw(IMG_gray_card[id], x, y, 0, card_scale, card_scale)
  end
  local card_width = card_width
  local card_height = card_height
  local gray_shit_height = card_height - 100
  local gray_shit_dx = math.floor(card_width*2/3)
  local gray_shit_x = x + gray_shit_dx
  local gray_shit_width = card_width - gray_shit_dx
  local middle = y+(card_height-gray_shit_height)/2
  love.graphics.setColor(255, 255, 255)
  if not card.hidden then
    if card.type == "follower" then
      love.graphics.setFont(load_font("sg_assets/fonts/statwan_s.png"))
      love.graphics.printf(card.atk, x, y+102, card_width/3, "center")
      love.graphics.printf(card.def, x+card_width/3, y+102, card_width/3, "center")
      love.graphics.printf(card.sta, x+2*card_width/3, y+102, card_width/3, "center")
    end
    local suffix = ""
    if not (card.type == "character" or card.active) then
      suffix = "-g"
    end
    if hover_frame then
      love.graphics.draw(load_asset("s-highlight-"..card.type..".png"), x, y)
    else
      love.graphics.draw(load_asset("s-"..card.type..suffix..".png"), x, y)
    end
    if card.size then
      love.graphics.setFont(load_font("sg_assets/fonts/sizewan_s.png"))
      love.graphics.printf(card.size, gray_shit_x + 3, y+2, gray_shit_width, "center")
    end
    if card.type == "character" then
      love.graphics.setFont(load_font("sg_assets/fonts/lifewan_s.png"))
      love.graphics.printf(card.life, gray_shit_x + 2, y+100, gray_shit_width, "center")
    end
    if card.faction then
      draw_faction_loveframe(card.faction, x+1, y+1, 0, 0.5, 0.5, suffix)
    end
  end
  if text then
    love.graphics.setColor(28,28,28)
    love.graphics.rectangle("fill",x,middle,
      card_width, gray_shit_height)
    love.graphics.setColor(255,255,255)
    love.graphics.setFont(default_font)
    love.graphics.printf(text, x, middle+3, card_width, "center")
  end
end

function card_button(side,idx,x,y)
  local button = loveframes.Create("imagebutton")
  button:SetSize(80, 120)
  button:SetX(x)
  button:SetY(y)
  button:SetState("playing")
  button.client = game.client
  button.Draw = function(self)
    local x = self:GetX()
    local y = self:GetY()
    local hover = self:GetHover()
    local down = self.down
    local hand = side == "hand"
    local hover_frame = hover and hand

    if hand then
      love.graphics.draw(load_asset("hand_slot.png"), x-1, y-1)
    end

    if down and hand then
      x,y = x+1,y+1
    end

    if self.card then
      local text = nil
      if self.card.trigger then
        text = "trigger"
      elseif game.print_attack_info and not hand then
        if self.player == game.attacker[1] and idx == game.attacker[2] then
          text = "attack"
        elseif self.player == game.defender[1] and idx == game.defender[2] then
          text = "defend"
        end
      end
      love.graphics.setColor(255, 255, 255, 255)
      draw_card_loveframe(self.card, x, y, hover_frame, text)
    end
  end
  button.Update = function(self)
    local hand = side == "hand"
    local player = game.P1
    if player.side == "right" then player = player.opponent end
    if side == "right" then player = player.opponent end

    local member = "field"
    if hand then member = "hand" end

    self.player = player
    self.card = player[member][idx]
    if self.card and self:GetHover() and not self.card.hidden then
      game.hover_card = self.card
    end
  end
  if side == "hand" then
    button.OnClick = function(self)
      if not self.card then return end
      if self.client then
        net_send({type="play",index=idx})
        self.player.game.act_buttons = false
      elseif self.player:can_play_card(idx) then
        self.player:play_card(idx)
      end
    end
  end
  return button
end

function faction_button(faction, x, y)
  local button = loveframes.Create("imagebutton")
  button:SetSize(180, 270)
  button:SetX(x)
  button:SetY(y)
  button.Draw = function(self)
    local x = self:GetX()
    local y = self:GetY()
    local hover = self:GetHover()
    local down = self.down

    if down then
      x,y = x+1,y+1
    end

    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.draw(load_asset("start_"..faction..".png"), x, y)
    if not hover then
      love.graphics.setColor(0,0,0,92)
      love.graphics.rectangle("fill",x,y,180,270)
      love.graphics.setColor(255, 255, 255, 255)
    end
  end
  button.OnClick = function(self)
    net_send({type="select_faction",faction=faction})
  end
  return button
end

function Game:draw()
  self:draw_field()

  local left, right = self.P1, self.P2
  if self.P1.side ~= "left" then
    left, right = right, left
  end

  local junk, fw = load_asset("field.png")

  self.loveframes_buttons = self.loveframes_buttons or game_loveframes_buttons

  if not self.loveframes_buttons then
    self.loveframes_buttons = {}
    game_loveframes_buttons = self.loveframes_buttons
    self.loveframes_buttons.hand = {}
    for i=1,5 do
      self.loveframes_buttons.hand[i] = 
        card_button("hand", i, unpack(slot_to_dxdy.hand[i]))
    end
    for _,side in ipairs({"left", "right"}) do
      self.loveframes_buttons[side] = {}
      for i=0,5 do
        local x = slot_to_dxdy[side][i][1] + field_x
        local y = slot_to_dxdy[side][i][2] + field_y
        self.loveframes_buttons[side][i] = card_button(side, i, x, y)
      end
    end

    local ready = loveframes.Create("button")
    ready:SetText("Ready")
    ready:SetPos(395+55, 400+50)
    ready:SetSize(50, 60)
    ready:SetState("playing")
    ready.OnClick = function()
        if game.client then
          net_send({type="ready"})
          game.act_buttons = false
        else
          game.ready = true
        end
      end
    ready.Update = function(self)
        self.enabled = game.act_buttons
      end

    local shuffle = loveframes.Create("button")
    shuffle:SetText("Shuffle")
    shuffle:SetPos(395+55, 465+50)
    shuffle:SetSize(50, 20)
    shuffle:SetState("playing")
    shuffle.OnClick = function()
        if self.client then
          net_send({type="shuffle"})
          self.act_buttons = false
        else
          left:attempt_shuffle()
        end
      end
    shuffle.Update = function(self)
        self.enabled = game.act_buttons
      end

    self.loveframes_buttons.ready = ready
    self.loveframes_buttons.shuffle = shuffle
    
    local list = loveframes.Create("list")
    list:SetState("playing")
    list:SetPos(field_x+fw+4+13+4 + 5, 15+240+5)
    list:SetSize(800-field_x*2-fw-4-13-4-10, 120)
    list:SetPadding(5)
    list:SetSpacing(5)
    
    local text = loveframes.Create("text")
    text:SetText("assy cron")
    list:AddItem(text)

    self.loveframes_buttons.card_text_list = list
    self.loveframes_buttons.card_text = text
  end

  local ldeck, rdeck, lgrave, rgrave = left.deck, right.deck, left.grave, right.grave
  if type(ldeck) == "table" then
    ldeck, rdeck, lgrave, rgrave = #ldeck, #rdeck, #lgrave, #rgrave
  end

  draw_hand_frame()

  set_color(28, 28, 28)
  set_font(default_font)
  --gprint("deck "..ldeck.."    grave "..lgrave, 45, 425)
  --gprint("turn "..self.turn, 260, 425)
  --gprint("deck "..rdeck.."    grave "..rgrave, 405, 425)
  local field_hud_left_start_x, field_hud_y = 135 + field_x, 400 + field_y
  local field_hud_right_start_x = 372 + field_x
  gprint(ldeck, field_hud_left_start_x, field_hud_y)
  gprint(lgrave, field_hud_left_start_x + 38, field_hud_y)
  gprint(left.shuffles, field_hud_left_start_x + 70, field_hud_y)
  gprint(rdeck, field_hud_right_start_x, field_hud_y)
  gprint(rgrave, field_hud_right_start_x + 38, field_hud_y)
  gprint(right.shuffles, field_hud_right_start_x + 70, field_hud_y)
  set_color(255, 255, 255)
  set_font(load_font("sg_assets/fonts/sizewan.png"))
  gprintf(self.turn, field_x+3, 358+field_y, fw, "center")
  set_color(28, 28, 28)
  set_font(default_font)
  gprint(self.time_remaining.."s", 465+55, 467 - 30 + 50)
  gprint("size "..left:field_size().."/10", 450+55, 467 - 2 * 30 + 50)
  if self.hover_card then
    draw_hover_card(self.hover_card, self.loveframes_buttons.card_text)
  end
end
