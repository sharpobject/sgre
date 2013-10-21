local TCP_sock = nil
local leftovers = ""
local INITIAL_VERSION_MSG = "Checking for updates..."
local length = nil
VERSION_MSG = INITIAL_VERSION_MSG

function coin_msg(P1_first)
  return {type="coin", P1_first=P1_first}
end

function flush_socket()
  local junk,err,data = TCP_sock:receive('*a')
  -- lol, if it returned successfully then that's bad!
  if not err then
    if VERSION_MSG == INITIAL_VERSION_MSG then
      VERSION_MSG = "Could not check for updates :("
    end
  end
  leftovers = leftovers..data
  if data:len() > 0 then
    print("GOT "..data)
  end
end

function close_socket()
  TCP_sock:close()
  TCP_sock = nil
end

function network_init()
  TCP_sock = socket.tcp()
  TCP_sock:settimeout(7)
  if not TCP_sock:connect("burke.ro",49570) then
    VERSION_MSG = "Could not check for updates :("
  end
  TCP_sock:settimeout(0)
  TCP_sock:send(VERSION)
  network_init = function() end
end

function do_messages()
  if not TCP_sock then return end
  flush_socket()
  if not length then
    if leftovers:len() >= 4 then
      length = tonumber(leftovers:sub(1,4))
      leftovers = leftovers:sub(5)
    end
  end
  if leftovers:len() == length then
    VERSION_MSG = leftovers
    close_socket()
  end
end
