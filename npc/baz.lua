ep_order = {"EP0", "EP1", "EP2", "EP3", "EX1", "EP4", "EP5",
    "EP6", "EX2", "EP7", "EP8", "EP9", "UE1", "EX3", "EP10",
    "EP11", "EP12", "UE2", "EP13", "EP14", "EP15", }
eps_up_to_ep = {}
for i=1,#ep_order do
  eps_up_to_ep[ep_order[i]] = {}
  for j=1,i do
    eps_up_to_ep[ep_order[i]][ep_order[j]] = true
  end
end

-- NPCs from each ep will be limited to cards of ep <= this ep
ep_cap = {
  EP0="EP1",
  EP1="EP1",
  EP2="EP2",
  EP3="EP3",
  EX1="EX1",
  EP4="EP4",
  EP5="EP5",
  EP6="EP6",
  EX2="EX2",
  EP7="EP7",
  EP8="EP8",
  EP9="EP9",
  UE1="UE1",
  EX3="EX3",
  EP10="EP10",
  EP11="EP11",
  EP12="EP12",
  UE2="UE2",
  EP13="EP13",
  EP14="EP14",
  EP15="EP15",
}
-- Some NPCs can have more than 3 of a card. Most cannot....
can_exceed_3 = {
["120006"]=true,
["120007"]=true,
["120022"]=true,
["110034"]=true,
["110035"]=true,
}

custom_ep_cap = {
["120006"]="EP5",
["110034"]="EP5",
["110035"]="EP5",
["110036"]="EP5",
["110037"]="EP5",
["110038"]="EP5",
["110039"]="EP5",
["110040"]="EP5",
["110041"]="EP5",
["110042"]="EP5",
}


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
      if curr[j] and curr[j] > 0 and
          -- Don't include 2nd loop of eternal witness
          curr[j] ~= 200880 then
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

function try_wiggling_it(char_id, target_n, sum, acc)
  if not can_exceed_3[char_id] then
    for k,v in pairs(acc) do
      if v > 3 then
        acc[k] = 3
      end
    end
  end
  local npc_ep = custom_ep_cap[char_id] or id_to_card[char_id].episode
  for k,v in pairs(acc) do
    local card_ep = id_to_card[tostring(k)].episode
    if not eps_up_to_ep[ep_cap[npc_ep]][card_ep] then
      acc[k] = nil
      sum[k] = nil
    end
  end
  local n_obs = vsum(sum)
  if vsum(acc) > target_n then
    for k,v in pairs(acc) do
      acc[k] = 0
    end
  end
  while(vsum(acc) < target_n) do
    local candidate, value = "000000", -1000000000
    for k,v in pairs(sum) do
      if acc[k] < math.max(3,id_to_card[tostring(k)].limit)
          or can_exceed_3[char_id] then
        local expected_obs = acc[k] * n_obs / target_n
        local this_val = (v - expected_obs) / (acc[k]+1)
        --print(this_val)
        if this_val > value then
          candidate, value = k,this_val
        end
      end
    end
    --print(value)
    acc[candidate] = acc[candidate] + 1
  end
end

require"util"
json=require"dkjson"

out_games = {}
games=json.decode(file_contents("butt"))
id_to_card=json.decode(file_contents("../swogi.json")).id_to_card
for k,v in pairs(games) do
  local acc = {}
  local sum = {}
  for _,game in ipairs(v) do
    local counter = arr_to_counter(game_to_cards(game))
    max_into_counter(acc, counter)
    sum_into_counter(sum, counter)
  end
  try_wiggling_it(k, 30, sum, acc)
  if vsum(acc) > 30 then
--    print("oh no "..k.." "..vsum(acc))
  end
  out_games[k] = acc
end
print(json.encode(out_games))