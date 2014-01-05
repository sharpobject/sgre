local floor,ceil,min,max = math.floor, math.ceil, math.min, math.max
local abs = math.abs
local random = math.random

local recycle_one = function(player)
  if #player.grave > 0 then
    player:grave_to_bottom_deck(#player.grave)
  end
end

local ex2_recycle = function(player, char)
  if #player.grave >= 5 and
      #player:hand_idxs_with_preds(pred.neg(pred[char.faction])) == 0 and
      #player:field_idxs_with_preds(pred.neg(pred[char.faction])) == 0 then
    local target = uniformly(player:grave_idxs_with_preds(pred.follower))
    if target then
      player:grave_to_bottom_deck(target)
    end
  end
end

local ep7_recycle = function(player)
  if player.game.turn % 2 == 0 then
    local target = uniformly(player:grave_idxs_with_preds())
    if target then
      player:grave_to_exile(target)
    end
    target = uniformly(player:grave_idxs_with_preds(pred.follower))
    if target then
      player:grave_to_bottom_deck(target)
    end
  end
end

local sita_vilosa = function(player)
  local target_idxs = player.opponent:get_follower_idxs()
  local buff = OnePlayerBuff(player.opponent)
  for _,idx in ipairs(target_idxs) do
    if idx < 4 and player.opponent.field[idx] then
      buff[idx] = {sta={"-",1}}
    end
  end
  buff:apply()
  if player.opponent:is_npc() then
    OneBuff(player.opponent,0,{life={"-",1}}):apply()
  end
end

local cinia_pacifica = function(player)
  local target_idxs = player.opponent:get_follower_idxs()
  if #target_idxs == 0 then
    return
  end
  local target_idx = uniformly(target_idxs)
  OneBuff(player.opponent,target_idx,{atk={"-",1},sta={"-",1}}):apply()
  if player.opponent:is_npc() then
    OneBuff(player.opponent,0,{life={"-",1}}):apply()
  end
end

local luthica_preventer = function(player)
  local target_idxs = player:field_idxs_with_preds(pred[player.character.faction], pred.follower)
  if #target_idxs == 0 then
    return
  end
  local target_idx = uniformly(target_idxs)
  OneBuff(player,target_idx,{atk={"+",1},sta={"+",1}}):apply()
  if player.opponent:is_npc() then
    OneBuff(player.opponent,0,{life={"-",1}}):apply()
  end
end

local iri_flina = function(player)
  if player:field_size() > player.opponent:field_size() then
    OneBuff(player.opponent,0,{life={"-",1}}):apply()
  end
  if player.opponent:is_npc() then
    OneBuff(player.opponent,0,{life={"-",1}}):apply()
  end
end

local curious_vernika = function(player)
  local idx = player.opponent:field_idxs_with_most_and_preds(pred.def, pred.follower)[1]
  if idx then
    OneBuff(player.opponent,idx,{def={"=",0}}):apply()
  end
end

local thorn_witch_rose = function(player)
  local nme_followers = player.opponent:get_follower_idxs()
  if #nme_followers == 0 then
    return
  end
  local target_idx = uniformly(nme_followers)
  local buff_size = ceil(math.abs(player.opponent.field[target_idx].size - player.opponent.field[target_idx].def)/2)
  OneBuff(player.opponent,target_idx,{atk={"-",buff_size},sta={"-",buff_size}}):apply()
end

local head_knight_jaina = function(player)
  local target = uniformly(player:field_idxs_with_preds(pred.follower))
  if target then
    if player.game.turn % 2 == 0 then
      OneBuff(player, target, {atk={"+",2},sta={"+",1}}):apply()
    else
      OneBuff(player, target, {atk={"+",2}}):apply()
    end
  end
end

local clarice = function(stats, skill)
  return function(player)
    local to_kill = player:field_idxs_with_preds(function(card) return card.id == 300201 end)
    for _,idx in ipairs(to_kill) do
      player:field_to_grave(idx)
    end
    local slot = player:last_empty_field_slot()
    if slot then
      if stats == "turn" then
        local amt = 10 - (player.game.turn % 10)
        if amt ~= 10 then
          player.field[slot] = Card(300201)
          OneBuff(player, slot, {atk={"=",amt},def={"=",1},sta={"=",amt}}):apply()
        end
      else
        player.field[slot] = Card(300201)
        OneBuff(player, slot, {atk={"=",stats[1]},def={"=",stats[2]},sta={"=",stats[3]}}):apply()
        if skill then
          player.field[slot].skills[1] = 1075
        end
      end
    end
  end
end

local rihanna = function(top, bottom)
  return function(player)
    local target = uniformly(player:field_idxs_with_preds(pred.follower))
    local slot = uniformly(player:empty_field_slots())
    if target and slot then
      local card = player.field[target]
      player.field[target] = nil
      player.field[slot] = card
      if slot <= 3 then
        OneBuff(player, slot, top):apply()
      end
      if slot >= 3 then
        OneBuff(player, slot, bottom):apply()
      end
    end
  end
end

local council_vp_tieria = function(group_pred, faction_pred)
  return function(player)
    local target = uniformly(player:field_idxs_with_preds(group_pred, pred.follower))
    local faction_count = #player:field_idxs_with_preds(faction_pred, pred.follower)
    if target then
      if faction_count == 1 then
        OneBuff(player, target, {atk={"+",1},sta={"+",2}}):apply()
      elseif faction_count >= 2 then
        OneBuff(player, target, {size={"-",1},atk={"+",1},sta={"+",2}}):apply()
      end
    end
  end
end

local hanbok_sita = function(player, opponent, my_card)
  local target = uniformly(player:field_idxs_with_preds(pred.follower))
  local the_buff = {atk={"+",1},sta={"+",2}}
  if target then
    if #opponent:field_idxs_with_preds() > #player:field_idxs_with_preds() then
      the_buff.atk[2] = the_buff.atk[2] + 1
    end
    if #player.hand >= #opponent.hand then
      the_buff.sta[2] = the_buff.sta[2] + 1
    end
    OneBuff(player, target, the_buff):apply()
  end
end

local hanbok_cinia = function(player, opponent, my_card)
  local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
  local buff = GlobalBuff(player)
  if target then
    buff.field[opponent][target] = {def={"-",1},sta={"-",2}}
  end
  target = opponent:hand_idxs_with_preds(pred.follower)[1]
  if target then
    buff.hand[opponent][target] = {}
    if #opponent:field_idxs_with_preds() > #player:field_idxs_with_preds() then
      buff.hand[opponent][target].def = {"-",1}
    end
    if #player.hand >= #opponent.hand then
      local amt = min(2,opponent.hand[target].sta-1)
      buff.hand[opponent][target].sta={"-",amt}
    end
  end
  buff:apply()
end

local hanbok_luthica = function(player, opponent, my_card)
  local n = 1
  if #opponent:field_idxs_with_preds() > #player:field_idxs_with_preds() then
    n = n + 1
  end
  if #player.hand >= #opponent.hand then
    n = n + 1
  end
  for i=1,n do
    local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
    if target then
      OneBuff(opponent, target, {sta={"-",2}}):apply()
    end
  end
end

local hanbok_iri = function(player, opponent, my_card)
  local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
  local the_buff = {atk={"-",1},sta={"-",2}}
  if target then
    if #opponent:field_idxs_with_preds() > #player:field_idxs_with_preds() then
      the_buff.atk[2] = the_buff.atk[2] + 1
    end
    if #player.hand >= #opponent.hand then
      the_buff.sta[2] = the_buff.sta[2] + 1
    end
    OneBuff(opponent, target, the_buff):apply()
  end
end

local buff_random = function(player, opponent, my_card, my_buff)
  local target_idxs = player:field_idxs_with_preds(pred.follower)
  if #target_idxs == 0 then
    return
  end
  local target_idx = uniformly(target_idxs)
  OneBuff(player,target_idx,my_buff):apply()
end

local buff_all = function(player, opponent, my_card, my_buff)
  local buff = OnePlayerBuff(player)
  for _,idx in ipairs(player:field_idxs_with_preds(pred.follower)) do
    buff[idx] = my_buff
  end
  buff:apply()
end

local wind_forestier = function(stats)
  return function(player)
    local target_idxs = player.opponent:field_idxs_with_preds(pred.follower)
    if #target_idxs == 0 then
      return
    end
    local buff = {}
    for _,stat in ipairs(stats) do
      buff[stat] = {"-",floor(player.game.turn/2)}
    end
    OneBuff(player.opponent, uniformly(target_idxs), buff):apply()
  end
end

characters_func = {

--Mysterious Girl Sita Vilosa
[100001] = sita_vilosa,

--Beautiful and Smart Cinia Pacifica
[100002] = cinia_pacifica,

--Crux Knight Luthica
[100003] = luthica_preventer,

--Runaway Iri Flina
[100004] = iri_flina,

--Nold
[100005] = function(player)
  if #player.hand == 0 then
    return
  end
  local hand_idx = math.random(#player.hand)
  local buff = GlobalBuff(player) --stolen from Tower of Books
  buff.hand[player][hand_idx] = {size={"+",1}}
  buff:apply()
  local my_cards = player:field_idxs_with_preds(function(card) return card.size > 2 end)
  if #my_cards == 0 then
    return
  end
  local target_idx = uniformly(my_cards)
  OneBuff(player,target_idx,{size={"-",1}}):apply()
end,

--Ginger
[100006] = function(player)
  local ncards = #player:field_idxs_with_preds()
  local target_idxs = player:field_idxs_with_preds(pred.follower, function(card) return card.size >= ncards end)
  local buff = OnePlayerBuff(player)
  for _,idx in ipairs(target_idxs) do
    buff[idx] = {atk={"+",1}, sta={"+",2}}
  end
  buff:apply()
end,

--Curious Girl Vernika
[100007] = curious_vernika,

--Cannelle
[100008] = function(player)
  if player.opponent:field_size() == 0 or #player:get_follower_idxs() == 0 then
    return
  end
  local max_size = player.opponent.field[player.opponent:field_idxs_with_most_and_preds(pred.size)[1]].size
  local min_size = player.field[player:field_idxs_with_least_and_preds(pred.size)[1]].size
  local buff_size = abs(max_size - min_size)
  local target_idxs = player:field_idxs_with_least_and_preds(pred.size, pred.follower)
  local buff = OnePlayerBuff(player)
  for _,idx in ipairs(target_idxs) do
    buff[idx] = {atk={"+",buff_size}, sta={"+",buff_size}}
  end
  buff:apply()
end,

--Gart
[100009] = function(player)
  local num_follower = #player.opponent:get_follower_idxs()
  if num_follower == 0 then
    return
  end
  local num_vita = #player.opponent:field_idxs_with_preds({pred.follower, pred.V})
  local buff = OnePlayerBuff(player.opponent)
  if num_follower==num_vita then
    local target_idxs = shuffle(player.opponent:get_follower_idxs())
    for i=1,2 do
      if target_idxs[i] then
        buff[target_idxs[i]] = {sta={"-",1}}
      end
    end
  else
    local target_idx = uniformly(player.opponent:field_idxs_with_preds(pred.follower, pred.neg(pred.faction.V)))
    if target_idx then
      buff[target_idx] = {atk={"-",2},sta={"-",2}}
    end
  end
  buff:apply()
end,

--Dress Sita
[100010] = function(player)
  local nme_followers = player.opponent:get_follower_idxs()
  if #nme_followers == 0 then
    return
  end
  local buff = OnePlayerBuff(player.opponent)
  if #nme_followers > 1 then
    local target_idx = player.opponent:field_idxs_with_most_and_preds(pred.size, pred.follower)[1]
    buff[target_idx] = {atk={"-",2},def={"-",1},sta={"-",2}}
  elseif #nme_followers == 1 then
    buff[nme_followers[1]] = {sta={"-",2}}
  end
  buff:apply()
end,

--Dress Cinia
[100011] = function(player)
  local target_idxs = player.opponent:get_follower_idxs()
  if #target_idxs == 0 then
    return
  end
  local max_size
  if #player.hand == 0 then
    max_size = 0
  elseif #player.hand == 1 then
    max_size = math.ceil(player.hand[1].size/2)
  else
    max_size = math.ceil((player.hand[1].size + player.hand[2].size)/2)
  end
  local target_idx = player.opponent:field_idxs_with_preds(pred.follower, function(card) return card.size <= max_size end)[1]
  if target_idx then
    OneBuff(player.opponent,target_idx,{atk={"-",2},def={"-",2},sta={"-",2}}):apply()
  end
end,

--Dress Luthica
[100012] = function(player)
  local buff = OnePlayerBuff(player)
  local size1 = 0
  local size2 = 0
  if player.hand[1] then
    size1 = player.hand[1].size
  end
  if player.hand[2] then
    size2 = player.hand[2].size
  end
  local target_idxs = player:get_follower_idxs()
  if math.abs(size1 - size2)%2 == 1 then
    for _,idx in ipairs(target_idxs) do
      buff[idx] = {sta={"+",2}}
    end
  else
    for _,idx in ipairs(target_idxs) do
      buff[idx] = {atk={"+",2}}
    end
  end
  buff:apply()
end,

--Dress Iri
[100013] = function(player)
  if #player.hand == 0 then
    return
  end
  if (player.character.life + player.hand[1].size)%2 == 0 then
    OneBuff(player,0,{life={"+",3}}):apply()
  end
end,

--Dress Vernika
[100014] = function(player)
  local target_idxs = player:field_idxs_with_preds(pred.follower, function(card) return card.size > 1 end)
  if #target_idxs == 0 then
    return
  end
  local size1 = 0
  local size2 = 0
  if player.hand[1] then
    size1 = player.hand[1].size
  end
  if player.hand[2] then
    size2 = player.hand[2].size
  end
  local size_diff = math.abs(size1 - size2)
  OneBuff(player,uniformly(target_idxs),{size={"-",size_diff}}):apply()
end,

--Kendo Sita
[100015] = function(player)
  if #player.opponent:get_follower_idxs() == 0 then
    return
  end
  if not player.opponent.field[3] then
    local old_card_idx = uniformly(player.opponent:get_follower_idxs())
    local card = player.opponent.field[old_card_idx]
    player.opponent.field[3] = card
    player.opponent.field[old_card_idx] = nil
  end
  if pred.follower(player.opponent.field[3]) then
    OneBuff(player.opponent,3,{sta={"-",3}}):apply()
  end
end,

--Chess Cinia
[100016] = function(player)
  local target_idx = player.opponent:field_idxs_with_most_and_preds(pred.size, pred.follower)[1]
  local followers = player:get_follower_idxs()
  if not target_idx or #followers == 0 then
    return
  end
  local buff_size = 0
  if player.field[4] then
    buff_size = math.ceil((player.field[followers[1]].size + player.field[4].size)/2)
  else
    buff_size = math.ceil(player.field[followers[1]].size/2)
  end
  OneBuff(player.opponent,target_idx,{atk={"-",buff_size},sta={"-",buff_size}}):apply()
end,

--Sports Luthica
[100017] = function(player)
  if player.field[5] and pred.follower(player.field[5]) and not player.field[1] then
    local card = player.field[5]
    player.field[1] = card
    player.field[5] = nil
    OneBuff(player,1,{sta={"+",5}}):apply()
  elseif player.field[1] and pred.follower(player.field[1]) and not player.field[5] then
    local card = player.field[1]
    player.field[5] = card
    player.field[1] = nil
    OneBuff(player,5,{sta={"+",5}}):apply()
  end
end,

--Cheerleader Iri
[100018] = function(player)
  local hand_idx = uniformly(player:hand_idxs_with_preds(function(card) return card.size >= 2 end))
  if hand_idx then
    local buff = GlobalBuff(player) --stolen from Tower of Books
    buff.hand[player][hand_idx] = {size={"-",1}}
    buff:apply()
  end
end,

--Team Manager Vernika
[100019] = function(player)
  local hand_size = #player.hand
  if hand_size < 4 then
    for i=1,hand_size do
      player:hand_to_bottom_deck(1)
    end
  else
    return
  end
  local buff_size = math.ceil(hand_size/2)
  local followers = player:get_follower_idxs()
  if #followers > 0 then
    OneBuff(player,uniformly(followers),{atk={"+",buff_size},sta={"+",buff_size}}):apply()
  end
end,

--Swimwear Sita
[100020] = function(player)
  local hand_idx = player:hand_idxs_with_least_and_preds(pred.size, pred.follower)[1]
  local nme_followers = player.opponent:get_follower_idxs()
  if (not hand_idx) or #nme_followers == 0 then
    return
  end
  local def_lose = math.floor(player.hand[hand_idx].atk/2)
  OneBuff(player.opponent,uniformly(nme_followers),{def={"-",def_lose}}):apply()
end,

--Swimwear Cinia
[100021] = function(player)
  local my_followers = player:get_follower_idxs()
  local nme_followers = player.opponent:get_follower_idxs()
  if #my_followers == 0 or #nme_followers == 0 then
    return
  end
  local my_size = player.field[my_followers[1]].size
  local target_idxs = player.opponent:field_idxs_with_preds(pred.follower, function(card) return card.size < my_size end)
  local buff = OnePlayerBuff(player.opponent)
  for _,idx in ipairs(target_idxs) do
    buff[idx] = {atk={"-",1},sta={"-",2}}
  end
  buff:apply()
end,

--Swimwear Luthica
[100022] = function(player)
  local my_followers = player:get_follower_idxs()
  if #player.hand == 0 or #my_followers == 0 then
    return
  end
  if pred.C(player.hand[1]) and #player:field_idxs_with_preds(pred.neg(pred.C)) == 0 then
    OneBuff(player,uniformly(my_followers),{atk={"+",2},sta={"+",2}}):apply()
  end
end,

--Swimwear Iri
[100023] = function(player)
  if player.opponent.field[5] then
    player.opponent:field_to_bottom_deck(5)
  end
  if player.opponent:field_size() == 0 then
    return
  end
  local target_idx = uniformly(player.opponent:field_idxs_with_preds())
  local card = player.opponent.field[target_idx]
  for i=target_idx,4 do
    if not player.opponent.field[i+1] then
      player.opponent.field[i+1] = card
      player.opponent.field[target_idx] = nil
      break
    end
  end
  if player.opponent.field[5] then
    player.opponent:destroy(5)
  end
end,

--Swimwear Vernika
[100024] = function(player)
  if #player.opponent.hand < 2 or #player:get_follower_idxs() == 0 then
    return
  end
  local new_size = math.abs(player.opponent.hand[1].size - player.opponent.hand[2].size)
  local target_idx = player:field_idxs_with_most_and_preds(pred.size, pred.follower)[1]
  if target_idx then
    OneBuff(player,target_idx,{size={"=",new_size}}):apply()
  end
end,

--Lightseeker Sita
[100025] = function(player)
  local nme_followers = player.opponent:get_follower_idxs()
  local target_idxs = player:field_idxs_with_preds(pred.D, pred.follower, function(card) return card.size < 10 end)
  if #target_idxs == 0 then
    return
  end
  local target_idx = uniformly(target_idxs)
  local buff_size = floor(1.5*player.field[target_idx].size)
  player:field_to_grave(target_idx)
  if #nme_followers > 0 then
    OneBuff(player.opponent,uniformly(nme_followers),{sta={"-",buff_size}}):apply()
  end
end,

--Foreign Student Cinia
[100026] = function(player)
  local my_followers = player:get_follower_idxs()
  if #my_followers == 0 or #player.hand == 0 then
    return
  end
  local target_idx = uniformly(my_followers)
  if pred.V(player.hand[1]) then
    OneBuff(player,target_idx,{atk={"+",1},sta={"+",2}}):apply()
  elseif pred.A(player.hand[1]) then
    OneBuff(player,target_idx,{sta={"+",3}}):apply()
  elseif pred.C(player.hand[1]) then
    OneBuff(player,target_idx,{def={"+",1}}):apply()
  elseif pred.D(player.hand[1]) then
    OneBuff(player,target_idx,{size={"-",2}}):apply()
  end
end,

--Blue Reaper Luthica
[100027] = function(player)
  local target_idxs = player:field_idxs_with_preds(pred.follower, pred.C)
  if #target_idxs == 0 then
    return
  end
  local crux_cards = #player.opponent:field_idxs_with_preds(pred.C) + #player.opponent:hand_idxs_with_preds(pred.C)
  local non_crux_cards = #player.opponent:field_idxs_with_preds() + #player.opponent.hand - crux_cards
  OneBuff(player,uniformly(target_idxs),{sta={"+",math.max(crux_cards, non_crux_cards)}}):apply()
end,

--Lovestruck Iri
[100028] = function(player)
  local factions = {}
  for i=1,5 do
    if player.opponent.hand[i] and factions[1] ~= player.opponent.hand[i].faction then
      factions[#factions+1] = player.opponent.hand[i].faction
    end
    if player.opponent.field[i] and factions[1] ~= player.opponent.field[i].faction then
      factions[#factions+1] = player.opponent.field[i].faction
    end
  end
  if #factions > 1 and #player.hand > 0 then
    local hand_idx = math.random(#player.hand)
    local buff = GlobalBuff(player)
    buff.hand[player][hand_idx] = {size={"-",2}}
    buff:apply()
  end
end,

--Night Denizen Vernika
[100029] = function(player)
  local nme_followers = player.opponent:get_follower_idxs()
  if #nme_followers == 0 then
    return
  end
  local target_idx = uniformly(nme_followers)
  OneBuff(player.opponent,target_idx,{sta={"-",3}}):apply()
  OneBuff(player, 0, {life={"+",1}}):apply()
end,

--Thorn Witch Rose
[100030] = thorn_witch_rose,

-- rose pacifica
[100031] = function(player)
  local hand_idx = player:hand_idxs_with_preds(pred.D)[1]
  if hand_idx then
    local sz = player.hand[hand_idx].size
    player:hand_to_grave(hand_idx)
    local target = uniformly(player.opponent:field_idxs_with_preds(pred.follower))
    if target then
      OneBuff(player.opponent, target, {atk={"-",sz},sta={"-",sz}}):apply()
    end
  end
end,

-- blood witch rose
[100032] = function(player)
  if player.game.turn % 1 == 1 then
    local idx = uniformly(player.opponent:hand_idxs_with_preds(pred.spell))
    if idx then
      player.opponent:hand_to_exile(idx)
    end
  else
    local idx = uniformly(player.opponent:grave_idxs_with_preds(pred.spell))
    if idx then
      player.opponent:grave_to_exile(idx)
    end
  end
end,

-- outcast rose
[100033] = function(player)
  if #player:field_idxs_with_preds(pred.follower) >= 2 then
    local target = uniformly(player:field_idxs_with_preds(pred.follower, pred.D))
    local buff = OnePlayerBuff(player)
    buff[0] = {life={"-",1}}
    if target then
      buff[target] = {atk={"+",2},def={"+",1},sta={"+",2}}
    end
    buff:apply()
  end
end,

-- picnic rose
[100034] = function(player)
  local targets = shuffle(player:field_idxs_with_preds(pred.follower))
  if #targets >= 2 then
    local amt = abs(player.field[targets[1]].size - player.field[targets[2]].size)
    local buff = OnePlayerBuff(player)
    for i=1,2 do
      buff[targets[i]] = {sta={"+",amt}}
    end
    buff:apply()
  end
end,

-- wedding dress rose
[100035] = thorn_witch_rose,

-- wedding dress sita
[100036] = sita_vilosa,

-- wedding dress cinia
[100037] = cinia_pacifica,

-- wedding dress luthica
[100038] = luthica_preventer,

-- wedding dress iri
[100039] = iri_flina,

-- wedding dress vernika
[100040] = curious_vernika,

-- laevateinn
[100041] = function(player)
  local size_to_n = {}
  for i=1,#player.hand do
    local sz = player.hand[i].size
    size_to_n[sz] = (size_to_n[sz] or 0) + 1
  end
  local size = -1
  for k,v in pairs(size_to_n) do
    if v >= 2 and k > size then
      size = k
    end
  end
  if size > 0 then
    OneBuff(player, 0, {life={"+",ceil(size/2)}}):apply()
  end
end,

-- sisters sion & rion
[100042] = function(player)
  local field_idxs = player:field_idxs_with_preds(pred.follower)
  local hand_idxs = player:hand_idxs_with_preds(pred.follower)
  local target = uniformly(field_idxs)
  if target then
    OneBuff(player, target, {atk={"+",#hand_idxs},sta={"+",#field_idxs}}):apply()
  end
end,

-- head knight jaina
[100043] = head_knight_jaina,

-- resting jaina
[100044] = function(player, opponent, my_card)
  if player.game.turn % 3 == 0 then
    local targets = shuffle(player:field_idxs_with_preds(pred.follower, pred.C))
    local buff = OnePlayerBuff(player)
    for i=1,min(2,#targets) do
      buff[targets[i]] = {atk={"+",3},sta={"+",3}}
    end
    buff[0] = {life={"+",2}}
    buff:apply()
  end
end,

-- adept jaina
[100045] = function(player, opponent, my_card)
  local amt = min(4, 6-#player.hand)
  local target = uniformly(player:field_idxs_with_preds(pred.follower))
  if target then
    OneBuff(player, target, {atk={"+",amt}}):apply()
  end
end,

-- swimwear jaina
[100046] = function(player, opponent, my_card)
  local target = uniformly(player:field_idxs_with_preds(pred.follower))
  if target and player:first_empty_field_slot() then
    for i=target+1,5 do
      if not player.field[i] then
        local card = player.field[target]
        player.field[target] = nil
        player.field[i] = card
        OneBuff(player, i, {atk={"+",i}}):apply()
        return
      end
    end
    local slot = player:first_empty_field_slot()
    local card = player.field[target]
    player.field[target] = nil
    player.field[slot] = card
    OneBuff(player, slot, {atk={"+",slot}}):apply()
  end
end,

-- sword planter jaina
[100047] = function(player, opponent, my_card)
  local amt = 0
  local sizes = {}
  for i=1,#player.hand do
    if not sizes[player.hand[i].size] then
      sizes[player.hand[i].size] = true
      amt = amt + 1
    end
  end
  local targets = shuffle(player:field_idxs_with_preds(pred.follower))
  local buff = OnePlayerBuff(player)
  for i=1,min(2,#targets) do
    buff[targets[i]] = {atk={"+",amt}}
  end
  buff:apply()
end,

-- wedding dress jaina
[100048] = head_knight_jaina,

-- sigma
[100049] = function(player, opponent, my_card)
  local buff = GlobalBuff(player)
  local hand_targets = shuffle(player:hand_idxs_with_preds(pred.follower))
  local targets = shuffle(player:field_idxs_with_preds(pred.follower))
  for i=1,min(2,#hand_targets) do
    buff.hand[player][hand_targets[i]] = {atk={"+",1},sta={"+",1}}
  end
  for i=1,min(2,#targets) do
    buff.field[player][targets[i]] = {sta={"+",1}}
  end
  buff:apply()
end,

-- child sita
[100050] = function(player, opponent, my_card)
  local buff = OnePlayerBuff(opponent)
  for _,idx in ipairs({1,2,5}) do
    if opponent.field[idx] and pred.follower(opponent.field[idx]) then
      buff[idx] = {sta={"-",2}}
    end
  end
  buff:apply()
end,

-- child cinia
[100051] = function(player, opponent, my_card)
  local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if target then
    if opponent.field[target].size >= 3 then
      OneBuff(opponent, target, {atk={"-",2}}):apply()
    else
      OneBuff(opponent, target, {sta={"-",3}}):apply()
    end
  end
end,

-- child luthica
[100052] = function(player, opponent, my_card)
  local target = uniformly(player:field_idxs_with_preds(pred.follower, pred.C))
  if target then
    if player.field[target].size >= 3 then
      OneBuff(player, target, {atk={"+",2}}):apply()
    else
      OneBuff(player, target, {sta={"+",3}}):apply()
    end
  end
end,

-- child iri
[100053] = function(player, opponent, my_card)
  if #player.hand % 2 == 0 then
    local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
    if target then
      OneBuff(opponent, target, {atk={"-",1},def={"-",1},sta={"-",1}}):apply()
    end
  end
end,

-- hot springs sita
[100054] = function(player, opponent, my_card)
  local buff = OnePlayerBuff(opponent)
  for i=2,4 do
    if opponent.field[i] and pred.follower(opponent.field[i]) then
      buff[i] = {sta={"-",2}}
    end
  end
  buff:apply()
  local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if target then
    OneBuff(opponent, target, {sta={"-",1}}):apply()
  end
end,

-- hot springs cinia
[100055] = function(player, opponent, my_card)
  local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if target then
    if opponent.field[target].def <= 0 then
      OneBuff(opponent, target, {atk={"-",2},sta={"-",2}}):apply()
    else
      OneBuff(opponent, target, {def={"-",1},sta={"-",1}}):apply()
    end
  end
end,

-- hot springs luthica
[100056] = function(player, opponent, my_card)
  local target = uniformly(player:field_idxs_with_preds(pred.follower))
  if target then
    if player.field[target].def >= 1 then
      OneBuff(player, target, {atk={"+",2},sta={"+",2}}):apply()
    else
      OneBuff(player, target, {def={"+",1},sta={"+",1}}):apply()
    end
  end
end,

-- hot springs iri
[100057] = function(player, opponent, my_card)
  local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if target then
    if opponent.field[target].sta >= 10 then
      OneBuff(opponent, target, {sta={"-",4}}):apply()
    else
      OneBuff(opponent, target, {atk={"-",1},def={"-",1},sta={"-",1}}):apply()
    end
  end
end,

-- miracle panda panica
[100058] = function(player, opponent, my_card)
  if player.game.turn % 2 ==1 then
    local buff = OnePlayerBuff(player)
    local targets = shuffle(player:field_idxs_with_preds(pred.follower))
    for i=1,min(2,#targets) do
      buff[targets[i]] = {atk={"+",1}}
    end
    buff:apply()
  else
    local target = uniformly(player:field_idxs_with_preds(pred.follower))
    if target then
      OneBuff(player, target, {sta={"+",2}}):apply()
    end
  end
end,

-- child vernika
[100059] = function(player, opponent, my_card)
  if player.hand[1] then
    local amt = min(3,ceil(player.hand[1].size/2))
    player:hand_to_bottom_deck(1)
    local target = opponent:field_idxs_with_most_and_preds(pred.sta,pred.follower)[1]
    if target then
      OneBuff(opponent, target, {def={"-",amt}}):apply()
    end
  end
end,

-- child rose
[100060] = function(player, opponent, my_card)
  local hand_idx = player:hand_idxs_with_preds(pred.spell, pred.A,
      function(card) return card.size <= (9-player:field_size()) end)[1]
  local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
  local slot = player:first_empty_field_slot()
  if hand_idx and slot then
    local amt = player.hand[hand_idx].size
    player:hand_to_field(hand_idx)
    if target then
      OneBuff(opponent, target, {atk={"-",amt},sta={"-",amt}}):apply()
    end
  end
end,

-- child jaina
[100061] = function(player, opponent, my_card)
  local buff = GlobalBuff(player)
  local my_guy = uniformly(player:field_idxs_with_preds(pred.follower))
  local op_guy = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if my_guy then
    buff.field[player][my_guy] = {atk={"+",2}}
  end
  if op_guy then
    buff.field[opponent][op_guy] = {atk={"-",1}}
  end
  buff:apply()
end,

-- child ginger
[100062] = function(player, opponent, my_card)
  local target = uniformly(player:field_idxs_with_preds(pred.follower))
  if target then
    OneBuff(player, target, {atk={"+",2}}):apply()
    player:field_to_top_deck(target)
  end
  target = uniformly(player:field_idxs_with_preds(pred.follower))
  if target then
    OneBuff(player, target, {atk={"+",2}}):apply()
  end
end,

-- child laevateinn
[100063] = function(player)
  local size_to_n = {}
  for i=1,#player.hand do
    local sz = player.hand[i].size
    size_to_n[sz] = (size_to_n[sz] or 0) + 1
  end
  local size = -1
  for k,v in pairs(size_to_n) do
    if v >= 2 and k > size then
      size = k
    end
  end
  if size > 0 then
    for i=5,1,-1 do
      if player.hand[i] and player.hand[i].size == size then
        player:hand_to_bottom_deck(i)
      end
    end
    OneBuff(player, 0, {life={"+",min(4,ceil(size/2))}}):apply()
  end
end,

-- child sigma
[100064] = function(player, opponent, my_card)
  if player.hand[1] then
    local amt = min(4,floor(player.hand[1].size/2))
    player:hand_to_bottom_deck(1)
    local target = uniformly(player:field_idxs_with_preds(pred.follower))
    if target then
      OneBuff(player, target, {atk={"+",amt},sta={"+",amt}}):apply()
    end
  end
end,

-- layna scentriver
[100065] = luthica_preventer,

-- chief maid
[100066] = iri_flina,

-- new knight
[100067] = sita_vilosa,

-- nytitch
[100068] = cinia_pacifica,

-- alchemist clarice
[100069] = clarice({5,0,5}),

-- street idol clarice
[100070] = clarice("turn"),

-- assistant clarice
[100071] = clarice({1,0,9}),

-- swimwear clarice
[100072] = clarice({7,0,2}),

-- dress clarice
[100073] = clarice({3,0,3}, true),

-- wedding dress clarice
[100074] = clarice({5,0,5}),

-- lig nijes
[100075] = function(player)
  local life = player.opponent.character.life
  if 26 <= life then
    OneBuff(player.opponent, 0, {life={"-",2}}):apply()
  elseif 16 <= life and life <= 20 then
    OneBuff(player, 0, {life={"+",1}}):apply()
  elseif life <= 9 then
    OneBuff(player.opponent, 0, {life={"-",2}}):apply()
  end
end,

-- child nold
[100076] = function(player, opponent, my_card)
  if (player.game.turn + #player.hand) % 2 == 0 then
    local target = uniformly(player:field_idxs_with_preds(pred.follower,
        function(card) return card.size >= 2 end))
    if target then
      OneBuff(player, target, {size={"-",2}}):apply()
    end
  end
end,

-- child cannelle
[100077] = function(player, opponent, my_card)
  local target = uniformly(opponent:hand_idxs_with_preds(pred.follower))
  if target then
    local buff = GlobalBuff(player)
    buff.hand[opponent][target] = {size={"=",1},atk={"=",5},def={"=",0},sta={"=",7}}
    buff:apply()
  end
end,

-- child gart
[100078] = function(player, opponent, my_card)
  if #player:field_idxs_with_preds(pred.A) + #player:hand_idxs_with_preds(pred.A) == 0 then
    local target = uniformly(player:field_idxs_with_preds(pred.follower))
    if target then
      OneBuff(player, target, {atk={"+",2},sta={"+",1}}):apply()
    end
  end
end,

-- child panica
[100079] = function(player, opponent, my_card)
  local target = uniformly(player:field_idxs_with_preds(pred.follower))
  if target then
    if player.game.turn % 2 == 0 then
      OneBuff(player, target, {atk={"+",1},sta={"+",3}}):apply()
    else
      OneBuff(player, target, {sta={"+",3}}):apply()
    end
  end
end,

-- bedroom nold
[100081] = function(player, opponent, my_card)
  local target = uniformly(player:field_idxs_with_preds(pred.follower, pred.A))
  if target then
    OneBuff(player, target, {size={"-",1},sta={"+",2}}):apply()
  end
end,

-- bunny girl cannelle
[100083] = function(player, opponent, my_card)
  local target = uniformly(player:field_idxs_with_preds(pred.follower,
      function(card) return card.size <= 5 end))
  if target then
    OneBuff(player, target, {size={"+",1},atk={"+",2},def={"+",1},sta={"+",2}}):apply()
  end
end,

-- rain-soaked gart
[100084] = function(player, opponent, my_card)
  local amt = #player:hand_idxs_with_preds(pred.follower)
  local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if target then
    OneBuff(opponent, target, {def={"-",amt},sta={"-",amt}}):apply()
  end
end,

-- hammered sigma
[100087] = function(player, opponent, my_card)
  if #player.hand > 0 then
    local n = player.hand[1].size
    local targets = player:hand_idxs_with_preds(pred.follower)
    local buff = GlobalBuff(player)
    for i=1,min(n,#targets) do
      buff.hand[player][targets[i]] = {atk={"+",1},sta={"+",1}}
    end
    buff:apply()
  end
end,

-- anj inyghem
[100088] = function(player)
  local life = player.opponent.character.life
  if 31 <= life then
    OneBuff(player.opponent, 0, {life={"-",2}}):apply()
  elseif 20 <= life and life <= 25 then
    local target = uniformly(player:field_idxs_with_preds(pred.follower))
    if target then
      OneBuff(player, target, {atk={"+",1},sta={"+",2}}):apply()
    end
  elseif 10 <= life and life <= 15 then
    local target = uniformly(player.opponent:field_idxs_with_preds(pred.follower))
    if target then
      OneBuff(player.opponent, target, {atk={"-",1},sta={"-",2}}):apply()
    end
  elseif life <= 6 then
    OneBuff(player.opponent, 0, {life={"=",0}}):apply()
  end
end,

-- swimsuit sita
[100090] = function(player, opponent, my_card)
  local do_second = player.character.life < opponent.character.life
  local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if target then
    OneBuff(opponent, target, {sta={"-",3}}):apply()
  end
  if do_second then
    target = uniformly(opponent:field_idxs_with_preds(pred.follower))
    if target then
      OneBuff(opponent, target, {sta={"-",2}}):apply()
    end
  end
end,

-- swimsuit cinia
[100091] = function(player, opponent, my_card)
  local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if target then
    if player.character.life < opponent.character.life then
      OneBuff(opponent, target, {atk={"-",2},sta={"-",3}}):apply()
    else
      OneBuff(opponent, target, {atk={"-",1},sta={"-",2}}):apply()
    end
  end
end,

-- swimsuit luthica
[100092] = function(player, opponent, my_card)
  local target = uniformly(player:field_idxs_with_preds(pred.follower, pred.C))
  if target then
    if player.character.life < opponent.character.life then
      OneBuff(player, target, {atk={"+",2},sta={"+",3}}):apply()
    else
      OneBuff(player, target, {atk={"+",1},sta={"+",2}}):apply()
    end
  end
end,

-- swimsuit iri
[100093] = function(player)
  if player.character.life < player.opponent.character.life then
    OneBuff(player.opponent, 0, {life={"-",2}}):apply()
  else
    OneBuff(player, 0, {life={"+",1}}):apply()
  end
end,

-- vita principal treanna
[100095] = function(player, opponent, my_card)
  local target = uniformly(player:field_idxs_with_preds(pred.follower))
  if target then
    if pred.skill(player.field[target]) then
      player.field[target].skills = {}
      OneBuff(player, target, {size={"-",1},atk={"+",2},sta={"+",2}}):apply()
    else
      OneBuff(player, target, {atk={"+",2},sta={"+",2}}):apply()
    end
  end
end,

-- dean rihanna
[100096] = rihanna({sta={"+",3}},{atk={"+",2}}),

-- dress rihanna
[100097] = rihanna({atk={"+",1},sta={"+",2}},{atk={"+",2},sta={"+",1}}),

-- swimwear rihanna
[100098] = function(player, opponent, my_card)
  local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
  local slot = uniformly(opponent:empty_field_slots())
  if target and slot then
    local card = opponent.field[target]
    opponent.field[target] = nil
    opponent.field[slot] = card
    if slot <= 3 then
      OneBuff(opponent, slot, {atk={"-",1},sta={"-",2}}):apply()
    end
    if slot >= 3 and opponent.field[slot] then
      OneBuff(opponent, slot, {atk={"-",2},sta={"-",1}}):apply()
    end
  end
end,

-- waitress rihanna
[100099] = rihanna({sta={"+",4}},{size={"-",1},atk={"+",1}}),

-- persuasive rihanna
[100100] = function(player, opponent, my_card)
  local target = uniformly(player:field_idxs_with_preds(pred.follower))
  local slot = uniformly(player:empty_field_slots())
  if target and slot then
    local card = player.field[target]
    player.field[target] = nil
    player.field[slot] = card
  end
  target = uniformly(opponent:field_idxs_with_preds(pred.follower))
  slot = uniformly(opponent:empty_field_slots())
  if target and slot then
    local card = opponent.field[target]
    opponent.field[target] = nil
    opponent.field[slot] = card
  end
  local do_steal = false
  for i=5,1,-1 do
    if player.field[i] and opponent.field[i] then
      to_steal = true
    end
  end
  slot = player:first_empty_field_slot()
  target = uniformly(opponent:field_idxs_with_preds())
  if do_steal and slot and target then
    local card = opponent.field[target]
    opponent.field[target] = nil
    player.field[slot] = card
  end
end,

-- wedding dress rihanna
[100101] = rihanna({sta={"+",3}},{atk={"+",2}}),

-- hanbok sita
[100102] = hanbok_sita,

-- hanbok cinia
[100103] = hanbok_cinia,

-- hanbok luthica
[100104] = hanbok_luthica,

-- hanbok iri
[100105] = hanbok_iri,

-- vernika answer
[100107] = function(player, opponent, my_card)
  for i=1,5 do
    while opponent.hand[i] and pred.spell(opponent.hand[i]) do
      opponent:hand_to_bottom_deck(i)
    end
  end
end,

-- waiting sita
[100108] = function(player, _, char)
  ex2_recycle(player, char)
  local buff = {atk={"+",2},sta={"+",2}}
  if #player.deck <= #player.opponent.deck then
    buff.def = {"+",1}
    buff.sta[2]=3
  end
  local target = uniformly(player:field_idxs_with_preds(pred.follower))
  if target then
    OneBuff(player, target, buff):apply()
  end
end,

-- council president cinia
[100109] = function(player, _, char)
  ex2_recycle(player, char)
  if #player.deck <= #player.opponent.deck then
    local target = uniformly(player.opponent:field_idxs_with_preds(pred.follower))
    if target then
      OneBuff(player.opponent, target, {def={"-",1},sta={"-",2}}):apply()
    end
  end
  local target = uniformly(player:field_idxs_with_preds(pred.follower))
  if target then
    OneBuff(player, target, {atk={"+",2},sta={"+",2}}):apply()
  end
end,

-- wanderer luthica
[100110] = function(player, _, char)
  ex2_recycle(player, char)
  local target = uniformly(player:field_idxs_with_preds(pred.follower))
  if target then
    OneBuff(player, target, {atk={"+",2},sta={"+",2}}):apply()
  end
  if #player.deck <= #player.opponent.deck then
    OneBuff(player.opponent, 0, {life={"-",1}}):apply()
    target = uniformly(player:field_idxs_with_preds(pred.follower))
    if target then
      OneBuff(player, target, {sta={"+",1}}):apply()
    end
  end
end,

-- conflicted iri
[100111] = function(player, _, char)
  ex2_recycle(player, char)
  if #player.deck <= #player.opponent.deck then
    local targets = shuffle(player.opponent:field_idxs_with_preds(pred.follower))
    if targets[1] then
      OneBuff(player.opponent, targets[1], {sta={"-",3}}):apply()
    end
    if targets[2] then
      OneBuff(player.opponent, targets[2], {sta={"-",1}}):apply()
    end
  end
  local target = uniformly(player:field_idxs_with_preds(pred.follower))
  if target then
    OneBuff(player, target, {atk={"+",2},sta={"+",2}}):apply()
  end
end,

-- office chief esprit
[100112] = function(player, opponent, my_card)
  local nskills = 0
  local followers = player:field_idxs_with_preds(pred.follower)
  for _,idx in ipairs(followers) do
    nskills = nskills + #player.field[idx]:squished_skills()
  end
  if nskills <= 2 then
    local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
    if target then
      opponent.field[target].skills = {}
    end
  else
    local target = uniformly(followers)
    OneBuff(player, target, {atk={"+",nskills},sta={"+",nskills}}):apply()
  end
end,

-- council vp tieria
[100113] = council_vp_tieria(pred.student_council, pred.V),

-- maid lesnoa
[100114] = council_vp_tieria(pred.maid, pred.A),

-- seeker odien
[100115] = council_vp_tieria(pred.seeker, pred.C),

-- lightning palomporom
[100116] = council_vp_tieria(pred.witch, pred.D),

-- ereshkigal
-- [100117] = function(player, opponent, my_card)
-- end,

-- apostle l red sun

[100118] = function(player, opponent, my_card)
  --print("OMGGGGG")
  player:to_bottom_deck(Card(300193))
  if player.character.life < opponent.character.life then
    OneBuff(player, 0, {life={"+",1}}):apply()
  end
end,
--[[[100118] = function(player, opponent, my_card)
  local target = uniformly(player:field_idxs_with_preds(pred.follower))
  if target then
    if #player.deck > 0 and pred.follower(player.deck[#player.deck]) then
      OneBuff(player, target, {atk={"+",1},sta={"+",3}}):apply()
    else
      OneBuff(player, target, {atk={"+",1},sta={"+",1}}):apply()
    end
  end
end,--]]

-- crux knight rosa
[100119] = function(player, opponent, my_card)
  if #player.hand == 5 then
    player:hand_to_top_deck(1)
  end
  local amt = min(3,5-#player.hand)
  local target = player:deck_idxs_with_preds(pred.follower)[1]
  if target then
    local buff = GlobalBuff(player)
    buff.deck[player][target] = {atk={"+",amt},sta={"+",amt}}
    buff:apply()
  end
  ep7_recycle(player)
end,

-- shaman helena k sync
[100120] = function(player, opponent, my_card)
  local buff = GlobalBuff(player)
  local amt = 1
  for _,idx in ipairs(opponent:field_idxs_with_preds(pred.follower)) do
    buff.field[opponent][idx] = {atk={"-",1}}
    amt = amt + 1
  end
  for _,idx in ipairs(opponent:hand_idxs_with_preds(pred.follower)) do
    buff.hand[opponent][idx] = {atk={"-",1}}
    amt = amt + 1
  end
  amt = min(3, amt)
  local target = player:deck_idxs_with_preds(pred.follower)[1]
  if target then
    buff.deck[player][target] = {atk={"+",amt}}
  end
  buff:apply()
  ep7_recycle(player)
end,

-- detective asmis
[100121] = function(player, opponent, my_card)
  local buff = GlobalBuff(player)
  if #opponent.deck > 0 and pred.spell(opponent.deck[#opponent.deck]) then
    buff.deck[opponent][#opponent.deck] = {size={"+",1}}
  end
  if #player.deck > 0 then
    if pred.follower(player.deck[#player.deck]) then
      buff.deck[player][#player.deck] = {size={"-",1},atk={"+",1},sta={"+",1}}
    else
      buff.deck[player][#player.deck] = {size={"-",1}}
    end
  end
  ep7_recycle(player)
end,

-- witch cadet linus falco
[100122] = function(player, opponent, my_card)
  --print("OMGGGGG LINUXXXX")
  for i=1,2 do
    local buff = GlobalBuff(player)
    local target = uniformly(opponent:deck_idxs_with_preds(pred.follower))
    if target then
      buff.deck[opponent][target] = {atk={"-",1},sta={"-",1}}
    end
    buff:apply()
  end
  ep7_recycle(player)
end,

-- GS 3rd Star
[100133] = function(player, opponent, my_card)
  --print("OMGGGGG BSD")
  for i=1,2 do
    local buff = GlobalBuff(player)
    local target = uniformly(opponent:deck_idxs_with_preds(pred.follower))
    if target then
      buff.deck[opponent][target] = {atk={"-",1},sta={"-",1}}
    end
    buff:apply()
  end
  ep7_recycle(player)
end,
--[[[100133] = function(player, opponent, my_card)
  print("OMGGGGG")
  player:to_bottom_deck(Card(300193))
  if player.character.life < opponent.character.life then
    OneBuff(player, 0, {life={"+",1}}):apply()
  end
end,--]]

--At the start of the turn, Crux cards are sent from the top of your Deck to your Hand until there are four cards in your Hand. Any sent Followers get ATK +1/STA +1. If no cards are sent, a random Follower in your Field gets ATK +1/STA +1.</s
-- icy glacier
[100139] = function(player, opponent, my_card)
  local buff = GlobalBuff(player)
  local do_default = true
  for i=1,4 do
    local idx = player:deck_idxs_with_preds(pred.C)[1]
    if #player.hand < 4 and idx then
      player:deck_to_hand(idx)
      if pred.follower(player.hand[#player.hand]) then
        do_default = false
        buff.hand[player][#player.hand] = {atk={"+",1},sta={"+",1}}
      end
    end
  end
  if do_default then
    local idx = uniformly(player:field_idxs_with_preds(pred.follower))
    if idx then
      OneBuff(player, idx, {atk={"+",1},sta={"+",1}}):apply()
    end
  end
end,

-- wafuku sita
[100171] = hanbok_sita,

-- wafuku cinia
[100172] = hanbok_cinia,

-- wafuku luthica
[100173] = hanbok_luthica,

-- wafuku iri
[100174] = hanbok_iri,

-- hero sita
[100182] = hanbok_sita,

-- hero cinia
[100183] = hanbok_cinia,

-- hero luthica
[100184] = hanbok_luthica,

-- hero iri
[100185] = hanbok_iri,

-- Wind Shear
[110002] = function(player, opponent, my_card)
  buff_random(player, opponent, my_card, {sta={"+",1}})
end,

-- Winged Seeker
[110003] = function(player, opponent)
  local buff = OnePlayerBuff(opponent)
  for _,idx in ipairs(opponent:field_idxs_with_preds(pred.follower)) do
    if (opponent.field[idx].size + idx) % 2 == 0 then
      buff[idx] = {atk={"-",1},sta={"-",1}}
    end
  end
  buff:apply()
end,

-- Enchantress
[110004] = function(player, opponent, my_card)
  buff_random(player, opponent, my_card, {atk={"+",1}})
end,

-- Trickster
[110005] = function(player, opponent, my_card)
  buff_random(player, opponent, my_card, {atk={"+",1}})
end,

-- Myo Observer
[110006] = function(player, opponent, my_card)
  buff_random(player, opponent, my_card, {atk={"+",1}})
end,

-- True Bunny Lady 
[110007] = function(player, opponent, mycard)
  buff_all(player, opponent, my_card, {sta={"+",1}})
end,

-- True Wind Shear
[110008] = function(player, opponent, mycard)
  buff_all(player, opponent, my_card, {sta={"+",1}})
end,

-- Wind Breaker  
[110009] = function(player)
  local target_idxs = player.opponent:field_idxs_with_preds(pred.follower)
  if #target_idxs == 0 then
    return
  end
  OneBuff(player.opponent, uniformly(target_idxs), {sta={"-",2}}):apply()
end,

-- Wind Sneaker
[110010] = function(player)
  if #player.hand == 0 then
    return
  end
  local buff = GlobalBuff(player)
  buff.hand[player][math.random(#player.hand)] = {size={"-",1}}
  buff:apply()
end,

-- Wind Forestier  
[110011] = wind_forestier({"sta"}),

-- True Enchantress
[110012] = function(player, opponent, mycard)
  buff_all(player, opponent, my_card, {atk={"+",1}})
end,

-- True Trickster
[110013] = function(player, opponent, my_card)
  buff_random(player, opponent, my_card, {size={"-",2}})
end,

-- True Myo Observer
[110014] = function(player, opponent, mycard)
  buff_all(player, opponent, my_card, {atk={"+",1}})
end,

-- True Wind Breaker
[110015] = function(player, opponent)
  local target_idxs = shuffle(opponent:field_idxs_with_preds({pred.follower}))
  if target_idxs[1] then
    OneBuff(opponent, target_idxs[1], {sta={"-",2}}):apply()
  end
  local target_idxs2 = shuffle(opponent:field_idxs_with_preds({pred.follower}))
  if target_idxs2[1] then
    OneBuff(opponent, target_idxs2[1], {sta={"-",1}}):apply()
  end
end,

-- True Wind Sneaker
[110016] = function(player)
  if #player.hand == 1 then
    local buff = GlobalBuff(player)
    buff.hand[player][math.random(#player.hand)] = {size={"-",1}}
    buff:apply()
  elseif #player.hand > 1 then
    local buff = GlobalBuff(player)
    local idxs = {}
    for i=1,#player.hand do
      idxs[i] = i
    end
    local target_idxs = shuffle(idxs)
    buff.hand[player][target_idxs[1]] = {size={"-",1}}
    buff.hand[player][target_idxs[2]] = {size={"-",1}}
    buff:apply()
  end
end,

-- True Wind Forestier
[110017] = wind_forestier({"atk", "sta"}),

-- Doppelganger Sita
[110018] = function(player)
  local target_idxs = player.opponent:get_follower_idxs()
  local buff = OnePlayerBuff(player.opponent)
  for _,idx in ipairs(target_idxs) do
    if idx < 4 and player.opponent.field[idx] then
      buff[idx] = {sta={"-",1}}
    end
  end
  buff:apply()
end,

-- Doppelganger Cinia
[110019] = function(player)
  local target_idxs = player.opponent:get_follower_idxs()
  if #target_idxs == 0 then
    return
  end
  local target_idx = uniformly(target_idxs)
  OneBuff(player.opponent,target_idx,{atk={"-",1},sta={"-",1}}):apply()
end,

-- Doppelganger Luthica
[110020] = function(player)
  local target_idxs = player:field_idxs_with_preds(pred[player.character.faction], pred.follower)
  if #target_idxs == 0 then
    return
  end
  local target_idx = uniformly(target_idxs)
  OneBuff(player,target_idx,{atk={"+",1},sta={"+",1}}):apply()
end,

-- Doppelganger Iri
[110021] = function(player)
  if player:field_size() > player.opponent:field_size() then
    OneBuff(player.opponent,0,{life={"-",1}}):apply()
  end
end,

--Wind Gambler
[110022] = function(player)
  if player.character.life % 2 == 1 then
    OneBuff(player, 0, {life={"-",1}}):apply()
  else
    OneBuff(player, 0, {life={"+",2}}):apply()
  end
end,

--Wind Girl
[110023] = function(player)
  OneBuff(player, 0, {life={"+",1}}):apply()
end,

-- rio
[110133] = function(player, opponent, mycard)
  buff_all(player, opponent, my_card, {atk={"+",3},sta={"+",3}})
  recycle_one(player)
end,

-- nanai
[110134] = function(player)
  local amt, opponent = 0, player.opponent
  for i=1,5 do
    while opponent.hand[i] and pred.spell(opponent.hand[i]) do
      opponent:hand_to_grave(i)
      amt = amt + 2
    end
  end
  local buff = OnePlayerBuff(opponent)
  for _,idx in ipairs(opponent:field_idxs_with_preds(pred.follower)) do
    buff[idx] = {atk={"-",amt},sta={"-",amt}}
  end
  buff:apply()
  recycle_one(player)
end,

-- seven
[110135] = function(player)
  local buff = OnePlayerBuff(player.opponent)
  for _,idx in ipairs(player.opponent:field_idxs_with_preds(pred.follower)) do
    local card = player.opponent.field[idx]
    buff[idx] = {atk={"+",card.sta-1},sta={"=",1}}
  end
  buff:apply()
  recycle_one(player)
end,

-- new knight
[110136] = function(player)
  local buff = GlobalBuff(player)
  for _,idx in ipairs(player.opponent:field_idxs_with_preds(pred.follower)) do
    buff.field[player.opponent][idx] = {def={"-",2}}
  end
  for _,idx in ipairs(player:field_idxs_with_preds(pred.follower)) do
    buff.field[player][idx] = {def={"+",2}}
  end
  for _,idx in ipairs(player:hand_idxs_with_preds(pred.follower)) do
    buff.hand[player][idx] = {def={"+",2}}
  end
  buff:apply()
  recycle_one(player)
end,

-- origin disciple
[110137] = function(player)
  OneBuff(player, 0, {life={"+",8}}):apply()
end,

-- sion flina
[110138] = function(player)
  if #player.opponent:field_idxs_with_preds(pred.rion) > 0 then
    OneBuff(player, 0, {life={"-",7}}):apply()
  end
  recycle_one(player)
end,

-- rion flina
[110139] = function(player)
  local targets = player.opponent:field_idxs_with_preds(pred.follower, pred.neg(pred.shion))
  local buff = OnePlayerBuff(player.opponent)
  for _,idx in ipairs(targets) do
    buff[idx] = {atk={"-",2},def={"-",2},sta={"-",2}}
  end
  buff:apply()
  if #player.opponent:field_idxs_with_preds(pred.shion) > 0 then
    OneBuff(player, 0, {life={"-",7}}):apply()
  end
  recycle_one(player)
  recycle_one(player)
end,

-- frett
[110140] = function(player)
  local idxs = player.opponent:field_idxs_with_preds(function(card) return card.size ~= 3 end)
  for _,idx in ipairs(idxs) do
    player.opponent:destroy(idx)
  end
  recycle_one(player)
end,

-- odien
[110141] = function(player)
  local idxs = player.opponent:field_idxs_with_preds(pred.follower, pred.skill)
  for _,idx in ipairs(idxs) do
    player.opponent:destroy(idx)
  end
  recycle_one(player)
end,

-- lyrica
[110142] = function(player)
  local idxs = player.opponent:field_idxs_with_preds(pred.follower, pred.neg(pred.skill))
  for _,idx in ipairs(idxs) do
    player.opponent:destroy(idx)
  end
  recycle_one(player)
end,

-- sarah
[110149] = function(player, opponent, my_card)
  local targets = {}
  for i=1,5 do
    if opponent.field[i] and pred.follower(opponent.field[i]) and
        ((opponent.field[i-1] and pred.follower(opponent.field[i-1])) or
          (opponent.field[i+1] and pred.follower(opponent.field[i+1])) or
          opponent.field[i].sta == 1) then
      targets[#targets+1] = i
    end
  end
  for _,idx in ipairs(targets) do
    opponent:destroy(idx)
  end
  recycle_one(player)
end,

-- gart
[110150] = function(player, opponent, my_card)
  if player.game.turn == 14 then
    OneBuff(opponent, 0, {life={"=",0}}):apply()
  end
  recycle_one(player)
end,

-- knight messenger
[110151] = function(player, opponent, my_card)
  while #player.grave > 0 do
    recycle_one(player)
  end
end,

-- gs 1st star
[110152] = function(player, opponent, my_card)
  local targets = opponent:field_idxs_with_preds(pred.follower)
  local buff = OnePlayerBuff(opponent)
  for _,idx in ipairs(targets) do
    buff[idx] = {sta={"-",1}}
  end
  buff:apply()
  targets = opponent:field_idxs_with_preds(pred.follower, pred.skill)
  for _,idx in ipairs(targets) do
    opponent.field[idx].skills = {1237}
  end
  recycle_one(player)
end,

-- kana dtd
[110153] = function(player, opponent, my_card)
  OneBuff(player, 0, {life={"+",4}}):apply()
  while #player.grave > 0 do
    recycle_one(player)
  end
  while #player.hand > 0 do
    player:hand_to_top_deck(#player.hand)
  end
end,

-- lotte
[110154] = function(player, opponent, my_card)
  if player.game.turn > 1 then
    if #player:field_idxs_with_preds() == 0 then
      OneBuff(opponent, 0, {life={"-",10}}):apply()
    end
  end
end,

-- conundrum
[110155] = function(player, opponent, my_card)
  if player.character.life <= 7 then
    OneBuff(opponent, 0, {life={"=",0}}):apply()
  end
end,

-- knight vanguard
[110156] = function(player, opponent, my_card)
  if player.game.turn > 1 then
    local amt = 5-#opponent.hand
    OneBuff(opponent, 0, {life={"-",3*amt}}):apply()
  end
end,

-- serie
[110157] = function(player, opponent, my_card)
  local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if target then
    opponent.field[target].active = false
  end
  local buff = OnePlayerBuff(player)
  local targets = player:field_idxs_with_preds(pred.follower)
  for _,idx in ipairs(targets) do
    local amt = 2*abs(player.field[idx].def)
    buff[idx] = {atk={"+",amt},def={"+",amt},sta={"+",amt}}
  end
  buff:apply()
  recycle_one(player)
end,

-- envy lady
[110158] = function(player, opponent, my_card)
  local buff = GlobalBuff(player)
  local targets = opponent:field_idxs_with_preds(pred.follower)
  for _,idx in ipairs(targets) do
    local card = opponent.field[idx]
    buff.field[opponent][idx] = {}
    for _,stat in ipairs({"atk","def","sta"}) do
      if card[stat] > id_to_canonical_card[card.id][stat] then
        buff.field[opponent][idx][stat] = {"=",id_to_canonical_card[card.id][stat]}
      end
    end
  end
  targets = player:field_idxs_with_preds(pred.follower)
  for _,idx in ipairs(targets) do
    local card = player.field[idx]
    buff.field[player][idx] = {}
    for _,stat in ipairs({"atk","def","sta"}) do
      if card[stat] < id_to_canonical_card[card.id][stat] then
        buff.field[player][idx][stat] = {"=",id_to_canonical_card[card.id][stat]}
      end
    end
  end
  buff:apply()
  recycle_one(player)
end,

-- sleeping club president
[110159] = function(player, opponent, my_card)
  if #player.hand > 0 and #opponent.hand > 0 then
    player.hand[1], opponent.hand[1] = opponent.hand[1], player.hand[1]
  end
end,

-- fourteen
[110160] = function(player, opponent, my_card)
  for i=1,3 do
    if #opponent.deck > 0 then
      opponent:deck_to_grave(#opponent.deck)
    end
  end
  recycle_one(player)
end,

-- maid luna
[110161] = function(player, opponent, my_card)
  local my_idx = uniformly(player:field_idxs_with_preds(pred.follower))
  local op_idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
  local buff = GlobalBuff(player)
  if my_idx then
    local amt = #player.grave
    buff.field[player][my_idx] = {atk={"+",amt},sta={"+",amt}}
  end
  if op_idx then
    local amt = #opponent.grave
    buff.field[opponent][op_idx] = {atk={"-",amt},sta={"-",amt}}
  end
  buff:apply()
end,

-- youngest knight
[110162] = function(player, opponent, my_card)
  local targets = opponent:field_idxs_with_preds(
      function(card) return card.size <= 5 end)
  for _,idx in ipairs(targets) do
    opponent:field_to_grave(idx)
  end
end,

-- chirushi
[110163] = function(player, opponent, my_card)
  local func = function(card) return card.id == 200035 end
  for i=1,3 do
    if player:first_empty_field_slot() then
      local hand_idx = player:hand_idxs_with_preds(func)[1]
      if hand_idx then
        player:hand_to_field(hand_idx)
      else
        local deck_idx = player:deck_idxs_with_preds(func)[1]
        if deck_idx then
          player:deck_to_field(deck_idx)
        end
      end
    end
  end
end,

-- ragafelt
[110164] = function(player, opponent, my_card)
  local buff = GlobalBuff(player)
  local targets = opponent:deck_idxs_with_preds(pred.follower)
  for _,idx in ipairs(targets) do
    buff.deck[opponent][idx] = {atk={"-",2},def={"-",2},sta={"-",2}}
  end
  buff:apply()
  local to_top = {}
  for i=1,5 do
    local idx = uniformly(opponent:deck_idxs_with_preds(pred.follower))
    if idx then
      to_top[i] = table.remove(opponent.deck, idx)
    end
  end
  for i=1,#to_top do
    opponent.deck[#opponent.deck + 1] = to_top[i]
  end
end,

-- winfield
[110165] = function(player, opponent, my_card)
  local op_cards = opponent:field_idxs_with_preds()
  for _,idx in ipairs(op_cards) do
    opponent.field[idx].active = false
  end
  local buff = OnePlayerBuff(player)
  local targets = player:field_idxs_with_preds(pred.follower)
  for _,idx in ipairs(targets) do
    local amt = 5*player.field[idx].def
    buff[idx] = {atk={"+",amt},sta={"+",amt}}
  end
  buff:apply()
  for i=1,3 do
    local target = opponent:hand_idxs_with_preds(pred.spell)[i]
    if target then
      opponent:hand_to_grave(target)
    end
  end
end,

-- kris flina
[110166] = function(player, opponent, my_card)
  local my_slot = player:first_empty_field_slot()
  local op_slot = opponent:first_empty_field_slot()
  local buff = GlobalBuff(player)
  if my_slot then
    player.field[my_slot] = Card(300055)
    buff.field[player][my_slot] = {atk={"=",13},def={"=",2},sta={"=",13}}
  end
  if op_slot then
    opponent.field[op_slot] = Card(300055)
    buff.field[opponent][op_slot] = {size={"=",9},atk={"=",4},def={"=",2},sta={"=",4}}
    opponent.field[op_slot]:gain_skill(1272)
  end
  buff:apply()
end,

-- amethystar
[110173] = function(player, opponent, my_card)
  local which = random(1,5)
  if which == 1 then
    local targets = opponent:field_idxs_with_preds(pred.follower)
    local buff = OnePlayerBuff(opponent)
    for _,idx in ipairs(targets) do
      buff[idx] = {atk={"-",3},sta={"-",3}}
    end
    buff:apply()
  elseif which == 2 then
    local targets = player:field_idxs_with_preds(pred.follower)
    local buff = OnePlayerBuff(player)
    for _,idx in ipairs(targets) do
      buff[idx] = {atk={"+",3},sta={"+",3}}
    end
    buff:apply()
  elseif which == 3 then
    OneBuff(opponent, 0, {life={"-",2}}):apply()
  elseif which == 4 then
    OneBuff(player, 0, {life={"+",2}}):apply()
  else
    while #player.grave > 0 do
      recycle_one(player)
    end
  end
end,

-- zislana
[110174] = function(player, opponent, my_card)
  while #player.grave > 0 do
    recycle_one(player)
  end
end,

-- magician
[110175] = function(player, opponent, my_card)
  if opponent.field[player.game.turn] then
    OneBuff(opponent, 0, {life={"-",8}}):apply()
  end
  if player.game.turn == 5 then
    player.game.turn = 1
  end
  while #player.grave > 0 do
    recycle_one(player)
  end
end,

-- jaina preventer
[110176] = function(player, opponent, my_card)
  local func = function(card)
    base = Card(card.id)
    return card.atk > base.atk or card.def > base.def or card.sta > base.sta
  end
  local targets = opponent:field_idxs_with_preds(pred.follower, func)
  for _,idx in ipairs(targets) do
    opponent:destroy(idx)
  end
  while #player.grave > 0 do
    recycle_one(player)
  end
end,

-- disciple johana
[110177] = function(player, opponent, my_card)
  local amt = #opponent.hand
  while #opponent.hand > 0 do
    opponent:hand_to_grave(1)
  end
  local buff = GlobalBuff(player)
  buff.field[player][0] = {life={"+",amt}}
  buff.field[opponent][0] = {life={"-",amt}}
  buff:apply()
  while #player.grave > 0 do
    recycle_one(player)
  end
end,

-- disciple josefina
[110178] = function(player, opponent, my_card)
  local my_guys = player:field_idxs_with_preds(pred.follower)
  local op_guys = opponent:field_idxs_with_preds(pred.follower)
  if #op_guys > #my_guys then
    for _,idx in ipairs(op_guys) do
      local slot = player:first_empty_field_slot()
      if slot then
        player.field[slot] = opponent.field[idx]
        opponent.field[idx] = nil
        player.field[slot].size = 1
      end
    end
  end
  if player:field_size() >= 2 then
    local to_send = player:field_idxs_with_preds(pred.follower,
        function(card) return card.size > 1 end)
    for _,idx in ipairs(to_send) do
      local slot = opponent:first_empty_field_slot()
      if slot then
        opponent.field[slot] = player.field[idx]
        player.field[idx] = nil
        opponent.field[slot].size = 5
      end
    end
  end
  while #player.grave > 0 do
    recycle_one(player)
  end
end,

-- fool
[110179] = function(player, opponent, my_card)
  local to_steal = uniformly(opponent:field_idxs_with_preds(pred.neg(pred.knight)))
  if to_steal and player:first_empty_field_slot() then
    local card = opponent.field[to_steal]
    card.size = 1
    opponent.field[to_steal] = nil
    player.field[player:first_empty_field_slot()] = card
  end
  local to_grave = opponent:field_idxs_with_preds(pred.neg(pred.knight))
  for _,idx in ipairs(to_grave) do
    opponent:field_to_grave(idx)
  end
  while #player.grave > 0 do
    recycle_one(player)
  end
end,

-- chenin blanc
[110180] = function(player, opponent, my_card)
  OneBuff(opponent, 0, {life={"=",10}}):apply()
  for _,p in ipairs({player, opponent}) do
    for i=1,5 do
      p.field[i] = Card(200035)
    end
  end
end,

-- famed disciple
[110182] = function(player, opponent, my_card)
  local even = opponent:field_idxs_with_preds(
      function(card) return card.size % 2 == 0 end)
  for _,idx in ipairs(even) do
    opponent:destroy(idx)
  end
  local targets = opponent:field_idxs_with_preds()
  for _,idx in ipairs(targets) do
    opponent.field[idx].size = 4
  end
  for i=1,#opponent.hand do
    opponent.hand[i].size = 4
  end
end,

-- disciple shuru
[110183] = function(player, opponent, my_card)
  if player.game.turn == 1 then
    local decks = {V="http://swogitools.com/index.php?deck=100001D2P300007C3P300005C2P300006C3P300004C2P300008C3P300003C3P300002C3P300001C2P200003C2P200002C2P200005C1P200001C2P200004C&compression=false",
        A="http://swogitools.com/index.php?deck=100002D2P300025C3P300023C2P300024C3P300022C2P300026C3P300021C3P300020C3P300019C2P200012C2P200011C2P200015C1P200014C2P200013C&compression=false",
        C="http://swogitools.com/index.php?deck=100003D2P300043C3P300041C2P300042C3P300040C2P300044C3P300039C3P300038C3P300037C2P200022C1P200021C2P200025C2P200023C2P200024C&compression=false",
        D="http://swogitools.com/index.php?deck=100004D3P300061C3P300059C2P300060C2P300058C3P300062C2P300057C3P300056C3P300055C1P200035C2P200033C2P200032C2P200034C2P200031C&compression=false"}
    local deck_str = decks[opponent.character.faction]
    if deck_str then
      local deck = str_to_deck(deck_str)
      table.remove(deck, 1)
      deck = map(Card, deck)
      opponent.deck = shuffle(deck)
    else
      opponent.deck = {}
    end
  end
end,

-- Gold Lion Nold
[120001] = function(player, opponent, my_card)
  buff_all(player, opponent, my_card, {size={"-",1}})
end,

-- Breeze Queen Cannelle
[120002] = function(player)
  local target_idxs = player:field_idxs_with_preds(pred.follower, function(card) return card.size <= 3 end)
  local buff = OnePlayerBuff(player)
  for _,idx in ipairs(target_idxs) do
    buff[idx] = {atk={"+",2},sta={"+",2}}
  end
  buff:apply()
end,

-- Star Bird Gart
[120003] = function(player, opponent)
  local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if target then
    opponent.field[target].active = false
  end
end,

-- true vampire god
[120010] = function(player, opponent)
  if opponent.character.life >= 15 then
    OneBuff(opponent, 0, {life={"-",1}}):apply()
  elseif opponent.character.life <= 8 then
    OneBuff(opponent, 0, {life={"=",0}}):apply()
  end
  recycle_one(player)
end,

-- ereshkigal
[120015] = function(player, opponent, my_card)
  --[[if player.character.life <= 7 or opponent.character.life <= 7 or
      player.game.turn == 14 then
    OneBuff(opponent, 0, {life={"=",0}}):apply()
    return
  end--]]

  if player.game.turn ~= 1 then
    local amt = 2*(5-#opponent.hand)
    OneBuff(opponent, 0, {life={"-",amt}}):apply()
  end

  local func = function(card)
    base = Card(card.id)
    return card.atk > base.atk or card.def > base.def or card.sta > base.sta
  end
  local targets = opponent:field_idxs_with_preds(pred.follower, func)
  for _,idx in ipairs(targets) do
    opponent:field_to_bottom_deck(idx)
  end
end,
}
setmetatable(characters_func, {__index = function()return function() end end})
