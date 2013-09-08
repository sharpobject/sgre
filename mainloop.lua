function wait(n)
  n = n or 1
  for i=1,n do
    coroutine.yield()
  end
end

local main_select_boss, main_play, main_go_hard,
      main_PNTL, main_PNTL_lobby, main_PNTL_game

function fmainloop()
  local func, arg = main_select_boss, nil
  while true do
    func,arg = func(unpack(arg or {}))
    collectgarbage("collect")
  end
end

function str_to_deck(s)
  s = s:sub(s:find("[%dDPC]+")):split("DPC")
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

function main_select_boss()
  local which = nil
  local real_game = nil

  local mk_cb = function(n)
    return function()
      which = n
    end
  end
  local cbs = {}
  for i=1,40 do
    cbs[i]=mk_cb(i)
  end
  network_init()
  local real_cb = function() real_game = true end
  local do_button = function(text, cb, i, j)
    gprintf(text, 400 + (j-5.5)*50 - 20, 190 + i * 50, 40, "center")
    make_button(cb, 400 + (j-5.5)*50 - 20, 185 + i * 50, 40, 40, true)
  end
  while true do
    for i=1,4 do
      for j=1,10 do
        local floor = (i-1)*10+j
        if floor~=37 then
          do_button(floor.."F", cbs[floor], i, j)
        end
      end
    end
    do_button("real\ngame", real_cb, 0, 1)
    gprint(VERSION_MSG, 250, 40)
    wait()
    if which then
      if (""..which):len() == 1 then
        which = "0"..which
      end
      return main_play, {""..which}
    end
    if real_game then
      return main_PNTL
    end
  end
end

function main_play(which)
  local player = file_to_deck("player")
  local npc = file_to_deck("floor"..which)
  game = Game(player, npc)
  game:run()
end

function PNTL_reader(PNTL)
  local coro = coroutine.create(function()
    local leftovers = ""
    while true do
      local new_stuff = posix.read(PNTL.stdout, 1000)
      while new_stuff do
        leftovers = leftovers .. new_stuff
        new_stuff = posix.read(PNTL.stdout, 1000)
      end
      local err = posix.read(PNTL.stderr, 1000)
      while err do
        io.stderr:write(err)
        err = posix.read(PNTL.stderr, 1000)
      end
      local success = false
      if leftovers:len() >= 3 then
        needed_len = string.byte(leftovers[1])*65536+
                     string.byte(leftovers[2])*256+
                     string.byte(leftovers[3])
        if leftovers:len() >= 3 + needed_len then
          this_msg = leftovers:sub(4, 3+needed_len)
          leftovers = leftovers:sub(4+needed_len)
          --print("message: "..this_msg)
          this_msg = json.decode(this_msg)
          PNTL.waiting = PNTL.waiting or {}
          local waiting = PNTL.waiting[this_msg.type_name] or {}
          PNTL.waiting[this_msg.type_name] = {}
          print("Got message "..this_msg.type_name.." "..#waiting)
          for _,cb in ipairs(waiting) do
            cb(this_msg)
          end
          coroutine.yield(this_msg)
          success = true
        end
      end
      if not success then
        coroutine.yield()
      end
    end
  end)
  return function()
    return coroutine.lazier_resume(coro)
  end
end

function main_PNTL()
  local PNTL = {}
  PNTL.pid, PNTL.stdin, PNTL.stdout, PNTL.stderr = popen3("./PNTL.sh")
  posix.fcntl(PNTL.stdout, posix.F_SETFL, posix.O_NONBLOCK)
  posix.fcntl(PNTL.stderr, posix.F_SETFL, posix.O_NONBLOCK)
  posix.fcntl(PNTL.stdin, posix.F_SETFL, posix.O_NONBLOCK)
  for k,v in pairs(PNTL) do print(k,v) end
  PNTL.read = PNTL_reader(PNTL)
  PNTL.send = function(self, stuff)
    local to_write = json.encode(stuff)
    local len = to_write:len()
    to_write = string.char(len/65536) ..
               string.char((len/256) % 256) ..
               string.char(len%65536) ..
               to_write
    posix.write(self.stdin, to_write)
    print("sending! "..to_write)
  end
  PNTL.short_packet = function(self, type)
    self:send({method="short_packet", type=type})
  end
  PNTL.request_packet = function(self, args)
    self:send({method="request_packet", args=args})
  end
  PNTL.await_packet = function(self, typ, fn)
    PNTL.waiting = PNTL.waiting or {}
    PNTL.waiting[typ] = PNTL.waiting[typ] or {}
    local thread = nil
    if type(fn) == "thread" then
      thread = fn
      fn = function(...) return coroutine.lazier_resume(thread, ...) end
    end
    print("awaiting "..typ.."!")
    PNTL.waiting[typ][#PNTL.waiting[typ]+1] = fn
    if thread then
      return coroutine.yield()
    end
  end
  while true do
    local junk, stuff = PNTL:read()
    while stuff do
      local to_ret = nil
      if stuff.type_name == "login" and stuff.result == 0 then
        to_ret = {main_PNTL_lobby, {PNTL}}
      end
      --print(json.encode(stuff))
      --print(stuff.type_name, stuff.result)
      if to_ret then
        print("FUCK")
        return unpack(to_ret)
      end
      junk, stuff = PNTL:read()
    end
    wait()
  end
end

function main_PNTL_lobby(PNTL)
  print "LOBBY"
  local cb = function()
    if not PNTL.game then
      local game
      game = coroutine.create(function()
        local packet
        PNTL:request_packet({type="dungeon_adventure",dungeon=1})
        packet = PNTL:await_packet("dungeon_adventure", game)
        if packet.result ~= 0 then
          print("could not do dungeon :(")
          PNTL.game = nil
          return
        end
        packet = PNTL:await_packet("dungeon_game_start", game)
        PNTL:short_packet("dungeon_game_start")
        PNTL:await_packet("game_start", game)
        PNTL.do_game_start = true
        PNTL:short_packet("game_init_info")
        PNTL:await_packet("game_init_info", game)
        PNTL:short_packet("game_turn_start")
        PNTL:await_packet("game_turn_start", game)
        --PNTL:short_packet("game_skill_active")
        --PNTL:await_packet("game_skill_active", game)
        --PNTL:short_packet("game_draw")
      end)
      PNTL.game = game
      coroutine.lazier_resume(PNTL.game)
    end
  end
  local do_button = function(text, cb, i, j)
    gprintf(text, 400 + (j-5.5)*50 - 20, 190 + i * 50, 40, "center")
    make_button(cb, 400 + (j-5.5)*50 - 20, 185 + i * 50, 40, 40, true)
  end
  while true do
    do_button("Nold!", cb, 0, 1)
    local junk, stuff = PNTL:read()
    while stuff do
      local to_ret = nil
      if PNTL.do_game_start then
        PNTL.do_game_start = nil
        to_ret = {main_PNTL_game, {PNTL}}
      end
      --print(json.encode(stuff))
      if to_ret then
        return unpack(to_ret)
      end
      junk, stuff = PNTL:read()
    end
    wait()
  end
end

function slot_to_card(slot)
  if not slot.is_modified then return nil end
  local ret = Card(slot.card_id)
  ret.active = slot.is_active
  ret.hidden = false--not slot.is_visible
  if pred.follower(ret) then
    ret.size = slot.size
    ret.atk = slot.atk
    ret.def = slot.def
    ret.sta = slot.sta
    ret.skills = {}
    for i=1,3 do
      if slot.skills[i].skill_id ~= 0 then
        ret.skills[i] = slot.skills[i].skill_id
      end
    end
  elseif pred.spell(ret) then
    ret.size = slot.size
  else
    error("hax")
  end
  return ret
end

function mk_pile(n)
  local ret = {}
  for i=1,n do
    ret[i] = Card(200033)
  end
  return ret
end

function main_PNTL_game(PNTL)
  local game = Game(get_deck(), get_deck())
  game.PNTL = PNTL
  local hands = 0
  local no_buttons = nil
  local playin_card = nil
  function PNTL:ready()
    self:short_packet("action_end")
    hands = 0
  end
  function PNTL:attempt_shuffle()
    if game.P1.shuffles > 0 then
      self:short_packet("shuffle")
      no_buttons = "shuffle"
    end
  end
  function PNTL:play_card(idx)
    self:request_packet({type="play_card", slot=idx-1})
    no_buttons = "card_summon"
    playin_card = idx
  end
  while true do
    --gprintf("I have no idea what im doing", 400, 400, 200, "center")
    local junk, stuff = PNTL:read()
    while stuff do
      local to_ret = nil
      if stuff.type_name == no_buttons then
        if no_buttons == "card_summon" and stuff.result == 0 then
          table.remove(game.P1.hand, playin_card)
        end
        no_buttons = nil
      end
      if stuff.type_name == "game_turn_start" then
        PNTL:short_packet("game_skill_active")
        print("WORKING IT "..stuff.type_name)
        game.turn = stuff.turn_number
        for idx,info in ipairs(stuff.players) do
          local player = game["P"..idx]
          player.character = Card(info.character_id)
          player.field[0] = player.character
          player.character.life = info.life
          player.grave = mk_pile(info.player_data.trash_card_count)
          player.deck = mk_pile(info.player_data.deck_card_count)
          player.shuffles = info.player_data.shuffle_count
          for i=1,5 do
            player.field[i] = slot_to_card(info.slot_data[i])
          end
        end
      elseif stuff.type_name == "game_draw" then
        hands = hands + 1
        print("THERE ARE "..hands.." HANDS")
        print("WORKING IT "..stuff.type_name)
        local player = game["P"..(stuff.player_index+1)]
        player.grave = mk_pile(stuff.player_data.trash_card_count)
        player.deck = mk_pile(stuff.player_data.deck_card_count)
        player.shuffles = stuff.player_data.shuffle_count
        for i=1,5 do
          player.hand[i] = slot_to_card(stuff.slot_data[i])
        end
      elseif stuff.type_name == "shuffle" then
        print(json.encode(stuff))
        print("WORKING IT "..stuff.type_name)
        local player = game["P"..(stuff.player_index+1)]
        player.grave = mk_pile(stuff.trash_card_count)
        player.deck = mk_pile(stuff.deck_card_count)
        player.shuffles = stuff.shuffle_count
        for i=1,5 do
          player.hand[i] = slot_to_card(stuff.slot_data[i])
        end
      elseif stuff.type_name == "card_summon" and stuff.result == 0 then
        print("WORKING IT "..stuff.type_name)
        local player = game["P"..(stuff.player_index+1)]
        local slot = stuff.slot+1
        player.field[slot] = slot_to_card(stuff.slot_data[1])
      elseif stuff.type_name == "action_end" then
        PNTL:short_packet("battle_calculation")
      elseif stuff.type_name == "battle_calculation" then
        PNTL:short_packet("turn_end")
      elseif stuff.type_name == "turn_end" then
        PNTL:short_packet("game_turn_start")
      elseif stuff.type_name == "game_skill_active" then
        PNTL:short_packet("game_draw")
      elseif stuff.type_name == "battle_game_end" then
        if stuff.winning_team then
          --error("fuck")
        else
          PNTL:short_packet("battle_game_end")
          PNTL:short_packet("battle_game_out")
          PNTL:short_packet("update_account")
          PNTL:short_packet("dungeon_reward_state")
          PNTL.game = nil
          to_ret = {main_PNTL_lobby, {PNTL}}
        end
      end
      --print(json.encode(stuff))
      if to_ret then
        return unpack(to_ret)
      end
      junk, stuff = PNTL:read()
    end
    game.act_buttons =  hands == 2 and not no_buttons
    game:draw()
    wait()
  end

end
