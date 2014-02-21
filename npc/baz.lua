function game_to_cards(game)
  if #game==0 then return {} end
  local ret = {}
  for i=1,5 do
    ret[i] = game[1][i]
  end
  local prev = game[1]
  for i=2,#game do
    local curr = game[i]
    local idx = 1
    for j=1,5 do
      if prev[j] == curr[idx] then
        idx = idx + 1
      end
    end
    for j=idx,5 do
      if curr[j] > 0 then
        ret[#ret+1] = curr[j]
      end
    end
    prev = curr
  end
  return ret
end

function max_into_counter(a, b)
  for k,v in pairs(b) do
    if v > (a[k] or 0) then
      a[k] = v
    end
  end
end

function sum_into_counter(a, b)
  for k,v in pairs(b) do
    a[k] = (a[k] or 0) + v
  end
end

function vsum(a)
  local ret = 0
  for k,v in pairs(a) do
    ret = ret + v
  end
  return ret
end

function try_wiggling_it(target_n, sum, acc)
  local n_obs = vsum(sum)
  if vsum(acc) > 30 then
    for k,v in pairs(acc) do
      acc[k] = 1
    end
  end
  while(vsum(acc) < target_n) do
    local candidate, value = "000000", -1000000000
    for k,v in pairs(sum) do
      local expected_obs = acc[k] * n_obs / target_n
      local this_val = (v - expected_obs) / acc[k]
    --  print(this_val)
      if this_val > value then
        candidate, value = k,this_val
      end
    end
   -- print(value)
    acc[candidate] = acc[candidate] + 1
  end
end

require"util"
json=require"dkjson"

out_games = {}
games=json.decode(file_contents("butt"))
for k,v in pairs(games) do
  local acc = {}
  local sum = {}
  for _,game in ipairs(v) do
    local counter = arr_to_counter(game_to_cards(game))
    max_into_counter(acc, counter)
    sum_into_counter(sum, counter)
  end
  try_wiggling_it(30, sum, acc)
  if vsum(acc) > 30 then
--    print("oh no "..k.." "..vsum(acc))
  end
  out_games[k] = acc
end
print(json.encode(out_games))