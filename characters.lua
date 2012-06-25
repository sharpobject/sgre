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
      OneBuff(player,0,{life={"-",1}}):apply()
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
   
end,

}