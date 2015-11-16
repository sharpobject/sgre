require "gradient"
local love = love

local generic_text_color = {155, 94, 33, 255}
local cardinfo_text_color = {128, 82, 36}

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
    if RIP_IMAGEFONTS then return load_vera(12) end
    if font_map[name] then return font_map[name] end
    assert(font_to_str[name])
    local ret = love.graphics.newImageFont(name, font_to_str[name])
    font_map[name] = ret
    assert(ret)
    return ret
  end
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

local GFX_SCALE = 1
local card_scale = .25
local card_width, card_height
local texture_width, texture_height

local fonts = {}

local load_img_async_func

function load_image_on_main_thread(id)
  local s = love.image.newImageData("swordgirlsimages/"..id.."L.jpg")
  local w, h = s:getWidth(), s:getHeight()
  local wp = math.pow(2, math.ceil(math.log(w)/math.log(2)))
  local hp = math.pow(2, math.ceil(math.log(h)/math.log(2)))
  if wp ~= w or hp ~= h then
    local padded = love.image.newImageData(wp, hp)
    padded:paste(s, 0, 0)
    s = padded
  end
  local ret = love.graphics.newImage(s)
  if SUPPORTS_MIPMAPS then
    ret:setMipmapFilter("linear", 0)
  else
    ret:setFilter("linear", "linear")
  end
  s:mapPixel(function(x,y,r,g,b,a)
      local ret = (r+g+b)/3
      return ret,ret,ret,a
    end)
  local gray = love.graphics.newImage(s)
  if SUPPORTS_MIPMAPS then
    gray:setMipmapFilter("linear", 0)
  else
    gray:setFilter("linear", "linear")
  end
  if id ~= 900000 then
    IMG_rdy[id] = true
  end
  return ret,gray,w,h,wp,hp
end

function acquire_img(id)
  local max_cards_in_mem = 64
  local tstamps = IMG_tstamps
  local img_arr = IMG_card
  local img_g_arr = IMG_gray_card
  local ready_arr = IMG_rdy
  tstamps[id] = IMG_tstamp
  if not img_arr[id] then
    img_arr[id], img_g_arr[id] = load_img(id)
    IMG_count = IMG_count + 1
    for i=1,3 do
      if IMG_count > max_cards_in_mem then
        local smallest = IMG_tstamp
        local del_id = 0
        for idx, stamp in pairs(tstamps) do
          if stamp < smallest and ready_arr[idx] then
            del_id = idx
            smallest = stamp
          end
        end
        img_arr[del_id], img_g_arr[del_id] = nil, nil
        ready_arr[del_id] = nil
        tstamps[del_id] = nil
        IMG_count = IMG_count - 1
      end
    end
  end
  IMG_tstamp = IMG_tstamp + 1
end

function load_img(id)
  function async_callback(id, tex, tex_gray)
    if IMG_card[id] then
      local img_ref = IMG_card[id]
      img_ref:getData():paste(tex, 0, 0)
      img_ref:refresh()
      local img_gray_ref = IMG_gray_card[id]
      img_gray_ref:getData():paste(tex_gray, 0, 0)
      img_gray_ref:refresh()
      IMG_rdy[id] = true
    end
  end

  local s = love.image.newImageData(texture_width, texture_height)
  local s2 = love.image.newImageData(texture_width, texture_height)
  local ret = love.graphics.newImage(s)
  if SUPPORTS_MIPMAPS then
    ret:setMipmapFilter("linear", 0)
  else
    ret:setFilter("linear", "linear")
  end
  local gray = love.graphics.newImage(s2)
  if SUPPORTS_MIPMAPS then
    gray:setMipmapFilter("linear", 0)
  else
    gray:setFilter("linear", "linear")
  end
  load_img_async_func(async_callback, id)
  return ret,gray,texture_width,texture_height
end

function async_load(id)
  collectgarbage("collect")
  love = require "love"
  require "love.image"

  -- tries to grab image, returns predefined placeholder otherwise
  function load_img_data(id)
    local status, tex = pcall(function()
        return love.image.newImageData("swordgirlsimages/"..id.."L.jpg")
      end)
    if status then
      return tex
    end
    return love.image.newImageData("swordgirlsimages/900000L.jpg")
  end

  local tex = load_img_data(id)
  local w, h = tex:getWidth(), tex:getHeight()
  local wp = math.pow(2, math.ceil(math.log(w)/math.log(2)))
  local hp = math.pow(2, math.ceil(math.log(h)/math.log(2)))
  if wp ~= w or hp ~= h then
    local padded = love.image.newImageData(wp, hp)
    padded:paste(tex, 0, 0)
    tex = padded
  end
  local tex_gray = love.image.newImageData(wp, hp)
  tex_gray:paste(tex, 0, 0)
  tex_gray:mapPixel(function(x,y,r,g,b,a)
      local ret = (r+g+b)/3
      return ret,ret,ret,a
    end)
  return id,tex,tex_gray
end


function graphics_init()
  IMG_rdy = {}
  IMG_card = {}
  IMG_gray_card = {}

  IMG_tstamps = {}
  IMG_tstamp = 1
  IMG_count = 0

  SUPPORTS_MIPMAPS = love.graphics.isSupported("mipmap")

  IMG_card[900000], IMG_gray_card[900000], card_width, card_height,
    texture_width, texture_height = load_image_on_main_thread(900000)

  card_width = card_width * card_scale
  card_height = card_height * card_scale

  load_img_async_func = async.define("load_img_async", async_load)
end

function draw_hover_card(text_obj)
  local card = G_hover_card or get_active_char() or 100089
  if type(card) == "number" then
    card = Card(card)
  end

  local fx, fy, fw, fh = prepare_hover_frame()
  love.graphics.setColor(255, 255, 255)
  local id = card.id
  acquire_img(id)
  local x,y = 612,21
  local card_bg = load_asset("cardframe.png")
  love.graphics.draw(card_bg, x-7, y-7, 0, 1, 1)
  draw_border_hover(fx, fy, fw, fh)
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
  local name_obj, stats_obj, eff_obj, quote_obj = text_obj[1], text_obj[2], text_obj[3], text_obj[4]
  local eff1_obj, eff2_obj, eff3_obj = eff_obj[1], eff_obj[2], eff_obj[3]
  name_obj:SetText(card.name)
  stats_obj:SetText("Limit "..card.limit.."      "..
    card.points.."pt      "..card.rarity.."      "..
    card.episode)
  if card.type == "follower" then
    local skills = card.skills or {}
    for i=1,3 do
      local text
      if skills[i] then
        if skill_text[skills[i]] then
          text = skill_text[skills[i]]
        else
          text = "Unknown skill with id " .. skills[i]
        end
      else
        text = ""
      end
      -- TODO: scrub the json file instead of scrubbing here
      text = table.concat(filter(function(x) return string.byte(x) < 128 end,procat(text)))
      eff_obj[i]:SetText(text:gsub("\n"," \n "):gsub("Turn Start:","TURN START:")
        :gsub("Attack:","ATTACK:")
        :gsub("Defend:","DEFEND:"))
    end
  else
    local text = (skill_text[card.id] or "")
    -- TODO: scrub the json file instead of scrubbing here
    text = table.concat(filter(function(x) return string.byte(x) < 128 end,procat(text)))
    eff_obj[1]:SetText(text:gsub("\n"," \n "):gsub("Turn Start:","TURN START:"))
    eff_obj[2]:SetText("")
    eff_obj[3]:SetText("")
  end
  quote_obj:SetText(card.flavor:gsub("\n"," \n "))
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

function draw_border_hover(x,y,w,h)
--secondary border layout for menus and hovers
--called by: draw_hover_frame()
--tried4's TODO: work out the numbers so that they seem less arbitary
  love.graphics.setColor(255, 255, 255)
  local cx, cy = 3+4,2+4
  local c, cw, ch = load_asset("border-1.png")
  love.graphics.draw(load_asset("border-left.png"), x-4, y, 0, 1, h)
  love.graphics.draw(load_asset("border-right.png"), x+w, y, 0, 1, h)
  love.graphics.draw(load_asset("border-top.png"), x, y-4, 0, w, 1)
  love.graphics.draw(load_asset("border-bottom.png"), x, y+h, 0, w, 1)
  love.graphics.draw(load_asset("ornament-a-1.png"), x-cx-3, y-cy-7)
  love.graphics.draw(load_asset("ornament-a-2.png"), x+w+cx-cw+2, y-cy-7)
  love.graphics.draw(load_asset("border-3.png"), x-cx, y+h+cy-ch)
  love.graphics.draw(load_asset("border-4.png"), x+w+cx-cw, y+h+cy-ch)
end

function limit_string(text, maxlen)
  local ret = string.len(text) < maxlen and text
      or string.sub(text, 1, maxlen).."…"
  return ret
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
  local left_text, right_text = limit_string(self.P1.name, 12), limit_string(self.P2.name, 12)
  if self.P1.side ~= "left" then
    p1_name, p2_name = p2_name, p1_name
    left_text, right_text = right_text, left_text
  end
  love.graphics.draw(p1_name, fx+7, fy+fh-6-nh)
  love.graphics.draw(p2_name, fx+fw-7-nw, fy+fh-6-nh)
  love.graphics.setFont(load_vera(11))
  love.graphics.printf(left_text, fx+7+4, fy+fh-6-nh+3, nw-8, "left")
  love.graphics.printf(right_text, fx+fw-7-nw+4, fy+fh-6-nh+3, nw-8, "right")
  draw_border(fx, fy, fw, fh)
end

function draw_hover_frame(x,y,w,h,title)
  if not x then
    local junk, fw = load_asset("field.png")
    x = field_x+fw+4+13+4
    y = field_y
    w, h = 800 - field_x - x, 600 - field_y - y
  end
  love.graphics.setColor(254, 226, 106)
  love.graphics.rectangle("fill", x, y, w, h)
  if title then
    local title_bg = load_asset("title_bg.png")
    love.graphics.draw(title_bg, x, y, 0, w, 1)
    love.graphics.setColor(253, 233, 94)
    love.graphics.setFont(load_vera(14))
    love.graphics.printf(title, 60, y+5, 100, "center")
  end
  draw_border_hover(x, y, w, h)
end

function prepare_hover_frame(x,y,w,h,title)
  if not x then
    local junk, fw = load_asset("field.png")
    x = field_x+fw+4+13+4
    y = field_y
    w, h = 800 - field_x - x, 600 - field_y - y
  end
  love.graphics.setColor(254, 226, 106)
  love.graphics.rectangle("fill", x, y, w, h)
  if title then
    local title_bg = load_asset("title_bg.png")
    love.graphics.draw(title_bg, x, y, 0, w, 1)
    love.graphics.setColor(253, 233, 94)
    love.graphics.setFont(load_vera(14))
    love.graphics.printf(title, 60, y+5, 100, "center")
  end
  return x, y, w, h
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
    id = 900000
  end
  acquire_img(id)
  if not IMG_rdy[id] then
    id = 900000
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

function anim_layer()
  local layer = loveframes.Create("image")
  layer:SetSize(0, 0)
  layer:SetX(0)
  layer:SetY(0)
  layer:SetState("playing")
  layer.Draw = function(self)
    for i=0,11 do
      local animation = self.anims[i]
      if animation then
        local img = load_asset(animation.filename)
        local dx = animation.dx - math.floor((img:getWidth() - 80)/2)
        local dy = animation.dy - math.floor((img:getHeight() - 120)/2)
        local pos = self.slotpos[i]
        love.graphics.draw(img, pos.x+dx, pos.y+dy)
      end
    end
    if self.coin_flip then
      local imgname, alpha = unpack(self.coin_frameset)
      local coin_img = load_asset("animations/coin_flip/"..imgname..".png")
      if self.coin_frame > 16 and self.coin_frame < 28 then
        local spin_img = load_asset("animations/coin_flip/flip_bg.png")
        love.graphics.draw(spin_img, 221, 144)
      end
      love.graphics.setColor(255,255,255,alpha)
      love.graphics.draw(coin_img, 221, 144)
      love.graphics.setColor(255,255,255,255)
    end
  end
  layer.Update = function(self)
    for i=0,5 do
      local player = game.P1
      if player.side == "right" then player = player.opponent end
      if side == "right" then player = player.opponent end
      local animation = player.animation[i]
      if animation then
        local frame = math.floor(animation.frame)..""
        while frame:len() < 3 do frame = "0"..frame end
        self.anims[i] = {
            filename = "animations/"..animation.kind.."/"..frame..".png",
            dx = animation.dx,
            dy = animation.dy,
          }
        animation.frame = animation.frame + .15
        if animation.frame >= animation.framecount then
          player.animation[i] = nil
          self.anims[i] = nil
        end
      end
      local opponent = player.opponent
      animation = opponent.animation[i]
      if animation then
        local frame = math.floor(animation.frame)..""
        while frame:len() < 3 do frame = "0"..frame end
        self.anims[i+6] = {
            filename = "animations/"..animation.kind.."/"..frame..".png",
            dx = animation.dx,
            dy = animation.dy,
          }
        animation.frame = animation.frame + .15
        if animation.frame >= animation.framecount then
          opponent.animation[i] = nil
          self.anims[i+6] = nil
        end
      end
    end

    if game.coin_flip then
      self.coin_flip = true
      local frame = math.floor(self.coin_frame)
      if frame == 5 and self.coin_lf < 5 then
        play_sound("coin_start")
      elseif frame == 36 and self.coin_lf < 36 then
        play_sound("coin_end")
      end
      self.coin_lf = frame
      self.coin_frameset = game.coin_anim[frame]
      self.coin_frame = self.coin_frame + .5 / 3
      if self.coin_frame >= 54 then
        game.coin_flip = false
        self.coin_flip = false
        self.coin_frame = 1
      end
    end
  end
  layer.anims = {}
  layer.slotpos = {}
  layer.coin_frame = 1
  layer.coin_flip = false
  for _,side in ipairs({"left", "right"}) do
    for i=0,5 do
      local origx = slot_to_dxdy[side][i][1] + field_x
      local origy = slot_to_dxdy[side][i][2] + field_y
      local offset = side == "left" and 0 or 6
      layer.slotpos[i+offset] = {x = origx, y = origy}
    end
  end
  return anim_layer
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
      local buff_animation = player.buff_animation[idx]
      if buff_animation then
        self.buff_animation = buff_animation
        buff_animation.frame = buff_animation.frame + .5 / 3
        if buff_animation.frame >= 20 then
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
    play_button_sound()
    net_send({type="select_faction",faction=faction})
  end
  return button
end

 --replace text buttons with image buttons
 --called by: mainloop.lua
 --tried4's TODO: highlight on hover feature

function make_menubar(x,y)
  local button = loveframes.Create("imagebutton")
  button:SetX(x)
  button:SetY(y)
  button:SetState("lobby")
  button.Draw = function(self)
    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.draw(load_asset("menubar.png"), x-1-1, y-1)
  end
  return button
end

function menu_dungeon_button(x, y)
  local button = loveframes.Create("imagebutton")
  button:SetX(x)
  button:SetY(y)
  button:SetState("lobby")
  button.Draw = function(self)
    love.graphics.setColor(255, 255, 255)
    love.graphics.draw(load_asset("dungeon.png"), x-1, y-1)
  end
  return button
end

function menu_fight_button(x, y)
  local button = loveframes.Create("imagebutton")
  button:SetX(x)
  button:SetY(y)
  button:SetState("lobby")
  button.Draw = function(self)
    love.graphics.setColor(255, 255, 255)
    love.graphics.draw(load_asset("fight.png"), x-1-1, y-1)
  end
  return button
end

function menu_cafe_button(x, y)
  local button = loveframes.Create("imagebutton")
  button:SetX(x)
  button:SetY(y)
  button:SetState("lobby")
  button.Draw = function(self)
    love.graphics.setColor(255, 255, 255)
    love.graphics.draw(load_asset("cafe.png"), x-1, y-1)
  end
  return button
end

function menu_deck_button(x, y)
  local button = loveframes.Create("imagebutton")
  button:SetX(x)
  button:SetY(y)
  button:SetState("lobby")
  button.Draw = function(self)
    love.graphics.setColor(255, 255, 255)
    love.graphics.draw(load_asset("deck.png"), x-1, y-1)
  end
  return button
end

function menu_craft_button(x, y)
  local button = loveframes.Create("imagebutton")
  button:SetX(x)
  button:SetY(y)
  button:SetState("lobby")
  button.Draw = function(self)
    love.graphics.setColor(255, 255, 255)
    love.graphics.draw(load_asset("lab.png"), x-1, y-1)
  end
  return button
end

function menu_xmute_button(x, y)
  local button = loveframes.Create("imagebutton")
  button:SetX(x)
  button:SetY(y)
  button:SetState("lobby")
  button.Draw = function(self)
    love.graphics.setColor(255, 255, 255)
    love.graphics.draw(load_asset("xmute.png"), x-1, y-1)
  end
  return button
end

 -- Player Info Panel
 -- Lobby only

function make_player_info(frame)
  --tried4's TODO: don't hardcode frame position and size
  local player_panel = loveframes.Create("frame",frame)
  local x,y,w,h = left_hover_frame_pos()
  player_panel:SetPos(764-w,-10)
  player_panel:SetSize(w,h)
  player_panel:ShowCloseButton(false)
  player_panel:SetDraggable(false)
  player_panel.Draw = function(self)
  draw_hover_frame(self.x, self.y, self.width, self.height)
  love.graphics.draw(load_asset("bg-ornament.png"),764-w+26,-10+20)
  love.graphics.draw(load_asset("logo.png"),764-w+22,-10+20,0,.85)
  local id = get_active_char() or 100089
  acquire_img(id)
  love.graphics.draw(load_asset("cardframe.png"), 800-w-11, 80)
  love.graphics.draw(IMG_card[id], 800-w-4, 87, 0, .5, .5)
  love.graphics.draw(load_asset("m-character.png"), 800-w-4, 87)
  love.graphics.draw(load_asset("nick_name.png"),788-w-4, 337)
  love.graphics.setColor(144, 103, 55, 255)
  love.graphics.printf(user_data.username, 800-w*2/3-4, 347, 38, "center")
  love.graphics.setFont(load_font("sg_assets/fonts/lifewan.png"))
  love.graphics.setColor(255, 255, 255, 255)
  local card = Card(id)
  love.graphics.printf(math.max(card.life, 0), 800-w/2+17, h/2+4, 50, "center")
  draw_faction(card.faction, 800-w-1, 90, 0, 1, 1)
  end
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
  ptext:SetDefaultColor(generic_text_color)
  ptext:SetText(prompt)
  ptext:Center()
  ptext:SetY(35)

  local lb = loveframes.Create("button", frame)
  lb:SetPos(5, 60)
  lb:SetWidth(143)
  lb:SetText(lt)
  lb.OnClick = function()
    play_button_sound()
    lcb()
    frame:Remove()
  end

  local rb = loveframes.Create("button", frame)
  rb:SetPos(152, 60)
  rb:SetWidth(143)
  rb:SetText(rt)
  rb.OnClick = function()
    play_cancel_sound()
    rcb()
    frame:Remove()
  end

  frame:SetModal(true)
end

function get_hover_list_text(state)
  local junk, fw = load_asset("field.png")

  local list = loveframes.Create("list")
  list:SetState(state)
  list:SetPos(field_x+fw+4+13+4 + 5, 15+240+18)
  list:SetSize(800-field_x*2-fw-4-13-4-10, 250)
  list:SetPadding(5)
  list:SetSpacing(5)

  local name = loveframes.Create("text")
  name:SetDefaultColor(cardinfo_text_color)
  name:SetText("Sword Girl")
  name:SetFont(load_vera(11))
  list:AddItem(name)

  local stats = loveframes.Create("text")
  stats:SetDefaultColor(cardinfo_text_color)
  stats:SetText("Limit: over 9000")
  stats:SetFont(load_vera(10))
  list:AddItem(stats)

  local eff1 = loveframes.Create("text")
  eff1:SetDefaultColor(cardinfo_text_color)
  eff1:SetText("TURN START:")
  eff1:SetFont(load_vera(10))
  list:AddItem(eff1)

  local eff2 = loveframes.Create("text")
  eff2:SetDefaultColor(cardinfo_text_color)
  eff2:SetText("ATTACK:")
  eff2:SetFont(load_vera(10))
  list:AddItem(eff2)

  local eff3 = loveframes.Create("text")
  eff3:SetDefaultColor(cardinfo_text_color)
  eff3:SetText("DEFEND:")
  eff3:SetFont(load_vera(10))
  list:AddItem(eff3)

  local text = {eff1, eff2, eff3}

  local quote = loveframes.Create("text")
  quote:SetDefaultColor(cardinfo_text_color)
  quote:SetText("[The moe is strong with this one]")
  quote:SetFont(load_vera(10))
  list:AddItem(quote)
  return list, name, stats, text, quote
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

    if not self.anim_layer then
      self.anim_layer = anim_layer()
    end

    local ready = loveframes.Create("button")
    local ready_sz = 78
    local shuffle_sz = 122 - ready_sz - 2
    ready:SetText("Ready")
    ready:SetPos(447, 457)
    ready:SetSize(50, ready_sz)
    ready:SetState("playing")
    ready.OnClick = function()
        play_button_sound()
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
        play_button_sound()
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

    local list, name, stats, text, quote = get_hover_list_text("playing")

    local lobby_button = loveframes.Create("button")
    lobby_button:SetState("playing")
    lobby_button:SetY(list:GetY()+list:GetHeight()+5)
    lobby_button:SetX(list:GetX())
    lobby_button:SetWidth(list:GetWidth())
    lobby_button:SetText("Lobby")
    lobby_button:SetHeight(600-field_y-5-lobby_button:GetY())
    function lobby_button:OnClick()
      play_cancel_sound()
      modal_choice("Really forfeit?", "Yes", "No", function()
          net_send({type="forfeit"})
        end)
    end
    lobby_button.Update = function(self)
        self.enabled = game.act_buttons
      end


    self.loveframes_buttons.card_text_list = list
    self.loveframes_buttons.card_text = {name, stats, text, quote}
  end

  local ldeck, rdeck, lgrave, rgrave = left.deck, right.deck, left.grave, right.grave
  if type(ldeck) == "table" then
    ldeck, rdeck, lgrave, rgrave = #ldeck, #rdeck, #lgrave, #rgrave
  end


   -- self.loveframes_buttons.ready:SetSize(50, ready_sz)
    --self.loveframes_buttons.shuffle:SetSize(50, shuffle_sz)
    --self.loveframes_buttons.shuffle:SetY(457+ready_sz+2)
  draw_hand_frame()

  love.graphics.setColor(99, 71, 19)
  love.graphics.setFont(load_vera(11))
  --love.graphics.print("deck "..ldeck.."    grave "..lgrave, 45, 425)
  --love.graphics.print("turn "..self.turn, 260, 425)
  --love.graphics.print("deck "..rdeck.."    grave "..rgrave, 405, 425)
  local field_hud_left_start_x, field_hud_y = 135 + field_x, 401 + field_y
  local field_hud_right_start_x = 371 + field_x
  love.graphics.print(ldeck, field_hud_left_start_x, field_hud_y)
  love.graphics.print(lgrave, field_hud_left_start_x + 36, field_hud_y)
  love.graphics.print(left.shuffles, field_hud_left_start_x + 70, field_hud_y)
  love.graphics.print(rdeck, field_hud_right_start_x, field_hud_y)
  love.graphics.print(rgrave, field_hud_right_start_x + 36, field_hud_y)
  love.graphics.print(right.shuffles, field_hud_right_start_x + 70, field_hud_y)
  love.graphics.setColor(255, 255, 255)
  love.graphics.setFont(load_font("sg_assets/fonts/turnwan.png"))
  local draw_turn = self.turn..""
  if draw_turn:len() < 2 then draw_turn = "0"..draw_turn end
  love.graphics.printf(draw_turn[1], field_x+268, 358+field_y, 999)
  love.graphics.printf(draw_turn[2], field_x+282, 358+field_y, 999)
  --love.graphics.setColor(28, 28, 28)
  --love.graphics.setFont(load_vera(12))
  local time_remaining = self.time_remaining
  if time_remaining < 0.1 then time_remaining = 0 end
  if self.game_type == "pve" then time_remaining = "∞" end
  love.graphics.setFont(load_vera(32))
  draw_outlined_text(left:field_size(), "right", 497+48, 457+20, 100)
  love.graphics.setFont(load_vera(16))
  draw_outlined_text("/", "right", 497+48+6, 457+20+18, 100)
  love.graphics.setFont(load_vera(12))
  draw_outlined_text("10", "right", 497+48+24, 457+20+26, 100)
  love.graphics.setFont(load_vera(32))
  draw_outlined_text(time_remaining, "center", 497+42, 538, 100)
  if self.hover_card then
    G_hover_card = self.hover_card
  end
end

function draw_outlined_text(text, align, x, y, limit)
  love.graphics.setColor(174, 120, 21)
  local base_x = align == "center" and x-limit/2 or align == "right" and x-limit or x
  love.graphics.printf(text, base_x-1, y-1, limit, align)
  love.graphics.printf(text, base_x+1, y-1, limit, align)
  love.graphics.printf(text, base_x-1, y+1, limit, align)
  love.graphics.printf(text, base_x+1, y+1, limit, align)

  love.graphics.setColor(255, 255, 255)
  love.graphics.printf(text, base_x, y, limit, align)
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
    love.graphics.setColor(generic_text_color)
    love.graphics.setFont(load_vera(10))
    local name = id_to_canonical_card[id].name
    name = limit_string(name, 28)
    love.graphics.print(name, x, y)
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

function card_count_thing(count, points, parent)
  local button = loveframes.Create("button", parent)
  --button:SetHeight(13 * (1+buffer_spaces))
  button.Draw = function(self)
    local x = self:GetX()
    local y = self:GetY()
    local w, h = self:GetWidth(), self:GetHeight()
    local cards_img = load_asset("deck_ct.png")
    local points_img = load_asset("deck_pt.png")
    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.draw(cards_img, x, y, 0, 1, 1)
    love.graphics.draw(points_img, x+w-30-25, y, 0, 1, 1)
    love.graphics.setColor(generic_text_color)
    love.graphics.setFont(load_vera(11))
    love.graphics.print(count, x+22, y+1)
    love.graphics.print(points, x+w-30, y+1)
  end
  button.Update = function(self)
  end
  function button:set_count(n)
    count = n
  end
  function button:set_points(n)
    points = n
  end
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
        love.graphics.setColor(generic_text_color)
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

