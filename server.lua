socket = require("socket")
json = require("dkjson")
require("stridx")
require("util")
require("class")
require("queue")
require("engine")
require("cards")
require("buff")
require("skills")
require("spells")
require("characters")
require("dumbprint")
hash = require("lib.hash")
print"requiring the thing"
bcrypt = require("bcrypt")
print"required it"
require("ssl")
require("validate")
require("giftable")

local byte = string.byte
local char = string.char
local floor = math.floor
local min = math.min
local max = math.max
local pairs = pairs
local ipairs = ipairs
local random = math.random
local time = os.time
local type = type
local socket = socket
local json = json
local hash = hash
local bcrypt = bcrypt
local TIMEOUT = 10


local INDEX = 1
local connections = {}
local uid_to_connection = {}
local uid_to_data = {}
local socket_to_idx = {}
local users = json.decode(file_contents("db/users"))
users.filename = "db/users"
users.last_modified = nil
users.username_to_uid = users.username_to_uid or {}
users.uid_to_username = users.uid_to_username or {}
users.uid_to_email = users.uid_to_email or {}
local uid_waiting_for_fight = nil

local file_q = Queue()
local chat_q = Queue()

starter_decks = json.decode(file_contents("starter_decks.json"))
starter_decks = fix_num_keys(starter_decks)

npc_decks = json.decode(file_contents("npc_decks.json"))
npc_decks = fix_num_keys(npc_decks)
for k,v in pairs(npc_decks) do
  v[k] = 1
end

dungeons = json.decode(file_contents("dungeons.json"))
dungeons=fix_num_keys(dungeons)
for _,qq in pairs(dungeons.rewards) do
  for _,t in pairs(qq) do
    for k,v in pairs(t) do
      if type(v) == "number" then
        t[k]=t[v]
      end
    end
    for i=1,100 do
      t[i] = t[i] or t[i-1]
    end
  end
end
--set_file("processed_dungeons", json.encode(dungeons))

ssl_context = assert(ssl.newcontext({
    mode="server",
    protocol="tlsv1",
    key="keys/key.pem",
    certificate="keys/cert.pem"
  }))

function modified_file(t)
  if not t.last_modified then
    file_q:push(t)
  end
  t.last_modified = os.time()
end

function write_a_file()
  if file_q:len() > 0 then
    local t = file_q:pop()
    set_file(t.filename, json.encode(t))
    t.last_modified = nil
  end
end

function load_user_data(uid)
  if uid_to_data[uid] then
    return
  end
  local path = "db/"..uid:sub(1,2).."/"..uid:sub(3)
  local data = json.decode(file_contents(path))
  data.filename = path
  data.last_modified = nil
  uid_to_data[uid] = fix_num_keys(data)
end

local function sha1(s)
  local sha = hash.sha1()
  sha:process(s)
  return sha:finish()
end

local function check_deck(deck, data)
  local char, other = 0, 0
  for k,v in pairs(deck) do
    if type(k) ~= "number" or
        type(v) ~= "number" or
        v ~= floor(v) or
        v < 1 or
        v > (data.collection[k] or 0) or
        (not id_to_canonical_card[k]) or
        v > id_to_canonical_card[k].limit then
      return false
    end
    if k < 200000 then
      char = char + v
    else
      other = other + v
    end
  end
  if char > 1 or other > 30 then
    return false
  end
  return char+other
end

local function check_active_deck(data)
  if (not data.active_deck) or
     (not data.decks[data.active_deck]) then
    return false
  end
  return check_deck(data.decks[data.active_deck], data) == 31
end

function try_register(msg)
  local email, username, password = msg.email, msg.username, msg.password
  if (not check_username(username)) or
      (not check_email(email)) or
      (not check_password(password)) or
      users.username_to_uid[username] then
    return false
  end
  local uid = sha1(email)
  if users.uid_to_email[uid] then
    return false
  end
  local path = "db/"..uid:sub(1,2).."/"..uid:sub(3)
  set_file(path, json.encode({
    username = username,
    email = email,
    password = bcrypt.digest(password, bcrypt.salt(10)),
    tokens = 0,
    wins = 0,
    losses = 0,
    dungeon_clears = {},
    dungeon_floors = {},
    collection = {},
    decks = {},
    friends = {},
    cafe = {},
    }))
  users.uid_to_email[uid] = email
  users.uid_to_username[uid] = username
  users.username_to_uid[username] = uid
  modified_file(users)
  return true
end

Connection = class(function(s, socket)
  s.index = INDEX
  INDEX = INDEX + 1
  socket:settimeout(0)
  socket = ssl.wrap(socket, ssl_context)
  socket:settimeout(0)
  connections[s.index] = s
  socket_to_idx[socket] = s.index
  s.socket = socket
  s.leftovers = ""
  s.state = "handshake"
  s.last_read = time()
end)

function Connection:dohandshake()
  if self.socket:dohandshake() then
    self.state = "connected"
  end
end


function Connection:send(stuff)
  if self.state=="handshake" then return end
  print("CONNECTION SEND")
  assert(type(stuff) == "table")
  if type(stuff) == "table" then
    local json = json.encode(stuff)
    local len = json:len()
    local prefix = "J"..char(floor(len/65536))..char(floor((len/256)%256))..char(len%256)
    print(byte(prefix[1]), byte(prefix[2]), byte(prefix[3]), byte(prefix[4]))
    print("sending json "..json)
    local computed_length = (byte(prefix[2])*65536 + byte(prefix[3])*256 + byte(prefix[4]))
    print("length "..len.." computed length "..computed_length)
    assert(len == computed_length)
    stuff = prefix..json
  end
  local foo = {self.socket:send(stuff)}
  if stuff[1] ~= "I" then
    print(unpack(foo))
  end
  if not foo[1] then
    self:close()
  end
end

function Connection:opponent_disconnected()
  print("OP DIS")
  self.opponent = nil
  self.game:game_over(self.player_index)
  destroy_game(self, true)
  self:send({type="opponent_disconnected"})
end

function Connection:close()
  print("CONN CLOSE")
  if self.opponent then
    self.opponent:opponent_disconnected()
  end
  socket_to_idx[self.socket] = nil
  connections[self.index] = nil
  if self.uid then
    uid_to_connection[self.uid] = nil
    if uid_waiting_for_fight == self.uid then
      uid_waiting_for_fight = nil
    end
  end
  self.socket:close()
end

function Connection:J(jmsg)
  print("CONN J")
  message = json.decode(jmsg)
  local tmp_password = message.password
  if tmp_password then
    message.password = "ass"
    print("got JSON message "..json.encode(message))
    message.password = tmp_password
  else
    print("got JSON message "..jmsg)
  end
  if message.type == "general_chat" and self.state ~= "connected" then
    self:try_chat(message)
    return
  end
  if self.state == "connected" then
    if message.type == "register" then
      local res = try_register(message)
      self:send({type="register_result", success=res})
    elseif message.type == "login" then
      self:try_login(message)
    else
      print("got unexpected message in connected state with type "..tostring(message.type))
    end
  elseif self.state == "lobby" then
    if message.type == "select_faction" then
      self:try_select_faction(message)
    end
    if message.type == "join_fight" then
      self:try_join_fight(message)
    end
    if message.type == "dungeon" then
      self:try_dungeon(message)
    end
    if message.type == "update_deck" then
      if not self:try_update_deck(message) then
        self:crash_and_burn()
      end
    end
    if message.type == "feed_card" then
      if not self:feed_card(message) then
        self:send({type="server_message",message="feeding failed D="})
      end
    end
    if message.type == "craft" then
      self:try_craft(message)
    end
  elseif self.state == "playing" then
    self.game["P"..self.player_index]:receive(message)
    self:send({type="can_act", can_act=(not self.game["P"..self.player_index].ready)})
  end
end

-- TODO: this should not be O(n^2) lol
function Connection:data_received(data)
  print("CONN DATA RECv")
  self.last_read = time()
  --print("got raw data "..data)
  data = self.leftovers .. data
  local idx = 1
  while data:len() > 0 do
    --assert(type(data) == "string")
    local msg_type = data[1]
    --assert(type(msg_type) == "string")
    if msg_type == "J" then
      if data:len() < 4 then
        break
      end
      local msg_len = byte(data[2])*65536 + byte(data[3])*256 + byte(data[4])
      if data:len() < 4 + msg_len then
        break
      end
      local jmsg = data:sub(5, msg_len+4)
      print("Pcall results for json: ", pcall(function()
        self:J(jmsg)
      end))
      data = data:sub(msg_len+5)
    else
      self:close()
      return
    end
  end
  self.leftovers = data
end

function Connection:read()
  if self.state == "handshake" then return end
  print("CONN READ")
  local junk, err, data = self.socket:receive("*a")
  if not err then
    error("shitfuck")
  end
  if err == "closed" then
    self:close()
    return
  end
  if data and data:len() > 0 then
    self:data_received(data)
  end
end

function Connection:try_login(msg)
  local function failure(reason)
    self:send({type="login_result", success=false, reason=reason})
  end
  local email, password = msg.email, msg.password
  local check_res, check_reason = check_email(email)
  if check_res then
    check_res, check_reason = check_password(password)
  end
  if not check_res then
    return failure(check_reason)
  end
  local uid = sha1(email)
  if not users.uid_to_email[uid] then
    return failure("that email is not registered")
  end
  load_user_data(uid)
  local data = uid_to_data[uid]
  local correct_password = bcrypt.verify(password, data.password)
  if not correct_password then
    return failure("incorrect password")
  end
  self.uid = uid
  if uid_to_connection[uid] then
    uid_to_connection[uid]:close()
  end
  if #data.dungeon_clears < #dungeons.npcs then
    for i=#data.dungeon_clears+1, #dungeons.npcs do
      data.dungeon_clears[i] = 0
      data.dungeon_floors[i] = 1
    end
    modified_file(data)
  end
  if not data.cafe then 
    data.cafe = {} 
    modified_file(data)
  end
  uid_to_connection[uid] = self
  self.state = "lobby"
  self:send({type="login_result", success=true})
  self:send({type="user_data", value={
    username = data.username,
    email = data.email,
    tokens = data.tokens,
    wins = data.wins,
    losses = data.losses,
    dungeon_clears = data.dungeon_clears,
    dungeon_floors = data.dungeon_floors,
    collection = data.collection,
    decks = data.decks,
    friends = data.friends,
    active_deck = data.active_deck,
    cafe = data.cafe,
  }})
end

function Connection:try_select_faction(msg)
  local data = uid_to_data[self.uid]
  if (not data.active_deck) and
      msg.faction and
      starter_decks[msg.faction] then
    -- ALL THE DECKS LOL
    for k,v in pairs(starter_decks) do
      self:update_collection(v)
    end
    -- self:update_collection(starter_decks[msg.faction])
    self:set_deck(1, starter_decks[msg.faction])
    self:set_active_deck(1)
  end
end

function Connection:try_join_fight(msg)
  if not uid_waiting_for_fight then
    uid_waiting_for_fight = self.uid
  elseif uid_waiting_for_fight ~= self.uid then
    start_fight(self.uid, uid_waiting_for_fight)
    uid_waiting_for_fight = nil
  end
end

function Connection:try_dungeon(msg)
  local which = msg.idx
  if (not which) or (not dungeons.npcs[which]) then
    return
  end
  local total_floors = #dungeons.npcs[which]
  local data = uid_to_data[self.uid]
  if not check_active_deck(data) then
    self:crash_and_burn()
    return false
  end
  local my_floor = data.dungeon_floors[which]
  my_floor = min(total_floors, my_floor)
  local npcs = dungeons.npcs[which][my_floor]
  local npc_id = uniformly(npcs)
  local lose_floor, win_floor = 1,1
  if my_floor ~= total_floors then
    lose_floor = max(my_floor-1, 1)
    win_floor = my_floor+1
  end
  data.dungeon_floors[which] = lose_floor
  modified_file(data)
  function self:on_game_over(win)
    if win then
      if my_floor == total_floors then
        data.dungeon_clears[which] = data.dungeon_clears[which] + 1
      end
      -- dungeon rewards section
      local reward_floor = dungeons.rewards[which][my_floor] or dungeons.rewards[which][0]
      local reward_data = reward_floor[data.dungeon_clears[which]] or reward_floor[0]
      local num_ores=reward_data["ore"] or 0
      local ores={"210008", "210009", "210011", "210012"}
      local rewards={}
      if num_ores > 0 then
        for i=1,num_ores do
          local ore_id=uniformly(ores)
          if not rewards[ore_id] then
            rewards[ore_id] = 1
          else
            rewards[ore_id] = rewards[ore_id] + 1
          end
        end
      end
      local reward_cards=reward_data["cards"]
      if reward_cards then
        for i, v in pairs(reward_cards) do
          if not rewards[i] then
            rewards[i] = v
          else
            rewards[i] = rewards[i] + v
          end
        end
      end
      self:update_collection(rewards)
      self:send({type="dungeon_rewards",rewards=rewards})
      -- end dungeon rewards section
      data.dungeon_floors[which] = win_floor
      modified_file(data)
    end
  end
  setup_pve(self, npc_id)
end

function start_fight(aid, bid)
  local a,b = uid_to_connection[aid], uid_to_connection[bid]
  local function on_fight_over(self, score)
    local data = uid_to_data[self.uid]
    local num_accessories = 0
    if score < 0 then
      num_accessories = 0
    elseif score <= 20 then
      num_accessories = 2
    elseif score <= 30 then
      num_accessories = 3
    elseif score <= 50 then
      num_accessories = 4
    else
      num_accessories = 5
    end
    local rewards = {}
    local s1_accessories = {"210001", "210002", "210003", "210004", "210005", "210006", "210007"}
    if num_accessories > 0 then
      for i=1,num_accessories do
        local acc_id = uniformly(s1_accessories)
        if not rewards[acc_id] then
          rewards[acc_id] = 1
        else
          rewards[acc_id] = rewards[acc_id] + 1
        end
      end
    end
    self:update_collection(rewards)
    self:send({type="dungeon_rewards",rewards=rewards})
    modified_file(data)
  end
  a.on_fight_over = on_fight_over
  b.on_fight_over = on_fight_over
  setup_game(a,b)
end

function Connection:update_collection(diff, reason)
  local data = uid_to_data[self.uid]
  for k,v in pairs(diff) do
    if (data.collection[k] or 0) + v < 0 then
      return false
    end
  end
  for k,v in pairs(diff) do
    data.collection[k] = (data.collection[k] or 0) + v
    if data.collection[k] == 0 then
      data.collection[k] = nil
    end
  end
  self:send({type="update_collection",diff=diff,reason=reason})
  modified_file(data)
  return true
end

function Connection:update_cafe(card_id, cafe_id)
  local data = uid_to_data[self.uid]
  self:send({type="update_cafe",cafe=data.cafe,card_id=card_id, cafe_id=cafe_id})
end

function Connection:set_deck(idx, deck)
  local char,other=0,0
  local data = uid_to_data[self.uid]
  if not check_deck(deck, data) then 
    return false
  end
  if idx ~= floor(idx) or
      idx < 1 or
      idx > 100 then
    return false
  end
  for i=1,idx do
    data.decks[i] = data.decks[i] or {}
  end
  data.decks[idx] = deck
  self:send({type="set_deck",idx=idx,deck=deck})
  modified_file(data)
  return true
end

function Connection:try_update_deck(msg)
  local idx = msg.idx
  local diff = fix_num_keys(msg.diff)
  local data = uid_to_data[self.uid]
  if type(idx) ~= "number" or
      type(diff) ~= "table" or 
      idx ~= floor(idx) or
      idx < 1 or
      idx > 100 then
    return false
  end
  local deck = shallowcpy(data.decks[idx] or {})
  for k,v in pairs(diff) do
    if type(v) ~= "number" then
      return false
    end
    deck[k] = (deck[k] or 0) + v
    if deck[k] == 0 then
      deck[k] = nil
    end
  end
  if not check_deck(deck, data) then
    return false
  end
  for i=1,idx-1 do
    data.decks[i] = data.decks[i] or {}
  end
  data.decks[idx] = deck
  modified_file(data)
  return true
end

function Connection:crash_and_burn()
  self:send({type="nope_nope_nope"})
  self:close()
end

function Connection:set_active_deck(idx)
  local char,other=0,0
  local data = uid_to_data[self.uid]
  if not idx then return false end
  local deck = data.decks[idx]
  if not deck then return false end
  for k,v in pairs(deck) do
    if k < 200000 then
      char = char + v
    else
      other = other + v
    end
  end
  if char ~= 1 or other ~= 30 then
    return false
  end
  data.active_deck = idx
  self:send({type="set_active_deck",idx=idx})
  modified_file(data)
  return true
end

function Connection:try_chat(msg)
  local data = uid_to_data[self.uid]
  if type(msg.text) ~= "string" or
      msg.text:len() < 1 or
      msg.text:len() > 200 then
    return false
  end
  chat_q:push({type="general_chat", from=data.username, text=msg.text})
  return true
end

function Connection:feed_card(msg)
  local data = uid_to_data[self.uid]
  local eater_id = msg.msg[1]
  local cafe_id = msg.msg[2]
  local food_id = msg.msg[3]
  if not (data.collection[food_id] and data.collection[eater_id]) then
    return false  -- trying to feed cards that you don't have
  end
  if not data.cafe[eater_id] then
    data.cafe[eater_id] = {}
  end
  if not data.cafe[eater_id][cafe_id] then
    local num_cafe_character = #data.cafe[eater_id]
    if num_cafe_character < data.collection[eater_id] and giftable[eater_id] and num_cafe_character < 11 then
      data.cafe[eater_id][num_cafe_character+1] = {0, 0, 0, 0, 0} 
      cafe_id = num_cafe_character+1
      -- the above 5 numbers are {WIS, SENS, PERS, GLAM, LIKE}
    else
      return false  -- trying to feed an ungiftable character or an cafe-ized character when all have been cafe-ized or too many cafe characters
    end
  end

  local cafe_stats = data.cafe[eater_id][cafe_id]

  -- figure out how much to modify cafe character stats by
  local food_card = Card(food_id, 0)
  local base_gift_modifiers = {0, 0, 0, 0}  --{WIS, SENS, PERS, GLAM}
  local like_multiplier = 1.0
  if cafe_stats[5] > 25 and cafe_stats[5] < 50 then
    like_multiplier = 2.0
  elseif cafe_stats[5] >= 50 then
      like_multiplier = 3.0
  end
  local stat_multiplier = 1.0
  local rarity_to_stat_multiplier = {
    ["UC"]=1.5,
    ["R"]=2.0,
    ["DR"]=3.0,
    ["TR"]=4.0}
  if rarity_to_stat_multiplier[food_card.rarity] then
    stat_multiplier = stat_multiplier * rarity_to_stat_multiplier[food_card.rarity]
  end
  if food_card.type == "spell" and food_id%2 == 0 then
    base_gift_modifiers = {1, -1, 0, 0}
  elseif food_card.type == "spell" and food_id%2 == 1 then
    base_gift_modifiers = {0, 0, -1, 1}
  elseif food_card.type == "follower" and food_id%2 == 0 then
    base_gift_modifiers = {-1, 1, 0, 0}
  elseif food_card.type == "follower" and food_id%2 == 1 then
    base_gift_modifiers = {0, 0, 1, -1}
  else
    return false  -- invalid gift
  end

  local like_change = 2
  if math.random() > 0.5 then
    like_change = -1
  end
  if food_card.rarity == "EV" then
    like_change = 0
  end

  -- modify cafe character stats
  local diff = {0, 0, 0, 0, 0}
  for i = 1,4 do
    diff[i] = math.ceil(base_gift_modifiers[i] * like_multiplier * stat_multiplier)
  end
  diff[5] = like_change
  for i = 1,5 do
    cafe_stats[i] = cafe_stats[i] + diff[i]
    if cafe_stats[i] < 0 then
      cafe_stats[i] = 0
    end
  end

  -- check for transformation
  if cafe_stats[5] > 99 then
    if giftable[eater_id][5] and cafe_stats[1] > 200 and cafe_stats[2] > 200 and cafe_stats[3] > 200 and cafe_stats[4] > 200 then
      cafe_stats = nil
      self:update_collection({[eater_id]=-1, [giftable[eater_id][5]]=1})
    elseif giftable[eater_id][1] and cafe_stats[1] > cafe_stats[2] and cafe_stats[1] > cafe_stats[3] and cafe_stats[1] > cafe_stats[4] then
      cafe_stats = nil
      self:update_collection({[eater_id]=-1, [giftable[eater_id][1]]=1})
    elseif giftable[eater_id][2] and cafe_stats[2] > cafe_stats[1] and cafe_stats[2] > cafe_stats[3] and cafe_stats[2] > cafe_stats[4] then
      cafe_stats = nil
      self:update_collection({[eater_id]=-1, [giftable[eater_id][2]]=1})
    elseif giftable[eater_id][3] and cafe_stats[3] > cafe_stats[1] and cafe_stats[3] > cafe_stats[2] and cafe_stats[3] > cafe_stats[4] then
      cafe_stats = nil
      self:update_collection({[eater_id]=-1, [giftable[eater_id][3]]=1})
    elseif giftable[eater_id][4] and cafe_stats[4] > cafe_stats[1] and cafe_stats[4] > cafe_stats[2] and cafe_stats[4] > cafe_stats[3] then
      cafe_stats = nil
      self:update_collection({[eater_id]=-1, [giftable[eater_id][4]]=1})
    end
    self:send({type="server_message",message="HENSHIN!"})
    table.remove(data.cafe[eater_id], cafe_id)
    eater_id = nil
    cafe_id = nil
  end

  -- cleanup
  self:update_cafe(eater_id, cafe_id)
  self:update_collection({[food_id]=-1})
  self:send({type="server_message",message="you fed!"})
  modified_file(data)
  return true
end

function Connection:try_craft(msg)
  local ret_diff = {}
  local id = msg.id
  local data = uid_to_data[self.uid]
  if type(id) == "number" then
    local recipe = recipes[msg.id]
    if recipe then
      local used_amt = {}
      for _,deck in pairs(data.decks) do
        for input,_ in pairs(recipe) do
          used_amt[input] = max(deck[input] or 0, used_amt[input] or 0)
        end
      end
      local enough = true
      for input,_ in pairs(recipe) do
        if (data.collection[input] or 0) - used_amt[input] < recipe[input] then
          enough = false
          break
        end
      end
      if enough then
        for k,v in pairs(recipe) do
          ret_diff[k] = -v
        end
        ret_diff[id] = (ret_diff[id] or 0) + 1
      end
    end
  end
  self:update_collection(ret_diff, "craft")
end

function prep_deck(uid)
  local t
  if type(uid) == "string" then
    local data = uid_to_data[uid]
    t = data.decks[data.active_deck]
  else -- passed an NPC ID as uid
    t = npc_decks[uid]
  end
  local ret = {}
  for id, count in pairs(t) do
    for i=1,count do
      ret[#ret+1] = id+0
    end
  end
  return ret
end

function score_game(game)
  local scores = {0, 0}
  local turn_bonus = 0
  if game.turn < 3 then
    turn_bonus = -100
  elseif game.turn < 7 then
    turn_bonus = 20
  elseif game.turn < 10 then
    turn_bonus = 30
  else
    turn_bonus = 40
  end
  for i,player in pairs({game.P1, game.P2}) do
    local deck_bonus = 0
    if #player.deck > 23 then
      deck_bonus = -100
    elseif #player.deck < 10 then
      deck_bonus = 10
    end
    local life_bonus = 0
    if player.lose then
      life_bonus = -10
    elseif player.character.life < 10 then
      life_bonus = 10
    end
    scores[i] = deck_bonus + turn_bonus + life_bonus
  end
  return scores
end
function destroy_game(a, win)
  local scores = score_game(a.game)
  local score = scores[a.player_index]
  a.game = nil
  a.player_index = nil
  a.opponent = nil
  a.state = "lobby"
  if a.on_fight_over then
    a:on_fight_over(score)
  end
  a.on_fight_over = nil
  if a.on_game_over then
    a:on_game_over(win)
  end
  a.on_game_over = nil
end

function setup_game(a,b)
  print("SETUP")
  local game = Game(prep_deck(a.uid), prep_deck(b.uid))
  game.P1.connection = a
  game.P2.connection = b
  a.game = game
  b.game = game
  a.player_index = 1
  b.player_index = 2
  a.state = "playing"
  b.state = "playing"
  a.opponent = b
  b.opponent = a
  a:send({type="game_start", opponent_name=users.uid_to_username[b.uid],
    game_type="pvp"})
  b:send({type="game_start", opponent_name=users.uid_to_username[a.uid],
    game_type="pvp"})
  game.thread = coroutine.create(function()
    game:run()
  end)
  resume_game(game)
end

function setup_pve(a,b)
  print("SETUP PVE")
  local game = Game(prep_deck(a.uid), prep_deck(b))
  game.P1.connection = a
  a.game = game
  a.player_index = 1
  a.state = "playing"
  a:send({type="game_start", opponent_name=Card(b).name, game_type="pve"})
  game.thread = coroutine.create(function()
    game:run()
  end)
  resume_game(game)
end

function resume_game(game)
  print("RESUME GAME")
  if coroutine.status(game.thread) == "suspended" then
    local status, err = coroutine.resume(game.thread)
    if not status then
      print("game ended\n"..err.."\n"..debug.traceback(game.thread))
    end
  end
end

function wait() end

function main()
  local server_socket,qq,qqq,qqqq = socket.bind("*", 49570)
  print(server_socket,qq,qqq,qqqq)

  local prev_now = time()
  while true do
    print("MAINLOOP")
    server_socket:settimeout(0)
    local new_conn = server_socket:accept()
    if new_conn then
      print("making new connection!")
      for k,v in pairs(connections) do
        print(k, v.state)
      end
      Connection(new_conn)
    end
    local recvt = {server_socket}
    for _,v in pairs(connections) do
      if v.state == "handshake" then
        v:dohandshake()
      end
      recvt[#recvt+1] = v.socket
    end
    local ready = socket.select(recvt, nil, 1)
    socket.sleep(.01)
    assert(type(ready) == "table")
    for _,v in ipairs(ready) do
      if socket_to_idx[v] then
        connections[socket_to_idx[v]]:read()
      end
    end

    while chat_q:len() ~= 0 do
      local msg = chat_q:pop()
      for k,connection in pairs(connections) do
        if connection.state ~= "connected" then
          connection:send(msg)
        end
      end
    end

    for _,v in pairs(connections) do
      if v.state == "playing" then
        resume_game(v.game)
        if v.game.winner then
          destroy_game(v, v.player_index == v.game.winner)
        end
      end
    end

    write_a_file()

    --[[local now = time()
    if now ~= prev_now then
      for _,v in pairs(connections) do
        if now - v.last_read > 10 then
          --v:close()
        elseif now - v.last_read > 1 then
          --v:send("ELOL")
        end
      end
      prev_now = now
    end
    broadcast_lobby()--]]
  end
end

math.randomseed(os.time())
main()
