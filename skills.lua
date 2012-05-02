local skill_numtype_to_type = {"attack", "defend", "start"}
skill_id_to_type = map_dict(function(n) return skill_numtype_to_type[n] end,
                   {[1001]=3,[1002]=1,[1003]=1,[1004]=2,[1005]=1,[1006]=2,
                    [1007]=3,[1008]=1,[1009]=2,[1010]=1,[1011]=3,[1012]=2,
                    [1013]=1,[1014]=1,[1015]=3,[1016]=2,[1017]=2,[1018]=2,
                    [1019]=1,[1020]=3,[1021]=1,[1022]=2,[1023]=3,[1024]=3,
                    [1025]=2,[1026]=1,[1027]=3,[1028]=3,[1029]=1,[1030]=2,
                    [1031]=2,[1033]=2,[1034]=3,[1035]=1,[1036]=1,[1037]=2,
                    [1038]=1,[1039]=3,[1040]=2,[1041]=2,[1042]=1,[1043]=2,
                    [1044]=1,[1045]=1,[1046]=2,[1047]=2,[1048]=1,[1049]=1,
                    [1050]=3,[1051]=3,[1052]=3,[1053]=3,[1054]=1,[1057]=2,
                    [1058]=3,[1059]=1,[1060]=1,[1061]=3,[1062]=2,[1063]=3,
                    [1064]=3,[1065]=2,[1066]=3,[1067]=1,[1068]=3,[1069]=2,
                    [1070]=3,[1071]=2,[1072]=1,[1074]=2,[1075]=1,[1077]=1,
                    [1078]=1,[1079]=2,[1080]=1,[1081]=1,[1082]=2,[1083]=1,
                    [1084]=3,[1085]=1,[1086]=1,[1087]=2,[1088]=2,[1089]=1,
                    [1090]=1,[1091]=2,[1092]=2,[1093]=1,[1094]=2,[1095]=3,
                    [1096]=3,[1097]=2,[1098]=1,[1099]=1,[1100]=2,[1101]=1,
                    [1102]=3,[1103]=2,[1104]=1,[1105]=2,[1106]=3,[1107]=2,
                    [1108]=1,[1109]=1,[1110]=3,[1111]=3,[1112]=2,[1113]=1,
                    [1114]=2,[1115]=1,[1116]=3,[1117]=2,[1118]=1,[1119]=2,
                    [1120]=1,[1121]=3,[1122]=2,[1123]=1,[1174]=1,[1218]=1,
                    [1219]=2,[1314]=1,[1315]=1,[1316]=2,})
setmetatable(skill_id_to_type, {__index = function() return "start" end})

local refresh_id = 1076

skill_func = {
-- guard maid, maid cross
[1007] = function(player)
  local target_idx = uniformly(player:field_idxs_with_preds({pred.maid,pred.follower}))
  if target_idx then
    local buff = Buff(player)
    buff.field[player][target_idx] = {atk={"+",1}, sta={"+",1}}
    buff:apply()
  end
end,

-- chief maid, maid wisdom
[1008] = function(player, my_idx)
  local spell_idx = player:hand_idxs_with_preds({pred.spell})[1]
  if spell_idx then
    player:hand_to_grave(spell_idx)
    local buff = Buff(player)
    buff.field[player][my_idx] = {atk={"+",2}}
    buff:apply()
  end
end,

-- mop maid, mop slash
[1009] = function(player, my_idx)
  local buff = Buff(player)
  local idxs = player:field_idxs_with_preds({pred.follower})
  for _,idx in ipairs(idxs) do
    if math.abs(my_idx - idx) <= 1 then
      buff.field[player][idx] = {atk={"+",1}}
    end
  end
  buff:apply()
end,

-- aristocrat girl, noblesse
[1010] = function(player, my_idx, my_card, other_idx, other_card)
  if other_card.def >= 2 then
    local buff = Buff(player)
    buff.field[player.opponent][other_idx] = {sta={"-",3}}
    buff:apply()
  end
end,

--private maid, true caring
[1011] = function(player)
  local target_idx = uniformly(player.opponent:field_idxs_with_preds({pred.follower}))
  if target_idx then
    local buff = Buff(player)
    buff.field[player.opponent][target_idx] = {atk={"-",1}}
    buff:apply()
  end
end,

--senpai maid, i'll try my best
[1012] = function(player, my_idx)
  local buff = Buff(player)
  buff.field[player][my_idx] = {atk={"+",1}, sta={"+",2}}
  buff:apply()
end,

--striker, fireball!
[1013] = function(player, my_idx, my_card, other_idx)
  local buff = Buff(player)
  buff.field[player.opponent][other_idx] = {sta={"-",1}}
  buff:apply()
end,

}

setmetatable(skill_func, {__index = function() return function() end end})
