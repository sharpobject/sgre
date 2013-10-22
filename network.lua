local TCP_sock = nil
local leftovers = ""
local J
local char, byte = string.char, string.byte
net_q = Queue()

function net_send(stuff)
  assert(type(stuff) == "table")
  if type(stuff) == "table" then
    local json = json.encode(stuff)
    local len = json:len()
    local prefix = "J"..char(len/65536)..char((len/256)%256)..char(len%256)
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
  net_q:push(stuff)
end

function data_received(data)
  if data:len() > 2 then
    print("got raw data "..data)
  end
  data = leftovers .. data
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
        J(jmsg)
      end))
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
  TCP_sock:settimeout(0)
  network_init = function() end
end

function do_messages()
  if not TCP_sock then return end
  flush_socket()
end
