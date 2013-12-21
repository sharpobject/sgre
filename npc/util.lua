local sort, pairs, select, unpack, error =
  table.sort, pairs, select, unpack, error
local type, setmetatable, getmetatable =
      type, setmetatable, getmetatable
local random = math.random

-- bounds b so a<=b<=c
function bound(a, b, c)
  if b<a then return a
  elseif b>c then return c
  else return b end
end

-- mods b so a<=b<=c
function wrap(a, b, c)
  return (b-a)%(c-a+1)+a
end

function arr_to_set(tab)
  local ret = {}
  for i=1,#tab do
    ret[tab[i]] = true
  end
  return ret
end

-- filter for numeric tables
function filter(func, tab)
  local ret = {}
  for i=1,#tab do
    if func(tab[i]) then
      ret[#ret+1] = tab[i]
    end
  end
  return ret
end

-- map for numeric tables
function map(func, tab)
  local ret = {}
  for i=1, #tab do
    ret[i]=func(tab[i])
  end
  return ret
end

-- map for dicts
function map_dict(func, tab)
  local ret = {}
  for key,val in pairs(tab) do
    ret[key]=func(val)
  end
  return ret
end

function map_inplace(func, tab)
  for i=1, #tab do
    tab[i]=func(tab[i])
  end
  return tab
end

function map_dict_inplace(func, tab)
  for key,val in pairs(tab) do
    tab[key]=func(val)
  end
  return tab
end

-- reduce for numeric tables
function reduce(func, tab, ...)
  local idx, value = 2, nil
  if select("#", ...) ~= 0 then
    value = select(1, ...)
    idx = 1
  elseif #tab == 0 then
    error("Tried to reduce empty table with no initial value")
  else
    value = tab[1]
  end
  for i=idx,#tab do
    value = func(value, tab[i])
  end
  return value
end

function car(tab)
  return tab[1]
end
-- This sucks lol
function cdr(tab)
  return {select(2, unpack(tab))}
end

-- a useful right inverse of table.concat
function procat(str)
  local ret = {}
  for i=1,#str do
    ret[i]=str:sub(i,i)
  end
  return ret
end

-- iterate over frozen pairs in sorted order
function spairs(tab)
  local keys,vals,idx = {},{},0
  for k in pairs(tab) do
    keys[#keys+1] = k
  end
  sort(keys)
  for i=1,#keys do
    vals[i]=tab[keys[i]]
  end
  return function()
    idx = idx + 1
    return keys[idx], vals[idx]
  end
end

function uniformly(t)
  if #t==0 then
    return nil
  end
  return t[random(#t)]
end

-- accepts a table, returns a shuffled copy of the table
-- accepts >1 args, returns a permutation of the args
function shuffled(first_arg, ...)
  local ret = {}
  local tab = {first_arg, ...}
  local is_packed = (#tab > 1)
  if (not is_packed) then
      tab = first_arg
      for i=1,#tab do
          ret[i] = tab[i]
      end
  else
      ret = tab
  end
  local n = #ret
  for i=1,n do
      local j = random(i,n)
      ret[i], ret[j] = ret[j], ret[i]
  end
  if is_packed then
      return unpack(ret)
  end
  return ret
end

function shuffle(tab)
  local n = #tab
  for i=1,n do
    local j = random(i,n)
    tab[i], tab[j] = tab[j], tab[i]
  end
  return tab
end

function reverse(tab)
  local n = #tab
  for i=1,n/2 do
    tab[i],tab[n+1-i] = tab[n+1-i],tab[i]
  end
  return tab
end

function shallowcpy(tab)
  local ret = {}
  for k,v in pairs(tab) do
    ret[k]=v
  end
  return ret
end

local deepcpy_mapping = {}
local real_deepcpy
function real_deepcpy(tab)
  if deepcpy_mapping[tab] ~= nil then
    return deepcpy_mapping[tab]
  end
  local ret = {}
  deepcpy_mapping[tab] = ret
  deepcpy_mapping[ret] = ret
  for k,v in pairs(tab) do
    if type(k) == "table" then
      k=real_deepcpy(k)
    end
    if type(v) == "table" then
      v=real_deepcpy(v)
    end
    ret[k]=v
  end
  return setmetatable(ret, getmetatable(tab))
end

function deepcpy(tab)
  if type(tab) ~= "table" then return tab end
  local ret = real_deepcpy(tab)
  deepcpy_mapping = {}
  return ret
end

function shallowcpy(tab)
  if type(tab) ~= "table" then return tab end
  local ret = {}
  for k,v in pairs(tab) do
    ret[k]=v
  end
  return ret
end

-- pls no table keys
function deepeq(a,b)
  if type(a) ~= "table" or type(b) ~= "table" then
    --print("comparing non-tables "..tostring(a) .." and "..tostring(b))
    return a==b
  end
  local done_k = {}
  for k,v in pairs(a) do
    done_k[k] = true
    if not deepeq(a[k],b[k]) then
      --print("false because key "..k.." has different values "..tostring(a[k]).." and "..tostring(b[k]))
      return false
    end
  end
  for k,_ in pairs(b) do
    if not done_k[k] then
      --print("false because key "..k.." is missing from a")
      return false
    end
  end
  --print("true!")
  return true
end

function file_contents(filename)
  if love then
    local file = love.filesystem.newFile(filename)
    file:open("r")
    return file:read(file:getSize())
  end
  return io.open(filename):read("*a")
end

function set_file(filename, contents)
  local file = io.open(filename, "w")
  file:write(contents)
  file:close()
end

function arr_to_counter(t)
  local ret = {}
  for i=1,#t do
    local elem = t[i]
    ret[elem] = (ret[elem] or 0) + 1
  end
  return ret
end

-- for fixing json encoded numeric dicts
function fix_num_keys(t)
  local ret = {}
  for k,v in pairs(t) do
    ret[tonumber(k) or k] = v
  end
  return ret
end
