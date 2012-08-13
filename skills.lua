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
                    [1219]=2,[1314]=1,[1315]=1,[1316]=2,[1076]=3,["refresh"]=3})
setmetatable(skill_id_to_type, {__index = function() return "start" end})

local refresh = function(player, my_idx, my_card)
  my_card:refresh()
end

local esprit = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card.skills then
    local removed = false
    for idxx,skill in ipairs(other_card.skills) do
      if skill then
        other_card:remove_skill(idxx)
        removed = true
      end
    end
    if removed then
      OneBuff(player, my_idx, {atk={"+",1}, def={"+",1}, sta={"+",1}}):apply()
    end
  end
end

local dressup_skill = function(dressup_id, player, my_idx)
  local dressup = function(card) return card.id == dressup_id end
  local dressup_target = player:deck_idxs_with_preds({dressup})[1]
  if dressup_target then
    local field_idxs = player:field_idxs_with_preds({dressup})
    for _,idx in ipairs(field_idxs) do
      player:field_to_grave(idx)
    end
    player:deck_to_field(dressup_target)
    dressup_target = player:field_idxs_with_preds({dressup})
    OneBuff(player, dressup_target, {size={"=",5}, atk={"+",3}, sta={"+",3}}):apply()
    player:field_to_grave(my_idx)
  end
end

local heartful_catch = function(dressup_id, player, my_idx, other_idx, buff_type)
  local dressup = function(card) return card.id == dressup_id end
  local buff = false
  local field_targets = player:field_idxs_with_preds({dressup})
  for _,idx in ipairs(field_targets) do
    if idx ~= my_idx then
      player:field_to_grave(idx)
      buff = true
    end
  end
  local hand_target = player:hand_idxs_with_preds({pred.dressup})[1]
  if hand_target then
    player:hand_to_grave(hand_target)
    buff = true
  end
  local grave_target = player:grave_idxs_with_preds({pred.dressup})[1]
  if grave_target then
    player:grave_to_exile(grave_target)
    buff = true
  end
  if buff then
    if buff_type == "-" then
      OneBuff(player.opponent, other_idx, {atk={buff_type,1}, sta={buff_type,2}}):apply()
    elseif buff_type == "+" then
      OneBuff(player, my_idx, {atk={buff_type,1}, sta={buff_type,2}}):apply()
    end
  end
end


local blue_cross_skill = function(player, my_idx, my_card, skill_idx, buff)
  if #player.hand <=2 then
    OneBuff(player, my_idx, buff):apply()
  elseif #player.hand >= 4 then
    my_card:remove_skill(skill_idx)
  end
end,


skill_func = {
["refresh"] = refresh,

-- episode 1 follower skills

-- untested
-- new cook club student, may i see?
[1001] = function(player)
  local target_idx = uniformly(player:field_idxs_with_preds({pred.cook_club,pred.follower}))
  if target_idx then
    local buff = GlobalBuff(player)
    buff.field[player][target_idx] = {atk={"+",1}, sta={"+",1}}
    buff:apply()
  end
end,

-- cook club katie, best taste ever!
[1002] = function(player, my_idx, my_card)
  if my_card.sta > 1 then
    local buff = GlobalBuff(player)
    buff.field[player][my_idx] = {atk={"+",1}, sta={"-"},1}
    buff:apply()
  end
end,

-- cook club sylphie, 25 assistant asmis, crescent elder riesling, best attack
[1003] = function(player, my_idx)
  local buff = GlobalBuff(player)
  buff.field[player][my_idx] = {atk={"+",1}}
  buff:apply()
end,

-- prefect layna, proper behavior
[1004] = function(player, my_idx)
  local buff = GlobalBuff(player)
  buff.field[player][my_idx] = {sta={"+",#player.hand + 1}}
  buff:apply()
end,

-- lib. serie, wrath of the book!
[1005] = function(player, my_idx)
  local libs = #player:hand_idxs_with_preds({pred.lib})
  if libs > 0 then
    local buff = GlobalBuff(player)
    buff.field[player][my_idx] = {atk={"+",libs}}
    buff:apply()
  end
end,

-- lib vernika, sita's friend rosie, 25 agent nine, seeker luthera, lost doll, best defense
[1006] = function(player, my_idx)
  local buff = GlobalBuff(player)
  buff.field[player][my_idx] = {def={"+",2}}
  buff:apply()
end,

-- tested
-- guard maid, maid cross
[1007] = function(player)
  local target_idx = uniformly(player:field_idxs_with_preds({pred.maid,pred.follower}))
  if target_idx then
    local buff = GlobalBuff(player)
    buff.field[player][target_idx] = {atk={"+",1}, sta={"+",1}}
    buff:apply()
  end
end,

-- chief maid, maid wisdom
[1008] = function(player, my_idx)
  local spell_idx = player:hand_idxs_with_preds({pred.spell})[1]
  if spell_idx then
    player:hand_to_grave(spell_idx)
    local buff = GlobalBuff(player)
    buff.field[player][my_idx] = {atk={"+",2}}
    buff:apply()
  end
end,

-- mop maid, mop slash
[1009] = function(player, my_idx)
  local buff = GlobalBuff(player)
  local idxs = player:field_idxs_with_preds({pred.follower})
  for _,idx in ipairs(idxs) do
    if math.abs(my_idx - idx) <= 1 then
      buff.field[player][idx] = {atk={"+",1}}
    end
  end
  buff:apply()
end,

-- aristocrat girl, noblesse
[1010] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card.def >= 2 then
    local buff = GlobalBuff(player)
    buff.field[player.opponent][other_idx] = {sta={"-",3}}
    buff:apply()
  end
end,

--private maid, true caring
[1011] = function(player)
  local target_idx = uniformly(player.opponent:field_idxs_with_preds({pred.follower}))
  if target_idx then
    local buff = GlobalBuff(player)
    buff.field[player.opponent][target_idx] = {atk={"-",1}}
    buff:apply()
  end
end,

--senpai maid, i'll try my best
[1012] = function(player, my_idx)
  local buff = GlobalBuff(player)
  buff.field[player][my_idx] = {atk={"+",1}, sta={"+",2}}
  buff:apply()
end,

--striker, fireball!
[1013] = function(player, my_idx, my_card, skill_idx, other_idx)
  local buff = GlobalBuff(player)
  buff.field[player.opponent][other_idx] = {sta={"-",1}}
  buff:apply()
end,

-- untested
-- flag knight frett, flag return
[1014] = function(player)
  if player.field[3] and player.field[3].type == "follower" then
    local buff = GlobalBuff(player)
    buff.field[player][3] = {atk={"+",1}, sta={"+",1}}
    buff:apply()
  end
end,

-- knight adjt. sarisen, sisters in arms
[1015] = function(player, my_idx)
  local idxs = player:field_idxs_with_preds({pred.knight,pred.follower})
  if #idxs > 1 then
    local buff = OnePlayerBuff(player)
    for _,idx in ipairs(idxs) do
      if idx ~= my_idx then
        buff[idx] = {atk={"+",1}, sta={"+",1}}
      end
    end
    buff:apply()
  end
end,

-- crux knight pintail, contract witch, surprise!
[1016] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card.size < my_card.size then
    local buff = GlobalBuff(player)
    buff.field[player][my_idx] = {atk={"+",1}, sta={"+",1}}
    buff:apply()
  end
end,

-- priestess, healing prayer
[1017] = function(player)
  local buff = OnePlayerBuff(player)
  buff[0] = {life={"+",1}}
  buff:apply()
end,

-- seeker amethystar, holy heal
[1018] = function(player, my_idx)
  if player.game.turn % 2 == 1 then
    OneBuff(player, my_idx, {sta={"+",3}}):apply()
  end
end,

-- seeker lydia, cross
[1019] = function(player, my_idx, my_card, skill_idx, other_idx)
  if #player.field_idxs_with_preds({pred.faction.C}) >= 2 then
    OneBuff(player.opponent, other_idx, {atk={"-",1}, def={"-",2}, sta={"-",1}}):apply()
  end
end,

-- acolyte, holy peace
[1020] = function(player)
  if player.game.turn % 2 == 0 then
    local target_idxs = player:field_idxs_with_preds({pred.faction.C, pred.follower})
    local buff = OnePlayerBuff(player)
    for _,idx in ipairs(target_idxs) do
      buff[idx] = {atk={"+",2}, sta={"+",2}}
    end
    buff:apply()
  end
end,

-- scardel sion flina, sion attack!
[1021] = function(player)
  local target_idxs = player:field_idxs_with_preds({pred.sion_rion, pred.follower})
  local buff = OnePlayerBuff(player)
  for _,idx in ipairs(target_idxs) do
    buff[idx] = {atk={"+",1}}
  end
  buff:apply()
end,

-- scardel rion flina, rion defense!
[1022] = function(player)
  local target_idxs = player:field_idxs_with_preds({pred.sion_rion, pred.follower})
  local buff = OnePlayerBuff(player)
  for _,idx in ipairs(target_idxs) do
    buff[idx] = {sta={"+",1}}
  end
  buff:apply()
end,

-- moondancer kata flina, moonlight dancer!
[1023] = function(player)
  local target_idxs = shuffle(player.opponent:field_idxs_with_preds({pred.follower}))
  if #target_idxs >= 1 then
    local buff = OnePlayerBuff(player.opponent)
    for i=1,min(2,#target_idxs) do
      buff[target_idxs[i]] = {atk={"-",1}, sta={"-",1}}
    end
    buff:apply()
  end
end,

-- scardel shiraz, night's place
[1024] = function(player)
  if #player:field_idxs_with_preds({pred.faction.D,pred.follower}) then
    local target_idx = uniformly(player.opponent:field_idxs_with_preds({pred.follower}))
    OneBuff(player.opponent, target_idx, {sta={"-",2}}):apply()
  end
end,

-- master luna flina, moon guardian
[1025] = function(player, my_idx)
  local new_def = #player:hand_idxs_with_preds({pred.faction.D, pred.follower})
  OneBuff(player, my_idx, {def={"=",new_def}, sta={"+",new_def}}):apply()
end,

-- red moon aka flina, cook club ace, silent maid, seeker director, lantern witch,
-- coin lady, reverse defense
[1026] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local diff = abs(other_card.def)
  OneBuff(player, my_idx, {atk={"+",diff}, def={"=",0}, sta={"+",diff}}):apply()
end,

-- blue moon beecky flina, chilly blood
[1027] = function(player, my_idx)
  local target_idxs = shuffle(player:get_follower_idxs())
  local buff = OnePlayerBuff(player)
  buff[my_idx] = {atk={"+",1}, sta={"+",1}}
  if #target_idxs >= 2 then
    if target_idxs[1] == my_idx then
      buff[target_idxs[2]] = {atk={"+",1}, sta={"+",1}}
    else
      buff[target_idxs[1]] = {atk={"+",1}, sta={"+",1}}
    end
  end
  buff.apply()
end,

-- episode 2 follower skills

-- lib. milka, book return
[1028] = function(player)
  local target_idx = uniformly(player:field_idxs_with_preds({pred.lib, pred.follower}))
  if target_idx then
    OneBuff(player, target_idx, {sta={"+",2}}):apply()
  end
end,

-- council casey, fanatic sarah, seeker irene, reading witch, valor strike!
[1029] = function(player, my_idx, my_card, skill_idx)
  OneBuff(player, my_idx, {atk={"+",2}}):apply()
  my_card:remove_skill(skill_idx)
end,

-- council treas. amy, budget time!
[1030] = function(player, my_idx, my_card, skill_idx)
  local buff = OnePlayerBuff(player)
  local target_idxs = player:field_idxs_with_preds({pred.council, pred.follower})
  for _,idx in ipairs(target_idxs) do
    buff[idx] = {sta={"+",2}}
  end
  buff:apply()
  my_card:remove_skill(skill_idx)
end,

-- council pres. celine, presidential power
[1031] = function(player, my_idx)
  local target_idx = uniformly(player:hand_idxs_with_preds({pred.council}))
  if target_idx then
    player:hand_to_top_deck(target_idx)
    OneBuff(player, my_idx, {atk={"+",1}, sta={"+",2}}):apply()
  end
end,

-- insomniac nanasid, insomnia
[1033] = function(player, my_idx, my_card, skill_idx, other_idx)
  local buff = GlobalBuff(player)
  buff.field[player][my_idx] = {atk={"+",2}, def={"-", 1}}
  buff.field[player.opponent][other_idx] = {atk={"-",2}}
  buff:apply()
  my_card:remove_skill(skill_idx)
end,

-- traumatized hilde, sad memory
[1034] = function(player, my_idx, my_card)
  local target_idxs = shuffle(player:get_follower_idxs())
  local buff = OnePlayerBuff(player)
  if my_card.atk > 0 then
    buff[my_idx] = {atk={"-",1}}
  end
  for i=1,math.min(2, #target_idxs) do
    if buff[i] then
      buff[i][sta] = {"+",2}
    else
      buff[i] = {sta={"+",2}}
    end
  end
  buff:apply()
end,

-- stigma flint, stigma
[1035] = function(player)
  local ally_target_idx = uniformly(player:get_field_idxs_with_preds({pred.stig_wit_fel, pred.follower}))
  local opp_target_idx = uniformly(player.opponent:get_follower_idxs())
  if ally_target_idx then
    player:field_to_exile(ally_target_idx)
    player.opponent:destroy(opp_target_idx)
  end
end,

-- fated rival seven, brilliant idea
[1036] = function(player)
  local grave_target_idxs = shuffle(player:grave_idxs_with_preds({pred.A}))
  if #grave_target_idxs > 0 then
    local opp_target_idxs = shuffle(player.opponent:get_follower_idxs())
    local buff = OnePlayerBuff(player.opponent)
    for i=1,math.min(2,#grave_target_idxs) do
      player:grave_to_exile(grave_target_idxs[i])
    end
    for i=1,math.min(2,opp_target_idxs) do
      buff[opp_target_idxs[i]] = {atk={"-",1}, def={"-",1}, sta={"-",2}}
    end
    buff:apply()
  end
end,

-- stigma witness felicia, proof of stigma
[1037] = function(player)
  local target_idxs = player:field_idxs_with_preds({pred.stig_flint, pred.follower})
  if #target_idxs > 0 then
    local buffsize = #player:field_idxs_with_preds({pred.A, pred.follower})
    local buff = OnePlayerBuff(player)
    for _,idx in ipairs(target_idxs) do
      buff[idx] = {atk={"-",buffsize}, sta={"-",buffsize}}
    end
    buff:apply()
  end
end,

-- seeker lucia, take cover!
[1038] = function(player, my_idx, my_card)
  local buffsize = math.min(#player:field_idxs_with_preds({pred.seeker}) + #player:hand_idxs_with_preds({pred.seeker}), my_card.sta - 1)
  OneBuff(player, my_idx, {atk={"+",buffsize}, sta={"-",buffsize}}):apply()
end,

-- seeker melissa, research results
[1039] = function(player, my_idx, my_card, skill_idx)
  local target_idxs = shuffle(player:field_idxs_with_preds({pred.seeker, pred.follower}))
  local buff = OnePlayerBuff(player)
  for i=1,math.min(2,#target_idxs) do
    buff[target_idxs[i]] = {atk={"+",2}, sta={"+",2}}
  end
  buff:apply()
  my_card:remove_skill(skill_idx)
end,

-- crux knight sinclair, grace of the goddess
[1040] = function(player, my_idx)
  local grave_idxs = shuffle(player:grave_idxs_with_preds({pred.C}))
  if #grave_idxs > 0 then
    local target_idxs = player:get_follower_idxs()
    for i=1,math.min(2,#grave_idxs) do
      player:grave_to_exile(grave_idxs[i])
    end
    local buff = OnePlayerBuff(player)
    buff[my_idx] = {atk={"+",2}, sta={"+",2}}
    if target_idxs[1] ~= my_idx then
      buff[target_idxs[1]] = {atk={"+",1}, sta={"+",1}}
    else
      buff[target_idxs[2]] = {atk={"+",1}, sta={"+",1}}
    end
    buff:apply()
  end
end,

-- cauldron witch, cauldron!
[1041] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if #player:field_idxs_with_preds({pred.follower, pred.D}) > 1 then
    local buffsize = math.ceil(other_card.atk / 2)
    OneBuff(player, my_idx, {sta={"+",buffsize}}):apply()
    my_card:remove_skill(skill_idx)
  end
end,

-- tea party witch, pumpkin!
[1042] = function(player)
  local target_idxs = player:field_idxs_with_preds({pred.witch, pred.follower})
  local buff = OnePlayerBuff(player)
  for _,idx in ipairs(target_idxs) do
    buff[idx] = {sta={"+",1}}
  end
  buff:apply()
end,

-- heart stone witch, magic of the heart
[1043] = function(player, my_idx, my_card, skill_idx)
  local target_idxs = player:field_idxs_with_preds({pred.witch, pred.follower})
  local buff = OnePlayerBuff(player)
  for _,idx in ipairs(target_idxs) do
    buff[idx] = {atk={"+",2}, sta={"+",2}}
  end
  buff:apply()
  my_card:remove_skill(skill_idx)
end,

-- undertaker, undertaker
[1044] = function(player, my_idx)
  local buffsize = 0
  if player.grave[1] then
    player:grave_to_exile(1)
    buffsize = buffsize + 1
  end
  if player.opponent.grave[1] then
    player.opponent:grave_to_exile(1)
    buffsize = buffsize + 1
  end
  if buffsize > 0 then
    OneBuff(player, my_idx, {atk={"+",buffsize}, sta={"+",buffsize}}):apply()
  end
end,

-- visitor ophelia, first visit
[1045] = function(player, my_idx)
  OneBuff(player, my_idx, {size={"-",1}}):apply()
end,

-- visitor ophelia, academic curiosity
[1046] = function(player, my_idx, my_card, skill_idx, other_idx)
  local buff = GlobalBuff(player)
  local buffsize = math.min(math.abs(my_card.size - (my_card.def - 1)),5)
  buff.field[player][my_idx] = {def={"-",1}}
  buff.field[player.opponent][other_idx] = {atk={"-",buffsize}, def={"-",buffsize}, sta={"-",buffsize}}
  buff:apply()
end,

-- episode 3 follower skills

-- genius student nanai, great power!
[1047] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local player_grave_idxs = player:grave_idxs_with_preds({function(card)
    return card.size == other_card.size end})
  local opp_grave_idxs = player.opponent:grave_idxs_with_size(other_card.size)
  local buffsize = 0
  for _,idx in ipairs(player_grave_idxs) do
    player:grave_to_exile(idx)
    buffsize = buffsize + 1
  end
  for _,idx in ipairs(opp_grave_idxs) do
    player.opponent:grave_to_exile(idx)
    buffsize = buffsize + 1
  end
  if buffsize > 0 then
    OneBuff(player.opponent, other_idx, {atk={"-",buffsize}, sta={"-",buffsize}}):apply()
  end
end,

-- lib. daisy, agent maid, arcana i magician, crescent maze, null defense!
[1048] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card.def >= 1 then
    OneBuff(player.opponent, other_idx, {def={"=",0}}):apply()
    my_card:remove_skill_until_refresh(skill_idx)
  end
end,

-- lib. manager lotte, cultist maid, seeker ruth, dollmaster elfin rune, amnesia
[1049] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if #other_card.skills then
    local removed = false
    for idxx,skill in ipairs(other_card.skills) do
      if skill then
        other_card:remove_skill(idxx)
        removed = true
      end
    end
    if removed then
      my_card:remove_skill(skill_idx)
    end
  end
end,

-- mediator cabernet, two and one
[1050] = function(player)
  local target_idxs = player:field_idxs_with_preds({pred.D, pred.follower})
  if target_idxs then
    local buff = OnePlayerBuff(player)
    for _,idx in ipairs(target_idxs) do
      buff[idx] = {atk={"+",2}, sta={"+",2}}
    end
    buff:apply()
  end
end,

-- linia pacifica, master's command
[1051] = function(player, my_idx, my_card)
  local buffsize = math.ceil(my_card.size / 2)
  local target_idxs = player:field_idxs_with_preds({pred.A, pred.follower})
  local buff = OnePlayerBuff(player)
  for _,idx in ipairs(target_idxs) do
    if math.abs(idx - my_idx) <= 1 then
      buff[idx] = {atk={"+",buffsize}, sta={"+",buffsize}}
    end
  end
  buff:apply()
end,

-- vanguard knight, orders from above
[1052] = function(player, my_idx)
  local buffsize = #player:hand_idxs_with_preds({pred.C})
  OneBuff(player, my_idx, {atk={"+",buffsize}, sta={"+",buffsize}}):apply()
end,

-- lib. ace, book's wisdom
[1053] = function(player, my_idx, my_card)
  local buffsize = my_card.size
  local target_idxs = player:field_idxs_with_preds({pred.V, pred.follower})
  local buff = OnePlayerBuff(player)
  for _,idx in ipairs(target_idxs) do
    buff[idx] = {atk={"+",buffsize}, sta={"+",buffsize}}
  end
  buff:apply()
end,

-- sage esprit, hidden truth
[1054] = esprit,

-- guide rio, best attack
[1218] = function(player, my_idx)
  local buffsize = uniformly({1,2,3})
  OneBuff(player, my_idx, {atk={"+",buffsize}}):apply()
end,

-- sage esprit, coin lady, hidden truth
[1057] = esprit,

-- episode EX1 follower skills

-- council maron, dress up!
[1058] = function(player, my_idx, my_card)
  return dressup_skill(300143, player, my_idx) end,

-- dressup maron, heartful catch!
[1059] = function(player, my_idx, my_card, skill_idx, other_idx)
  return heartful_catch(300143, player, my_idx, other_idx, "-") end,

-- sleep club president, fortune lady, lancer knight, magic circle witch, recycle
[1060] = function(player)
  local grave_targets = shuffle(player:grave_idxs_with_preds({function(card) return true end}))
  if grave_targets then
    player:grave_to_exile(grave_targets[1])
    if grave_targets[2] then
      player:grave_to_bottom_deck(grave_targets[2])
    end
  end
end,

-- sister vermet vilosa, hidden wind slash
[1061] = function(player, my_idx)
  OneBuff(player, my_idx, {sta={"+",2}}):apply()
  local target = uniformly(player.opponent:hand_idxs_with_preds({pred.spell}))
  if target then
    player.opponent:hand_to_grave(target)
  end
end,

-- sanctuary hunter asmis, quest for truth
[1062] = function(player, my_idx, my_card, skill_idx)
  if my_card.faction == player.character.faction then
    OneBuff(player, 0, {life="+",8}):apply()
    my_card:remove_skill(skill_idx)
  end
end,

-- unlucky lady, value of misfortune
[1063] = function(player)
  if player.game.turn % 2 == 0 then
    local targets = player:field_idxs_with_preds({pred.follower, pred.faction.A})
    local buff = OnePlayerBuff(player)
    for _,idx in ipairs(targets) do
      buff[idx] = {atk={"+",2}, sta={"+",2}}
    end
    buff:apply()
  end
end,

-- 2s agent fourteen, mission accomplished
[1064] = function(player, my_idx)
  while #player.opponent.hand < 5 do
    player.opponent:draw_from_bottom_deck()
  end
  OneBuff(player, my_idx, {sta={"+",2}}):apply()
end,

-- arbiter rivelta answer, friendly advice
[1065] = function(player, my_idx, my_card, skill_idx, other_idx)
  if my_card.faction == player.character.faction then
    local sent = math.min(#player.grave, 5)
    if sent > 0 then
      for i=1,sent do
        player:grave_to_exile(math.random(#player.grave))
      end
      OneBuff(player.opponent, other_idx, {atk={"-"},math.ceil(sent/2)}):apply()
      my_card:remove_skill(skill_idx)
    end
  end
end,

-- seeker smartylane, dress up!
[1066] = function(player, my_idx, my_card)
  return dressup_skill(300157, player, my_idx) end,

-- dressup smartylane, heartful catch!
[1067] = function(player, my_idx, my_card, skill_idx, other_idx)
  return heartful_catch(300157, player, my_idx, other_idx, "+") end,

-- medic knight, recycle
[1068] = function(player, my_idx)
  player.opponent:mill(1)
  OneBuff(player, my_idx, {sta={"+",2}}):apply()
end,

-- crux knight fleta, hesistation of justice
[1069] = function(player, my_idx, my_card, skill_idx)
  if my_card.faction == player.character.faction then
    local target_idxs = player:field_idxs_with_preds({pred.follower, pred.faction.C})
    local buff = OnePlayerBuff(player)
    for _,idx in ipairs(target_idxs) do
      buff[idx] = {atk={"+",3}, sta={"+"},3}
    end
    buff:apply()
    my_card.remove_skill(skill_idx)
  end
end,

-- vampire hunter ire flina, vampire killer
[1070] = function(player, my_idx)
  local target_idx = uniformly(player.opponent:hand_idxs_with_preds({pred.follower}))
  if target_idx then
    player.opponent:hand_to_grave(target_idx)
  end
  OneBuff(player, my_idx, {sta={"+",2}}):apply()
end,

-- scardel elder barbera, elder scroll
-- todo: test this
[1071] = function(player, my_idx, my_card, skill_idx)
  if my_card.faction == player.character.faction then
    local target_idx = player:grave_idxs_with_most_and_preds(
      pred.size, {pred.follower, pred.faction.D})[1]
    if target_idx then
      local target_card = player.grave[target_idx]
      player:grave_to_exile(target_idx)
      local field_idx = player:first_empty_field_slot()
      if field_idx then
        player.field[field_idx] = deepcpy(target_card)
        local buff_size = my_card.def
        OneBuff(player, field_idx, {atk={"+",buff_size}, sta={"+",buff_size}}):apply()
      end
    end
    my_card.remove_skill(skill_idx)
  end
end,

-- sweet lady isfeldt, energy supplement
[1072] = function(player, my_idx)
  OneBuff(player, my_idx, {sta={"+",2}}):apply()
end,

-- sweet lady isfeldt, sweet spell
[1073] = function(player, my_idx, my_card, skill_idx)
  my_card.skills[skill_idx] = 1074
end,

-- sweet lady isfeldt, sweet count
[1074] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card.size <= my_card.size then
    player.opponent:field_to_top_deck(other_idx)
    my_card.skills[skill_idx] = 1073
  end
end,

-- lib. student, dispatch maid, blue cross member, gs recon, heavy burden
[1075] = function(player, my_idx, my_card, skill_idx, other_idx)
  OneBuff(player.opponent, other_idx, {size={"+",1}}):apply()
  my_card:remove_skill(skill_idx)
end,

[1076] = refresh,

-- council student, meeting prep!
[1077] = function(player, my_idx, my_card, skill_idx)
  local target_idx = player:field_idxs_with_preds({pred.follower, pred.council})[1]
  if target_idx then
    OneBuff(player, target_idx, {sta={"+",3}}):apply()
    my_card:remove_skill(skill_idx)
  end
end,

-- sleep club advisor, time for bed
[1078] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  other_card.active = false
  my_card:remove_skill(skill_idx)
end,

-- council weekly help, seize
[1079] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local buff = GlobalBuff(player)
  buff.field[player][my_idx] = {atk={"=",other_card.atk}}
  buff.field[player.opponent][other_idx] = {atk={"=",my_card.atk}}
  buff:apply()
end,

-- lib. milty, book management?
[1080] = function(player, my_idx)
  local sta_buff, atk_buff = #player:hand_idxs_with_preds({pred.lib}), 0
  if sta_buff >= 3 then
    atk_buff = 1
  end
  OneBuff(player, my_idx, {atk={"+",atk_buff}, sta={"+",sta_buff}}):apply()
end,

-- council vp tieria, campaign prep
[1081] = function(player, my_idx, my_card, skill_idx)
  local buff_size = 1 + #player:field_idxs_with_preds({pred.council})
  OneBuff(player, my_idx, {atk={"+",buff_size}, sta={"+",buff_size}}):apply()
  my_card:remove_skill_until_refresh(skill_idx)
end,

-- lib. lotte & serie, fruits of friendship!
[1082] = function(player)
  if player.character.faction == "V" then
    if #player.hand >= 2 then
      for i=1,2 do
        player:hand_to_bottom_deck(1)
      end
      local target1_idx = uniformly(player:field_idxs_with_preds({pred.follower, 
        function(card) return not card.active end})
      local target2_idx = uniformly(player:get_follower_idxs())
      player.field[target1_idx].active = true
      OneBuff(player, target2_idx, {size={"-",1}, atk={"+",1}, def={"+",1}}):apply()
    end
  end
end,

-- peace lady, master's heart
[1083] = function(player, my_idx)
  local target_idx = uniformly(player:hand_idxs_with_preds({pred.maid}))
  if target_idx then
    player:hand_to_top_deck(target_idx)
    OneBuff(player, my_idx, {atk={"+",1}, sta={"+",2}}):apply()
  end
end,

-- justice lady, dress up rise
[1084] = function(player, my_idx)
  local lucerrie = function(card) return card.id == 300181 end
  local deck_idx = player:deck_idxs_with_preds({lucerrie})
  local field_idx = player:first_empty_field_slot
  if deck_idx and field_idx then
    player:deck_to_field(deck_idx)
    player:field_to_grave(my_idx)
    OneBuff(player, field_idx, {size={"=",5}, atk={"+",3}, sta={"+",2}}):apply()
  end
end,

-- dress up lucerrie, rising attack
[1085] = function(player, my_idx)
  local lucerrie = function(card) return card.id == 300181 end
    local buff = false
    local field_targets = player:field_idxs_with_preds({lucerrie})
    for _,idx in ipairs(field_targets) do
      if idx ~= my_idx then
        player:field_to_grave(idx)
        buff = true
      end
    end
    local hand_target = player:hand_idxs_with_preds({pred.dressup})[1]
    if hand_target then
      player:hand_to_grave(hand_target)
      buff = true
    end
    local grave_target = player:grave_idxs_with_preds({pred.dressup})[1]
    if grave_target then
      player:grave_to_exile(grave_target)
      buff = true
    end
    if buff then
      local opp_target = math.random(#player.opponent.hand)
      player.opponent:hand_to_grave(opp_target)
    end
  end
end,

-- meteor call lady, meteor call
[1086] = function(player, my_idx, my_card, skill_idx)
  local opp_target_idx = uniformly(player.opponent:get_follower_idxs())
  local buff_size = 1 + #player:field_idxs_with_preds({pred.lady})
  OneBuff(player.opponent, opp_target_idx, {sta={"-",buff_size}}):apply()
  my_card:remove_skill_until_refresh(skill_idx)
end,

-- picnic maid, faith and trust
[1087] = function(player, my_idx, my_card, skill_idx)
  local opp_target_idx = uniformly(player.opponent:get_follower_idxs())
  local buff_size = #player:hand_idxs_with_preds({function(card) 
    return pred.maid(card) or pred.lady(card) end})
  if buff_size > 0 then
    OneBuff(player.opponent, opp_target_idx, {sta={"-",buff_size}}):apply()
    my_card:remove_skill_until_refresh(skill_idx)
  end
end,

-- chief & mop maid, proof of obedience
[1088] = function(player)
  if player.character.faction == "A" then
    if #player.hand >= 2 then
      for i=1,2 do
        player:hand_to_bottom_deck(1)
      end
      local target1_idx = uniformly(player:field_idxs_with_preds({pred.follower, 
        function(card) return not card.active end})
      local target2_idx = uniformly(player.opponent:get_follower_idxs())
      player.field[target1_idx].active = true
      OneBuff(player.opponent, target2_idx, {size={"+",1}, atk={"-",1}, sta={"-",2}}):apply()
    end
  end
end,

-- blue cross sherry, blue cross voucher
[1089] = function(player, my_idx, my_card, skill_idx)
  blue_cross_skill(player, my_idx, my_card, skill_idx, {def={"-",2}})
end,

-- blue cross aurora, blue cross contract
[1090] = function(player, my_idx, my_card, skill_idx)
  blue_cross_skill(player, my_idx, my_card, skill_idx, {atk={"-",1}, sta={"-",1}})
end,

-- blue cross federine, blue cross oath
[1091] = function(player, my_idx, my_card, skill_idx)
  blue_cross_skill(player, my_idx, my_card, skill_idx, {sta={"-",2}})
end,

-- blue cross blue cross memory
[1092] = function(player, my_idx, my_card, skill_idx)
  if #player.hand <=2 then
    for i=1,5 do
      if i ~= my_idx and player.field[i] then
        player:field_to_grave(i)
      end
    end
  elseif #player.hand >=4 then
    my_card:remove_skill(skill_idx)
  end
end,

-- seeker sarah, blue cross wisdom
[1093] = function(player, my_idx, my_card, skill_idx, other_idx)
  local buff_size = #player:hand_idxs_with_preds({pred.seeker})
  if buff_size > 0 then
    OneBuff(player.opponent, other_idx, {def={"-",buff_size}}):apply()
  end
end,

-- knight frett & pintail, knight dash
[1094] = function(player)
  if player.character.faction == "C" then
    if #player.hand >= 2 then
      for i=1,2 do
        player:hand_to_bottom_deck(1)
      end
      local target1_idx = uniformly(player:field_idxs_with_preds({pred.follower, 
        function(card) return not card.active end})
      local target2_idx = uniformly(player:get_follower_idxs())
      player.field[target1_idx].active = true
      OneBuff(player, target2_idx, {size={"-",1}, atk={"+",1}, sta={"+",2}}):apply()
    end
  end
end,

-- sion flina, dress up
[1095] = function(player, my_idx)
  local rion_idx = player:deck_idxs_with_preds({function(card)
    return card.id == 300058 or card.id == 300196 end})[1]
  local dressup_idx = player:deck_idxs_with_preds({function(card)
    return card.id == 300198 end})[1]
  if rion_idx and dressup_idx then
    player:field_to_grave(my_idx)
    player:deck_to_grave(rion_idx)
    local field_idx = player:first_empty_field_slot()
    player:deck_to_field(dressup_idx)
    OneBuff(player, field_idx, {size={"=",5}, atk={"+",3}, sta={"+",3}}):apply()
  end
end,

-- rion flina, dress up
[1096] = function(player, my_idx)
  local sion_idx = player:deck_idxs_with_preds({function(card)
    return card.id == 300057 or card.id == 300195 end})[1]
  local dressup_idx = player:deck_idxs_with_preds({function(card)
    return card.id == 300198 end})[1]
  if sion_idx and dressup_idx then
    player:field_to_grave(my_idx)
    player:deck_to_grave(sion_idx)
    local field_idx = player:first_empty_field_slot()
    player:deck_to_field(dressup_idx)
    OneBuff(player, field_idx, {size={"=",5}, atk={"+",3}, sta={"+",3}}):apply()
  end
end,

-- gs alla marcia, gs march
[1097] = function(player, my_idx, my_card, skill_idx)
  local deck_idx = player:deck_idxs_with_preds({function(card)
    return card.id == 300193 end})[1]
  if deck_idx then
    local field_idx = player:first_empty_field_slot()
    player:deck_to_field(deck_idx)
    OneBuff(player, field_idx, {atk={"+",2}}):apply()
  end
  my_card:remove_skill_until_refresh(skill_idx)
end,

-- dress up sionrion, twin attack
[1098] = function(player, my_idx)
  local field_idxs = player:field_idxs_with_preds({function(card)
    return card.id == 300198 end})
  for _,idx in ipairs(field_idxs) do
    if idx ~= my_idx then
      player:field_to_grave(idx)
    end
  end
  if #player.hand > 0 then
    player:hand_to_grave(1)
    local grave_idx = uniformly(player:grave_idxs_with_preds({pred.sionrion}))
    if grave_idx then
      player:grave_to_exile(grave_idx)
      local buff = GlobalBuff(player)
      buff.field[player][0] = {life={"+",1}}
      buff.field[player.opponent][0] = {life={"-",1}}
      buff.apply()
    end
  end
end,

-- office witch, bean curse
[1099] = function(player, my_idx, my_card, skill_idx)
  if #player.opponent:ncards_in_field() % 2 == 0 then
    if #player.opponent.hand > 0 then
      player.opponent:hand_to_grave(math.random(#player.opponent.hand))
    end
  end
  my_card:remove_skill(skill_idx)
end,

-- crescent kris & con., master's love
[1100] = function(player)
  if player.character.faction == "D" then
    if #player.hand >= 2 then
      for i=1,2 do
        player:hand_to_bottom_deck(1)
      end
      local target1_idx = uniformly(player:field_idxs_with_preds({pred.follower, 
        function(card) return not card.active end})
      local target2_idx = uniformly(player.opponent:get_follower_idxs())
      player.field[target1_idx].active = true
      OneBuff(player.opponent, target2_idx, {size={"+",1}, atk={"-",1}, def={"-",1}}):apply()
    end
  end
end,

-- 1st witness kana.dkd, just give up
[1101] = function(player, my_idx, my_card)
  if my_card.def >= 1 then
    OneBuff(player, my_idx, {def={"-",1}}):apply()
    if player.deck[#player.deck].faction == player.character.faction and 
      player:first_empty_field_slot() then
      player:deck_to_field(#player.deck)
    end
  end
end,

-- 1st witness kana.dkd, just give up
[1102] = function(player, my_idx)
  OneBuff(player, my_idx, {def={"=",2}}):apply()
end,

-- lib. evenne, 2s agent thirteen, blue cross ferris, crescent aligote, no negligence
[1103] = function(player, my_idx, my_card, skill_idx)
  if player.character.faction == my_card.faction then
    OneBuff(player.opponent, 0, {life={"-",1}}):apply()
  end
  my_card:remove_skill(skill_idx)
end,

-- lib. serie, mascara
[1104] = function(player, my_idx, my_card, skill_idx)
  if #player.hand < 5 then
    local deck_target_idx = player:deck_idxs_with_preds({pred.lib})[1]
    if deck_target_idx then
      player:deck_to_hand(deck_target_idx)
      my_card:remove_skill_until_refresh(skill_idx)
    end
  end
end,

-- lib. milka, guitar!
[1105] = function(player, my_idx, my_card, skill_idx)
  local target_idx = player:field_idxs_with_preds({pred.lib, pred.follower})[1]
  OneBuff(player, target_idx, {sta={"+",2}}):apply()
  my_card:remove_skill_until_refresh(skill_idx)
end,

-- lib. h.l. tezina, i'll help you.
[1106] = function(player, my_idx, my_card, skill_idx)
  if player.character.faction == "V" then
    local lib_target = player:hand_idxs_with_preds({pred.V, pred.lib})[1]
    local other_target = player:hand_idxs_with_preds({pred.V, function(card) return not pred.lib(card) end})[1]
    if lib_target and other_target then
      player:hand_to_bottom_deck(lib_target)
      other_target = player:hand_idxs_with_preds({pred.V, function(card) return not pred.lib(card) end})[1]
      player:hand_to_bottom_deck(other_target)
      local enemy_target = uniformly(player.opponent:get_follower_idxs())
      if enemy_target then
        player.opponent:field_to_bottom_deck(enemy_target)
      end
      my_card:remove_skill(skill_idx)
    end
  end
end,

-- waitress gart, c-can i take your order?
[1107] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card and (other_card.faction == "A" or other_card.faction == "D") then
    OneBuff(player.opponent, other_idx, {atk={"-",2}, sta={"-",2}}):apply()
  else
    OneBuff(player, my_idx, {atk={"+",2}, sta={"+",2}}):apply()
  end
  my_card:remove_skill_until_refresh(skill_idx)
end,

-- battlefield sita, wind slash
[1108] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card then
    local debuff_size = math.ceil(my_card.atk / 2)
    local buff_size = math.ceil(debuff_size / 2)
    local buff = GlobalBuff(player)
    buff.field[player.opponent][other_idx] = {sta={"-",debuff_size}}
    buff.field[player][my_idx] = {sta={"+",buff_size}}
    buff:apply()
  end
end,

-- lady misfortune, lady call
[1109] = function(player, my_idx, my_card, skill_idx)
  if #player.hand < 5 then
    deck_target_idx = player:deck_idxs_with_preds({pred.lady})[1]
    if deck_target_idx then
      player:deck_to_hand(deck_target_idx)
    end
  end
  my_card:remove_skill_until_refresh(skill_idx)
end,

-- drum maid, power of music
[1110] = function(player, my_idx, my_card)
  local pred = function(card) return pred.guitar(card) or pred.bass(card) end
  if #player:hand_idxs_with_preds({pred}) > 0 or #player:field_idxs_with_preds({pred}) > 0 then
    local hand_idx = player:hand_idxs_with_preds({pred})[1]
    if hand_idx then
      player:hand_to_exile(hand_idx)
      player:field_to_exile(my_idx)
    else
      player:field_exile(my_idx)
      local field_idx = player:field_idxs_with_preds({pred})[1]
      if field_idx then
        player:field_to_exile(field_idx)
      end
    end
    local other_idxs = player.opponent:hand_idxs_with_preds({pred.follower})
    while other_idxs[1] do
      player.opponent:hand_to_grave(other_idxs[1])
      other_idxs = player.opponent:hand_idxs_with_pres({pred.follower})
    end
  end
end,

-- rainy blue lady, labor union
[1111] = function(player, my_idx, my_card, skill_idx)
  if player.character.faction == "A" then
    local maid_target = player:hand_idxs_with_preds({pred.maid})[1]
    local nonmaid_target = player:hand_idxs_with_preds({pred.A, function(card) return not pred.maid(card) end})[1]
    if maid_target and nonmaid_target then
      player:hand_to_bottom_deck(nonmaid_target)
      maid_target = player:hand_idxs_with_preds({pred.maid})[1]
      player:hand_to_bottom_deck(maid_target)
      local other_target = uniformly(player.opponent:get_follower_idxs())
      if other_target then
        player.opponent:field_to_bottom_deck(other_target)
      end
      my_card:remove_skill(skill_idx)
    end
  end
end,

-- agent nold, agent change
[1112] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card and other_card.size > my_card.size then
    local buff = GlobalBuff(player)
    buff.field[player][my_idx] = {atk={"-",2}, sta={"-",2}}
    buff.field[player.opponent][other_idx] = {atk={"+",2}, sta={"+",2}}
    buff:apply()
    player.deck[#player.deck+1] = other_card
    player.opponent.field[other_idx] = nil
    if my_card.sta > 0 then
      player.opponent.deck[#player.opponent.deck+1] = my_card
      player.field[my_idx] = nil
    end
    my_card.remove_skill(skill_idx)
  end
end,

-- crimson witch cinia, crimson magic
[1113] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card then
    local buff_size = 1 + #player:hand_idxs_with_preds({pred.A})
    local buff = GlobalBuff(player)
    buff.field[player.opponent][other_idx] = {sta={"-",buff_size}}
    buff.field[player][my_idx] = {sta={"+",buff_size}}
    buff:apply()
  end
end,

-- blue cross jainier, blue cross support
[1114] = function(player, my_idx, my_card, skill_idx)
  if #player.hand < 4 then
    while #player.hand < 4 do
      player:draw_a_card()
    end
  else
    my_card:remove_skill(skill_idx)
  end
end,

-- seeker odien, seeker call
[1115] = function(player, my_card, my_idx, skill_idx)
  local deck_target_idx = player:deck_idxs_with_preds({pred.seeker})[1]
  if deck_target_idx then
    local sent_card = player.deck[deck_target_idx]
    player:deck_to_hand(deck_target_idx)
    OneBuff(player, my_idx, {sta={"+", sent_card.size}}):apply()
  end
  my_card:remove_skill_until_refresh(skill_idx)
end,

-- knight lukif
[1116] = function(player, my_idx, my_card, skill_idx)
  if player.character.faction == "C" then
    local knight_target = player:hand_idxs_with_preds({pred.knight})[1]
    local nonknight_target = player:hand_idxs_with_preds({pred.C, function(card) return not pred.knight(card) end})[1]
    if knight_target and nonknight_target then
      player:hand_to_bottom_deck(nonknight_target)
      knight_target = player:hand_idxs_with_preds({pred.knight})[1]
      player:hand_to_bottom_deck(knight_target)
      local other_target = uniformly(player.opponent:get_follower_idxs())
      if other_target then
        player.opponent:field_to_bottom_deck(other_target)
      end
      my_card:remove_skill(skill_idx)
    end
  end
end,

-- sommelier sigma, holy beast's blessing
[1117] = function(player)
  if player.character.faction == "C" then
    for i=1,2 do
      local target_idx = uniformly(player:hand_idxs_with_preds({pred.follower}))
      if target_idx then
        OneBuff(player, target_idx, {atk="+",1}, sta={"+",1}):apply()
      end
    end
  end
end,

-- crux nemesis luthica, price of betrayal
[1118] = function(player, my_idx)
  local buff_size = #player:hand_idxs_with_preds({pred.follower})
  OneBuff(player, my_idx, {atk={"+",buff_size}, sta={"+",buff_size}}):apply()
  if buff_size > 0 then
    local hand_target_idx = player:hand_idxs_with_preds({pred.follower})[1]
    player:hand_to_top_deck(hand_target_idx)
  end
end,

-- gs agent, agent call
[1119] = function(player, my_idx, my_card, skill_idx)
  local deck_target_idx = player:deck_idxs_with_preds({pred.gs})[1]
  if deck_target_idx then
    player:deck_to_field(deck_target_idx)
  end
  my_card:remove_skill(skill_idx)
end,

-- gs colonel z, full retreat
[1120] = function(player, my_idx, my_card)
  local field_target_idxs = player:field_idxs_with_preds({pred.gs, function(card) return card ~= my_card end})
  local hand_target_idxs = player:hand_idxs_with_preds({pred.gs})
  if #field_target_idxs > 0 or #hand_target_idxs > 0 then
    local buff_size = #field_target_idxs + #hand_target_idxs
    for _,idx in ipairs(field_target_idxs) do
      player:field_to_bottom_deck(idx)
    end
    while #hand_target_idxs > 0 do
      player:hand_to_bottom_deck(hand_target_idxs[1])
      hand_target_idxs = player:hand_idxs_with_preds({pred.gs})
    end
    OneBuff(player, my_idx, {atk={"+",buff_size}, sta={"+",buff_size}}):apply()
  end
end,

-- crescent elder chenin
[1121] = function(player, my_idx, my_card, skill_idx)
  if player.character.faction == "D" then
    local crescent_target = player:hand_idxs_with_preds({pred.crescent})[1]
    local noncrescent_target = player:hand_idxs_with_preds({pred.D, pred.neg(pred.crescent)})[1]
    if crescent_target and noncrescent_target then
      player:hand_to_bottom_deck(noncrescent_target)
      crescent_target = player:hand_idxs_with_preds({pred.crescent})[1]
      player:hand_to_bottom_deck(crescent_target)
      local other_target = uniformly(player.opponent:get_follower_idxs())
      if other_target then
        player.opponent:field_to_bottom_deck(other_target)
      end
      my_card:remove_skill(skill_idx)
    end
  end
end,

-- dark master vernika, moonlight conquest
[1122] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card then
    local sizes = {}
    for i=1,#player.hand do
      sizes[player.hand[i].size] = true
    end
    local buff_size = 0
    for i=1,10 do
      if sizes[i] then buff_size = buff_size + 1 end
    end
    local buff = GlobalBuff(player)
    buff.field[player.opponent][other_idx] = {atk={"-",buff_size}, sta={"-",buff_size}}
    buff.field[player][0] = {life={"+", math.ceil(buff_size/2)}}
  end
  my_card:remove_skill_until_refresh(skill_idx)
end,

-- vampire hunter iri, power of the eyes
[1123] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card then
    local buff_size = 2 + math.abs(my_card.size - other_card.size)
    OneBuff(player, my_idx, {atk={"+",buff_size}, sta={"+",buff_size}}):apply()
  end
  my_card:remove_skill_until_refresh(skill_idx)
end,

-- l. rio, true courage
[1124] = function(player, my_idx)
  OneBuff(player, my_idx, {atk={"+",2}}):apply()
end,

-- summer santa ninian, comeback
[1125] = function(player, my_idx, my_card, skill_idx)
  if not my_card.active then
    my_card.active = true
    my_card:remove_skill_until_refresh(skill_idx)
  end
end,

-- seeker lydia, knight's contract
[1126] = function(player, my_idx)
  local buff_size = #player:field_idxs_with_preds({pred.C})
  OneBuff(player, my_idx, {def={"=",buff_size}, sta={"+",buff_size}}):apply()
end,

-- luna flina, moon power
[1127] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card and #player:field_idxs_with_preds({pred.D}) >= 2 then
    OneBuff(player.opponent, other_idx, {atk={"-",1}, def={"-",2} sta={"-",1}}):apply()
  end
end,

}


setmetatable(skill_func, {__index = function() return function() end end})
