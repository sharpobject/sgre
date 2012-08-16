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
   local target_idx = target_idxs[math.random(#target_idxs)]
   OneBuff(player.opponent,target_idx,{atk={"-",1},sta={"-",1}}):apply()
end,

--Crux Knight Luthica
[100003] = function(player)
   local target_idxs = player:field_idxs_with_preds(pred.C, pred.follower)
   local target_idx = target_idxs[math.random(#target_idxs)]
   OneBuff(player,target_idx,{atk={"+",1},sta={"+",1}}):apply()
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
   local target_idx = target_idxs[math.random(#target_idxs)]
   OneBuff(player,target_idx,{size={"-",1}}):apply()   

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
   local num_vita = #player.opponent:field_idxs_with_preds({pred.follower, pred.faction.V})
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
      buff[target_idx] = {atk={"-",2},sta={"-",2}}
   end
   buff:apply()
end,

--Dress Sita
[100010] = function(player)
   local target_idxs = player.opponent:get_follower_idxs()
   local buff = OnePlayerBuff(player.opponent)
   if #target_idxs > 1 then
      local target_idx = player.opponent:field_idxs_with_most_and_preds(pred.size, pred.follower)[1]
      buff[target_idx] = {atk={"-",2},def={"-",1},sta={"-",2}}
   elseif #followers == 1 then
      buff[followers[1]] = {sta={"-",2}}
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
   OneBuff(player.opponent,target_idxs[1],{atk={"-",2},def={"-",2},sta={"-",2}}):apply()
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
   local target_idxs = {}
   for _,i in ipairs(followers) do
      if player.field[i].size > 1 then
	 target_idxs[#target_idxs+1] = i
      end
   end
   if #target_idxs == 0 then
      return
   end
   if #player.hand > 1 then
      local size_diff = math.abs(player.hand[1].size - player.hand[2].size)
      OneBuff(player,uniformly(target_idxs),{size={"-",size_diff}}):apply()
   end
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
   OneBuff(player,uniformly(target_idxs),{size={"-",1}}):apply()
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
      OneBuff(player,target_idx,{atk={"+",buff_size},sta={"+",buff_size}}):apply()
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
   OneBuff(player.opponent,target_idx,{def={"-",def_lose}}):apply()
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
   OneBuff(player,target_idx,{size={"=",new_size}}):apply()
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
   
}