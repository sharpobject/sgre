characters_func = {

--Mysterious Girl Sita Vilosa
[100001] = function(player)
   local target_idxs = player.opponent:field_idxs_with_preds(pred.follower)
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
   local target_idxs = player.opponent:field_idxs_with_preds(pred.follower)
   local target_idx = target_idxs[math.random(#target_idxs)]
   local buff = OnePlayerBuff(player.opponent)
   buff[idx] = {atk={"-",1},sta={"-",1}}
   buff:apply()
end,

}