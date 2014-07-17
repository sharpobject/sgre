require "gradient"
local love = love

do
  local font_map = {}
  local font_to_str = {
    ["sg_assets/fonts/dgnwan.png"] = "0123456789",
    ["sg_assets/fonts/dmgwan.png"] = "0123456789",
    ["sg_assets/fonts/equalwan_s.png"] = "=0123456789",
    ["sg_assets/fonts/equalwan.png"] = "=0123456789",
    ["sg_assets/fonts/lifewan_rs.png"] = "0123456789",
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
    ["sg_assets/fonts/turnwan.png"] = "0123456789",
  }

  function load_vera(size)
    if font_map[size] then return font_map[size] end
    local ret = love.graphics.newFont(size)
    font_map[size] = ret
    assert(ret)
    return ret
  end

  function load_font(name)
    if font_map[name] then return font_map[name] end
    assert(font_to_str[name])
    local ret = love.graphics.newImageFont(name, font_to_str[name])
    font_map[name] = ret
    assert(ret)
    return ret
  end
end

function load_img(s)
  s = love.image.newImageData("swordgirlsimages/"..s)
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
    s = love.image.newImageData("sg_assets/"..s)
    local w, h = s:getWidth(), s:getHeight()
    local ret = love.graphics.newImage(s)
    asset_map[orig_s] = {ret, w, h}
    return ret,w,h
  end
end

do
  local real_load_img = load_img
  load_img = function(s)
    local status,a,b,c,d = pcall(function()
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

local fonts = {}

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

function draw_hover_card(text_obj)
  local card = G_hover_card or get_active_char() or 100089
  if type(card) == "number" then
    card = Card(card)
  end

  draw_hover_frame()
  love.graphics.setColor(255, 255, 255)
  local id = card.id
  if not IMG_card[id] then
    IMG_card[id], IMG_gray_card[id] = load_img(id.."L.jpg")
  end
  local x,y = 612,15
  love.graphics.draw(IMG_card[id], x, y, 0, 0.5, 0.5)
  local card_width = card_width*2
  local card_height = card_height*2
  local gray_shit_height = (card_height - 200)/2
  local gray_shit_dx = math.floor(card_width*2/3)
  local gray_shit_x = x + gray_shit_dx
  local gray_shit_width = card_width - gray_shit_dx
  local middle = y+(card_height-gray_shit_height)/2
  love.graphics.draw(load_asset("m-"..card.type..".png"), x, y)
  if card.type == "character" then
    if card.life >= 10 then
      love.graphics.setFont(load_font("sg_assets/fonts/lifewan.png"))
    else
      love.graphics.setFont(load_font("sg_assets/fonts/lifewan_rs.png"))
    end
    love.graphics.printf(card.life, gray_shit_x+5, y+207, gray_shit_width, "center")
  elseif card.type == "follower" then
    love.graphics.setFont(load_font("sg_assets/fonts/statwan.png"))
    love.graphics.printf(card.atk, x, y+208, card_width/3, "center")
    love.graphics.printf(card.def, x+card_width/3, y+208, card_width/3, "center")
    love.graphics.printf(card.sta, x+2*card_width/3, y+208, card_width/3, "center")
  end
  if card.size then
    love.graphics.setFont(load_font("sg_assets/fonts/sizewan.png"))
    love.graphics.printf(card.size, gray_shit_x+5, y+11, gray_shit_width, "center")
  end
  if card.faction then
    draw_faction(card.faction, x+3, y+3, 0, 1, 1)
  end
  love.graphics.setColor(28 ,28 ,28)
  local text = card.name.."\n".."Limit "..card.limit.."      "..
    card.points.."pt      "..card.rarity.."      "..
    card.episode.." ".."\n\n"
  text = text .. (skill_text[card.id] or "")
  if card.type == "follower" then
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
        text = text .. "\n\n"
      end
    end
  end
  text = text.."\n\n"..card.flavor
  -- TODO: scrub the json file instead of scrubbing here
  text = table.concat(filter(function(x) return string.byte(x) < 128 end,procat(text)))
  text_obj:SetText(text:gsub("\n"," \n "))
end

local bkg_grad, bkg_batch = nil, nil
function draw_background()
  bkg_grad = bkg_grad or gradient({direction="horizontal", {254, 248, 164, 0}, {254, 248, 164}})
  local bkg, bkg_width, bkg_height = load_asset("background.png")
  bkg:setWrap('repeat','repeat')
  if not bkg_batch then
    bkg_batch = love.graphics.newSpriteBatch(bkg, 4000, "static")
    for x=0,800,20 do
      for y=0,600,20 do
        bkg_batch:add(x,y)
      end
    end
  end
  love.graphics.draw(bkg_batch)
  love.graphics.draw(bkg_grad, 0, -love.graphics.getHeight()/2, 0,
      love.graphics.getWidth()/bkg_grad:getWidth(),
      love.graphics.getHeight()*2/bkg_grad:getHeight())
end

function draw_border(x,y,w,h)
  love.graphics.setColor(255, 255, 255)
  local cx, cy = 3+4,2+4
  local c, cw, ch = load_asset("border-1.png")
  love.graphics.draw(load_asset("border-left.png"), x-4, y, 0, 1, h)
  love.graphics.draw(load_asset("border-right.png"), x+w, y, 0, 1, h)
  love.graphics.draw(load_asset("border-top.png"), x, y-4, 0, w, 1)
  love.graphics.draw(load_asset("border-bottom.png"), x, y+h, 0, w, 1)
  love.graphics.draw(load_asset("border-1.png"), x-cx, y-cy)
  love.graphics.draw(load_asset("border-2.png"), x+w+cx-cw, y-cy)
  love.graphics.draw(load_asset("border-3.png"), x-cx, y+h+cy-ch)
  love.graphics.draw(load_asset("border-4.png"), x+w+cx-cw, y+h+cy-ch)
end

field_x, field_y = 16, 10
local field_x, field_y = field_x, field_y
function Game:draw_field()
  local field_img, fw, fh = load_asset("field.png")
  local fx, fy = field_x, field_y
  love.graphics.draw(field_img, fx, fy)
  love.graphics.draw(load_asset("field_hud.png"), fx+4, fy+340)
  local p1_name, p2_name, nw, nh =
      load_asset("name-red.png"), load_asset("name-blue.png")
  local left_text, right_text = self.P1.name, self.P2.name
  if self.P1.side ~= "left" then
    p1_name, p2_name = p2_name, p1_name
    left_text, right_text = right_text, left_text
  end
  love.graphics.draw(p1_name, fx+7, fy+fh-6-nh)
  love.graphics.draw(p2_name, fx+fw-7-nw, fy+fh-6-nh)
  love.graphics.setFont(load_vera(12))
  love.graphics.printf(left_text, fx+7+4, fy+fh-6-nh+2, nw-8, "left")
  love.graphics.printf(right_text, fx+fw-7-nw+4, fy+fh-6-nh+2, nw-8, "right")
  draw_border(fx, fy, fw, fh)
end

function draw_hover_frame(x,y,w,h)
  if not x then
    local junk, fw = load_asset("field.png")
    x = field_x+fw+4+13+4
    y = field_y
    w, h = 800 - field_x - x, 600 - field_y - y
  end
  love.graphics.setColor(254, 226, 106)
  love.graphics.rectangle("fill", x, y, w, h)
  draw_border(x, y, w, h)
end

function left_hover_frame_pos()
  local junk, fw = load_asset("field.png")
  local x = field_x+fw+4+13+4
  local y = field_y
  local w, h = 800 - field_x - x, 600 - field_y - y
  x = 800 - (x+w)
  return x,y,w,h
end

function draw_hand_frame()
  local junk, fw, fh = load_asset("field.png")
  local x = field_x
  local y = field_y+fh+4+6+4
  local w, h = fw, 600 - field_y - y
  love.graphics.setColor(254, 226, 106)
  love.graphics.rectangle("fill", x, y, w, h)
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
  hand = {{28,458},
          {112,458},
          {196,458},
          {280,458},
          {364,458}}}

function draw_card(card, x, y, lighten_frame, text)
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
    if lighten_frame then
      love.graphics.draw(load_asset("s-highlight-"..card.type..".png"), x, y)
    else
      love.graphics.draw(load_asset("s-"..card.type..suffix..".png"), x, y)
    end
    if card.size then
      love.graphics.setFont(load_font("sg_assets/fonts/sizewan_s.png"))
      love.graphics.printf(card.size, gray_shit_x + 3, y+2, gray_shit_width, "center")
    end
    if card.type == "character" then
      if card.life >= 10 then
        love.graphics.setFont(load_font("sg_assets/fonts/lifewan_s.png"))
        love.graphics.printf(card.life, gray_shit_x + 2, y+100, gray_shit_width, "center")
      else
        love.graphics.setFont(load_font("sg_assets/fonts/lifewan_rs.png"))
        love.graphics.printf(math.max(card.life, 0), gray_shit_x + 2, y+98, gray_shit_width, "center")
      end
    end
    if card.faction then
      draw_faction(card.faction, x+1, y+1, 0, 0.5, 0.5, suffix)
    end
  end
  if text then
    love.graphics.setColor(28,28,28)
    love.graphics.rectangle("fill",x,middle,
      card_width, gray_shit_height)
    love.graphics.setColor(255,255,255)
    love.graphics.setFont(load_vera(12))
    love.graphics.printf(text, x, middle+3, card_width, "center")
  end
end

function set_buff_font(kind)
  if kind == "+" then
    love.graphics.setFont(load_font("sg_assets/fonts/pluswan_s.png"))
  elseif kind == "-" then
    love.graphics.setFont(load_font("sg_assets/fonts/minuswan_s.png"))
  else
    love.graphics.setFont(load_font("sg_assets/fonts/equalwan_s.png"))
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
    love.graphics.setColor(255, 255, 255, 255)

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
      draw_card(self.card, x, y, hover_frame, text)
    end

    if self.animation then
      local img = load_asset(self.animation.filename)
      local dx = self.animation.dx - math.floor((img:getWidth() - 80)/2)
      local dy = self.animation.dy - math.floor((img:getHeight() - 120)/2)
      love.graphics.draw(img, x+dx, y+dy)
    end

    if self.buff_animation then
      local frame = self.buff_animation.frame
      local stat_to_dxdy = {size = {card_width*2/3 + 3, 2},
                            atk = {0, 102},
                            def = {card_width/3, 102},
                            sta = {card_width*2/3, 102},
                            life = {card_width*2/3 + 2, 99}}
      for k,v in pairs(stat_to_dxdy) do
        local this_buff = self.buff_animation[k]
        if this_buff then
          set_buff_font(this_buff[1])
          love.graphics.printf(this_buff[1]..this_buff[2], x+v[1], y+v[2]-frame, card_width/3, "center")
        end
      end
    end
  end
  button.Update = function(self)
    local hand = side == "hand"
    local player = game.P1
    if player.side == "right" then player = player.opponent end
    if side == "right" then player = player.opponent end

    local member = "field"
    if hand then
      member = "hand"
    else
      local animation = player.animation[idx]
      if animation then
        local frame = math.floor(animation.frame)..""
        while frame:len() < 3 do frame = "0"..frame end
        self.animation = {
            filename = "animations/"..animation.kind.."/"..frame..".png",
            dx = animation.dx,
            dy = animation.dy,
          }
        animation.frame = animation.frame + .5
        if animation.frame == animation.framecount then
          player.animation[idx] = nil
        end
      else
        self.animation = nil
      end

      local buff_animation = player.buff_animation[idx]
      if buff_animation then
        self.buff_animation = buff_animation
        buff_animation.frame = buff_animation.frame + .5
        if buff_animation.frame == 20 then
          player.buff_animation[idx] = nil
        end
      else
        self.buff_animation = nil
      end
    end

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
        if game.game_type == "pve" or game.time_remaining > 0 then
          net_send({type="play",index=idx})
          self.player.game.act_buttons = false
        end
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

local function modal_choice(prompt, lt, rt, lcb, rcb)
  prompt = prompt or "Is this prompt dumb?"
  lt = lt or "Yes"
  rt = rt or "No"
  lcb = lcb or function()end
  rcb = rcb or function()end

  local frame = loveframes.Create("frame")
  frame:SetName("")
  frame:SetSize(300, 90)
  frame:ShowCloseButton(false)
  frame:SetDraggable(false)
  frame:Center()
  frame:SetState(loveframes.GetState())
  
  local ptext = loveframes.Create("text", frame)
  ptext:SetText(prompt)
  ptext:Center()
  ptext:SetY(35)
  
  local lb = loveframes.Create("button", frame)
  lb:SetPos(5, 60)
  lb:SetWidth(143)
  lb:SetText(lt)
  lb.OnClick = function() lcb() frame:Remove() end

  local rb = loveframes.Create("button", frame)
  rb:SetPos(152, 60)
  rb:SetWidth(143)
  rb:SetText(rt)
  rb.OnClick = function() rcb() frame:Remove() end
  
  frame:SetModal(true)
end

function get_hover_list_text(state)
  local junk, fw = load_asset("field.png")

  local list = loveframes.Create("list")
  list:SetState(state)
  list:SetPos(field_x+fw+4+13+4 + 5, 15+240+5)
  list:SetSize(800-field_x*2-fw-4-13-4-10, 250)
  list:SetPadding(5)
  list:SetSpacing(5)
  
  local text = loveframes.Create("text")
  text:SetText("assy cron")
  text:SetFont(load_vera(10))
  list:AddItem(text)
  return list, text
end

function Game:draw()
  self:draw_field()

  local left, right = self.P1, self.P2
  if self.P1.side ~= "left" then
    left, right = right, left
  end

  local junk, fw = load_asset("field.png")

  self.loveframes_buttons = self.loveframes_buttons or frames.playing

  if not self.loveframes_buttons then
    self.loveframes_buttons = {}
    frames.playing = self.loveframes_buttons
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
    local ready_sz = 78
    local shuffle_sz = 122 - ready_sz - 2
    ready:SetText("Ready")
    ready:SetPos(447, 457)
    ready:SetSize(50, ready_sz)
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
    shuffle:SetPos(447, 457+ready_sz+2)
    shuffle:SetSize(50, shuffle_sz)
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

    local list, text = get_hover_list_text("playing")

    local lobby_button = loveframes.Create("button")
    lobby_button:SetState("playing")
    lobby_button:SetY(list:GetY()+list:GetHeight()+5)
    lobby_button:SetX(list:GetX())
    lobby_button:SetWidth(list:GetWidth())
    lobby_button:SetText("Lobby")
    lobby_button:SetHeight(600-field_y-5-lobby_button:GetY())
    function lobby_button:OnClick()
      modal_choice("Really forfeit?", "Yes", "No", function()
          net_send({type="forfeit"})
        end)
    end
    lobby_button.Update = function(self)
        self.enabled = game.act_buttons
      end
    

    self.loveframes_buttons.card_text_list = list
    self.loveframes_buttons.card_text = text
  end

  local ldeck, rdeck, lgrave, rgrave = left.deck, right.deck, left.grave, right.grave
  if type(ldeck) == "table" then
    ldeck, rdeck, lgrave, rgrave = #ldeck, #rdeck, #lgrave, #rgrave
  end


   -- self.loveframes_buttons.ready:SetSize(50, ready_sz)
    --self.loveframes_buttons.shuffle:SetSize(50, shuffle_sz)
    --self.loveframes_buttons.shuffle:SetY(457+ready_sz+2)
  draw_hand_frame()

  love.graphics.setColor(28, 28, 28)
  love.graphics.setFont(load_vera(12))
  --love.graphics.print("deck "..ldeck.."    grave "..lgrave, 45, 425)
  --love.graphics.print("turn "..self.turn, 260, 425)
  --love.graphics.print("deck "..rdeck.."    grave "..rgrave, 405, 425)
  local field_hud_left_start_x, field_hud_y = 135 + field_x, 400 + field_y
  local field_hud_right_start_x = 372 + field_x
  love.graphics.print(ldeck, field_hud_left_start_x, field_hud_y)
  love.graphics.print(lgrave, field_hud_left_start_x + 38, field_hud_y)
  love.graphics.print(left.shuffles, field_hud_left_start_x + 70, field_hud_y)
  love.graphics.print(rdeck, field_hud_right_start_x, field_hud_y)
  love.graphics.print(rgrave, field_hud_right_start_x + 38, field_hud_y)
  love.graphics.print(right.shuffles, field_hud_right_start_x + 70, field_hud_y)
  love.graphics.setColor(255, 255, 255)
  love.graphics.setFont(load_font("sg_assets/fonts/turnwan.png"))
  local draw_turn = self.turn..""
  if draw_turn:len() < 2 then draw_turn = "0"..draw_turn end
  love.graphics.printf(draw_turn[1], field_x+268, 358+field_y, 999)
  love.graphics.printf(draw_turn[2], field_x+282, 358+field_y, 999)
  --love.graphics.setColor(28, 28, 28)
  --love.graphics.setFont(load_vera(12))
  love.graphics.setFont(load_font("sg_assets/fonts/equalwan.png"))
  local time_remaining = self.time_remaining
  if time_remaining < 0.1 then time_remaining = 0 end
  if self.game_type == "pve" then time_remaining = 99 end
  love.graphics.printf(time_remaining, 447+50, 532, field_x+fw-447-50, "center")
  love.graphics.printf("size "..left:field_size(), 447+50, 457 + 3, field_x+fw-447-50, "center")
  if self.hover_card then
    G_hover_card = self.hover_card
  end
end

function deck_card_list_button(id, upgrade, count, cb)
  id = tonumber(id)
  local button = loveframes.Create("button")
  button:SetHeight(13)
  button.Draw = function(self)
    local x = self:GetX()
    local y = self:GetY()
    local hover = self:GetHover()
    local w, h = self:GetWidth(), self:GetHeight()
    local down = self.down

    if hover and not down then
      love.graphics.setColor(220, 220, 255, 160)
      love.graphics.rectangle("fill", x,y,w,h)
    elseif down then
      love.graphics.setColor(220, 220, 255, 220)
      love.graphics.rectangle("fill", x,y,w,h)
    end
    love.graphics.setColor(0, 0, 0, 255)
    love.graphics.setFont(load_vera(10))
    love.graphics.print(id_to_canonical_card[id].name, x, y)
    if type(count) == "number" then
      love.graphics.printf(count, x, y, w, "right")
    end
  end
  button.Update = function(self)
    if self:GetHover() then
      self.card = self.card or Card(id, upgrade)
      G_hover_card = self.card
    end
  end
  button.OnClick = cb
  return button
end

function card_list_button(id, gray, count, cb)
  id = tonumber(id)
  local card = Card(id, upgrade)
  if gray then card.active = false end
  local button = loveframes.Create("imagebutton")
  button.card = card
  button:SetSize(80, 120)
  button.Draw = function(self)
    local x = self:GetX()
    local y = self:GetY()
    local lighten_frame = self:GetHover()
    local down = self.down
    local hand = side == "hand"
    love.graphics.setColor(255, 255, 255, 255)

    --love.graphics.draw(load_asset("hand_slot.png"), x-1, y-1)

    if down then
      x,y = x+1,y+1
    end

    if self.card then
      draw_card(self.card, x, y, lighten_frame)
      if type(count) ~= "nil" and type(count) ~= "table" then
        love.graphics.draw(load_asset("card_count.png"), x+8, y+69)
        love.graphics.setFont(load_vera(10))
        love.graphics.setColor(0, 0, 0, 255)
        love.graphics.printf(tostring(count), x, y+83, 66, "right")
      end
    end
  end
  button.Update = function(self)
    if self.card and self:GetHover() then
      G_hover_card = self.card
    end
  end
  button.OnClick = cb
  assert(button.set_count == nil)
  function button:set_count(n)
    count = n
  end
  function button:set_gray(new_gray)
    gray = new_gray
    card.active = not gray
  end
  button.card_id = id
  return button
end

