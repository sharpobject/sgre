require "cards"
local recipes = recipes
local ceil = math.ceil
local xmutable = require "xmutable"

function wait(n)
  n = n or 1
  for i=1,n do
    coroutine.yield()
  end
end

local main_select_boss, main_play, main_go_hard, main_login
local main_mxm, main_register, main_forgot_password
local main_modal_notice, main_select_faction, main_lobby
local main_fight, main_decks, main_xmute
local main_cafe, main_craft, main_dungeon

frames = {}
local frames = frames

local gobacktodungeon

function fmainloop()
  --local func, arg = main_craft, nil
  local func, arg = main_login, nil
  --local func, arg = main_go_hard, nil
  while true do
    func,arg = func(unpack(arg or {}))
    collectgarbage("collect")
  end
end

function str_to_deck(s)
  s = s:sub(s:find("%d%d%d%d[%dDPC]+")):split("DPC")
  local t = {}
  t[1] = s[1] + 0
  for i=2,#s,2 do
    for j=1,s[i]+0 do
      t[#t+1] = s[i+1]+0
    end
  end
  return t
end

local file_to_deck = function(s)
  file = love.filesystem.newFile("decks/"..s..".txt")
  file:open("r")
  s = file:read(file:getSize())
  file:close()
  return str_to_deck(s)
end

local char_ids = {}
local norm_ids = {}
for k,v in pairs(id_to_canonical_card) do
  if v.type == "spell" or v.type == "follower" then
    norm_ids[#norm_ids+1] = k
  end
end
for k,_ in pairs(characters_func) do
  char_ids[#char_ids+1] = k
end

local function get_deck()
  local t = {}
  t[1] = uniformly(char_ids)
  for i=2,31 do
    t[i] = uniformly(norm_ids)
  end
  return t
end

local function go_hard()
  Player.user_act = Player.ai_act
  GO_HARD = true
  BUFF_COUNTER = 0
  wait = function() end
  game = Game(get_deck(), get_deck())
end

function main_go_hard()
  local strictness = require 'strictness'
  for _,t in ipairs({skill_func, spell_func, characters_func}) do
    for k,v in pairs(t) do
      t[k] = strictness.strictf(v)
    end
  end
  while true do
    go_hard()
    game:run()
    coroutine.yield()
  end
end

local from_login = nil
local doing_login = false
function main_login(email, password)
  network_init()
  email = email or GLOBAL_EMAIL or ""
  password = password or GLOBAL_PASSWORD or ""

  if not frames.login then
    frames.login = {}

    local frame = loveframes.Create("frame")
    frame:SetName("Let's play the SG~")
    frame:SetSize(300, 150)
    frame:ShowCloseButton(false)
    frame:SetDraggable(false)
    frame:Center()
    frame:SetState("login")
    
    local text1 = loveframes.Create("text", frame)
    text1:SetPos(5, 35)
    text1:SetText("E-mail")
    
    local textinput1 = loveframes.Create("textinput", frame)
    textinput1:SetPos(80, 30)
    textinput1:SetWidth(215)
    frames.login.email_input = textinput1
    
    local text2 = loveframes.Create("text", frame)
    text2:SetPos(5, 65)
    text2:SetText("Password")
    
    local textinput2 = loveframes.Create("textinput", frame)
    textinput2:SetPos(80, 60)
    textinput2:SetWidth(215)
    textinput2:SetMasked(true)
    textinput2:SetMaskChar("*")
    frames.login.password_input = textinput2
    
    local loginbutton = loveframes.Create("button", frame)
    loginbutton:SetPos(5, 90)
    loginbutton:SetWidth(290)
    loginbutton:SetText("Login to the SG~")
    loginbutton.OnClick = function()
      net_send({type="login",
        email=textinput1:GetText(),
        password=textinput2:GetText()})
      doing_login = true
      frames.login.login_button.enabled = false
      frames.login.register_button.enabled = false
      frames.login.forgot_button.enabled = false
    end
    frames.login.login_button = loginbutton

    local donebutton = loveframes.Create("button", frame)
    donebutton:SetPos(5, 120)
    donebutton:SetWidth(143)
    donebutton:SetText("Register")
    donebutton.OnClick = function()
      from_login = {main_register, {textinput1:GetText(),
        textinput2:GetText()}}
    end
    frames.login.register_button = donebutton
    
    local clearbutton = loveframes.Create("button", frame)
    clearbutton:SetPos(152, 120)
    clearbutton:SetWidth(143)
    clearbutton:SetText("Forgot Password")
    clearbutton.OnClick = function()
      from_login = {main_forgot_password, {textinput1:GetText(),
        textinput2:GetText()}}
    end
    frames.login.forgot_button = clearbutton
  end

  frames.login.email_input:SetText(email)
  frames.login.password_input:SetText(password)
  loveframes.SetState("login")
  
  while true do
    wait()
    if doing_login then
      if net_q:len() ~= 0 then
        local resp = net_q:pop()
        print(json.encode(resp))
        if resp.type=="login_result" then
          if resp.success then
            while true do
              wait()
              if net_q:len() ~= 0 then
                resp = net_q:pop()
                if resp.type=="user_data" then
                  user_data = resp.value
                  if user_data.collection then
                    user_data.collection = fix_num_keys(user_data.collection)
                  end
                  if user_data.decks then
                    user_data.decks = map(fix_num_keys, user_data.decks)
                  end
                  if user_data.cafe then
                    user_data.cafe = fix_num_keys(user_data.cafe)
                  end
                  doing_login = false
                  from_login = {main_select_faction}
                  break
                end
              end
            end
          else
            doing_login = false
            from_login = {main_modal_notice,
              {"Login failed "..(resp.reason or ":("), 
                {main_login, {frames.login.email_input:GetText(),
                  frames.login.password_input:GetText()}}}}
          end
        end
      end
    end
    if (not doing_login) and from_login then
      frames.login.login_button.enabled = true
      frames.login.register_button.enabled = true
      frames.login.forgot_button.enabled = true
      local ret = from_login
      from_login = nil
      return unpack(ret)
    end
  end
end

local from_register = nil
local registering = false
function main_register(email, password)
  email = email or ""
  password = password or ""

  if not frames.register then
    frames.register = {}
    local frame, text1, textinput1, text2, textinput2,
      text3, textinput3, backbutton, registerbutton

    frame = loveframes.Create("frame")
    frame:SetName("Let's register for the SG~")
    frame:SetSize(300, 150)
    frame:ShowCloseButton(false)
    frame:SetDraggable(false)
    frame:Center()
    frame:SetState("register")
    
    text1 = loveframes.Create("text", frame)
    text1:SetPos(5, 35)
    text1:SetText("Username")
    
    textinput1 = loveframes.Create("textinput", frame)
    textinput1:SetPos(80, 30)
    textinput1:SetWidth(215)
    
    text2 = loveframes.Create("text", frame)
    text2:SetPos(5, 65)
    text2:SetText("E-mail")
    
    textinput2 = loveframes.Create("textinput", frame)
    textinput2:SetPos(80, 60)
    textinput2:SetWidth(215)
    frames.register.email_input = textinput2

    text3 = loveframes.Create("text", frame)
    text3:SetPos(5, 95)
    text3:SetText("Password")
    
    textinput3 = loveframes.Create("textinput", frame)
    textinput3:SetPos(80, 90)
    textinput3:SetWidth(215)
    textinput3:SetMasked(true)
    textinput3:SetMaskChar("*")
    frames.register.password_input = textinput3
    
    backbutton = loveframes.Create("button", frame)
    backbutton:SetPos(5, 120)
    backbutton:SetWidth(143)
    backbutton:SetText("Back")
    backbutton.OnClick = function()
      from_register = {main_login, {textinput2:GetText(), textinput3:GetText()}}
    end
    frames.register.back_button = backbutton
    
    registerbutton = loveframes.Create("button", frame)
    registerbutton:SetPos(152, 120)
    registerbutton:SetWidth(143)
    registerbutton:SetText("Register forrealz")
    registerbutton.OnClick = function(self)
      net_send({type="register",
        username=textinput1:GetText(),
        email=textinput2:GetText(),
        password=textinput3:GetText()})
      registering = true
      frames.register.register_button.enabled = false
      frames.register.back_button.enabled = false
    end
    frames.register.register_button = registerbutton
  end

  frames.register.email_input:SetText(email)
  frames.register.password_input:SetText(password)
  loveframes.SetState("register")
  
  while true do
    wait()
    if registering then
      if net_q:len() ~= 0 then
        local resp = net_q:pop()
        print(json.encode(resp))
        if resp.type=="register_result" then
          frames.register.register_button.enabled = true
          frames.register.back_button.enabled = true
          registering = false
          if resp.success then
            from_register = {main_modal_notice, {"Registration succeeded~", 
              {main_login, {frames.register.email_input:GetText(),
                frames.register.password_input:GetText()}}}}
          else
            from_register = {main_modal_notice, {"Registration failed :(", 
              {main_register, {frames.register.email_input:GetText(),
                frames.register.password_input:GetText()}}}}
          end
        end
      end
    elseif from_register then
      local ret = from_register
      from_register = nil
      return unpack(ret)
    end
  end
end

local from_forgot_password = nil
function main_forgot_password(email, password)
  email = email or ""
  password = password or ""

  if not frames.forgot_password then
    frames.forgot_password = {}

    local frame = loveframes.Create("frame")
    frame:SetName("Too bad you forgot your password for the SG~")
    frame:SetSize(300, 90)
    frame:ShowCloseButton(false)
    frame:SetDraggable(false)
    frame:Center()
    frame:SetState("forgot_password")
    
    local text1 = loveframes.Create("text", frame)
    text1:SetPos(5, 35)
    text1:SetText("E-mail")
    
    local textinput1 = loveframes.Create("textinput", frame)
    textinput1:SetPos(80, 30)
    textinput1:SetWidth(215)
    frames.forgot_password.email_input = textinput1
    
    local donebutton = loveframes.Create("button", frame)
    donebutton:SetPos(5, 60)
    donebutton:SetWidth(143)
    donebutton:SetText("Back")
    donebutton.OnClick = function()
      from_forgot_password = {main_login, {textinput1:GetText(),
        frames.forgot_password.password}}
    end
    
    local clearbutton = loveframes.Create("button", frame)
    clearbutton:SetPos(152, 60)
    clearbutton:SetWidth(143)
    clearbutton:SetText("Request New Password")
    clearbutton.OnClick = function()
      local modal = loveframes.Create("frame")
      modal:SetName("sorry-m9")
      modal:SetSize(300, 120)
      modal:ShowCloseButton(false)
      modal:SetDraggable(false)
      modal:Center()
      modal:SetState("forgot_password")
      modal:SetModal(true)
      
      local modaltext = loveframes.Create("text", modal)
      modaltext:SetText("Password reset is not implemented :(")
      modaltext:Center()
      modaltext:SetY(35)

      local modaltext2 = loveframes.Create("text", modal)
      modaltext2:SetText("Email sharpobject@swordgirls.net for help")
      modaltext2:Center()
      modaltext2:SetY(65)

      local loginbutton = loveframes.Create("button", modal)
      loginbutton:SetPos(5, 90)
      loginbutton:SetWidth(290)
      loginbutton:SetText("Back")
      loginbutton.OnClick = function()
        modal:Remove()
        from_forgot_password = {main_login, {textinput1:GetText(),
          frames.forgot_password.password}}
      end
    end
  end

  frames.forgot_password.password = password
  frames.forgot_password.email_input:SetText(email)
  loveframes.SetState("forgot_password")
  
  while true do
    wait()
    if from_forgot_password then
      local ret = from_forgot_password
      from_forgot_password = nil
      return unpack(ret)
    end
  end
end

local from_modal_notice = nil
function main_modal_notice(text, to_ret)
  if not frames.modal_notice then
    frames.modal_notice = {}

    local frame = loveframes.Create("frame")
    frame:SetName("Notice~")
    frame:SetSize(300, 90)
    frame:ShowCloseButton(false)
    frame:SetDraggable(false)
    frame:Center()
    frame:SetState("modal_notice")
    
    local text1 = loveframes.Create("text", frame)
    frames.modal_notice.text = text1
    
    local okbutton = loveframes.Create("button", frame)
    okbutton:SetPos(5, 60)
    okbutton:SetWidth(290)
    frames.modal_notice.ok_button = okbutton
  end

  frames.modal_notice.text:SetText(text)
  frames.modal_notice.text:Center()
  frames.modal_notice.text:SetY(35)
  frames.modal_notice.ok_button:SetText("OK")
  frames.modal_notice.ok_button.OnClick = function()
    from_modal_notice = to_ret
  end
  loveframes.SetState("modal_notice")
  
  while true do
    wait()
    if from_modal_notice then
      local ret = from_modal_notice
      from_modal_notice = nil
      return unpack(ret)
    end
  end
end

function rewards(data)
  local close = false
  -- make outer frame
  local frame = loveframes.Create("frame")
  frame:SetState("playing")
  frame:SetName("Rewards!")
  frame:SetSize(500, 300)
  frame:ShowCloseButton(false)
  frame:SetDraggable(false)
  frame:SetModal(true)
  loveframes.modalobject.modalbackground:SetState("playing")
  frame:Center()
  
  -- make text in frame
  local text1 = loveframes.Create("text", frame)
  text1:SetText("Rewards:")
  text1:Center()
  text1:SetY(35)

  -- make okbutton that sets 'close' to true
  local okbutton = loveframes.Create("button", frame)
  okbutton:SetWidth(150)
  okbutton:CenterX()
  okbutton:SetY(250)
  okbutton:SetText("OK!")
  okbutton.OnClick = function()
    close = true
  end

  -- spit out rewards received from msg.  if there are too many rewards, let it scroll
  local rewards_list = loveframes.Create("list", frame)
  local test_button = card_list_button(300001, false, 1, function() end)
  local card_width = test_button:GetWidth()
  local spacing = 5
  local ncards = 0
  rewards_list:SetHeight(test_button:GetHeight())
  rewards_list:EnableHorizontalStacking(true)
  rewards_list:SetSpacing(spacing)
  for i, v in pairs(data) do 
    ncards = ncards + 1
  end
  if ncards < 1 then
    rewards_list:Remove()
  end

  local width = math.min(ncards * card_width + (ncards - 1) * spacing, spacing * 4 + card_width * 5 + 15) -- 15 is scrollbar width
  rewards_list:SetWidth(width)
  rewards_list:CenterX()
  rewards_list:CenterY()
  for i, v in pairs(data) do 
    rewards_list:AddItem(card_list_button(i, false, v, function() end))
  end

  -- sit around and wait until 'close' is true, then remove this frame
  while true do
    if close == true then
      frame:Remove()
      break
    end
    wait()
  end
end

function main_select_faction()
  loveframes.SetState("select_faction")
  if user_data.active_deck then
    return main_lobby
  end

  if not frames.select_faction then
    frames.select_faction = {}
    for idx,faction in ipairs({"D","V","A","C"}) do
      idx = idx - 1
      local button = faction_button(faction, 16+(180+16)*idx, 165)
      button:SetState("select_faction")
    end
  end

  loveframes.SetState("select_faction")
  
  while true do
    wait()
    if user_data.active_deck then
      return main_lobby
    end
  end
end

local from_lobby = nil
function main_lobby()
  if not frames.lobby then
    frames.lobby = {}
    local frame, text, textinput

    frame = loveframes.Create("frame")
    frame:SetName("Let's talk about the SG~~")
    frame:SetSize(700, 500)
    frame:ShowCloseButton(false)
    frame:SetDraggable(false)
    frame:Center()
    frame:SetState("lobby")
    
    text = loveframes.Create("textinput", frame)
    text:SetMultiline(true)
    text:SetAutoScroll(true)
    text.linenumbers = false
    text:SetSize(690, 435)
    text:SetPos(5, 30)
    text:SetText("")
    text:SetLimit(200)
    text:SetEditable(false)
    frames.lobby.text = text
    
    textinput = loveframes.Create("textinput", frame)
    textinput:SetWidth(690)
    textinput:Center()
    textinput:SetY(470)
    function textinput:OnEnter()
      local text = self:GetText()
      self:Clear()
      net_send({type="general_chat",text=text})
    end

    frames.lobby.game_buttons = {}


	local button = loveframes.Create("button")
    button:SetPos(0,0)
    button:SetSize(50, 50)
    button:SetText("Fite")
    button:SetState("lobby")
    button.OnClick = function()
      net_send({type="join_fight"})
    end

	--local button = menu_fight_button(725,175)	
    table.insert(frames.lobby.game_buttons, button)
--[[
    local button = loveframes.Create("button")
    button:SetPos(50,0)
    button:SetSize(50, 50)
    button:SetText("NOLD")
    button:SetState("lobby")
    button.OnClick = function()
      net_send({type="dungeon", idx=1})
    end
    table.insert(frames.lobby.game_buttons, button)

    local button = loveframes.Create("button")
    button:SetPos(100,0)
    button:SetSize(50, 50)
    button:SetText("BUNNY")
    button:SetState("lobby")
    button.OnClick = function()
      net_send({type="dungeon", idx=2})
    end
    table.insert(frames.lobby.game_buttons, button)

    local button = loveframes.Create("button")
    button:SetPos(150,0)
    button:SetSize(50, 50)
    button:SetText("GARTS")
    button:SetState("lobby")
    button.OnClick = function()
      net_send({type="dungeon", idx=3})
    end
    table.insert(frames.lobby.game_buttons, button)

    local button = loveframes.Create("button")
    button:SetPos(200,0)
    button:SetSize(50, 50)
    button:SetText("GINGER")
    button:SetState("lobby")
    button.OnClick = function()
      net_send({type="dungeon", idx=4})
    end
    table.insert(frames.lobby.game_buttons, button)

    local button = loveframes.Create("button")
    button:SetPos(250,0)
    button:SetSize(50, 50)
    button:SetText("LAEV")
    button:SetState("lobby")
    button.OnClick = function()
      net_send({type="dungeon", idx=5})
    end
    table.insert(frames.lobby.game_buttons, button)

    local button = loveframes.Create("button")
    button:SetPos(300,0)
    button:SetSize(50, 50)
    button:SetText("SIGMA")
    button:SetState("lobby")
    button.OnClick = function()
      net_send({type="dungeon", idx=7})
    end
    table.insert(frames.lobby.game_buttons, button)
]]
    local button = loveframes.Create("button")
    button:SetPos(700,0)
    button:SetSize(50, 50)
    button:SetText("CAFE")
    button:SetState("lobby")
    button.OnClick = function()
      if frames.cafe then
        frames.cafe.populate_cafe_card_list()
        frames.cafe.update_feeding_list()
        frames.cafe.refresh_stats_pane()
      end
      from_lobby = {main_cafe}
    end

    local button = loveframes.Create("button")
    button:SetPos(750, 100)
    button:SetSize(50, 50)
    button:SetText("XMUTE")
    button:SetState("lobby")
    button.OnClick = function()
      if frames.xmute then
        frames.xmute.xmute_type = nil
        frames.xmute.populate_xmutable_card_list()
      end
      from_lobby = {main_xmute}
    end

   local button = loveframes.Create("button")
    button:SetPos(750,0)
    button:SetSize(50, 50)
    button:SetText("DECKS")
    button:SetState("lobby")
    button.OnClick = function()
      from_lobby = {main_decks}
    end
	--local button = menu_deck_button(725,250)	

    local button = loveframes.Create("button")
    button:SetPos(750,50)
    button:SetSize(50, 50)
    button:SetText("CRAFT")
    button:SetState("lobby")
    button.OnClick = function()
      from_lobby = {main_craft}
    end
    
    local button = loveframes.Create("button")
    button:SetPos(50,0)
    button:SetSize(70, 50)
    button:SetText("DUNGEON")
    button:SetState("lobby")
    button.OnClick = function()
      from_lobby = {main_dungeon}
    end
	--local button = menu_dungeon_button(725,100)	
    table.insert(frames.lobby.game_buttons, button)
  end

  local enable_buttons = check_active_deck()
  for _,button in ipairs(frames.lobby.game_buttons) do
    button:SetEnabled(enable_buttons)
  end

  loveframes.SetState("lobby")
  
  -- goes back to dungeon select screen after a dungeon battle
  if gobacktodungeon then
    gobacktodungeon = false
    from_lobby = {main_dungeon}
  end

  while true do
    wait()
    if net_q:len() ~= 0 then
      local msg = net_q:pop()
      if msg.type=="game_start" then
        -- check if dungeon, prepare to return to dungeon select screen if so
        if from_dungeon then
          gobacktodungeon = true
          frames.dungeon = from_dungeon
          from_dungeon = false
        end
        from_lobby = {main_fight, {msg}}
      end
    end
    if from_lobby then
      local ret = from_lobby
      from_lobby = nil
      return unpack(ret)
    end
  end
end

local function update_deck(deck, diff)
  for k,v in pairs(diff) do
    deck[k] = (deck[k] or 0) + v
    if deck[k] == 0 then
      deck[k] = nil
    end
  end
end

local function collection_ex_deck(coll, deck)
  local ret = {}
  for k,v in pairs(coll) do
    ret[k] = v - (deck[k] or 0)
    if ret[k] == 0 then
      ret[k] = nil
    end
  end
  return ret
end

local function deck_cmp(a, b)
  -- a<b
  a, b = tostring(a), tostring(b)
  if a[1]==b[1] then
    return tonumber(a)<tonumber(b)
  end
  if a[1] == "1" then return true end
  if b[1] == "1" then return false end
  if a[1] == "3" then return true end
  return false
end

local function name_cmp(a, b)
  return id_to_canonical_card[a].name:lower() <
      id_to_canonical_card[b].name:lower()
end

local from_craft = nil
function main_craft()
  if not frames.craft then
    frames.craft = {}
    frames.craft.page_num = 1
    frames.craft.stack = {}

    local list, text = get_hover_list_text("craft")
    frames.craft.card_text_list = list
    frames.craft.card_text = text

    local lobby_button = loveframes.Create("button")
    lobby_button:SetState("craft")
    lobby_button:SetY(list:GetY()+list:GetHeight()+5)
    lobby_button:SetX(list:GetX())
    lobby_button:SetWidth(list:GetWidth())
    lobby_button:SetText("Lobby")
    lobby_button:SetHeight(600-field_y-5-lobby_button:GetY())
    function lobby_button:OnClick()
      from_craft = {main_lobby}
    end

    local craft_pane = loveframes.Create("frame")
    craft_pane:SetState("craft")
    local x,y,w,h = left_hover_frame_pos()
    craft_pane:SetPos(x,y)
    craft_pane:SetSize(w,h)
    craft_pane:ShowCloseButton(false)
    craft_pane:SetDraggable(false)
    craft_pane.Draw = function(self)
      draw_hover_frame(self.x, self.y, self.width, self.height)
    end
  

    local text_card_list = loveframes.Create("list", craft_pane)
    text_card_list:SetWidth(w-12)
    text_card_list:Center()
    text_card_list:SetY(60)
    text_card_list:SetHeight(480)
    text_card_list:SetPadding(0)
    text_card_list:SetSpacing(0)
    function text_card_list:Draw() end

    function frames.craft.update_list()
      local substr = ""
      if craft_search_bar then substr = craft_search_bar:GetText() end
      if substr ~= "" then
        frames.craft.populate_text_card_list(recipes, substr, true)
        frames.craft.populate_card_list(recipes, substr)
      else
        frames.craft.populate_text_card_list(recipes)
        frames.craft.populate_card_list(recipes)
      end
    end

    function frames.craft.spawn_craft_frame(id)
      if frames.craft.craft_frame then
        return
      end
      local frame = loveframes.Create("frame")
      frames.craft.craft_frame = frame
      frame:SetName("Let's craft the "..id_to_canonical_card[id].name)
      frame:SetSize(400, 400)
      frame:ShowCloseButton(false)
      frame:SetDraggable(false)
      frame:SetState("craft")
      frame:SetModal(true)
      loveframes.modalobject.modalbackground:SetState("craft")
      frame:Center()

      local in_list = loveframes.Create("list", frame)
      local test_button = card_list_button(300001, false, 1, function() end)
      local card_width = test_button:GetWidth()
      local card_height = test_button:GetHeight()
      local spacing = 5
      local ncards = 0
      in_list:EnableHorizontalStacking(true)
      in_list:SetSpacing(spacing)
      local width = spacing * 3 + card_width * 4
      local height = spacing + card_height * 2
      in_list:SetWidth(width)
      in_list:SetHeight(height)
      frame:SetWidth(width+2*spacing+2)
      frame:SetHeight(30 + height + spacing+card_height+spacing+1)
      frame:Center()
      for i, v in pairs(recipes[id]) do 
        local coll_amt = frames.craft.collection[i] or 0
        local gray = coll_amt < v
        in_list:AddItem(card_list_button(i, gray, coll_amt.."/"..v,
          function()
            if recipes[i] then
              local stack = frames.craft.stack
              stack[#stack+1] = id
              frame:SetModal(false)
              frame:Remove()
              frames.craft.craft_frame = nil
              frames.craft.spawn_craft_frame(i)
            end
          end))
        ncards = ncards + 1
      end
      in_list:CenterX()
      in_list:SetY(30)
      function in_list.Draw() end

      local out_card = card_list_button(id, false, nil, function() end)
      out_card:SetParent(frame)
      out_card:SetY(30+2*spacing+2*card_height)
      out_card:SetX(math.floor(spacing+1+(card_width+spacing)/2))

      local back_button
      local craft_button = loveframes.Create("button", frame)
      craft_button:SetText("Craft!")
      craft_button:SetWidth(card_width)
      craft_button:SetHeight(card_height/2)
      craft_button:SetX(out_card:GetStaticX()+spacing+card_width)
      craft_button:SetY(out_card:GetStaticY()+card_height/4)
      craft_button.OnClick = function()
        net_send({type="craft", id=id})
        function frames.craft.enable_buttons()
          craft_button:SetEnabled(true)
          back_button:SetEnabled(true)
          frames.craft.collection = collection_ex_deck(
              user_data.collection, union_counters(user_data.decks))
          for _,button in pairs(in_list.children) do
            button:SetEnabled(true)
            local have_amt = frames.craft.collection[button.card_id] or 0
            local req_amt = recipes[id][button.card_id]
            button:set_count(have_amt.."/"..req_amt)
            button:set_gray(have_amt < req_amt)
          end
          for k,v in pairs(recipes[id]) do
            if (frames.craft.collection[k] or 0) < v then
              craft_button:SetEnabled(false)
              break
            end
          end
          frames.craft.enable_buttons = nil
        end
        craft_button:SetEnabled(false)
        back_button:SetEnabled(false)
        for _,button in pairs(in_list.children) do
          button:SetEnabled(false)
        end
      end

      for k,v in pairs(recipes[id]) do
        if (frames.craft.collection[k] or 0) < v then
          craft_button:SetEnabled(false)
          break
        end
      end

      back_button = loveframes.Create("button", frame)
      back_button:SetText("Close")
      back_button:SetWidth(card_width)
      back_button:SetHeight(card_height/2)
      back_button:SetX(out_card:GetStaticX()+2*spacing+2*card_width)
      back_button:SetY(out_card:GetStaticY()+card_height/4)
      back_button.OnClick = function()
        frame:SetModal(false)
        frame:Remove()
        frames.craft.craft_frame = nil
        local stack = frames.craft.stack
        if #stack > 0 then
          frames.craft.spawn_craft_frame(stack[#stack])
          stack[#stack] = nil
        end
      end

    end

    function frames.craft.populate_text_card_list(recipes)
      for k,v in spairs(recipes, name_cmp) do
        text_card_list:AddItem(deck_card_list_button(k, 0, v, function()
          frames.craft.spawn_craft_frame(k)
        end))
      end
    
    complete_card_list = deepcpy(text_card_list)
      frames.craft.populate_text_card_list = function(recipes, substr, search_changed) 
      if substr and search_changed then
        text_card_list:Clear()
        for k,v in spairs(recipes, name_cmp) do
          local comparing_card = Card(k, 0)
          local card_name = string.lower(comparing_card.name)
          local card_skill_text = ""
          if skill_text[k] then card_skill_text = string.lower(skill_text[k]) end
          if comparing_card.type == "follower" then
            local skills = comparing_card.skills or {}
            for i=1,3 do
              if skills[i] then
                if skill_text[skills[i]] then
                  card_skill_text = card_skill_text .. string.lower(skill_text[skills[i]])
                end
              end
              if i < 3 then
                card_skill_text = card_skill_text .. "\n\n"
              end
            end
          end
          if string.find(card_name, substr) or string.find(card_skill_text, substr) then
            text_card_list:AddItem(deck_card_list_button(k, 0, v, function()
            frames.craft.spawn_craft_frame(k)
            end))
          end
        end
      elseif search_changed and not substr then
        text_card_list = deepcpy(complete_card_list)
      end
    end
    
    end

    local card_list = loveframes.Create("list")
    card_list:SetState("craft")
    card_list:SetX(craft_pane:GetX()*2+craft_pane:GetWidth())
    card_list:SetY(craft_pane:GetX())
    card_list:SetHeight(600-card_list:GetY()*2)
    card_list:SetWidth(800-2*card_list:GetX())
    card_list:EnableHorizontalStacking(true)
    function card_list:Draw() end
    card_list:SetSpacing(5)

    local button_width = 20
    local lbutton = loveframes.Create("button")
    lbutton:SetState("craft")
    lbutton:SetX((800 - (craft_pane:GetX()*2+craft_pane:GetWidth())) - 2*button_width - 5)
    lbutton:SetY(530)
    lbutton:SetSize(20,20)
    lbutton:SetText("<")
    function lbutton:OnClick()
      frames.craft.page_num = frames.craft.page_num - 1
      frames.craft.update_list()
    end

    local rbutton = loveframes.Create("button")
    rbutton:SetState("craft")
    rbutton:SetX((800 - (craft_pane:GetX()*2+craft_pane:GetWidth())) - button_width)
    rbutton:SetY(530)
    rbutton:SetSize(20,20)
    rbutton:SetText(">")
    function rbutton:OnClick()
      frames.craft.page_num = frames.craft.page_num + 1
      frames.craft.update_list()
    end
    add_search_bar(craft_pane)
    add_craft_filters()
  
    function frames.craft.populate_card_list(collection, substr)
      card_list:Clear()
      local coll2 = tspairs(collection, deck_cmp)
      local coll = {}
      local collindex = 1
      for i=1,#coll2 do
        filtering = Card(coll2[i][1], 0)
        local card_skill_text = ""
        if skill_text[filtering.id] then card_skill_text = string.lower(skill_text[filtering.id]) end
        if filtering.type == "follower" then
          local skills = filtering.skills or {}
          for i=1,3 do
            if skills[i] then
              if skill_text[skills[i]] then
                card_skill_text = card_skill_text .. string.lower(skill_text[skills[i]])
              end
            end
            if i < 3 then
              card_skill_text = card_skill_text .. "\n\n"
            end
          end
        end
        if ((not craft_filter_values[1]) or craft_filter_values[1] == filtering.type)
            and ((not craft_filter_values[2]) or craft_filter_values[2] == filtering.episode)
            and ((not craft_filter_values[3]) or craft_filter_values[3] == filtering.rarity)
            and ((not craft_filter_values[4]) or craft_filter_values[4] == filtering.faction)
            and ((not craft_filter_values[5]) or craft_filter_values[5] == filtering.size)
            and ((not substr) or string.find(string.lower(filtering.name), substr) 
            or string.find(card_skill_text, substr)) then
          coll[collindex] = coll2[i]
          collindex = collindex + 1
        end
      end
      
      frames.craft.npages = ceil(#coll/16)
      if frames.craft.npages > 0 then
        frames.craft.page_num = bound(1,frames.craft.page_num,frames.craft.npages)
      else
        frames.craft.page_num = 1
      end
      local lbound = (frames.craft.page_num-1)*16+1
      for i=lbound,lbound+15 do
        if not coll[i] then return end
        local k,v = coll[i][1],coll[i][2]
        card_list:AddItem(card_list_button(k, false, v, function()
          frames.craft.spawn_craft_frame(k)
        end))
      end
    end
  end

  frames.craft.collection = collection_ex_deck(
      user_data.collection, union_counters(user_data.decks))
    
    
  list_init = true
  frames.craft.update_list(recipes)
  

  loveframes.SetState("craft")
  reset_filters("craft")
  while true do
    wait()
    if from_craft then
      local ret = from_craft
      from_craft = nil
      return unpack(ret)
    end
  end
end

local function feedable_coll(coll)
  local deck_cards = {}
  for deck_num, deck in pairs(user_data.decks) do
    for card_id, count in pairs(deck) do
      if deck_cards[card_id] then
        if deck_cards[card_id] < count then
          deck_cards[card_id] = count
        end
      else
        deck_cards[card_id] = count
      end
    end
  end
  local non_deck_cards = collection_ex_deck(coll, deck_cards)
  local ret = {}
  for k,v in pairs(non_deck_cards) do
    if (k >= 200000 and k < 210000) or (k >= 300000 and k < 310000) then
      ret[k] = v      
    end
  end
  return ret
end

local from_decks = nil
function main_decks()
  if not frames.decks then
    frames.decks = {}
    frames.decks.page_num = 1

    local list, text = get_hover_list_text("decks")
    frames.decks.card_text_list = list
    frames.decks.card_text = text

    local lobby_button = loveframes.Create("button")
    lobby_button:SetState("decks")
    lobby_button:SetY(list:GetY()+list:GetHeight()+5)
    lobby_button:SetX(list:GetX())
    lobby_button:SetWidth(list:GetWidth())
    lobby_button:SetText("Lobby")
    lobby_button:SetHeight(600-field_y-5-lobby_button:GetY())
    function lobby_button:OnClick()
      from_decks = {main_lobby}
    end

    local deck_pane = loveframes.Create("frame")
    deck_pane:SetState("decks")
    local x,y,w,h = left_hover_frame_pos()
    deck_pane:SetPos(x,y)
    deck_pane:SetSize(w,h)
    deck_pane:ShowCloseButton(false)
    deck_pane:SetDraggable(false)
    deck_pane.Draw = function(self)
      draw_hover_frame(self.x, self.y, self.width, self.height)
    end

    local deck_card_list = loveframes.Create("list", deck_pane)
    deck_card_list:SetWidth(w-12)
    deck_card_list:Center()
    deck_card_list:SetY(60)
    deck_card_list:SetHeight(480)
    deck_card_list:SetPadding(0)
    deck_card_list:SetSpacing(0)
    function deck_card_list:Draw() end


    function frames.decks.update_list()
      frames.decks.populate_deck_card_list(frames.decks.deck)
      frames.decks.populate_card_list(collection_ex_deck(
          user_data.collection, frames.decks.deck))
    end

    function frames.decks.populate_deck_card_list(deck)
      frames.decks.deck = deck
      deck_card_list:Clear()
      for k,v in spairs(deck, deck_cmp) do
        deck_card_list:AddItem(deck_card_list_button(k, 0, v, function()
          update_deck(frames.decks.deck, {[k]=-1})
          net_send({type="update_deck", idx=frames.decks.idx, diff={[k]=-1}})
          frames.decks.update_list()
        end))
      end
    end

    local card_list = loveframes.Create("list")
    card_list:SetState("decks")
    card_list:SetX(deck_pane:GetX()*2+deck_pane:GetWidth())
    card_list:SetY(deck_pane:GetX())
    card_list:SetHeight(600-card_list:GetY()*2)
    card_list:SetWidth(800-2*card_list:GetX())
    card_list:EnableHorizontalStacking(true)
    function card_list:Draw() end
    card_list:SetSpacing(5)

    local button_width = 20
    local lbutton = loveframes.Create("button")
    lbutton:SetState("decks")
    lbutton:SetX((800 - (deck_pane:GetX()*2+deck_pane:GetWidth())) - 2*button_width - 5)
    lbutton:SetY(530)
    lbutton:SetSize(20,20)
    lbutton:SetText("<")
    function lbutton:OnClick()
      frames.decks.page_num = frames.decks.page_num - 1
      frames.decks.update_list()
    end

    local rbutton = loveframes.Create("button")
    rbutton:SetState("decks")
    rbutton:SetX((800 - (deck_pane:GetX()*2+deck_pane:GetWidth())) - button_width)
    rbutton:SetY(530)
    rbutton:SetSize(20,20)
    rbutton:SetText(">")
    function rbutton:OnClick()
      frames.decks.page_num = frames.decks.page_num + 1
      frames.decks.update_list()
    end

    local function can_add_card(deck, id)
      local n = 0
      for k,v in pairs(deck) do
        if k >= 200000 then
          n = n + v
        end
      end
      return n < 30 and ((deck[id] or 0) < Card(id).limit)
    end
  
    add_decks_filters()

    function frames.decks.populate_card_list(collection)
      card_list:Clear()
      local coll2 = tspairs(collection, deck_cmp)
      local coll = {}
      local collindex = 1
      for i=1,#coll2 do
        filtering = Card(coll2[i][1], 0)
        if ((not decks_filter_values[1]) or decks_filter_values[1] == filtering.type)
            and ((not decks_filter_values[2]) or decks_filter_values[2] == filtering.episode)
            and ((not decks_filter_values[3]) or decks_filter_values[3] == filtering.rarity)
            and ((not decks_filter_values[4]) or decks_filter_values[4] == filtering.faction)
            and ((not decks_filter_values[5]) or decks_filter_values[5] == filtering.size) then
          coll[collindex] = coll2[i]
          collindex = collindex + 1
        end
      end
      frames.decks.npages = ceil(#coll/16)
      if frames.decks.npages > 0 then
        frames.decks.page_num = bound(1,frames.decks.page_num,frames.decks.npages)
      else
        frames.decks.page_num = 1
      end
      local lbound = (frames.decks.page_num-1)*16+1
      for i=lbound,lbound+15 do
        if not coll[i] then return end
        local k,v = coll[i][1],coll[i][2]
        card_list:AddItem(card_list_button(k, false, v, function()
          if Card(k).limit == 0 then return end
          if k < 200000 then
            local current_char = get_char(frames.decks.deck)
            if current_char == k then return end
            local msg = {}
            if current_char then
              update_deck(frames.decks.deck, {[current_char]=-1})
              msg[current_char] = -1
            end
            update_deck(frames.decks.deck, {[k]=1})
            msg[k] = 1
            net_send({type="update_deck", idx=frames.decks.idx, diff=msg})
            frames.decks.update_list()
          elseif can_add_card(frames.decks.deck, k) then
            update_deck(frames.decks.deck, {[k]=1})
            net_send({type="update_deck", idx=frames.decks.idx, diff={[k]=1}})
            frames.decks.update_list()
          end
        end))
      end
    end


    local multichoice = loveframes.Create("multichoice", deck_pane)
    multichoice:SetWidth(w - 12)
    multichoice:SetPos(6, 6)
    local nums = arr_to_set(procat("0123456789"))
    function multichoice:OnChoiceSelected(choice)
      if choice[1] ~= "D" then
        choice = "Deck "..(#user_data.decks+1)
      end
      local idx = 0
      for i=6,8 do
        local chr = choice[i]
        if not nums[chr] then break end
        idx = idx*10 + tonumber(chr)
      end
      user_data.active_deck = idx
      net_send({type="set_active_deck", idx=idx})
      frames.decks.idx = idx
      frames.decks.populate_deck_card_list(user_data.decks[idx] or {})
      frames.decks.populate_card_list(collection_ex_deck(
          user_data.collection, frames.decks.deck))
    end
    frames.decks.multichoice = multichoice
  end

  local multichoice = frames.decks.multichoice
  multichoice:Clear()
  for i=1,#user_data.decks do
    local str = "Deck "..i
    multichoice:AddChoice(str)
  end
  local current_str = "Deck "..user_data.active_deck
  multichoice:SelectChoice(current_str)

  loveframes.SetState("decks")
  reset_filters("decks")
  while true do
    wait()
    if from_decks then
      local ret = from_decks
      from_decks = nil
      return unpack(ret)
    end
  end
end



local from_cafe = nil
function main_cafe()
  if not frames.cafe then
    frames.cafe = {}
    frames.cafe.page_num = 1
    frames.cafe.active_character_card_id = false
    frames.cafe.active_character_cafe_id = false
    frames.cafe.active_character_stats = {0, 0, 0, 0, 0}

    -- list of cafe cards on the left
    local list, text = get_hover_list_text("cafe")
    frames.cafe.card_text_list = list
    frames.cafe.card_text = text

    local lobby_button = loveframes.Create("button")
    lobby_button:SetState("cafe")
    lobby_button:SetY(list:GetY()+list:GetHeight()+5)
    lobby_button:SetX(list:GetX())
    lobby_button:SetWidth(list:GetWidth())
    lobby_button:SetText("Lobby")
    lobby_button:SetHeight(600-field_y-5-lobby_button:GetY())
    function lobby_button:OnClick()
      from_cafe = {main_lobby}
    end

    local cafe_pane = loveframes.Create("frame")
    cafe_pane:SetState("cafe")
    local x,y,w,h = left_hover_frame_pos()
    cafe_pane:SetPos(x,y)
    cafe_pane:SetSize(w,h)
    cafe_pane:ShowCloseButton(false)
    cafe_pane:SetDraggable(false)
    cafe_pane.Draw = function(self)
      draw_hover_frame(self.x, self.y, self.width, self.height)
    end

    local cafe_card_list = loveframes.Create("list", cafe_pane)
    cafe_card_list:SetWidth(w-12)
    cafe_card_list:Center()
    cafe_card_list:SetY(60)
    cafe_card_list:SetHeight(480)
    cafe_card_list:SetPadding(0)
    cafe_card_list:SetSpacing(0)

    function frames.cafe.populate_cafe_card_list()
      cafe_card_list:Clear()
      for card_id, cafe_data in spairs(user_data.cafe) do
        for cafe_id, stats in spairs(cafe_data) do
          cafe_card_list:AddItem(deck_card_list_button(card_id, 0, 1, function()
              frames.cafe.active_character_card_id = card_id
              frames.cafe.active_character_cafe_id = cafe_id
              frames.cafe.refresh_stats_pane()
            end))
        end
      end
      local separator = loveframes.Create("text")
      separator:SetText("--------------------------------------------")
      cafe_card_list:AddItem(separator)
      for card_id, number in spairs(user_data.collection) do
        if giftable[card_id] then
          local uncafe_number = number
          if fix_num_keys(user_data.cafe)[card_id] then
            uncafe_number = number - #user_data.cafe[card_id]
          end
          if uncafe_number > 0 then
            cafe_card_list:AddItem(deck_card_list_button(card_id, 0, uncafe_number, function()
                frames.cafe.active_character_card_id = card_id
                frames.cafe.active_character_cafe_id = false
                frames.cafe.refresh_stats_pane()
              end))
          end
        end
      end
    end
    frames.cafe.populate_cafe_card_list()

    -- stats pane in upper-middle
    function frames.cafe.draw_stats_pane(card_id, stats)
      local stats_pane = loveframes.Create("frame")
      frames.cafe.stats_pane = stats_pane
      stats_pane:SetName("Stats")
      stats_pane:SetState("cafe")
      stats_pane:SetPos(x + w + 10, y)
      stats_pane:SetSize(380, 200)
      stats_pane:ShowCloseButton(false)
      stats_pane:SetDraggable(false)
      local texts = {"Wisdom: ", "Sensitivity: ", "Personality: ", "Glamour: ", "Like: "}
      local maximums = {500, 500, 500, 500, 100}
      for i=1,5 do
        local text = loveframes.Create("text", stats_pane)
        text:SetText(texts[i])
        text:SetX(stats_pane:GetWidth()/2)
        text:SetY(30*i)
        local progressbar = loveframes.Create("progressbar", stats_pane)
        progressbar:SetX(stats_pane:GetWidth()/2)
        progressbar:SetY(15+30*i)
        progressbar:SetWidth(stats_pane:GetWidth()/2-10)
        progressbar:SetHeight(10)
        progressbar:SetMax(maximums[i])
        progressbar:SetValue(stats[i])
      end
      if card_id then
        local card = Card(card_id, 0)
        local image = loveframes.Create("image", stats_pane)
        image.card = card
        image:SetSize(80, 120)
        image.Draw = function(self)
          local x = self:GetX()
          local y = self:GetY()
          love.graphics.setColor(255, 255, 255, 255)
          draw_card(self.card, x, y, function() end)
        end
        image:SetX(40)
        image:CenterY()
      end
    end

    function frames.cafe.refresh_stats_pane()
      if frames.cafe.stats_pane then
        frames.cafe.stats_pane:Remove()
      end
      local card_id = frames.cafe.active_character_card_id
      local cafe_id = frames.cafe.active_character_cafe_id
      local stats = frames.cafe.active_character_stats
      if card_id and cafe_id then
        stats = user_data.cafe[card_id][cafe_id]
      else
        stats = {0, 0, 0, 0, 0}
      end
      frames.cafe.draw_stats_pane(card_id, stats)
    end
    frames.cafe.refresh_stats_pane()

    --feeding area
    local feeding_card_list = loveframes.Create("list")
    feeding_card_list:SetState("cafe")
    feeding_card_list:SetX(cafe_pane:GetX()*2+cafe_pane:GetWidth())
    feeding_card_list:SetY(300)
    feeding_card_list:SetHeight(300)
    feeding_card_list:SetWidth(800-2*feeding_card_list:GetX())
    feeding_card_list:EnableHorizontalStacking(true)
    function feeding_card_list:Draw() end
    feeding_card_list:SetSpacing(5)

    local button_width = 20
    local lbutton = loveframes.Create("button")
    lbutton:SetState("cafe")
    lbutton:SetX((800 - (cafe_pane:GetX()*2+cafe_pane:GetWidth())) - 2*button_width - 5)
    lbutton:SetY(570)
    lbutton:SetSize(20,20)
    lbutton:SetText("<")
    function lbutton:OnClick()
      frames.cafe.page_num = frames.cafe.page_num - 1
      frames.cafe.update_feeding_list()
    end

    local rbutton = loveframes.Create("button")
    rbutton:SetState("cafe")
    rbutton:SetX((800 - (cafe_pane:GetX()*2+cafe_pane:GetWidth())) - button_width)
    rbutton:SetY(570)
    rbutton:SetSize(20,20)
    rbutton:SetText(">")
    function rbutton:OnClick()
      frames.cafe.page_num = frames.cafe.page_num + 1
      frames.cafe.update_feeding_list()
    end

    function frames.cafe.update_feeding_list()
      frames.cafe.populate_feeding_card_list(feedable_coll(user_data.collection))
    end

    function frames.cafe.populate_feeding_card_list(collection)
      feeding_card_list:Clear()
      local coll = tspairs(collection)
      frames.cafe.npages = ceil(#coll/8)
      if frames.cafe.npages > 0 then
        frames.cafe.page_num = bound(1,frames.cafe.page_num,frames.cafe.npages)
      else
        frames.cafe.page_num = 1
      end
      local lbound = (frames.cafe.page_num-1)*8+1
      for i=lbound,lbound+7 do
        if not coll[i] then return end
        local k,v = coll[i][1],coll[i][2]
        feeding_card_list:AddItem(card_list_button(k, false, v, function()
            if not frames.cafe.active_character_card_id then
              return false
            end 
            local confirm_box = loveframes.Create("frame", cafe)
            frames.cafe.confirm_box = confirm_box
            confirm_box:SetState("cafe")
            confirm_box:SetName("Really feed this card?")
            confirm_box:SetWidth(250)
            confirm_box:SetHeight(180)
            confirm_box:CenterX()
            confirm_box:CenterY()
            confirm_box:SetModal(true)
            loveframes.modalobject.modalbackground:SetState("cafe")
            confirm_box:ShowCloseButton(false)
            local card = Card(k, 0)
            local image = loveframes.Create("image", confirm_box)
            image.card = card
            image:SetSize(80, 120)
            image.Draw = function(self)
              local x = self:GetX()
              local y = self:GetY()
              love.graphics.setColor(255, 255, 255, 255)
              draw_card(self.card, x, y, function() end)
            end
            image:SetY(40)
            image:CenterX()
            local no_button = loveframes.Create("button", confirm_box)
            no_button:SetWidth(40)
            no_button:SetHeight(20)
            no_button:CenterY()
            no_button:SetX(confirm_box:GetWidth()-65)
            no_button:SetText("No")
            no_button.OnClick = function() confirm_box:Remove() end
            local yes_button = loveframes.Create("button", confirm_box)
            yes_button:SetWidth(40)
            yes_button:SetHeight(20)
            yes_button:CenterY()
            yes_button:SetX(25)
            yes_button:SetText("Yes")
            yes_button.OnClick = function()  
              local msg = {frames.cafe.active_character_card_id, frames.cafe.active_character_cafe_id, k}
              net_send({type="feed_card", msg=msg})
              confirm_box:Remove()
            end
          end))
      end
    end
    frames.cafe.update_feeding_list()

    function frames.cafe.popup_notification(message)
      local notification = loveframes.Create("frame", cafe)
      frames.cafe.notification = notification
      notification:SetState("cafe")
      notification:SetName("Attention!")
      notification:SetWidth(250)
      notification:SetHeight(180)
      notification:CenterX()
      notification:CenterY()
      notification:SetModal(true)
      loveframes.modalobject.modalbackground:SetState("cafe")
      notification:ShowCloseButton(false)

      local text = loveframes.Create("text", notification)
      text:SetText(message)
      text:Center()

      local ok_button = loveframes.Create("button", notification)
      ok_button:SetWidth(40)
      ok_button:SetHeight(20)
      ok_button:SetY(120)
      ok_button:CenterX()
      ok_button:SetText("Okay")
      ok_button.OnClick = function() notification:Remove() end
    end
  end

  loveframes.SetState("cafe")
  while true do
    wait()
    if from_cafe then
      local ret = from_cafe
      from_cafe = nil
      return unpack(ret)
    end
  end
end


local from_xmute = nil
function main_xmute()
  if not frames.xmute then
    frames.xmute = {}
    frames.xmute.page_num = 1
    frames.xmute.xmute_type = nil

    -- set up buttons and hover area
    local list, text = get_hover_list_text("xmute")
    frames.xmute.card_text_list = list
    frames.xmute.card_text = text

    local lobby_button = loveframes.Create("button")
    frames.xmute.lobby_button = lobby_button
    lobby_button:SetState("xmute")
    lobby_button:SetY(list:GetY()+list:GetHeight()+5)
    lobby_button:SetX(list:GetX())
    lobby_button:SetWidth(list:GetWidth())
    lobby_button:SetText("Lobby")
    lobby_button:SetHeight(600-field_y-5-lobby_button:GetY())
    function lobby_button:OnClick()
      from_xmute = {main_lobby}
    end

    local xmute_pane = loveframes.Create("frame")
    xmute_pane:SetState("xmute")
    local x,y,w,h = left_hover_frame_pos()
    xmute_pane:SetPos(x,y)
    xmute_pane:SetSize(w,h)
    xmute_pane:ShowCloseButton(false)
    xmute_pane:SetDraggable(false)
    xmute_pane.Draw = function(self)
      draw_hover_frame(self.x, self.y, self.width, self.height)
    end

    local dr_button = loveframes.Create("button", xmute_pane)
    dr_button:SetState("xmute")
    dr_button:SetWidth(120)
    dr_button:SetHeight(60)
    dr_button:CenterX()
    dr_button:SetY(math.ceil(h*0.15))
    dr_button:SetText("Double Rares")
    function dr_button:OnClick()
      frames.xmute.xmute_type = "DR"
      frames.xmute.populate_xmutable_card_list()
    end

    local accessories_button = loveframes.Create("button", xmute_pane)
    accessories_button:SetState("xmute")
    accessories_button:SetWidth(120)
    accessories_button:SetHeight(60)
    accessories_button:CenterX()
    accessories_button:SetY(math.ceil(h*0.45))
    accessories_button:SetText("Accessories")
    function accessories_button:OnClick()
      frames.xmute.xmute_type = "accessory"
      frames.xmute.populate_xmutable_card_list()
    end

    local ore_button = loveframes.Create("button", xmute_pane)
    ore_button:SetState("xmute")
    ore_button:SetWidth(120)
    ore_button:SetHeight(60)
    ore_button:CenterX()
    ore_button:SetY(math.ceil(h*0.75))
    ore_button:SetText("Ores")
    function ore_button:OnClick()
      frames.xmute.xmute_type = "ore"
      frames.xmute.populate_xmutable_card_list()
    end

    --List of transmutable cards of xmute_type
    local xmutable_card_list = loveframes.Create("list")
    xmutable_card_list:SetState("xmute")
    xmutable_card_list:SetX(xmute_pane:GetX()*2+xmute_pane:GetWidth())
    xmutable_card_list:SetY(250)
    xmutable_card_list:SetHeight(140)
    xmutable_card_list:SetWidth(800-2*xmutable_card_list:GetX())
    xmutable_card_list:SetDisplayType("horizontal")
    function xmutable_card_list:Draw() end
    xmutable_card_list:SetSpacing(5)

    function frames.xmute.populate_xmutable_card_list() 
      local xmute_type = frames.xmute.xmute_type
      xmutable_card_list:Clear()
      frames.xmute.populate_xmute_to_card_list()
      frames.xmute.draw_preview_pane()
      frames.xmute.collection = collection_ex_deck(user_data.collection, union_counters(user_data.decks))
      local coll = tspairs(frames.xmute.collection)
      local card_list = {}
      for i=1,#coll do
        local k, v = coll[i][1],coll[i][2]
        if xmute_type=="DR" then
          if Card(k).rarity == "DR" and Card(k).faction ~= "N" then
            table.insert(card_list,{k,v})
          end
        elseif xmute_type=="accessory" then
          if (k >= 210001 and k <= 210007) or (k >= 210022 and k <= 210028) then
            table.insert(card_list,{k,v})
          end
        elseif xmute_type=="ore" then
          if (k >= 210008 and k <= 210012) then
            table.insert(card_list,{k,v})
          end
        end
      end
      for i =1,#card_list do
        local k, v = card_list[i][1],card_list[i][2]
        xmutable_card_list:AddItem(card_list_button(k, false, v, function() 
          frames.xmute.populate_xmute_to_card_list(xmute_type, k)
          frames.xmute.draw_preview_pane(nil, k, xmute_type)
          end))
      end
    end

    --List of cards we can transmute to
    local xmute_to_card_list = loveframes.Create("list")
    xmute_to_card_list:SetState("xmute")
    xmute_to_card_list:SetX(xmute_pane:GetX()*2+xmute_pane:GetWidth())
    xmute_to_card_list:SetY(400)
    xmute_to_card_list:SetHeight(140)
    xmute_to_card_list:SetWidth(800-2*xmute_to_card_list:GetX())
    xmute_to_card_list:SetDisplayType("horizontal")
    function xmute_to_card_list:Draw() end
    xmute_to_card_list:SetSpacing(5)

    function frames.xmute.populate_xmute_to_card_list(xmute_type, from_card_id)
      xmute_to_card_list:Clear()
      if not xmute_type then return end
      for k, v in pairs(xmutable[xmute_type]) do
        if v[from_card_id] then
          for to_card_id, _ in spairs(v) do
            if to_card_id ~= from_card_id then
              xmute_to_card_list:AddItem(card_list_button(to_card_id, false, nil, function() 
                frames.xmute.draw_preview_pane(to_card_id, from_card_id, xmute_type)
                end))
            end
          end
        end
      end
    end

    --Top area where we preview our desired xmute and quantity
    function frames.xmute.draw_preview_pane(to_card_id, from_card_id, xmute_type)
      if frames.xmute.preview_pane then
        frames.xmute.preview_pane:Remove()
      end

      local multiplier = 4
      if xmute_type == "DR" then
        multiplier = 1
      end

      local preview_pane = loveframes.Create("frame")
      frames.xmute.preview_pane = preview_pane
      preview_pane:SetName("Transmute...")
      preview_pane:SetState("xmute")
      preview_pane:SetPos(x + w + 10, y)
      preview_pane:SetSize(380, 200)
      preview_pane:ShowCloseButton(false)
      preview_pane:SetDraggable(false)

      local arrow = loveframes.Create("text", preview_pane)
      arrow:SetText("->")
      arrow:SetPos(130, 80)

      local xmute_numberbox = loveframes.Create("numberbox", preview_pane)
      xmute_numberbox:SetPos(280, 50)
      xmute_numberbox:SetValue(1)
      xmute_numberbox:SetMin(0)
      xmute_numberbox:SetMax(100)
      local value = xmute_numberbox:GetValue()
      frames.xmute.draw_preview_cards(to_card_id, from_card_id, value, multiplier*value)
      xmute_numberbox.OnValueChanged = function(object, value)
        frames.xmute.draw_preview_cards(to_card_id, from_card_id, value, multiplier*value)
        end

      local xmute_button = loveframes.Create("button", preview_pane)
      frames.xmute.xmute_button = xmute_button
      xmute_button:SetPos(280, 90)
      xmute_button:SetSize(80, 40)
      xmute_button:SetText("Transmute!")
      xmute_button.OnClick = function() 
        local value = xmute_numberbox:GetValue()
        if not (frames.xmute.collection and from_card_id and to_card_id) then
          return
        end
        if value * multiplier > (frames.xmute.collection[from_card_id] or 0)
            or value < 1 then
          return
        end
        net_send({type="xmute", to_card_id=to_card_id, from_card_id=from_card_id, to_card_number=value, xmute_type=xmute_type})
        xmute_button:SetEnabled(false)
        frames.xmute.lobby_button:SetEnabled(false)
        end
    end

    function frames.xmute.draw_preview_cards(to_card_id, from_card_id, to_card_number, from_card_number)
      if not frames.xmute.preview_pane then return end
      if from_card_id then
        local button = card_list_button(from_card_id, false, nil, function() end)
        button:SetParent(frames.xmute.preview_pane)
        button:SetPos(30, 30)
        if frames.xmute.from_card_button then frames.xmute.from_card_button:Remove() end
        frames.xmute.from_card_button = button
      end
      if to_card_id then
        local button = card_list_button(to_card_id, false, nil, function() end)
        button:SetParent(frames.xmute.preview_pane)
        button:SetPos(160, 30)
        if frames.xmute.to_card_id then frames.xmute.to_card_id:Remove() end
        frames.xmute.to_card_id = button
      end

      if from_card_id and to_card_id then
        if from_card_number then
          local number = loveframes.Create("text", frames.xmute.preview_pane)
          number:SetPos(60, 155)
          number:SetText("x"..tostring(from_card_number))
          if frames.xmute.from_card_number then frames.xmute.from_card_number:Remove() end
          frames.xmute.from_card_number = number
        end
        if to_card_number then
          local number = loveframes.Create("text", frames.xmute.preview_pane)
          number:SetPos(190, 155)
          number:SetText("x"..tostring(to_card_number))
          if frames.xmute.to_card_number then frames.xmute.to_card_number:Remove() end
          frames.xmute.to_card_number = number
        end
      end
    end
    frames.xmute.draw_preview_pane()

    function frames.xmute.enable_buttons()
      frames.xmute.lobby_button:SetEnabled(true)
      frames.xmute.xmute_button:SetEnabled(true)
    end
  end

  loveframes.SetState("xmute")
  while true do
    wait()
    if from_xmute then
      local ret = from_xmute
      from_xmute = nil
      return unpack(ret)
    end
  end
end


function main_select_boss()
  local which = nil
  local mk_cb = function(n)
    return function()
      which = n
    end
  end
  local buttons = {}
  local cbs = {}
  for i=1,40 do
    cbs[i]=mk_cb(i)
    local x,y = (i-1)%10+1, math.floor((i-1)/10)
    buttons[i] = loveframes.Create("button")
    local button = buttons[i]
    button:SetPos(400+(x-5.5)*50 - 20, 185+y*50)
    button:SetWidth(40)
    button:SetHeight(40)
    button:SetText(i.."F")
    button.OnClick = cbs[i]
  end
  while true do
    wait()
    if which then
      if (""..which):len() == 1 then
        which = "0"..which
      end
      for i=1,40 do
        buttons[i]:Remove()
      end
      return main_play, {""..which}
    end
  end
end

function main_play(which)
  loveframes.SetState("playing")
  local player = file_to_deck("player")
  local npc = file_to_deck("floor"..which)
  game = Game(player, npc)
  game:run()
end

function main_mxm()
  network_init()
  game = Game(nil, nil, true)
  game:client_run()
end

function get_char(deck)
  for k,v in pairs(deck) do
    k = k + 0
    if k < 200000 then
      return k
    end
  end
end

function get_active_char()
  local deck = user_data.decks[user_data.active_deck]
  return get_char(deck)
end

function check_active_deck()
  local deck = user_data.decks[user_data.active_deck]
  local n = 0
  for k,v in pairs(deck) do
    n = n + v
  end
  return n == 31
end

local from_fight = nil
function main_fight(msg)
  loveframes.SetState("playing")
  game = Game(nil, nil, true, get_active_char())
  game.opponent_name = msg.opponent_name
  game.game_type = msg.game_type
  game.my_name = user_data.username
  game.P1.name = game.my_name
  game.P2.name = game.opponent_name
  game = game:client_run()
  if user_data.latest_rewards then
    rewards(user_data.latest_rewards)
    user_data.latest_rewards = nil
  end
  game = nil
  return main_lobby
end

local easy_dungeons = {{"Beginner Dungeon", 1}, {"Intermediate Dungeon", 2}, {"Advanced Dungeon", 3}, {"Bamboo Garden", 8}, {"Dream Island", 14},}
local normal_dungeons = {{"Frontier Ruins", 4}, {"Witch's Tower", 5}, {"Crux Training Camp", 7}, {"Linia's Mansion", 9}, {"Vampire Lands", 10}, {"Vita Public School", 12}, {"Vivid World", 13}, {"Catacombs", 16},}
local hard_dungeons = {{"Shadowland", 6}, {"Goddess Tower", 11}}

function main_dungeon()
  
  if not frames.dungeon then
    frames.dungeon = {}
  end
  if not frames.dungeon.page_num then
    frames.dungeon.page_num = 1
  end
  if not frames.dungeon.difficulty then
    frames.dungeon.difficulty = easy_dungeons
  end
  if not frames.dungeon.showing then
    frames.dungeon.showing = {}
  end
  if not frames.dungeon.showingfloor then
    frames.dungeon.showingfloor = {}
  end
  if not frames.dungeon.showingclear then
    frames.dungeon.showingclear = {}
  end
    
  local frame = loveframes.Create("frame")
  frame:SetName("Dungeons")
  frame:SetState("lobby")
  frame:SetSize(600, 450)
  frame:ShowCloseButton(false)
  frame:SetDraggable(false)
  frame:Center()
  frame:SetModal(true)
  loveframes.modalobject.modalbackground:SetState("lobby")
  

  local prevbutton = loveframes.Create("button", frame)
  prevbutton:SetPos(10, 400)
  prevbutton:SetSize(30, 30)
  prevbutton:SetText("<")
  function prevbutton:OnClick()
    if frames.dungeon.page_num > 1 then
      frames.dungeon.page_num = frames.dungeon.page_num - 1
    end
    update_dungeon_list(frame)
  end
    
  local nextbutton = loveframes.Create("button", frame)
  nextbutton:SetPos(70, 400)
  nextbutton:SetSize(30, 30)
  nextbutton:SetText(">")
  function nextbutton:OnClick()
    if frames.dungeon.page_num < ceil(#frames.dungeon.difficulty / 4) then
      frames.dungeon.page_num = frames.dungeon.page_num + 1
    end
    update_dungeon_list(frame)
  end
    
  local easybutton, normalbutton, hardbutton
  easybutton = loveframes.Create("button", frame)
  easybutton:SetPos(135, 400)
  easybutton:SetSize(80, 30)
  easybutton:SetText("EASY")
  easybutton:SetEnabled(false)
  function easybutton:OnClick()
    frames.dungeon.difficulty = easy_dungeons
    frames.dungeon.page_num = 1
    update_dungeon_list(frame)
  end
    
  normalbutton = loveframes.Create("button", frame)
  normalbutton:SetPos(245, 400)
  normalbutton:SetSize(80, 30)
  normalbutton:SetText("NORMAL")
  function normalbutton:OnClick()
    frames.dungeon.difficulty = normal_dungeons
    frames.dungeon.page_num = 1
    update_dungeon_list(frame)
  end
    
  hardbutton = loveframes.Create("button", frame)
  hardbutton:SetPos(355, 400)
  hardbutton:SetSize(80, 30)
  hardbutton:SetText("HARD")
  function hardbutton:OnClick()
    frames.dungeon.difficulty = hard_dungeons
    frames.dungeon.page_num = 1
    update_dungeon_list(frame)
  end
    
  local closebutton = loveframes.Create("button", frame)
  closebutton:SetPos(520, 400)
  closebutton:SetSize(60, 30)
  closebutton:SetText("CLOSE")
  function closebutton:OnClick() 
    from_dungeon = {main_lobby}
    close = true
  end 
    
  function update_dungeon_list(frame)

    local index = 1   
    while frames.dungeon.showing[index] do
      frames.dungeon.showing[index]:Remove()
      frames.dungeon.showing[index] = nil
      index = index + 1
    end
    
    index = 1
    if frames.dungeon.difficulty == easy_dungeons then
      normalbutton:SetEnabled(true)
      hardbutton:SetEnabled(true)
      easybutton:SetEnabled(false)
    elseif frames.dungeon.difficulty == normal_dungeons then
      normalbutton:SetEnabled(false)
      hardbutton:SetEnabled(true)
      easybutton:SetEnabled(true)
    else
      normalbutton:SetEnabled(true)
      hardbutton:SetEnabled(false)
      easybutton:SetEnabled(true)
    end
    while index < 5 do
      local currentdungeon = frames.dungeon.difficulty[(frames.dungeon.page_num - 1) * 4 + index]
      if currentdungeon then
        local dungeon_id = currentdungeon[2]
        local img_filename = tostring(dungeon_id)
        while(img_filename:len() < 3) do
          img_filename = "0"..img_filename
        end
        img_filename = "en_dungeon_icon_"..img_filename..".png"
        local image = loveframes.Create("button", frame)
        image:SetSize(121, 255)
        image:SetX(28 + 136 * (index - 1))
        image:CenterY()
        image.OnClick = function()
          from_dungeon = "start game"
          net_send({type="dungeon", idx=dungeon_id})
        end
        image.Draw = function(self)
          local x = self:GetX()
          local y = self:GetY()
          love.graphics.setColor(255, 255, 255, 255)
          love.graphics.draw(load_asset(img_filename), x, y)
        end
      
        local text = loveframes.Create("text", frame)
        local text2 = loveframes.Create("text", frame)
        
        text:SetText("Floor: "..user_data.dungeon_floors[dungeon_id])
        text:SetX(63 + 136 * (index - 1))
        text:SetY(355)
      
        text2:SetText("Clear: "..user_data.dungeon_clears[dungeon_id])
        text2:SetX(62 + 136 * (index - 1))
        text2:SetY(370)
        
        frames.dungeon.showing[#frames.dungeon.showing+1] = image
        frames.dungeon.showing[#frames.dungeon.showing+1] = text
        frames.dungeon.showing[#frames.dungeon.showing+1] = text2
        
        index = index + 1
      else
        break
      end
    end
    local pagetext = loveframes.Create("text", frame)
    pagetext:SetPos(45, 410)
    pagetext:SetText(frames.dungeon.page_num .. "/" .. ceil(#frames.dungeon.difficulty / 4))
    frames.dungeon.showing[#frames.dungeon.showing+1] = pagetext
  end 
    
  update_dungeon_list(frame)
    
  while true do
    wait()
    
    if from_dungeon == "start game" then
      --a dungeon was entered, prepare for battle
      local ret = {main_lobby}
      from_dungeon = frames.dungeon
      frame:Remove()
      return unpack(ret)
    elseif from_dungeon then
      --close button was clicked, so return to lobby
      local ret = from_dungeon
      from_dungeon = nil
      frame:Remove()
      
      return unpack(ret)
    end
  end
end


