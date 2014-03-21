local ceil = math.ceil

function wait(n)
  n = n or 1
  for i=1,n do
    coroutine.yield()
  end
end

local main_select_boss, main_play, main_go_hard, main_login
local main_mxm, main_register, main_forgot_password
local main_modal_notice, main_select_faction, main_lobby
local main_fight, main_decks

frames = {}
local frames = frames

function fmainloop()
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
  local file, err = io.open(ABSOLUTE_PATH.."decks"..PATH_SEP..s..".txt", "r")
  if file then
    s = file:read("*a")
    file:close()
  else
    file = love.filesystem.newFile("decks/"..s..".txt")
    file:open("r")
    s = file:read(file:getSize())
  end
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
  wait = function() end
  game = Game(get_deck(), get_deck())
end

function main_go_hard()
  while true do
    go_hard()
    game:run()
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
      -- TODO from_login = {main_forgot_password, {textinput1:GetText()}}
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
  local test_button = card_list_button(300001, 0, 1, function() end)
  local card_width = test_button:GetWidth()
  local spacing = 5
  local ncards = 0
  rewards_list:SetHeight(test_button:GetHeight())
  rewards_list:EnableHorizontalStacking(true)
  rewards_list:SetSpacing(spacing)
  for i, v in pairs(data) do 
    ncards = ncards + 1
    rewards_list:AddItem(card_list_button(i, 0, v, function() end))
  end
  local width = math.min(ncards * card_width + (ncards - 1) * spacing, spacing * 4 + card_width * 5 + 15) -- 15 is scrollbar width
  rewards_list:SetWidth(width)
  rewards_list:CenterX()
  rewards_list:CenterY()
  if ncards < 1 then
    rewards_list:Remove()
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
    table.insert(frames.lobby.game_buttons, button)

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
    button:SetPos(750,0)
    button:SetSize(50, 50)
    button:SetText("DECKS")
    button:SetState("lobby")
    button.OnClick = function()
      from_lobby = {main_decks}
    end

    local button = loveframes.Create("button")
    button:SetPos(750,50)
    button:SetSize(50, 50)
    button:SetText("CRAFT")
    button:SetState("lobby")
    button.OnClick = function()
      from_lobby = {main_craft}
    end
  end

  local enable_buttons = check_active_deck()
  for _,button in ipairs(frames.lobby.game_buttons) do
    button:SetEnabled(enable_buttons)
  end

  loveframes.SetState("lobby")

  while true do
    wait()
    if net_q:len() ~= 0 then
      local msg = net_q:pop()
      if msg.type=="game_start" then
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

local from_craft = nil
function main_craft()
  if not frames.craft then
    frames.craft = {}
    frames.craft.page_num = 1

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

    local craft_card_list = loveframes.Create("list", craft_pane)
    craft_card_list:SetWidth(w-12)
    craft_card_list:Center()
    craft_card_list:SetY(60)
    craft_card_list:SetHeight(480)
    craft_card_list:SetPadding(0)
    craft_card_list:SetSpacing(0)
    function craft_card_list:Draw() end

    function frames.craft.update_list()
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
    lbutton:SetY(570)
    lbutton:SetSize(20,20)
    lbutton:SetText("<")
    function lbutton:OnClick()
      frames.craft.page_num = frames.craft.page_num - 1
      frames.craft.update_list()
    end

    local rbutton = loveframes.Create("button")
    rbutton:SetState("craft")
    rbutton:SetX((800 - (craft_pane:GetX()*2+craft_pane:GetWidth())) - button_width)
    rbutton:SetY(570)
    rbutton:SetSize(20,20)
    rbutton:SetText(">")
    function rbutton:OnClick()
      frames.craft.page_num = frames.craft.page_num + 1
      frames.craft.update_list()
    end

    function frames.craft.populate_card_list(collection)
      card_list:Clear()
      local coll = tspairs(collection)
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
        card_list:AddItem(card_list_button(k, 0, v, function()
          -- TODO: open a popup that lets you craft this card
        end))
      end
    end
  end

  loveframes.SetState("craft")
  while true do
    wait()
    if from_craft then
      local ret = from_craft
      from_craft = nil
      return unpack(ret)
    end
  end
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
    lbutton:SetY(570)
    lbutton:SetSize(20,20)
    lbutton:SetText("<")
    function lbutton:OnClick()
      frames.decks.page_num = frames.decks.page_num - 1
      frames.decks.update_list()
    end

    local rbutton = loveframes.Create("button")
    rbutton:SetState("decks")
    rbutton:SetX((800 - (deck_pane:GetX()*2+deck_pane:GetWidth())) - button_width)
    rbutton:SetY(570)
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

    function frames.decks.populate_card_list(collection)
      card_list:Clear()
      local coll = tspairs(collection)
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
        card_list:AddItem(card_list_button(k, 0, v, function()
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

    local checkbox_width = 20

    local multichoice = loveframes.Create("multichoice", deck_pane)
    multichoice:SetWidth(w - 18 - checkbox_width)
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
      frames.decks.idx = idx
      frames.decks.populate_deck_card_list(user_data.decks[idx] or {})
      frames.decks.populate_card_list(collection_ex_deck(
          user_data.collection, frames.decks.deck))
    end
    frames.decks.multichoice = multichoice

    local checkbox = loveframes.Create("checkbox", deck_pane)
    checkbox:SetPos(12+multichoice:GetWidth(), 6+2)
  end

  local multichoice = frames.decks.multichoice
  multichoice:Clear()
  for i=1,#user_data.decks do
    local str = "Deck "..i
    if i == user_data.active_deck then
      str = str .. " (active)"
    end
    multichoice:AddChoice(str)
  end
  if #user_data.decks < 0 then
    multichoice:AddChoice("New Deck")
  end
  local current_str = "Deck "..user_data.active_deck.." (active)"
  multichoice:SelectChoice(current_str)

  loveframes.SetState("decks")
  while true do
    wait()
    if from_decks then
      local ret = from_decks
      from_decks = nil
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
