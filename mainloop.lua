function wait(n)
  n = n or 1
  for i=1,n do
    coroutine.yield()
  end
end

local main_select_boss, main_play, main_go_hard, main_login
local main_mxm, main_register, main_forgot_password
local main_modal_notice, main_select_faction, main_lobby
local main_fight

frames = {}
local frames = frames

function fmainloop()
  local func, arg = main_login, nil
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
    gfx_q:clear()
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

function main_select_faction()
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
    draw(load_asset("select_faction.png"), 153, 58)
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

    local button = loveframes.Create("button")
    button:SetPos(0,0)
    button:SetSize(50, 50)
    button:SetText("Fite")
    button:SetState("lobby")
    button.OnClick = function()
      net_send({type="join_fight"})
    end

    local button = loveframes.Create("button")
    button:SetPos(50,0)
    button:SetSize(50, 50)
    button:SetText("NOLD")
    button:SetState("lobby")
    button.OnClick = function()
      net_send({type="dungeon", idx=1})
    end

    local button = loveframes.Create("button")
    button:SetPos(100,0)
    button:SetSize(50, 50)
    button:SetText("SHORTY")
    button:SetState("lobby")
    button.OnClick = function()
      net_send({type="dungeon", idx=2})
    end

    local button = loveframes.Create("button")
    button:SetPos(150,0)
    button:SetSize(50, 50)
    button:SetText("GARTS")
    button:SetState("lobby")
    button.OnClick = function()
      net_send({type="dungeon", idx=3})
    end
  end

  loveframes.SetState("lobby")

  while true do
    wait()
    if net_q:len() ~= 0 then
      local msg = net_q:pop()
      if msg.type=="game_start" then
        from_lobby = {main_fight, {msg.opponent_name}}
      end
    end
    if from_lobby then
      local ret = from_lobby
      from_lobby = nil
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

function get_active_char()
  local deck = user_data.decks[user_data.active_deck]
  print(user_data.active_deck)
  for k,v in pairs(user_data.decks) do
    print(k,v)
  end
  print(deck)
  for k,v in pairs(deck) do
    k = k + 0
    if k < 200000 then
      return k
    end
  end
end

local from_fight = nil
function main_fight(opponent_name)
  loveframes.SetState("playing")
  game = Game(nil, nil, true, get_active_char())
  game.opponent_name = opponent_name
  game.my_name = user_data.username
  game.P1.name = game.my_name
  game.P2.name = game.opponent_name
  game:client_run()
  return main_lobby
end
