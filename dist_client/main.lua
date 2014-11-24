local msg = "Checking for updates..."
local async = require "async"
local json = require "dkjson"
local start_time = 1/0

function love.load()
  async.load()
  async.ensure.exactly(1)

  if love._os == "OS X" then
    package.cpath = love.filesystem.getSourceBaseDirectory() .. "/?.so;" ..
        package.cpath
    require("ssl.https")
  end

  httprequest = async.define("httprequest", function(url)
    require("socket")
    if love._os == "OS X" and not love.DID_CPATH then
      love.DID_CPATH = true
      package.cpath = love.filesystem.getSourceBaseDirectory() .. "/?.so;" ..
          package.cpath
    end
    local https = require("ssl.https")
    local accept_digest = "235f0db09c9ec586a1a4d55d6d3188892a038e70a43f42cd3e2e94a553ba8fe8"
    local body, code, headers, status, digest = https.request(url)
    if digest == accept_digest and code == 200 then
      return body
    elseif digest ~= accept_digest then
      return nil, "Got wrong certificate digest."
    else
      return nil, "Got status code "..tostring(code).." and body "..tostring(body)
    end
  end)

  local start_game, get_update, update_failed, no_update_required

  function start_game()
    msg = msg .. "\nStarting the game ~"
    start_time = love.timer.getTime() + 2
  end

  function get_update(list, idx, new_versions, old_versions, succeeded)
    if not succeeded then
      return update_failed()
    end
    if idx > #list then
      local file = love.filesystem.newFile("version.dat")
      file:open("w")
      file:write(json.encode(new_versions))
      file:close()
      return start_game()
    else
      local to_write = {}
      for k,v in pairs(old_versions) do to_write[k] = v end
      for i=1,idx-1 do
        to_write[list[i]] = new_versions[list[i]]
      end
      local file = love.filesystem.newFile("version.dat")
      file:open("w")
      file:write(json.encode(to_write))
      file:close()
    end
    msg = msg .. "\n" .. "Downloading " .. list[idx]
    httprequest({
      success = function(result)
        local file = love.filesystem.newFile(list[idx])
        local succeeding = true
        succeeding = succeeding and file:open("w")
        if succeeding then
          succeeding = succeeding and file:write(result)
        end
        if succeeding then
          succeeding = succeeding and file:close()
        end
        get_update(list, idx+1, new_versions, old_versions, succeeded and succeeding)
      end,
      error = function(err)
        error(err)
        update_failed()
      end,
    }, "https://update.burke.ro/"..list[idx])
  end
  function no_update_required()
    msg = msg .. "\nNo update required ~"
    return start_game()
  end
  function update_failed()
    msg = msg .. "\nUpdate failed :("
    return start_game()
  end

  httprequest({
    success = function(result, err)
      print(result, type(result))
      print(digest, type(digest))
      if not result then
        msg = msg .. "\n" .. err
        update_failed()
        return
      end
      local remote_versions = json.decode(result)
      local file = love.filesystem.newFile("version.dat")
      file:open("r")
      local my_version = file:read(file:getSize())
      print(my_version, type(my_version))
      my_version = json.decode(my_version)
      file:close()
      local to_get = {}
      for k,v in pairs(remote_versions) do
        if v > (my_version[k] or 0) then
          to_get[#to_get+1] = k
        end
      end
      if #to_get > 0 then
        get_update(to_get, 1, remote_versions, my_version, true)
      else
        no_update_required()
      end
    end,
    error = function(err)
      error(err)
      update_failed()
    end,
  }, "https://update.burke.ro/version.dat")
end

function love.update(dt)
  async.update()
  if love.timer.getTime() > start_time then
    local file = love.filesystem.newFile("version.dat")
    file:open("r")
    local my_version = file:read(file:getSize())
    my_version = json.decode(my_version)
    for k,v in pairs(my_version) do
      love.filesystem.mount(k, "")
    end
    require("main_again")
    love.load()
  end
end

function love.threaderror(t, err)
  error(err)
end

function love.draw()
  love.graphics.printf("Sword Girls do their best now and are preparing. Please wait warmly until it is ready.\n"..msg, 0, 250, 800, "center")
end
