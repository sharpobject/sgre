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

characters_func = {

--Mysterious Girl Sita Vilosa
[100001] = function(player)
   local target_idxs = player.opponent:get_follower_idxs()
   local buff = OnePlayerBuff(player.opponent)
   for _,idx in ipairs(target_idxs) do
      if idx < 4 then
	 buff[idx] = {sta={"-",1}}
      end
   end
   buff:apply()
end,

--Beautiful and Smart Cinia Pacifica
[100002] = function(player)
   local target_idxs = player.opponent:get_follower_idxs()
   local target_idx = uniformly(target_idxs)
   if target_idx then
     OneBuff(player.opponent,target_idx,{atk={"-",1},sta={"-",1}}):apply()
   end
end,

--Crux Knight Luthica
[100003] = function(player)
   local target_idxs = player:field_idxs_with_preds(pred.C, pred.follower)
   local target_idx = uniformly(target_idxs)
   if target_idx then
     OneBuff(player,target_idx,{atk={"+",1},sta={"+",1}}):apply()
   end
end,

--Runaway Iri Flina
[100004] = function(player)
   if player:field_size() > player.opponent:field_size() then
      OneBuff(player.opponent,0,{life={"-",1}}):apply()
   end
end,

--Nold
[100005] = function(player)
   if #player.hand == 0 then
      return
   end
   local hand_idx = math.random(#player.hand)
   local buff = GlobalBuff() --stolen from Tower of Books
   buff.hand[player][hand_idx] = {size={"+",1}}
   buff:apply()
   --there's gotta be a better way to do this.  oh well.
   local pre_target_idxs = player:field_idxs_with_preds(pred.size)
   local target_idxs = {}
   for _,i in ipairs(pre_target_idxs) do
      if player.field[i].size > 1 then
	 target_idxs[#target_idxs + 1] = i
      end
   end
   local target_idx = uniformly(target_idxs)
   if target_idx then
     OneBuff(player,target_idx,{size={"-",1}}):apply()
   end

   --fix this to use 18:33 sharpobject: local idx = uniformly(player.field_idxs_with_preds(function(card) return card.size >= 2 end))
   -- 18:33 sharpobject: then idx will be nil if there weren't any cards like that

end,

--Ginger
[100006] = function(player)
   local target_idxs = player:field_idxs_with_preds(function(card) return card.size >= player:field_size() end)
   local buff = OnePlayerBuff(player)
   for _,idx in ipairs(target_idxs) do
      buff[idx] = {atk={"+",1}, sta={"+",2}}
   end
   buff:apply()
end,

--Curious Girl Vernika
[100007] = function(player)
   local idx = player.opponent:field_idxs_with_most_and_preds(pred.def, pred.follower)[1]
   OneBuff(player.opponent,idx,{def={"=",0}}):apply()
end,

--Cannelle
[100008] = function(player)
   if player.opponent:field_size() == 0 or #player:get_follower_idxs() == 0 then
      return
   end
   local max_size = player.opponent.field[player.opponent:field_idxs_with_most_and_preds(pred.size)[1]].size
   local min_size = player.field[player:field_idxs_with_least_and_preds(pred.size)[1]].size
   local buff_size = max_size - min_size
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
   local nme_field_size = #player.opponent:field_size()
   if #nme_followers == 0 then
      return
   end
   local buff = OnePlayerBuff(player.opponent)
   if nme_field_size > 1 then
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
      max_size = player.hand[1].size
   else
      max_size = math.ceil((player.hand[1].size + player.hand[2].size)/2)
   end
   local target_idx = player:field_idxs_with_preds(function(card) return card.size <= max_size end)[1]
   if target_idx then
      OneBuff(player.opponent,target_idx,{atk={"-",2},def={"-",2},sta={"-",2}}):apply()
   end
end,

--Dress Luthica
[100012] = function(player)
   local target_idxs = player:get_follower_idxs()
   if #player.hand < 2 or #target_idxs == 0 then
      return
   end
   local buff = OnePlayerBuff(player)
   if math.abs(player.hand[1].size - player.hand[2].size)%2 == 1 then
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
   local followers = player:get_follower_idxs()
   local target_idxs = player:field_idxs_with_preds(function(card) return card.size > 1 end)
   if #target_idxs == 0 or #player.hand < 2 then
      return
   end
   local size_diff = math.abs(player.hand[1].size - player.hand[2].size)
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
   OneBuff(player.opponent,3,{sta={"-",3}}):apply()
end,

--Chess Cinia
[100016] = function(player)
   if #player:get_follower_idxs() == 0 or #player.opponent:get_follower_idxs() == 0 then
      return
   end
   local target_idx = player.opponent:field_idxs_with_most_and_preds(pred.size, pred.follower)[1]
   local followers = player:get_follower_idxs()
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
   if player.field[5] and not player.field[1] then
      local card = player.field[5]
      player.field[1] = card
      player.field[5] = nil
      OneBuff(player,1,{sta={"+",5}}):apply()
   elseif player.field[1] and not player.field[5] then
      local card = player.field[1]
      player.field[5] = card
      player.field[1] = nil
      OneBuff(player,5,{sta={"+",5}}):apply()
   end
end,

--Cheerleader Iri
[100018] = function(player)
   local target_idxs = {}
   for i=1,5 do
      if player.hand[i] then
         if player.hand[i].size > 1 then
            target_idxs[#target_idxs+1] = i
         end
      end
   end
   if #target_idxs > 0 then
     OneBuff(player,uniformly(target_idxs),{size={"-",1}}):apply()
   end
end,

--Team Manager Vernika
[100019] = function(player)
   local hand_size = #player.hand
   if hand_size < 4 then
      for i=1,hand_size do
	 player.hand_to_bottom_deck(1)
      end
      local buff_size = math.ceil(hand_size/2)
      local target_idx = uniformly(player.field:get_follower_idxs())
      if target_idx then
        OneBuff(player,target_idx,{atk={"+",buff_size},sta={"+",buff_size}}):apply()
      end
   end
end,

--Swimwear Sita
[100020] = function(player)
   local hand_followers = player:hand_idxs_with_preds(pred.follower)
   if #hand_followers == 0 then
      return
   end
   local best = 99999
   local hand_idx
   for _,i in ipairs(hand_followers) do
      if player.hand[i].size < best then
	 best = player.hand[i].size
	 hand_idx = i
      end
   end
   local def_lose = math.floor(player.hand[hand_idx].atk/2)
   local target_idx = uniformly(player.opponent:get_follower_idxs())
   if target_idx then
     OneBuff(player.opponent,target_idx,{def={"-",def_lose}}):apply()
   end
end,

--Swimwear Cinia
[100021] = function(player)
   local my_followers = player:get_follower_idxs()
   local nme_followers = player.opponent:get_follower_idxs()
   if #my_followers == 0 or #nme_followers == 0 then
      return
   end
   local my_size = player.field[my_followers[1]].size
   local target_idxs = {}
   for _,i in ipairs(nme_followers) do
      if player.opponent.field[i].size < my_size then
	 target_idxs[#target_idxs+1] = i
      end
   end
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
   if player.hand[1].faction == "C" and #my_followers == #player:field_idxs_with_preds({pred.follower, pred.C}) then
      OneBuff(player,uniformly(my_followers),{atk={"+",2},sta={"+",2}}):apply()
   end
end,

--Swimwear Iri
[100023] = function(player)
   if player.opponent.field[5] then
      player.opponent:field_to_bottom_deck(5)
   end
   local target_idx = uniformly(player.opponent:get_follower_idxs())
   local card = player.opponent.field[target_idx]
   for i=target_idx,4 do
      if not player.opponent.field[i+1] then
	 player.opponent.field[i+1] = card
	 player.opponent.field[target_idx] = nil
	 break
      end
   end
   if player.opponent.field[5] then
      player.opponent:field_to_grave(5)
   end
end,

--Swimwear Vernika
[100024] = function(player)
   if #player.opponent.hand < 2 then
      return
   end
   local new_size = math.abs(player.opponent.hand[1].size - player.opponent.hand[2].size)
   local target_idx = player:field_idx_with_most_and_preds(pred.size, {pred.follower})[1]
   if target_idx then
     OneBuff(player,target_idx,{size={"=",new_size}}):apply()
   end
end,

--Lightseeker Sita
[100025] = function(player)
   local my_followers = player:get_follower_idxs()
   local nme_followers = player.opponent:get_follower_idxs()
   if #my_followers == 0 or #nme_followers == 0 then
      return
   end
   local target_idxs = {}
   for _,i in ipairs(my_followers) do
      if player.field[i].size < 10 and player.field[i].faction == "D" then
	 target_idxs[#target_idxs+1] = i
      end
   end
   if #target_idxs == 0 then
      return
   end
   local target_idx = uniformly(target_idxs)
   local buff_size = floor(1.5*player.field[target_idx].size)
   player:field_to_grave(target_idx)
   OneBuff(player.opponent,uniformly(nme_followers),{sta={"-",buff_size}}):apply()
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
  if k > 0 then
    for i=1,5 do
      while player.hand[i].size == k do
        player:hand_to_bottom_deck(i)
      end
    end
    OneBuff(player, 0, {life={"+",min(4,ceil(k/2))}}):apply()
  end
end,

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

-- swimsuit iri
[100093] = function(player)
  if player.character.life < player.opponent.character.life then
    OneBuff(player.opponent, 0, {life={"-",2}}):apply()
  else
    OneBuff(player, 0, {life={"+",1}}):apply()
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
  local buff = {atk={"+",2},sta={"+",2}}
  if #player.deck <= #player.opponent.deck then
    buff.sta[2]=3
    OneBuff(player.opponent, 0, {life={"-",1}}):apply()
  end
  local target = uniformly(player:field_idxs_with_preds(pred.follower))
  if target then
    OneBuff(player, target, buff):apply()
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

-- rio
[110133] = function(player)
  local buff = OnePlayerBuff(player)
  for _,idx in ipairs(player:field_idxs_with_preds(pred.follower)) do
    buff[idx] = {atk={"+",3},sta={"+",3}}
  end
  buff:apply()
  recycle_one(player)
end,

-- nanai
[110134] = function(player)
  local amt, opponent = 0, player.opponent
  for i=1,5 do
    while opponent.hand[i] and pred.spell(opponent.hand[i]) do
      opponent:hand_to_grave(i)
      amt = amt + 1
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
}
setmetatable(characters_func, {__index = function()return function() end end})
