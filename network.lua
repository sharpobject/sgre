require("dumbprint")
--[[require"util"
require"stridx"
require"class"
require"queue"
socket = require"socket"
json = require"dkjson"-]]
require"ssl"

local TCP_sock = nil
local leftovers = ""
local J
local char, byte = string.char, string.byte
local floor = math.floor
local handlers = {}
local crash_msg = nil
net_q = Queue()

function net_send(stuff)
  assert(type(stuff) == "table")
  if type(stuff) == "table" then
    local json = json.encode(stuff)
    local len = json:len()
    local prefix = "J"..char(floor(len/65536))..char(floor((len/256)%256))..char(len%256)
    print(byte(prefix[1]), byte(prefix[2]), byte(prefix[3]), byte(prefix[4]))
    print("sending json "..json)
    stuff = prefix..json
  end
  local foo = {TCP_sock:send(stuff)}
  if stuff[1] ~= "I" then
    print(unpack(foo))
  end
  if not foo[1] then
    close_socket()
  end
end

function J(stuff)
  stuff = json.decode(stuff)
  if handlers[stuff.type] then
    handlers[stuff.type](stuff)
  else
    net_q:push(stuff)
  end
end

function data_received(data)
--  print("got raw data "..data)
  if data:len() == 0 then
  --  print("got nothing")
    return
  end
  data = leftovers .. data
  local idx = 1
  while data:len() > 0 do
    --assert(type(data) == "string")
    local msg_type = data[1]
    --assert(type(msg_type) == "string")
    if msg_type == "J" then
      if data:len() < 4 then
        print("breaking, dont have 4 bytes")
        break
      end
      local msg_len = byte(data[2])*65536 + byte(data[3])*256 + byte(data[4])
      if data:len() < 4 + msg_len then
        print("breaking, have "..data:len().." bytes but need "..msg_len)
        break
      end
      local jmsg = data:sub(5, msg_len+4)
      print("got JSON message "..jmsg)
      print("Pcall results for json: ", pcall(function()
        J(jmsg)
      end))
      if crash_msg then error(crash_msg) end
      data = data:sub(msg_len+5)
    else
      close_socket()
    end
  end
  leftovers = data
end

function flush_socket()
  local junk,err,data = TCP_sock:receive('*a')
  -- lol, if it returned successfully then that's bad!
  if not err then
    print("oh teh noes")
    data = junk
  end
  data_received(data)
end

function close_socket()
  TCP_sock:close()
  TCP_sock = nil
end

function network_init()
  TCP_sock = socket.tcp()
  TCP_sock:settimeout(7)
  if not TCP_sock:connect("localhost",49570) then
    error("failed to connect yolo")
  end
  local params = {
     mode = "client",
     protocol = "tlsv1",
  }
  TCP_sock = assert(ssl.wrap(TCP_sock, params))
  TCP_sock:dohandshake()
  TCP_sock:settimeout(0)
  network_init = function() end
end

local last_zombie_time = 0

function do_messages()
  if not TCP_sock then return end
  flush_socket()
  local now = love.timer.getTime()
  if now - 10 > last_zombie_time then
    net_send({type="zombie"})
    last_zombie_time = now
  end
end

function handlers.update_collection(msg)
  local diff = fix_num_keys(msg.diff)
  for k,v in pairs(diff) do
    user_data.collection[k] = (user_data.collection[k] or 0) + v
    if user_data.collection[k] == 0 then
      user_data.collection[k] = nil
    end
  end
  if msg.reason == "craft" and frames.craft.enable_buttons then
    frames.craft.enable_buttons()
  elseif msg.reason == "cafe" and frames.cafe.update_feeding_list then
    frames.cafe.update_feeding_list()
    frames.cafe.populate_cafe_card_list()
  elseif msg.reason == "xmute" then
    frames.xmute.enable_buttons()
    frames.xmute.populate_xmutable_card_list()
  end
end

function handlers.update_cafe(msg)
  user_data.cafe = fix_num_keys(msg.cafe)
  if frames.cafe then
    frames.cafe.active_character_card_id = msg.card_id
    frames.cafe.active_character_cafe_id = msg.cafe_id
    frames.cafe.populate_cafe_card_list()
    frames.cafe.refresh_stats_pane()
    if msg.transform and loveframes.GetState() == "cafe" then
      frames.cafe.stats_pane:Remove()
      frames.cafe.popup_notification("Transformation!")
    end
  end
end

function handlers.set_deck(msg)
  local deck = fix_num_keys(msg.deck)
  user_data.decks[msg.idx] = deck
end

function handlers.set_active_deck(msg)
  user_data.active_deck = msg.idx
end

function handlers.general_chat(msg)
  if frames.lobby then
    frames.lobby.text:SetText(frames.lobby.text:GetText().."\n"..
      msg.from..": "..msg.text)
  end
end

function handlers.dungeon_rewards(msg)
  user_data.latest_rewards=msg.rewards
end

function handlers.nope_nope_nope(msg)
  crash_msg = msg.reason or "nope_nope_nope"
end

function handlers.server_message(msg)
  if loveframes.GetState() == "cafe" then
    frames.cafe.popup_notification(msg.message)
  end
end

function handlers.update_dungeon(msg)
  user_data.dungeon_clears = msg.dungeon_clears
  user_data.dungeon_floors = msg.dungeon_floors
end

function handlers.today(msg)
  user_data.today = msg.today
end

function handlers.last_muspel_date(msg)
  user_data.last_muspel_date = msg.last_muspel_date
end

function handlers.zombie(msg)
end
