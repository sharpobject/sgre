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

local byte = string.byte
local char = string.char
local floor = math.floor
local pairs = pairs
local ipairs = ipairs
local random = math.random
local time = os.time
local TIMEOUT = 10


local INDEX = 1
local connections = {}
local socket_to_idx = {}

Connection = class(function(s, socket)
  s.index = INDEX
  INDEX = INDEX + 1
  connections[s.index] = s
  socket_to_idx[socket] = s.index
  s.socket = socket
  socket:settimeout(0)
  s.leftovers = ""
  s.state = "lobby"
  s.last_read = time()
end)

function Connection.send(self, stuff)
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

function Connection.opponent_disconnected(self)
  print("OP DIS")
  self.opponent = nil
  --self.state = "lobby"
  self:send({type="opponent_disconnected"})
end

function Connection.close(self)
  print("CONN CLOSE")
  if self.opponent then
    self.opponent:opponent_disconnected()
  end
  socket_to_idx[self.socket] = nil
  connections[self.index] = nil
  self.socket:close()
end

function Connection.J(self, message)
  print("CONN J")
  message = json.decode(message)
  if self.state == "playing" then
    self.game["P"..self.player_index]:receive(message)
    self:send({type="can_act", can_act=(not self.game["P"..self.player_index].ready)})
  end
end

-- TODO: this should not be O(n^2) lol
function Connection.data_received(self, data)
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

function Connection.read(self)
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
  local server_socket = socket.bind("burke.ro", 49570)

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
