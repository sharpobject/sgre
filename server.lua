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

local byte = string.byte
local char = string.char
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
  assert(type(stuff) == "table")
  if type(stuff) == "table" then
    local json = json.encode(stuff)
    local len = json:len()
    local prefix = "J"..char(len/65536)..char((len/256)%256)..char(len%256)
    print(byte(prefix[1]), byte(prefix[2]), byte(prefix[3]), byte(prefix[4]))
    print("sending json "..json)
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
  self.opponent = nil
  --self.state = "lobby"
  self:send({type="opponent_disconnected"})
end

function Connection.close(self)
  if self.opponent then
    self.opponent:opponent_disconnected()
  end
  socket_to_idx[self.socket] = nil
  connections[self.index] = nil
  self.socket:close()
end

function Connection.J(self, message)
  message = json.decode(message)
  if self.state == "playing" then
    self.game:receive(self.player_index, message)
    self:send({type="pong"})
  end
end

-- TODO: this should not be O(n^2) lol
function Connection.data_received(self, data)
  self.last_read = time()
  if data:len() ~= 2 then
    print("got raw data "..data)
  end
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
    end
  end
  self.leftovers = data
end

function Connection.read(self)
  local junk, err, data = self.socket:receive("*a")
  if not err then
    error("shitfuck")
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
  local game = Game(uniformly(decks), uniformly(decks))
  game.P1.connection = a
  game.P2.connection = b
  a.game = game
  b.game = game
  a.player_index = 1
  b.player_index = 2
  game.thread = coroutine.create(function()
    game:run()
  end)
  resume_game(game)
end

function resume_game(game)
  if coroutine.status(game.thread) == "suspended" then
    local status, err = coroutine.resume(game.thread)
    if not status then
      print("game ended\n"..err.."\n"..debug.traceback(game.thread))
    end
  end
end

function wait() end

function main()
  local server_socket = socket.bind("localhost", 49570)

  local prev_now = time()
  while true do
    server_socket:settimeout(0)
    local new_conn = server_socket:accept()
    if new_conn then
      Connection(new_conn)
    end
    local recvt = {server_socket}
    for _,v in pairs(connections) do
      recvt[#recvt+1] = v.socket
    end
    local ready = socket.select(recvt, nil, 1)
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
