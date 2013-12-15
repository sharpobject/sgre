socket = require("socket")
json = require("dkjson")
require("stridx")
require("util")
require("class")
require("queue")
require("globals")
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
require("validate")

local byte = string.byte
local char = string.char
local floor = math.floor
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

local file_q = Queue()

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
  data.filename = "path"
  data.last_modified = nil
  uid_to_data[uid] = data
end

local function sha1(s)
  local sha = hash.sha1()
  sha:process(s)
  return sha:finish()
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
    collection = {},
    decks = {},
    friends = {},
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
  connections[s.index] = s
  socket_to_idx[socket] = s.index
  s.socket = socket
  socket:settimeout(0)
  s.leftovers = ""
  s.state = "connected"
  s.last_read = time()
end)

function Connection:send(stuff)
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
  --self.state = "lobby"
  self:send({type="opponent_disconnected"})
end

function Connection:close()
  print("CONN CLOSE")
  if self.opponent then
    self.opponent:opponent_disconnected()
  end
  socket_to_idx[self.socket] = nil
  connections[self.index] = nil
  self.socket:close()
end

function Connection:J(message)
  print("CONN J")
  message = json.decode(message)
  if self.state == "connected" then
    if message.type == "register" then
      local res = try_register(message)
      self:send({type="register_result", success=res})
    elseif message.type == "login" then
      self:try_login(message)
    else
      print("got unexpected message in connected state with type "..tostring(message.type))
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
  print("got raw data "..data)
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
      print("got JSON message "..jmsg)
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
    collection = data.collection,
    decks = data.decks,
    friends = data.friends,
  }})
end

function Connection:try_select_faction(msg)
end

function str_to_deck(s)
  s = s:sub(s:find("%d%d%d[%dDPC]+")):split("DPC")
  local t = {}
  t[1] = s[1] + 0
  for i=2,#s,2 do
    for j=1,s[i]+0 do
      t[#t+1] = s[i+1]+0
    end
  end
  return t
end

file_to_deck = function(s)
  local file, err = io.open("decks/floor"..s..".txt", "r")
  if file then
    s = file:read("*a")
    file:close()
    return str_to_deck(s)
  end
end

decks = {}
for i=1,40 do
  if i < 10 then
    decks[#decks+1] = file_to_deck("0"..i)
  elseif i ~= 37 then
    decks[#decks+1] = file_to_deck(i)
  end
end
print("read "..#decks.." decks")

function setup_game(a,b)
  print("SETUP")
  local game = Game(uniformly(decks), uniformly(decks))
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
  local server_socket,qq,qqq,qqqq = socket.bind("localhost", 49570)
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

    local waiting = nil
    for _,v in pairs(connections) do
      if v.state == "lobby" then
        if waiting then
          setup_game(v, waiting)
        else
          waiting = v
        end
      elseif v.state == "playing" then
        resume_game(v.game)
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

main()
