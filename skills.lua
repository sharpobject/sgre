local floor,ceil,min,max = math.floor, math.ceil, math.min, math.max
local abs = math.abs
local random = math.random

local refresh = function(player, my_idx, my_card)
  my_card:refresh()
end

local lesprit = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if not other_card then
    return
  end
  local removed = pred.skill(other_card)
  other_card.skills = {}
  if removed then
    OneBuff(player, my_idx, {atk={"+",2}, def={"+",0}, sta={"+",2}}):apply()
  end
end

local esprit = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if not other_card then
    return
  end
  local removed = pred.skill(other_card)
  other_card.skills = {}
  if removed then
    OneBuff(player, my_idx, {atk={"+",1}, def={"+",1}, sta={"+",1}}):apply()
  end
end

local dressup_skill = function(dressup_id, player, my_idx)
  local dressup = function(card) return card.id == dressup_id end
  local field_idxs = player:field_idxs_with_preds({dressup})
  for _,idx in ipairs(field_idxs) do
    player:field_to_grave(idx)
  end
  local dressup_target = player:deck_idxs_with_preds({dressup})[1]
  if dressup_target and player:first_empty_field_slot() then
    player:deck_to_field(dressup_target)
    dressup_target = player:field_idxs_with_preds({dressup})[1]
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
  local hand_target = player:hand_idxs_with_preds(pred.dress_up)[1]
  if hand_target then
    player:hand_to_grave(hand_target)
    buff = true
  end
  local grave_target = player:grave_idxs_with_preds(pred.dress_up)[1]
  if grave_target then
    player:grave_to_exile(grave_target)
    buff = true
  end
  if buff then
    if buff_type == "-" then
      if not player.opponent.field[other_idx] then
        return
      end
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
end

local council_scoop = function(group_pred)
  return function(player, my_idx, my_card, skill_idx, other_idx, other_card)
    local target = player:deck_idxs_with_preds(pred.follower, group_pred)[1]
    if target and #player.hand < 5 then
      player:deck_to_hand(target)
    end
  end
end

local member_use = function(group_pred)
  return function(player, my_idx, my_card, skill_idx, other_idx, other_card)
    local target = player:hand_idxs_with_preds(group_pred)[1]
    if target then
      player:hand_to_bottom_deck(target)
      OneBuff(player, my_idx, {atk={"+",1},sta={"+",2}}):apply()
    end
  end
end

skill_func = {
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
    buff.field[player][my_idx] = {def={"+",1}, sta={"-",1}}
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
  local libs = #player:hand_idxs_with_preds({pred.library_club})
  if libs > 0 then
    local buff = GlobalBuff(player)
    buff.field[player][my_idx] = {atk={"+",libs}}
    buff:apply()
  end
end,

-- lib vernika, sita's friend rosie, 25 agent nine, seeker luthera, lost doll, best defense
[1006] = function(player, my_idx)
  local buff = GlobalBuff(player)
  buff.field[player][my_idx] = {sta={"+",2}}
  buff:apply()
end,

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
  if other_card and other_card.def >= 2 then
    local buff = GlobalBuff(player)
    buff.field[player.opponent][other_idx] = {sta={"-",3}}
    buff:apply()
  end
end,

--private maid, true caring
[1011] = function(player)
  local target_idx = uniformly(player.opponent:field_idxs_with_preds(pred.follower))
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
[1013] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if not other_card then
    return
  end
  local buff = GlobalBuff(player)
  buff.field[player.opponent][other_idx] = {sta={"-",1}}
  buff:apply()
end,

-- flag knight frett, flag return
[1014] = function(player)
  if player.field[3] and player.field[3].type == "follower" then
    local buff = GlobalBuff(player)
    buff.field[player][3] = {atk={"+",1}, sta={"+",1}}
    buff:apply()
  end
end,

-- knight adjt. sarisen, sisters in arms
[1015] = function(player, my_idx, my_card)
  local idxs = player:field_idxs_with_preds({pred.knight, pred.follower,
    function(card) return card ~= my_card end})
  if #idxs > 0 then
    local buff = OnePlayerBuff(player)
    for _,idx in ipairs(idxs) do
      buff[idx] = {atk={"+",1}, sta={"+",1}}
    end
    buff:apply()
  end
end,

-- crux knight pintail, contract witch, surprise!
[1016] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card and other_card.size < my_card.size then
    local buff = GlobalBuff(player)
    buff.field[player][my_idx] = {atk={"+",1}, def={"+",1}}
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
[1019] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if #player:field_idxs_with_preds(pred.C) >= 2 and other_card then
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
  local target_idxs = player:field_idxs_with_preds({pred.union(pred.shion_flina, pred.rion_flina), pred.follower})
  local buff = OnePlayerBuff(player)
  for _,idx in ipairs(target_idxs) do
    buff[idx] = {atk={"+",1}}
  end
  buff:apply()
end,

-- scardel rion flina, rion defense!
[1022] = function(player)
  local target_idxs = player:field_idxs_with_preds({pred.union(pred.shion_flina, pred.rion_flina), pred.follower})
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
  if #player:field_idxs_with_preds({pred.faction.D,pred.follower}) >= 2 then
    local target_idx = uniformly(player.opponent:field_idxs_with_preds({pred.follower}))
    if target_idx then
      OneBuff(player.opponent, target_idx, {sta={"-",2}}):apply()
    end
  end
end,

-- master luna flina, moon guardian
[1025] = function(player, my_idx)
  local new_def = #player:field_idxs_with_preds({pred.faction.D})
  OneBuff(player, my_idx, {def={"=",new_def}, sta={"+",new_def}}):apply()
end,

-- red moon aka flina, cook club ace, silent maid, seeker director, lantern witch,
-- coin lady, reverse defense
[1026] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if not other_card then
    return
  end
  local diff = min(9,abs(other_card.def))
  OneBuff(player, my_idx, {atk={"+",diff}, def={"=",0}, sta={"+",diff}}):apply()
end,

-- blue moon becky flina, chilly blood
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
  buff:apply()
end,

-- episode 2 follower skills

-- lib. milka, book return
[1028] = function(player)
  local target_idx = uniformly(player:field_idxs_with_preds({pred.library_club, pred.follower}))
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
  local target_idxs = player:field_idxs_with_preds({pred.student_council, pred.follower})
  for _,idx in ipairs(target_idxs) do
    buff[idx] = {sta={"+",2}}
  end
  buff:apply()
  my_card:remove_skill(skill_idx)
end,

-- council pres. celine, presidential power
[1031] = function(player, my_idx)
  local target_idx = uniformly(player:hand_idxs_with_preds({pred.student_council}))
  if target_idx then
    player:hand_to_top_deck(target_idx)
    OneBuff(player, my_idx, {atk={"+",1}, sta={"+",2}}):apply()
  end
end,

-- insomniac nanasid, insomnia
[1033] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local buff = GlobalBuff(player)
  buff.field[player][my_idx] = {atk={"+",2}, def={"-", 1}}
  if other_card then
    buff.field[player.opponent][other_idx] = {atk={"-",2}}
  end
  buff:apply()
  my_card:remove_skill(skill_idx)
end,

-- traumatized hilde, sad memory
[1034] = function(player, my_idx, my_card)
  if my_card.atk > 0 then
    local target_idxs = shuffle(player:get_follower_idxs())
    local buff = OnePlayerBuff(player)
    buff[my_idx] = {atk={"-",1}}
    for i=1,math.min(2, #target_idxs) do
      if buff[target_idxs[i]] then
        buff[target_idxs[i]].sta = {"+",2}
      else
        buff[target_idxs[i]] = {sta={"+",2}}
      end
    end
    buff:apply()
  end
end,

-- stigma flint, stigma
[1035] = function(player)
  local ally_target_idx = player:field_idxs_with_preds(
      function(card) return card.id == 300090 end)[1]
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
    for i=1,2 do
      local grave_target_idx = uniformly(player:grave_idxs_with_preds({pred.A}))
      if grave_target_idx then
        player:grave_to_exile(grave_target_idx)
      end
    end
    for i=1,math.min(2,#opp_target_idxs) do
      buff[opp_target_idxs[i]] = {atk={"-",1}, def={"-",1}, sta={"-",2}}
    end
    buff:apply()
  end
end,

-- stigma witness felicia, proof of stigma
[1037] = function(player)
  local target_idxs = player:field_idxs_with_preds(
      function(card) return card.id == 300087 end)
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
    for i=1,2 do
      local grave_idx = uniformly(player:grave_idxs_with_preds(pred.C))
      if grave_idx then
        player:grave_to_exile(grave_idx)
      end
    end
    local buff = OnePlayerBuff(player)
    buff[my_idx] = {atk={"+",2}, sta={"+",2}}
    if target_idxs[1] ~= my_idx then
      buff[target_idxs[1]] = {atk={"+",1}, sta={"+",1}}
    elseif target_idxs[2] then
      buff[target_idxs[2]] = {atk={"+",1}, sta={"+",1}}
    end
    buff:apply()
  end
end,

-- cauldron witch, cauldron!
[1041] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if #player:field_idxs_with_preds(pred.follower, pred.D) > 1 and other_card then
    local buffsize = math.ceil(other_card.atk / 2)
    OneBuff(player, my_idx, {sta={"+",buffsize}}):apply()
    my_card:remove_skill(skill_idx)
  end
end,

-- tea party witch, pumpkin!
[1042] = function(player)
  local target_idxs = player:field_idxs_with_preds(pred.witch, pred.follower)
  local buff = OnePlayerBuff(player)
  for _,idx in ipairs(target_idxs) do
    buff[idx] = {sta={"+",1}}
  end
  buff:apply()
end,

-- heart stone witch, magic of the heart
[1043] = function(player, my_idx, my_card, skill_idx)
  local target_idxs = player:field_idxs_with_preds(pred.witch, pred.follower)
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
  local my_grave_idx = player:grave_idxs_with_preds(pred.follower)
  local op_idx = player.opponent:grave_idxs_with_preds(pred.follower)
  my_grave_idx = my_grave_idx[#my_grave_idx]
  op_idx = op_idx[#op_idx]
  if my_grave_idx then
    player:grave_to_exile(my_grave_idx)
    buffsize = buffsize + 1
  end
  if op_idx then
    player.opponent:grave_to_exile(op_idx)
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
[1046] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local amt = math.min(math.abs(my_card.size - my_card.def),5)
  if other_card then
    OneBuff(player.opponent, other_idx, {atk={"-",amt},
        def={"-",amt}, sta={"-",amt}}):apply()
  end
end,

-- episode 3 follower skills

-- genius student nanai, great power!
[1047] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if not other_card then
    return
  end
  local player_grave_idxs = player:grave_idxs_with_preds({function(card)
    return card.size == other_card.size end})
  local opp_grave_idxs = player.opponent:grave_idxs_with_preds(
      function(card) return card.size == other_card.size end)
  local buffsize = 0
  for i=#player_grave_idxs,1,-1 do
    player:grave_to_exile(i)
    buffsize = buffsize + 1
  end
  for i=#opp_grave_idxs,1,-1 do
    local idx = opp_grave_idxs[i]
    player.opponent:grave_to_exile(i)
    buffsize = buffsize + 1
  end
  if buffsize > 0 then
    OneBuff(player.opponent, other_idx, {atk={"-",buffsize}, sta={"-",buffsize}}):apply()
  end
end,

-- lib. daisy, agent maid, arcana i magician, crescent maze, null defense!
[1048] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card and other_card.def >= 1 then
    OneBuff(player.opponent, other_idx, {def={"=",0}}):apply()
    my_card:remove_skill_until_refresh(skill_idx)
  end
end,

-- lib. manager lotte, cultist maid, seeker ruth, dollmaster elfin rune, amnesia
[1049] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card and pred.skill(other_card) then
    other_card.skills = {}
    my_card:remove_skill(skill_idx)
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
  local target_idxs = player:field_idxs_with_preds({pred.follower})
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
  while #player.deck > 0 and #player.hand < 4 do
    player:draw_a_card()
  end
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

-- council event inspector, guidance
[1055] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  OneBuff(player, my_idx, {sta={"+",1}}):apply()
end,

-- space fold
[1056] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local slot = player.opponent:first_empty_field_slot()
  if slot then
    player.opponent.field[slot] = my_card
    player.field[my_idx] = nil
    my_card:remove_skill(skill_idx)
  end
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
  local target = uniformly(player:grave_idxs_with_preds())
  if target then
    player:grave_to_exile(target)
  end
  target = uniformly(player:grave_idxs_with_preds())
  if target then
    player:grave_to_bottom_deck(target)
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
    local amt = 5
    if player.character.life < player.opponent.character.life then
      amt = 8
    end
    OneBuff(player, 0, {life={"+",amt}}):apply()
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
  while #player.opponent.hand < 5 and #player.opponent.deck > 0 do
    player.opponent:draw_from_bottom_deck()
  end
  OneBuff(player, my_idx, {sta={"+",2}}):apply()
end,

-- arbiter rivelta answer, friendly advice
[1065] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if my_card.faction == player.character.faction then
    local sent = math.min(#player.grave, 5)
    if sent > 0 then
      for i=1,sent do
        player:grave_to_bottom_deck(math.random(#player.grave))
      end
      if other_card then
        OneBuff(player.opponent, other_idx, {atk={"-",math.ceil(sent/2)}}):apply()
      end
    end
    my_card:remove_skill(skill_idx)
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
      buff[idx] = {atk={"+",3}, sta={"+",3}}
    end
    buff:apply()
    my_card:remove_skill(skill_idx)
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
        OneBuff(player, field_idx, {size={"=",my_card.size+1},
            atk={"+",buff_size}, sta={"+",buff_size}}):apply()
      end
    end
    my_card:remove_skill(skill_idx)
  end
end,

-- sweet lady isfeldt, energy supplement
[1072] = function(player, my_idx)
  OneBuff(player, my_idx, {sta={"+",2}}):apply()
end,

-- sweet lady isfeldt, sweet spell
[1073] = function(player, my_idx, my_card, skill_idx)
  my_card.skills[skill_idx] = 1076
end,

-- sweet lady isfeldt, sweet count
[1074] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if not other_card then
    return
  end
  if other_card.size <= my_card.size then
    player.opponent:field_to_top_deck(other_idx)
    my_card.skills[skill_idx] = 1073
  end
end,

-- lib. student, dispatch maid, blue cross member, gs recon, heavy burden
[1075] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if not other_card then
    return
  end
  OneBuff(player.opponent, other_idx, {size={"+",1}}):apply()
  my_card:remove_skill(skill_idx)
end,

[1076] = refresh,

-- council student, meeting prep!
[1077] = function(player, my_idx, my_card, skill_idx)
  local target_idx = player:field_idxs_with_preds({pred.follower, pred.student_council})[1]
  if target_idx then
    OneBuff(player, target_idx, {sta={"+",3}}):apply()
    my_card:remove_skill(skill_idx)
  end
end,

-- sleep club advisor, time for bed
[1078] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card then
    other_card.active = false
  end
  my_card:remove_skill(skill_idx)
end,

-- council weekly help, seize
[1079] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if not other_card then
    return
  end
  local buff = GlobalBuff(player)
  buff.field[player][my_idx] = {atk={"=",other_card.atk}}
  buff.field[player.opponent][other_idx] = {atk={"=",my_card.atk}}
  buff:apply()
end,

-- lib. milty, book management?
[1080] = function(player, my_idx)
  local sta_buff, atk_buff = #player:hand_idxs_with_preds({pred.library_club}), 0
  if sta_buff >= 3 then
    atk_buff = 1
  end
  OneBuff(player, my_idx, {atk={"+",atk_buff}, sta={"+",sta_buff}}):apply()
end,

-- council vp tieria, campaign prep
[1081] = function(player, my_idx, my_card, skill_idx)
  local buff_size = 1 + #player:field_idxs_with_preds({pred.student_council})
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
        function(card) return not card.active end}))
      local target2_idx = uniformly(player:get_follower_idxs())
      if target1_idx then
        player.field[target1_idx].active = true
      end
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
  local deck_idx = player:deck_idxs_with_preds({lucerrie})[1]
  local field_idx = player:first_empty_field_slot()
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
  local hand_target = player:hand_idxs_with_preds({pred.dress_up})[1]
  if hand_target then
    player:hand_to_grave(hand_target)
    buff = true
  end
  local grave_target = player:grave_idxs_with_preds({pred.dress_up})[1]
  if grave_target then
    player:grave_to_exile(grave_target)
    buff = true
  end
  if buff and #player.opponent.hand > 0 then
    local opp_target = math.random(#player.opponent.hand)
    player.opponent:hand_to_grave(opp_target)
  end
end,

-- meteor call lady, meteor call
[1086] = function(player, my_idx, my_card, skill_idx)
  local op_idx = uniformly(player.opponent:get_follower_idxs())
  local buff_size = 1 + #player:field_idxs_with_preds(pred.lady)
  if op_idx then
    OneBuff(player.opponent, op_idx, {sta={"-",buff_size}}):apply()
  end
  my_card:remove_skill_until_refresh(skill_idx)
end,

-- picnic maid, faith and trust
[1087] = function(player, my_idx, my_card, skill_idx)
  local opp_target_idx = uniformly(player.opponent:get_follower_idxs())
  local buff_size = #player:hand_idxs_with_preds({function(card)
    return pred.maid(card) or pred.lady(card) end})
  if opp_target_idx and buff_size > 0 then
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
        function(card) return not card.active end}))
      local target2_idx = uniformly(player.opponent:get_follower_idxs())
      if target1_idx then
        player.field[target1_idx].active = true
      end
      if target2_idx then
        OneBuff(player.opponent, target2_idx, {size={"+",1}, atk={"-",1}, sta={"-",2}}):apply()
      end
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
[1093] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if not other_card then
    return
  end
  local buff_size = #player:hand_idxs_with_preds(pred.seeker)
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
        function(card) return not card.active end}))
      local target2_idx = uniformly(player:get_follower_idxs())
      if target1_idx then
        player.field[target1_idx].active = true
      end
      OneBuff(player, target2_idx, {size={"-",1}, atk={"+",1}, sta={"+",2}}):apply()
    end
  end
end,

-- sion flina, dress up
[1095] = function(player, my_idx)
  local rion_idx = player:deck_idxs_with_preds(pred.rion_flina)[1]
  local dressup_func = function(card) return card.id == 300198 end
  local dressup_idx = player:deck_idxs_with_preds(dressup_func)[1]
  if rion_idx and dressup_idx then
    player:field_to_grave(my_idx)
    player:deck_to_grave(rion_idx)
    local field_idx = player:first_empty_field_slot()
    dressup_idx = player:deck_idxs_with_preds(dressup_func)[1]
    if dressup_idx then
      player:deck_to_field(dressup_idx)
      OneBuff(player, field_idx, {size={"=",5}, atk={"+",3}, sta={"+",3}}):apply()
    end
  end
end,

-- rion flina, dress up
[1096] = function(player, my_idx)
  local sion_idx = player:deck_idxs_with_preds(pred.shion_flina)[1]
  local dressup_func = function(card) return card.id == 300198 end
  local dressup_idx = player:deck_idxs_with_preds(dressup_func)[1]
  if sion_idx and dressup_idx then
    player:field_to_grave(my_idx)
    player:deck_to_grave(sion_idx)
    local field_idx = player:first_empty_field_slot()
    dressup_idx = player:deck_idxs_with_preds(dressup_func)[1]
    if dressup_idx then
      player:deck_to_field(dressup_idx)
      OneBuff(player, field_idx, {size={"=",5}, atk={"+",3}, sta={"+",3}}):apply()
    end
  end
end,

-- gs alla marcia, gs march
[1097] = function(player, my_idx, my_card, skill_idx)
  local deck_idx = player:deck_idxs_with_preds({function(card)
    return card.id == 300193 end})[1]
  local field_idx = player:first_empty_field_slot()
  if deck_idx and field_idx then
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
    player:hand_to_bottom_deck(1)
    local grave_idx = uniformly(player:grave_idxs_with_preds(pred.union(pred.shion, pred.rion)))
    if grave_idx then
      player:grave_to_exile(grave_idx)
      local buff = GlobalBuff(player)
      buff.field[player][0] = {life={"+",1}}
      buff.field[player.opponent][0] = {life={"-",1}}
      buff:apply()
    end
  end
end,

-- office witch, bean curse
[1099] = function(player, my_idx, my_card, skill_idx)
  if player.opponent:ncards_in_field() % 2 == 0 then
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
        function(card) return not card.active end}))
      local target2_idx = uniformly(player.opponent:get_follower_idxs())
      if target1_idx then
        player.field[target1_idx].active = true
      end
      if target2_idx then
        OneBuff(player.opponent, target2_idx, {size={"+",1}, atk={"-",1}, def={"-",1}}):apply()
      end
    end
  end
end,

-- 1st witness kana.dkd, just give up
[1101] = function(player, my_idx, my_card)
  if my_card.def >= 1 then
    OneBuff(player, my_idx, {def={"-",1}}):apply()
    if #player.deck > 0 and player.deck[#player.deck].faction == player.character.faction and
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
    local deck_target_idx = player:deck_idxs_with_preds({pred.library_club})[1]
    if deck_target_idx then
      player:deck_to_hand(deck_target_idx)
      my_card:remove_skill_until_refresh(skill_idx)
    end
  end
end,

-- lib. milka, guitar!
[1105] = function(player, my_idx, my_card, skill_idx)
  local target_idx = player:field_idxs_with_preds({pred.library_club, pred.follower})[1]
  if target_idx then
    OneBuff(player, target_idx, {sta={"+",2}}):apply()
  end
  my_card:remove_skill_until_refresh(skill_idx)
end,

-- lib. h.l. tezina, i'll help you.
[1106] = function(player, my_idx, my_card, skill_idx)
  if player.character.faction == "V" then
    local lib_target = player:hand_idxs_with_preds({pred.V, pred.library_club})[1]
    local other_target = player:hand_idxs_with_preds({pred.V, function(card) return not pred.library_club(card) end})[1]
    if lib_target and other_target then
      player:hand_to_bottom_deck(lib_target)
      other_target = player:hand_idxs_with_preds({pred.V, function(card) return not pred.library_club(card) end})[1]
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
  if other_card and (pred.A(other_card) or pred.D(other_card)) then
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
    local deck_target_idx = player:deck_idxs_with_preds({pred.lady})[1]
    if deck_target_idx then
      player:deck_to_hand(deck_target_idx)
    end
  end
  my_card:remove_skill_until_refresh(skill_idx)
end,

-- drum maid, power of music
[1110] = function(player, my_idx, my_card)
  local func = function(card) return pred.guitar(card) or pred.bass(card) end
  if #player:hand_idxs_with_preds(func) > 0 or #player:field_idxs_with_preds(func) > 0 then
    local hand_idx = player:hand_idxs_with_preds(func)[1]
    if hand_idx then
      player:hand_to_exile(hand_idx)
      player:field_to_exile(my_idx)
    else
      player:field_to_exile(my_idx)
      local field_idx = player:field_idxs_with_preds(func)[1]
      if field_idx then
        player:field_to_exile(field_idx)
      end
    end
    local other_idxs = player.opponent:hand_idxs_with_preds({pred.follower})
    while other_idxs[1] do
      player.opponent:hand_to_grave(other_idxs[1])
      other_idxs = player.opponent:hand_idxs_with_preds({pred.follower})
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
  if other_card and other_card.size >= my_card.size then
    my_card:remove_skill(skill_idx)
    local buff = GlobalBuff(player)
    buff.field[player][my_idx] = {atk={"-",2}, sta={"-",2}}
    buff.field[player.opponent][other_idx] = {atk={"+",2}, sta={"+",2}}
    buff:apply()
    player.deck[#player.deck+1] = other_card
    player.opponent.field[other_idx] = nil
    if player.field[my_idx] == my_card then
      player.field[my_idx] = nil
      player.opponent.deck[#player.opponent.deck+1] = my_card
    end
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
  if #player.hand <= 2 then
    while #player.hand < 4 and #player.deck > 0 do
      player:draw_a_card()
    end
  else
    my_card:remove_skill(skill_idx)
  end
end,

-- seeker odien, seeker call
[1115] = function(player, my_idx, my_card, skill_idx)
  local deck_target_idx = player:deck_idxs_with_preds({pred.seeker})[1]
  if deck_target_idx and #player.hand < 5 then
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
        local buff = GlobalBuff(player)
        buff.hand[player][target_idx] = {atk={"+",1}, sta={"+",1}}
        buff:apply()
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
  local slot = player:first_empty_field_slot()
  if deck_target_idx and slot then
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
    buff:apply()
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
    OneBuff(player.opponent, other_idx, {atk={"-",1}, def={"-",2}, sta={"-",1}}):apply()
  end
end,

-- tennis ace, beach volleyball lady, messenger knight, scardel unit felgus, ignore defense
[1128] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card then
    OneBuff(player.opponent, other_idx, {sta={"-",other_card.def}}):apply()
  end
end,

-- cook club elfsi, perfect lady, blue cross noel, gs spy, everything is ready
[1129] = function(player, my_idx, my_card)
  if my_card.active then
    OneBuff(player, my_idx, {atk={"+",1}, sta={"+",1}}):apply()
  end
end,

-- council exec. maron, ice lady, quartermaster knight, gs 1st star, our virtue
[1130] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card then
    if my_card.faction ~= other_card.faction then
      local buff = GlobalBuff(player)
      buff.field[player][my_idx] = {atk={"+",1}, sta={"+",1}}
      buff.field[player.opponent][other_idx] = {atk={"-",1}, sta={"-",1}}
      buff:apply()
    end
  end
end,

-- council roroa, memory block
[1131] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card and pred.skill(other_card) then
    other_card.skills = {1076}
  end
end,

-- tennis lure, scramble
[1132] = function(player)
  local my_target_idx = uniformly(player:get_follower_idxs())
  local other_target_idx = uniformly(player.opponent:get_follower_idxs())
  if my_target_idx and other_target_idx then
    local my_target = player.field[my_target_idx]
    local other_target = player.opponent.field[other_target_idx]
    local swap = my_target.skills
    my_target.skills = other_target.skills
    other_target.skills = swap
  end
end,

-- council coordinator, event swap
[1133] = function(player, my_idx, my_card, skill_idx)
  local target_idxs = player:field_idxs_with_preds(pred.follower, pred.V)
  local buff = OnePlayerBuff(player)
  for _,idx in ipairs(target_idxs) do
    buff[idx] = {atk={"+",2}}
  end
  buff:apply()
  my_card:remove_skill(skill_idx)
end,

-- campus waitress, best service
[1134] = function(player, my_idx, my_card)
  if my_card.atk >= 1 then
    OneBuff(player, my_idx, {atk={"-",1}, def={"+",1}, sta={"+",1}}):apply()
  end
end,

-- guitar maid, voice of music
[1135] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card and not other_card.active then
    OneBuff(player.opponent, other_idx, {atk={"-",1}, def={"-",1}, sta={"-",1}}):apply()
  end
end,

-- rainbow lady, rainbow magic
[1136] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card then
    local buff_size = math.min(math.abs(my_card.atk - other_card.atk), 5)
    OneBuff(player.opponent, other_idx, {def={"-",buff_size}}):apply()
  end
  my_card:remove_skill(skill_idx)
end,

-- 2s sink queen 571, submerge
[1137] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local deactivated = 0
  for _,idx in ipairs({my_idx -1, my_idx, my_idx + 1}) do
    if idx > 0 and idx <= 5 and player.field[idx] then
      player.field[idx].active = false
      deactivated = deactivated + 1
    end
  end
  if deactivated > 1 and other_card then
    player.opponent:field_to_bottom_deck(other_idx)
    my_card:remove_skill(skill_idx)
  end
end,

-- mist lady, mist sorcery
[1138] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card then
    other_card.atk = id_to_canonical_card[other_card.id].atk
    other_card.def = id_to_canonical_card[other_card.id].def
    other_card.sta = id_to_canonical_card[other_card.id].sta
  end
  my_card:remove_skill(skill_idx)
end,

-- knight manager, equipment check
[1139] = function(player)
  local target_idx = uniformly(player:field_idxs_with_preds({pred.follower, pred.knight}))
  if target_idx then
    OneBuff(player, target_idx, {size={"-",1}}):apply()
  end
end,

-- blue cross elda, blue cross mission
[1140] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card and other_card.size >= 4 then
    OneBuff(player, my_idx, {sta={"+",4}}):apply()
    my_card:remove_skill(skill_idx)
  end
end,

-- blue cross linda, blue cross business
[1141] = function(player, my_idx, my_card, skill_idx)
  blue_cross_skill(player, my_idx, my_card, skill_idx, {sta={"-",3}})
end,

-- blue cross lifreya, blue cross secret meeting
[1142] = function(player, my_idx, my_card, skill_idx)
  blue_cross_skill(player, my_idx, my_card, skill_idx, {atk={"-",2}})
end,

-- lightning witch, lightning trick
[1143] = function(player, my_idx)
  local rand = math.random(2)
  local buff = {}
  if rand == 1 then
    buff = {size={"+",1}}
  else
    buff = {size={"-",2}}
  end
  OneBuff(player, my_idx, buff):apply()
end,

-- gs fighting instructor, camaraderie
[1144] = function(player)
  local gs_target_idxs = player:field_idxs_with_preds({pred.gs, pred.follower})
  local nongs_target_idxs = player:field_idxs_with_preds({pred.neg(pred.gs), pred.follower})
  local buff = OnePlayerBuff(player)
  for _,idx in ipairs(gs_target_idxs) do
    buff[idx] = {atk={"+",1}, sta={"+",1}}
  end
  for _,idx in ipairs(nongs_target_idxs) do
    buff[idx] = {atk={"-",1}, sta={"-",1}}
  end
  buff:apply()
end,

-- creepy witch, blood relation
[1145] = function(player, my_idx, my_card)
  if my_card.def > 0 then
    OneBuff(player, my_idx, {def={"-",1}}):apply()
  end
end,

-- crescent unit azoth, blood relation
[1146] = function(player, my_idx)
  local buff_size = #player:field_idxs_with_preds({pred.scardel})
  OneBuff(player, my_idx, {sta={"+",buff_size}}):apply()
end,

-- creepy witch, chrome shelled magic
[1147] = function(player, my_idx, my_card, skill_idx)
  local buff_size = my_card.def
  OneBuff(player, my_idx, {atk={"+",buff_size}, sta={"+",buff_size}}):apply()
  my_card:remove_skill_until_refresh(skill_idx)
end,

-- 2nd witness kana.dnd, liquor of kana
[1148] = function(player, my_idx, my_card)
  local field_target_idx = uniformly(player.opponent:field_idxs_with_preds())
  if field_target_idx then
    player.opponent:field_to_exile(field_target_idx)
  end
  if #player.opponent.hand > 0 then
    local hand_target_idx = math.random(#player.opponent.hand)
    player.opponent:hand_to_exile(hand_target_idx)
  end
  if #player.opponent.grave > 0 then
    local grave_target_idx = math.random(#player.opponent.grave)
    player.opponent:grave_to_exile(grave_target_idx)
  end
  for _,stat in ipairs({"atk", "def", "sta"}) do
    my_card[stat] = id_to_canonical_card[my_card.id][stat]
  end
end,

-- sword's shield
[1149] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card then
    OneBuff(player, my_idx, {sta={"+",other_card.atk}}):apply()
  end
  my_card:remove_skill(skill_idx)
end,

-- reset hour
[1150] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local clone = Card(my_card.id)
  OneBuff(player, my_idx, {atk={"=",clone.atk},def={"=",clone.def},sta={"=",clone.sta}}):apply()
  my_card:remove_skill(skill_idx)
end,

-- death
[1151] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  player:field_to_grave(my_idx)
end,

-- lib. advisor, chain strike
[1152] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local targets = player:deck_idxs_with_preds(function(card) return card.id == my_card.id end)
  for _,idx in ipairs(targets) do
    player:deck_to_grave(idx)
  end
  local n = #targets
  OneBuff(player, my_idx, {atk={"+",n},def={"+",n},sta={"+",n*2}}):apply()
end,

-- cook club critic, unite
[1153] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local n = 0
  for _,idx in ipairs({my_idx-1,my_idx+1}) do
    local card = player.field[idx]
    if card and pred.follower(card) and pred[my_card.faction](card) then
      n = n + 1
    end
  end
  OneBuff(player, my_idx, {atk={"+",ceil(n/2)},sta={"+",n}}):apply()
end,

-- council press winfield, council scoop
[1154] = council_scoop(pred.student_council),

-- council press winfield, member use
[1155] = member_use(pred.student_council),

-- lunia scentriver, skill copy
[1156] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local n = 0
  local skills = other_card and other_card:squished_skills() or {}
  for i=1,2 do
    if skills[i] then
      n = n + 1
    end
    my_card.skills[i+1] = skills[i]
  end
  OneBuff(player, my_idx, {atk={"+",n},sta={"+",n}}):apply()
end,

-- occult lady charlotte, i'm taking you with me
[1157] = function(player, my_idx, my_card, skill_idx)
  local size = my_card.size
  player:field_to_grave(my_idx)
  local target = uniformly(player.opponent:field_idxs_with_preds(
      function(card) return card.size >= size end))
  if target then
    player.opponent:field_to_grave(target)
  end
end,

-- envy lady, social meeting
[1158] = council_scoop(pred.lady),

-- envy lady, peer use
[1159] = member_use(pred.lady),

-- shock lady elberto, shock!
[1160] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local buff = GlobalBuff(player)
  for _,idx in ipairs(player.opponent:field_idxs_with_preds(pred.follower)) do
    buff.field[player.opponent][idx] = {sta={"-",1}}
  end
  buff.field[player][my_idx] = {atk={"+",1}}
  buff:apply()
end,

-- shock lady elberto, shock!
[1161] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local buff = OnePlayerBuff(player.opponent)
  for _,idx in ipairs(player.opponent:field_idxs_with_preds(pred.follower)) do
    buff[idx] = {sta={"-",1}}
  end
  buff:apply()
end,

-- blue cross june, blue cross exchange
[1162] = function(player, my_idx, my_card, skill_idx)
  blue_cross_skill(player, my_idx, my_card, skill_idx, {atk={"-",4}})
end,

-- seeker melissa, seeker summon
[1163] = council_scoop(pred.seeker),

-- seeker melissa, comrade use
[1164] = member_use(pred.seeker),

-- seeker amethystar, enhance!
[1165] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  OneBuff(player, my_idx, {atk={"+",1},sta={"+",1}}):apply()
  my_card:remove_skill(skill_idx)
end,

-- seeker amethystar, enhance!
[1166] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  OneBuff(player, my_idx, {atk={"+",1},sta={"+",1}}):apply()
  my_card:remove_skill(skill_idx)
end,

-- seeker amethystar, enhance!
[1167] = function(player, my_idx, my_card, skill_idx)
  OneBuff(player, my_idx, {atk={"+",2},sta={"+",2}}):apply()
  my_card:remove_skill(skill_idx)
end,

-- crux knight swimie, knight strategy
[1168] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local sz = 0
  if #player.opponent.hand > 0 then
    sz = player.opponent.hand[1].size
  end
  OneBuff(player, my_idx, {atk={"+",sz},sta={"+",sz}}):apply()
  my_card:remove_skill_until_refresh(skill_idx)
end,

-- scardel unit gungnir, magic trap
[1169] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local target = uniformly(player.opponent:field_idxs_with_preds(pred.follower,
      function(card) return card ~= other_card end))
  if target then
    OneBuff(player.opponent, target, {atk={"-",1},sta={"-",1}}):apply()
  end
end,

-- gs 2nd star, gs summon
[1170] = council_scoop(pred.gs),

-- gs 2nd star, agent use
[1171] = member_use(pred.gs),

-- soul conductor charon, nether express
[1172] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local amt = 1
  if #player.grave + #player.opponent.grave >= 24 then
    amt = 3
  end
  OneBuff(player, my_idx, {atk={"+",amt},sta={"+",amt}}):apply()
end,

-- coin producer ritz, production switch
[1173] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local target = player.opponent:hand_idxs_with_preds(pred.follower)[1]
  if target then
    player.field[my_idx], player.opponent.hand[target] =
        player.opponent.hand[target], player.field[my_idx]
    player.game.combat_round_interrupted = true
  end
end,

-- blade tutor grace, charge!
[1174] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  OneBuff(player, my_idx, {atk={"+",2},sta={"+",2}}):apply()
  my_card:remove_skill_until_refresh(skill_idx)
end,

-- grave
[1175] = function(player, my_idx)
  player:field_to_grave(my_idx)
end,

-- sword girls sita, position change!
[1192] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local card_to_skill = {[300320]=1193,[300322]=1194,[300324]=1195,[300326]=1196,
                         [300875]=1822,[300877]=1824,[300879]=1826,[300881]=1828}
  local target_idx = player:deck_idxs_with_preds(pred.follower, pred.sword_girls)[1]
  local slot = player:first_empty_field_slot()
  if target_idx and slot then
    local target_card = player.deck[target_idx]
    if slot < my_idx then
      assert(card_to_skill[target_card.id])
      -- TODO: this probably still isn't quite right...
      target_card:gain_skill(card_to_skill[target_card.id])
    else
      for i=1,3 do
        if target_card.skills[i] == 1192 then
          target_card.skills[i] = nil
        end
      end
      target_card:gain_skill(1076)
    end
    player:deck_to_field(target_idx)
    OneBuff(player, slot, {sta={"+",3}}):apply()
    player:field_to_bottom_deck(my_idx)
  end
end,

-- sword girls sita, song of hope!
[1193] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local targets = player:field_idxs_with_preds(pred.follower)
  local buff = OnePlayerBuff(player)
  for _,idx in ipairs(targets) do
    buff[idx] = {atk={"+",2},sta={"+",1}}
  end
  buff:apply()
  my_card:remove_skill(skill_idx)
end,

-- sword girls cinia, song of cheer!
[1194] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local targets = player:field_idxs_with_preds(pred.follower)
  local buff = OnePlayerBuff(player)
  for _,idx in ipairs(targets) do
    buff[idx] = {sta={"+",3}}
  end
  buff[my_idx].size = {"-",1}
  buff:apply()
  my_card:remove_skill(skill_idx)
end,

-- sword girls luthica, song of will!
[1195] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local targets = player:field_idxs_with_preds(pred.follower)
  local buff = OnePlayerBuff(player)
  for _,idx in ipairs(targets) do
    buff[idx] = {def={"+",1},sta={"+",2}}
  end
  buff:apply()
  my_card:remove_skill(skill_idx)
end,

-- sword girls iri, song of love!
[1196] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local targets = player:field_idxs_with_preds(pred.follower)
  local buff = OnePlayerBuff(player)
  for _,idx in ipairs(targets) do
    buff[idx] = {size={"-",1}}
  end
  buff[my_idx].sta = {"+",2}
  buff:apply()
  my_card:remove_skill(skill_idx)
end,

-- animal suit sita, penguin strikes back
[1197] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local def,sta = {1,2,2},{1,2,3}
  local n = min(3,#player:field_idxs_with_preds(pred.sita))
  if n > 0 then
    OneBuff(player, my_idx, {def={"=",def[n]},sta={"+",sta[n]}}):apply()
  end
end,

-- animal suit cinia, panda beam!
[1198] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local atk,sta = {1,1,2},{1,2,3}
  local n = min(3,#player:field_idxs_with_preds(pred.cinia))
  if other_card and n > 0 then
    OneBuff(player.opponent, other_idx, {atk={"-",atk[n]},sta={"-",sta[n]}}):apply()
  end
end,

-- animal suit luthica, i want to be a bear!
[1199] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local atk,sta = {1,1,2},{1,2,3}
  local n = min(3,#player:field_idxs_with_preds(pred.luthica))
  if n > 0 then
    OneBuff(player, my_idx, {atk={"+",atk[n]},sta={"+",sta[n]}}):apply()
  end
end,

-- animal suit iri, ultimate rabbit
[1200] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local sta = {2,3,4}
  local n = min(3,#player:field_idxs_with_preds(pred.iri))
  if other_card and n > 0 then
    OneBuff(player.opponent, other_idx, {sta={"-",sta[n]}}):apply()
  end
end,

-- lethargy
[1201] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  OneBuff(player, my_idx, {atk={"-",1}}):apply()
end,

-- my liver...
[1202] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  OneBuff(player, my_idx, {sta={"-",3}}):apply()
end,

-- tough defense
[1203] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  OneBuff(player, my_idx, {sta={"+",3}}):apply()
end,

-- enhance defense
[1204] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  OneBuff(player, my_idx, {def={"+",2}}):apply()
end,

-- flash shield
[1205] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card then
    OneBuff(player, my_idx, {sta={"+",ceil(other_card.atk/2)}}):apply()
  end
  my_card:remove_skill(skill_idx)
end,

-- council press student, let's go, council!
[1206] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local targets = player:field_idxs_with_preds(pred.follower, pred.student_council)
  local buff = OnePlayerBuff(player)
  for _,idx in ipairs(targets) do
    buff[idx] = {atk={"+",1}}
  end
  buff:apply()
end,

-- council press student, come on, council!
[1207] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local targets = player:field_idxs_with_preds(pred.follower, pred.student_council)
  local buff = OnePlayerBuff(player)
  for _,idx in ipairs(targets) do
    buff[idx] = {sta={"+",1}}
  end
  buff:apply()
end,

-- producer maid, maid call
[1208] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local target = player:deck_idxs_with_preds(pred.follower, pred.maid)[1]
  if target and player:first_empty_field_slot() then
    local sz = player.deck[target].size
    player:deck_to_field(target)
    OneBuff(player, my_idx, {atk={"+",ceil(sz/2)},sta={"+",ceil(sz/2)}}):apply()
    my_card:remove_skill(skill_idx)
  end
end,

-- seeker irene, guardian artifact
[1209] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  OneBuff(player, my_idx, {atk={"+",3},sta={"+",3}}):apply()
  my_card:remove_skill(skill_idx)
  local target = player:deck_idxs_with_preds(pred.follower, pred.seeker,
      function(card)
        for i=1,3 do
          if card.skills[i] == 1209 then
            return false
          end
        end
        return true
      end)[1]
  if target then
    player.deck[target]:gain_skill(1209)
  end
end,

-- artisan baker witch, thirst for knowledge
[1210] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local target = uniformly(player:hand_idxs_with_preds(pred.follower, pred.witch))
  if target then
    local buff = GlobalBuff(player)
    buff.hand[player][target] = {size={"-",1}}
    buff:apply()
    local card = player.hand[target]
    my_card:gain_skill(card:squished_skills()[1])
  end
end,

-- council gart & sita, takoyaki and noodles
[1211] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local target = uniformly(player:field_idxs_with_preds(pred.follower, pred.V,
      function(card) return card ~= my_card end))
  if target then
    OneBuff(player, target, {atk={"+",random(3,5)},sta={"+",random(3,5)}}):apply()
    OneBuff(player, 0, {life={"-",1}}):apply()
    my_card:remove_skill_until_refresh(skill_idx)
  end
end,

-- cinia's new maid, accident!
[1212] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local target = uniformly(player:field_idxs_with_preds(pred.follower, pred.A,
      function(card) return card ~= my_card end))
  if target then
    local amt = #player:field_idxs_with_preds(pred.follower) +
        #player:hand_idxs_with_preds(pred.follower)
    amt = min(amt,5)
    OneBuff(player, target, {atk={"+",amt},sta={"+",amt}}):apply()
    OneBuff(player, 0, {life={"-",1}}):apply()
    my_card:remove_skill_until_refresh(skill_idx)
  end
end,

-- knight adjt. luthica, red sun
[1213] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local target = uniformly(player:field_idxs_with_preds(pred.follower, pred.C,
      function(card) return card ~= my_card end))
  if target then
    local amt = 0
    local with_def = player:field_idxs_with_preds(pred.follower,
        function(card) return card.def > 0 end)
    for _,idx in ipairs(with_def) do
      amt = amt + player.field[idx].def
    end
    amt = min(amt,5)
    OneBuff(player, target, {atk={"+",amt},sta={"+",amt}}):apply()
    OneBuff(player, 0, {life={"-",1}}):apply()
    my_card:remove_skill_until_refresh(skill_idx)
  end
end,

-- witch hunter becky flina, witch hunt
[1214] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local target = uniformly(player:field_idxs_with_preds(pred.follower, pred.D,
      function(card) return card ~= my_card end))
  if target then
    local amt = 0
    for i=1,#player.hand do
      amt = amt + player.hand[i].size
    end
    amt = min(ceil(amt/2),5)
    OneBuff(player, target, {atk={"+",amt},sta={"+",amt}}):apply()
    OneBuff(player, 0, {life={"-",1}}):apply()
    my_card:remove_skill_until_refresh(skill_idx)
  end
end,

-- fiona scentriver, delay!
[1215] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card and pred.skill(other_card) then
    other_card.skills = {1076}
  end
end,

-- fiona scentriver, delay!
[1216] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card and pred.skill(other_card) then
    other_card.skills = {1076}
  end
end,

-- fiona scentriver, delay!
[1217] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local target = uniformly(player.opponent:hand_idxs_with_preds(pred.follower))
  if target and pred.skill(player.opponent.hand[target]) then
    player.opponent.hand[target].skills = {1076}
  end
end,

-- guide rio, best attack
[1218] = function(player, my_idx)
  local buffsize = uniformly({1,2,3})
  OneBuff(player, my_idx, {atk={"+",buffsize}}):apply()
end,

-- guide rio, best defense
[1219] = function(player, my_idx)
  local buffsize = uniformly({1,2,3})
  OneBuff(player, my_idx, {sta={"+",buffsize}}):apply()
end,

-- lib. explorer rea, summon member!
[1220] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local target = uniformly(player:grave_idxs_with_preds(pred.library_club))
  if target then
    player:grave_to_bottom_deck(target)
  end
end,

-- lib. explorer kamit, underground exploration!
[1221] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local n = 0
  for i=1,min(4,#player.deck) do
    if pred.library_club(player.deck[i]) then
      n = n + 1
    end
  end
  OneBuff(player, my_idx, {atk={"+",floor(n/2)},sta={"+",n}}):apply()
end,

-- council press lyrica, press campaign!
[1222] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card then
    if other_card.atk <= #player:grave_idxs_with_preds(pred.follower, pred.V) then
      player.opponent:field_to_grave(other_idx)
    end
  end
end,

-- council press lyrica, guarantee!
[1223] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local target = player:grave_idxs_with_preds(pred.V, pred.follower)
  target = target[#target]
  if target then
    player:grave_to_exile(target)
  end
end,

-- dd lady tomo, lady ready!
[1224] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local n = #player:hand_idxs_with_preds(pred.lady) + #player:field_idxs_with_preds(
      pred.lady, function(card) return card ~= my_card end)
  OneBuff(player, my_idx, {atk={"+",floor(n/2)},sta={"+",n}}):apply()
end,

-- witch cadet zislana, witch cheer!
[1225] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local buff = GlobalBuff(player)
  buff.field[player][my_idx] = {sta={"+",1}}
  for _,idx in ipairs(player:hand_idxs_with_preds(pred.follower, pred.witch)) do
    buff.hand[player][idx] = {sta={"+",1}}
  end
  buff:apply()
end,

-- magic lady chirushi, hot winds! hurricane!
[1226] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local n = #player:field_idxs_with_preds(pred.lady) + #player:hand_idxs_with_preds(pred.lady)
  if n >= 2 and n <= 3 then
    OneBuff(player, my_idx, {atk={"+",3},sta={"+",3}}):apply()
  elseif n >= 5 then
    local buff = OnePlayerBuff(player.opponent)
    local targets = player.opponent:field_idxs_with_preds(pred.follower)
    for _,idx in ipairs(targets) do
      buff[idx] = {atk={"-",2},sta={"-",2}}
    end
    buff:apply()
  end
  my_card:remove_skill_until_refresh(skill_idx)
end,

-- knight sgt. seyfarf, defense sink!
[1227] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card then
    OneBuff(player.opponent, other_idx, {def={"=",my_card.def}}):apply()
  end
end,

-- seeker sarah, sacred shield!
[1228] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local seekers = player:field_idxs_with_preds(pred.follower, pred.seeker)
  if #seekers >= 2 then
    local buff = OnePlayerBuff(player)
    for _,idx in ipairs(seekers) do
      buff[idx] = {sta={"+",4}}
    end
    buff:apply()
    my_card:remove_skill_until_refresh(skill_idx)
  end
end,

-- knight veltier, rear maneuver!
[1229] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local target = player.hand[1]
  if target then
    local buff = GlobalBuff(player)
    buff.hand[player][1] = {size={"-",1}}
    buff.field[player][my_idx] = {sta={"+",target.size}}
    buff:apply()
    player:hand_to_top_deck(1)
  end
end,

-- aletheian a-ga, attack roulette!
[1230] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  OneBuff(player, my_idx, {atk={"=",random(1,10)}}):apply()
end,

-- aletheian a-ga, health roulette!
[1231] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  OneBuff(player, my_idx, {sta={"=",random(1,10)}}):apply()
end,

-- aletheian b-na, my body is a shield!
[1232] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if my_card.atk >= 1 then
    OneBuff(player, my_idx, {atk={"-",1},sta={"+",3}}):apply()
  end
end,

-- apostle schindler k. eru, sacrifice!
[1233] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local target = player:field_idxs_with_preds(pred.follower,
      function(card) return card ~= my_card end)[1]
  local buff = {atk={"+",1},sta={"+",1}}
  if target then
    if pred.aletheian(player.field[target]) then
      buff = {atk={"+",3},sta={"+",3}}
    elseif pred.D(player.field[target]) then
      buff = {atk={"+",2},sta={"+",2}}
    else
      buff = {sta={"+",3}}
    end
    player:field_to_grave(target)
  end
  OneBuff(player, my_idx, buff):apply()
end,

-- 4th witness kana. ddt, time control!
[1234] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if player.game.turn % 2 == 1 and other_card then
    OneBuff(player, my_idx, {sta={"+",other_card.atk}}):apply()
  end
end,

-- 4th witness kana. ddt, investigation!
[1236] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if player.game.turn % 2 == 0 then
    OneBuff(player, my_idx, {atk={"+",1},sta={"+",2}}):apply()
  end
end,

-- ack!
[1237] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  OneBuff(player, my_idx, {sta={"=",1}}):apply()
end,

-- lib. explorer vitelle, super eight!
[1238] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  OneBuff(player, my_idx, {atk={"=",8}}):apply()
end,

-- lib. explorer orte, attack sink!
[1239] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card then
    OneBuff(player, my_idx, {atk={"=",other_card.def + 2}}):apply()
  end
end,

-- lib. explorer orte, best three!
[1240] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card then
    OneBuff(player.opponent, other_idx, {sta={"-",3}}):apply()
  end
end,

-- lib. explorer returner, phase shift!
[1241] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card and other_card.atk > my_card.def + my_card.sta then
    if my_card.size > 2 then
      local slot = player:first_empty_field_slot()
      if slot then
        local new_card = Card(300353)
        player:field_to_exile(my_idx)
        player.field[slot] = new_card
        OneBuff(player, slot, {size={"=",my_card.size-1},atk={"+",2},sta={"+",2}}):apply()
        new_card.active = false
      end
    elseif pred.V(player.character) then
      player.opponent:field_to_grave(other_idx)
      player:field_to_grave(my_idx)
    else
      player.opponent:field_to_bottom_deck(other_idx)
      player:field_to_grave(my_idx)
    end
  end
end,

-- witch cadet dauner, status change!
[1242] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  OneBuff(player, my_idx, {size={"-",#player:hand_idxs_with_preds(pred.witch)}}):apply()
end,

-- witch cadet dauner, neutralize!
[1243] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card then
    for idx,id in pairs(other_card.skills) do
      if skill_id_to_type[id] == "attack" then
        other_card:remove_skill(idx)
      end
    end
  end
  my_card:remove_skill(skill_idx)
end,

-- witch cadet prelitch, harden!
[1244] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  OneBuff(player, my_idx, {def={"+",2}}):apply()
end,

-- witch cadet prelitch, shield support!
[1245] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local target = uniformly(player:field_idxs_with_preds(pred.follower, pred.witch))
  local buff = OnePlayerBuff(player)
  buff[my_idx] = {def={"=",0}}
  local amt = abs(my_card.def)
  if target then
    buff[target] = {atk={"+",amt},sta={"+",amt}}
  end
  buff:apply()
end,

-- shut-in lady neetness, phase shift!
[1246] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card and other_card.atk > my_card.def + my_card.sta then
    if my_card.size > 3 then
      local slot = player:first_empty_field_slot()
      if slot then
        local new_card = Card(300356)
        player:field_to_exile(my_idx)
        player.field[slot] = new_card
        OneBuff(player, slot, {size={"=",my_card.size-1}}):apply()
        new_card.active = false
        local hand_target = player.opponent:hand_idxs_with_preds(pred.spell)[1]
        if hand_target then
          local amt = player.opponent.hand[hand_target].size
          player.opponent:hand_to_grave(hand_target)
          OneBuff(player.opponent, other_idx, {sta={"-",amt}}):apply()
        end
      end
    elseif pred.A(player.character) then
      player.opponent:field_to_grave(other_idx)
      player:field_to_grave(my_idx)
    else
      player.opponent:field_to_bottom_deck(other_idx)
      player:field_to_grave(my_idx)
    end
  end
end,

-- seeker alameda, sanctuary call!
[1247] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local target = player:deck_idxs_with_preds(pred.sanctuary, pred.spell)[1]
  local slot = player:first_empty_field_slot()
  if target and slot then
    player:deck_to_field(target)
    my_card:remove_skill_until_refresh(skill_idx)
  end
end,

-- seeker adalia, sanctuary burst!
[1248] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  OneBuff(player, my_idx, {atk={"+",#player:field_idxs_with_preds(pred.sanctuary)}}):apply()
end,

-- seeker adalia, sanctuary return!
[1249] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local targets = player:field_idxs_with_preds(pred.sanctuary)
  for _,idx in ipairs(targets) do
    player.field[idx].active = true
  end
  my_card:remove_skill_until_refresh(skill_idx)
end,

-- seeker lagerfeld, phase shift!
[1250] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card and other_card.atk > my_card.def + my_card.sta then
    if my_card.size < 3 then
      local slot = player:first_empty_field_slot()
      if slot then
        local new_card = Card(300359)
        player:field_to_exile(my_idx)
        player.field[slot] = new_card
        OneBuff(player, slot, {size={"=",my_card.size+1}}):apply()
        new_card.active = false
        local buff = OnePlayerBuff(player)
        local targets = player:field_idxs_with_preds(pred.follower,
            function(card) return card ~= new_card end)
        for _,idx in ipairs(targets) do
          buff[idx] = {size={"-",2}}
        end
        buff:apply()
      end
    elseif pred.C(player.character) then
      player.opponent:field_to_grave(other_idx)
      player:field_to_grave(my_idx)
    else
      player.opponent:field_to_bottom_deck(other_idx)
      player:field_to_grave(my_idx)
    end
  end
end,

-- aletheian c-eda, boost!
[1251] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card and other_card.atk > my_card.def + my_card.sta then
    local target = uniformly(player:field_idxs_with_preds(pred.follower, pred.D))
    if target then
      OneBuff(player, target, {atk={"+",2},sta={"+",2}}):apply()
    end
  end
end,

-- apostle d-ra, sacrifice's reward!
[1252] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local target = player:hand_idxs_with_preds(pred.aletheian)[1]
  if target then
    local amt = player.hand[target].sta
    player:hand_to_grave(target)
    OneBuff(player, my_idx, {sta={"+",min(6,amt)}}):apply()
  end
end,

-- nether merchant minac, phase shift!
[1253] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card and other_card.atk > my_card.def + my_card.sta then
    if my_card.size > 3 then
      local slot = player:first_empty_field_slot()
      if slot then
        local new_card = Card(300362)
        local amt = ceil(my_card.size / 2)
        player:field_to_exile(my_idx)
        player.field[slot] = new_card
        OneBuff(player, slot, {size={"=",my_card.size-1}}):apply()
        new_card.active = false
        local buff = OnePlayerBuff(player.opponent)
        local targets = player.opponent:field_idxs_with_preds(pred.follower)
        for _,idx in ipairs(targets) do
          buff[idx] = {sta={"-",amt}}
        end
        buff:apply()
      end
    elseif pred.D(player.character) then
      player.opponent:field_to_grave(other_idx)
      player:field_to_grave(my_idx)
    else
      player.opponent:field_to_bottom_deck(other_idx)
      player:field_to_grave(my_idx)
    end
  end
end,

-- edelfelt of the wing, phase shift!
[1254] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card and other_card.atk > my_card.def + my_card.sta then
    local slot = player:first_empty_field_slot()
    if slot then
      local new_card = Card(300363)
      player:field_to_exile(my_idx)
      player.field[slot] = new_card
      new_card.active = false
      if player.shuffles == 0 then
        player.shuffles = 1
      end
    end
  end
end,

-- council temp sinclair, council's blessing!
[1255] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local grave_idxs = shuffle(player:grave_idxs_with_preds({pred.V}))
  if #grave_idxs > 0 then
    local target_idxs = player:get_follower_idxs()
    for i=1,2 do
      local grave_idx = uniformly(player:grave_idxs_with_preds(pred.V))
      if grave_idx then
        player:grave_to_exile(grave_idx)
      end
    end
    local buff = OnePlayerBuff(player)
    buff[my_idx] = {atk={"+",2}, sta={"+",2}}
    if target_idxs[1] ~= my_idx then
      buff[target_idxs[1]] = {atk={"+",1}, sta={"+",1}}
    elseif target_idxs[2] then
      buff[target_idxs[2]] = {atk={"+",1}, sta={"+",1}}
    end
    buff:apply()
  end
end,

-- dark witch seven, brilliant idea!
[1256] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local grave_target_idxs = shuffle(player:grave_idxs_with_preds({pred.D}))
  if #grave_target_idxs > 0 then
    local opp_target_idxs = shuffle(player.opponent:get_follower_idxs())
    local buff = OnePlayerBuff(player.opponent)
    for i=1,2 do
      local grave_target_idx = uniformly(player:grave_idxs_with_preds({pred.D}))
      if grave_target_idx then
        player:grave_to_exile(grave_target_idx)
      end
    end
    for i=1,math.min(2,#opp_target_idxs) do
      buff[opp_target_idxs[i]] = {atk={"-",1}, def={"-",1}, sta={"-",2}}
    end
    buff:apply()
  end
end,

-- attack charge
[1257] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  OneBuff(player, my_idx, {atk={"+",1},sta={"+",1}}):apply()
end,

-- destruction!
[1272] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  player:destroy(my_idx)
end,

-- absolute shield!
[1273] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if my_card.def < 0 then
    OneBuff(player, my_idx, {def={"=",-my_card.def}}):apply()
  end
end,

-- forced tranformation!
[1286] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if not other_card then
    return
  end
  other_card.id = 300139
  local amt = #player.opponent:field_idxs_with_preds(pred.rio)
  OneBuff(player.opponent, other_idx, {atk={"-",amt},def={"-",amt},sta={"-",amt}}):apply()
end,

-- fake slumber!
[1287] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  my_card.active = true
end,

-- i'm done warming up!
[1288] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local base = Card(my_card.id)
  local buff = {}
  for _,stat in ipairs({"atk","def","sta"}) do
    if my_card[stat] < base[stat] then
      buff[stat] = {"=",base[stat]}
    end
  end
  OneBuff(player, my_idx, buff):apply()
end,

-- coin child, all together now!
[1314] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
end,

-- coin child, coin of desire
[1315] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
end,

-- coin child, my lucky day!
[1316] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
end,

-- crux knight ibis, balance of power!
[1324] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local do_default = true
  local buff = GlobalBuff(player)
  buff.field[player][my_idx] = {}
  buff.field[player.opponent][other_idx] = {}
  if other_card then
    for _,stat in ipairs({"atk","def","sta"}) do
      if other_card[stat] > id_to_canonical_card[other_card.id][stat] then
        do_default = false
        local amt = ceil((other_card[stat] - id_to_canonical_card[other_card.id][stat])/2)
        buff.field[player][my_idx][stat] = {"+",amt}
        buff.field[player.opponent][other_idx][stat] = {"-",amt}
      end
    end
  end
  if do_default then
    buff.field[player][my_idx] = {sta={"+",2}}
  end
  buff:apply()
end,

-- Guide Rio
[1355] = function(player, my_idx, my_card)
  OneBuff(player, my_idx, {def={"+", 1}}):apply()
end,

-- l. esprit, quest for truth!
[1389] = lesprit,

-- l. esprit, quest for truth!
[1390] = lesprit,

-- resistance
[1408] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card then
    OneBuff(player, my_idx, {sta={"+",floor(other_card.atk/2)}}):apply()
  end
  my_card:remove_skill(skill_idx)
end,

-- girls' harmony, chrysalis!
[1425] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card and pred.skill(other_card) then
    OneBuff(player, my_idx, {sta={"+",other_card.atk}}):apply()
  end
end,

-- Cook Club Director Jamie if NPC, +1/+1
[1483] = function(player, my_idx)
  if player.opponent:is_npc() then
    OneBuff(player, my_idx, {sta={"+",1},atk={"+",1}}):apply()
  end
end,

-- alchemist yi ensan, poison attack
[1485] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local buff = GlobalBuff(player)
  buff.field[player][my_idx] = {sta={"+",1}}
  if other_card then
    buff.field[player.opponent][other_idx] = {sta={"-",1}}
  end
  buff:apply()
end,

-- badminton sita, sita smash!
[1522] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card and other_card.sta % 2 == 0 then
    OneBuff(player.opponent, other_idx, {sta={"-",1}}):apply()
    if pred.V(player.character) and pred.skill(other_card) then
      other_card.skills = {1076}
    end
  end
end,

-- archery cinia, 200% accuracy!
[1523] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local target = uniformly(player.opponent:field_idxs_with_preds(pred.active, pred.follower))
  if target then
    OneBuff(player.opponent, target, {sta={"-",2}}):apply()
    target = uniformly(player.opponent:field_idxs_with_preds(pred.follower))
    if pred.A(player.character) and target then
      OneBuff(player.opponent, target, {sta={"-",2}}):apply()
    end
  end
end,

-- judo luthica, judo throw!
[1524] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local amt = #player:field_idxs_with_preds(pred.follower)
  if not pred.C(player.character) then
    amt = min(2,amt)
  end
  if other_card then
    OneBuff(player.opponent, other_idx, {def={"-",amt}}):apply()
  end
end,

-- ping pong iri, serve of victory!
[1525] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card and other_card.def + other_card.sta <= 7 then
    local amt = other_card.size
    player.opponent:destroy(other_idx)
    local target = uniformly(player.opponent:field_idxs_with_preds(pred.follower))
    if pred.D(player.character) and target then
      OneBuff(player.opponent, target, {sta={"-",amt}}):apply()
    end
  end
end,

-- Cook Club Svia 
[1626] = function(player, my_idx)
  local buff = GlobalBuff(player)
  buff.field[player][my_idx] = {atk={"+",player.field[my_idx].def}}
  buff:apply()
end,

-- if enemy is NPC, best attack
[1706] = function(player, my_idx)
  if player.opponent:is_npc() then
    local buff = GlobalBuff(player)
    buff.field[player][my_idx] = {atk={"+",1}}
    buff:apply()
  end
end,

-- Carrier Maid
[1707] = function(player)
  local target_idx = uniformly(player:field_idxs_with_preds({pred.maid,pred.follower}))
  if target_idx then
    local buff = GlobalBuff(player)
    buff.field[player][target_idx] = {size={"-",1}}
    buff:apply()
  end
end,

-- Crux Knight Terra 
[1708] = function(player, my_idx, my_card, skill_idx)
  local target_idx = uniformly(player:field_idxs_with_preds({pred.knight,pred.follower}))
  if target_idx then
    OneBuff(player, target_idx, {atk={"+",2},sta={"+",2}}):apply()
  end
  my_card:remove_skill(skill_idx)
end,

-- rh asmis, cacao's blessing (rh)!
[1749] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  OneBuff(player, my_idx, {atk={"+",4},sta={"+",4}}):apply()
end,

-- rh asmis, homunculus power (rh)!
[1752] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if my_card.sta < id_to_canonical_card[my_card.id].sta then
    OneBuff(player, my_idx, {sta={"+",3}}):apply()
  elseif my_card.sta > id_to_canonical_card[my_card.id].sta then
    my_card.active = true
    OneBuff(player, my_idx, {atk={"+",2}}):apply()
  end
end,

-- occultist iris juvia
[1854] = function(player, my_idx, my_card, skill_idx)
  local mag = 0
  local pred_name = function(card) return card.name == my_card.name end
  for i=1,5 do
    local idx = player:hand_idxs_with_preds(pred_name)[1]
    if idx then
      player:hand_to_grave(idx)
      mag = mag + 1
    end
  end
  for i=1,#player.deck do
    local idx = player:deck_idxs_with_preds(pred_name)[1]
    if idx then
      player:deck_to_grave(idx)
      mag = mag + 1
    else
      break
    end
  end
  OneBuff(player, my_idx, {atk={"+",mag},def={"+",mag},sta={"+",mag}}):apply()
end,
}


setmetatable(skill_func, {__index = function() return function() end end})
