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
  local dressup = function(card) return floor(card.id) == floor(dressup_id) end
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
  local dressup = function(card) return floor(card.id) == floor(dressup_id) end
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
  if grave_target and not buff then
    player:grave_to_exile(grave_target)
    buff = true
  end
  if buff then
    if buff_type == "-" then
      if not player.opponent.field[other_idx] then
        return
      end
      OneBuff(player.opponent, other_idx, {atk={"-",1}, sta={"-",2}}):apply()
    elseif buff_type == "+" then
      OneBuff(player, my_idx, {atk={"+",1}, sta={"+",2}}):apply()
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

-- The Power of All Creation!
-- Genius Student Nanai
[1032] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if not other_card then
    return
  end
  local size = other_card.size
  local mag = 0
  local check = true
  local pred_size = function(card) return card.size == size end
  local idx = player:grave_idxs_with_preds(pred_size)[1]
  while idx do
    player:grave_to_exile(idx)
    mag = mag + 1
    idx = player:grave_idxs_with_preds(pred_size)[1]
  end
  idx = player.opponent:grave_idxs_with_preds(pred_size)[1]
  while idx do
    player.opponent:grave_to_exile(idx)
    mag = mag + 1
    idx = player.opponent:grave_idxs_with_preds(pred_size)[1]
  end
  OneBuff(player.opponent, other_idx, {atk={"-",mag},sta={"-",mag}}):apply()
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
      function(card) return floor(card.id) == 300090 end)[1]
  local opp_target_idx = uniformly(player.opponent:get_follower_idxs())
  if ally_target_idx and opp_target_idx then
    OneImpact(player, ally_target_idx):apply()
    player:field_to_bottom_deck(ally_target_idx)
    OneImpact(player.opponent, opp_target_idx):apply()
    player.opponent:destroy(opp_target_idx)
  end
end,

-- fated rival seven, brilliant idea
[1036] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local grave_target_idxs = shuffle(player:grave_idxs_with_preds(pred.A))
  if #grave_target_idxs > 0 then
    for i=1,2 do
      local grave_target_idx = uniformly(grave_target_idxs)
      if grave_target_idx then
        player:grave_to_exile(grave_target_idx)
      end
    end
    local opp_target_idx = uniformly(player.opponent:field_idxs_with_preds(pred.follower,
        function(card) return card ~= other_card end))
    local buff = OnePlayerBuff(player.opponent)
    if other_card then
      buff[other_idx] = {atk={"-",1}, def={"-",1}, sta={"-",2}}
    end
    if opp_target_idx then
      buff[opp_target_idx] = {atk={"-",1}, def={"-",1}, sta={"-",2}}
    end
    buff:apply()
  end
end,

-- stigma witness felicia, proof of stigma
[1037] = function(player)
  local target_idxs = player:field_idxs_with_preds(
      function(card) return floor(card.id) == 300087 end)
  if #target_idxs > 0 then
    local buffsize = #player:field_idxs_with_preds({pred.A})
    local buff = OnePlayerBuff(player)
    for _,idx in ipairs(target_idxs) do
      buff[idx] = {atk={"+",buffsize}, sta={"+",buffsize}}
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
  local my_grave_idx = player:grave_idxs_with_preds(pred.follower)[1]
  local op_idx = player.opponent:grave_idxs_with_preds(pred.follower)[1]
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
  if not other_card then
    return
  end
  local mag = math.min(math.abs(my_card.size - my_card.def), 5)
  OneBuff(player.opponent, other_idx, {atk={"-", mag}, def={"-", mag}, sta={"-", mag}}):apply()
end,

-- episode 3 follower skills

-- genius student nanai, great power!
[1047] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if not other_card then
    return
  end
  local buffsize = 0
  for _,p in ipairs({player, player.opponent}) do
    for i=#p.grave,1,-1 do
      if p.grave[i].size == other_card.size then
        p:grave_to_exile(i)
        buffsize = buffsize + 1
      end
    end
  end
  assert(#player:grave_idxs_with_preds({function(card)
    return card.size == other_card.size end}) == 0)
  assert(#player.opponent:grave_idxs_with_preds(
      function(card) return card.size == other_card.size end) == 0)
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
    OneImpact(player.opponent, other_idx):apply()
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
  if #player.grave >= 2 then
    local target = uniformly(player:grave_idxs_with_preds())
    if target then
      player:grave_to_exile(target)
    end
    target = uniformly(player:grave_idxs_with_preds())
    if target then
      player:grave_to_bottom_deck(target)
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
    local target_idxs = player:field_idxs_with_preds(pred.follower)
    local buff = OnePlayerBuff(player)
    for _,idx in ipairs(target_idxs) do
      buff[idx] = {atk={"+",3}, def={"+",1}, sta={"+",4}}
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
  my_card.skills[skill_idx] = 1074
end,

-- sweet lady isfeldt, sweet count
[1074] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if not other_card then
    return
  end
  if other_card.size <= my_card.size then
    player.opponent:field_to_top_deck(other_idx)
    my_card:remove_skill_until_refresh(skill_idx)
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
  local lucerrie = function(card) return floor(card.id) == 300181 end
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
  local lucerrie = function(card) return floor(card.id) == 300181 end
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
  local dressup_func = function(card) return floor(card.id) == 300198 end
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
  local dressup_func = function(card) return floor(card.id) == 300198 end
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
    return floor(card.id) == 300193 end})[1]
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
    return floor(card.id) == 300198 end})
  for _,idx in ipairs(field_idxs) do
    if idx ~= my_idx then
      player:field_to_grave(idx)
    end
  end
  if #player.hand > 0 then
    player:hand_to_top_deck(1)
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
  local faction_pred = function(card)
        return card.faction == player.character.faction
      end
  local deck_idx = player:deck_idxs_with_preds(faction_pred)[1]
  local slot = player:first_empty_field_slot()
  if deck_idx and slot then
    player:deck_to_field(deck_idx, slot)
  end
end,

-- 1st witness kana.dkd, just give up
[1102] = function(player, my_idx, my_card)
  if my_card.def <= 1 then
    OneBuff(player, my_idx, {def={"=",2}}):apply()
  end
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
    local debuff_size = ceil(my_card.atk / 2)
    local buff_size = floor(min(debuff_size, other_card.sta) / 2)
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
    player:to_top_deck(other_card)
    player.opponent.field[other_idx] = nil
    if player.field[my_idx] == my_card then
      player.field[my_idx] = nil
      player.opponent:to_bottom_deck(my_card)
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
    local followers = {}
    for _,idx in ipairs(player:hand_idxs_with_preds(pred.follower)) do
      followers[#followers+1] = {"hand", idx}
    end
    for _,idx in ipairs(player:field_idxs_with_preds(pred.follower)) do
      followers[#followers+1] = {"field", idx}
    end
    local buff = GlobalBuff(player)
    for i=1,2 do
      local fol = uniformly(followers)
      if fol then
        local zone, target_idx = fol[1], fol[2]
        local this_buff = buff[zone][player][target_idx]
        if this_buff then
          this_buff.atk[2] = this_buff.atk[2] + 1
          this_buff.sta[2] = this_buff.sta[2] + 1
        else
          buff[zone][player][target_idx] = {atk={"+",1}, sta={"+",1}}
        end
      end
    end
    buff:apply()
  end
end,

-- crux nemesis luthica, price of betrayal
[1118] = function(player, my_idx)
  local buff_size = #player:hand_idxs_with_preds({pred.follower})
  OneBuff(player, my_idx, {atk={"+",buff_size}, sta={"+",buff_size}}):apply()
  if #player.hand > 0 then
    player:hand_to_top_deck(1)
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
      if pred.D(player.hand[i]) then
        sizes[player.hand[i].size] = true
      end
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
    OneImpact(player.opponent, other_idx):apply()
    other_card.skills = {1076}
    my_card:remove_skill_until_refresh(skill_idx)
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
    other_card.atk = Card(other_card.id).atk
    other_card.def = Card(other_card.id).def
    other_card.sta = Card(other_card.id).sta
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
    buff[idx] = {atk={"+",1}, sta={"+",2}}
  end
  for _,idx in ipairs(nongs_target_idxs) do
    buff[idx] = {atk={"-",1}, sta={"-",2}}
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
  local buff = {}
  for _,stat in ipairs({"atk", "def", "sta"}) do
    local orig = Card(my_card.id)[stat]
    if my_card[stat] < orig then
      buff[stat] = {"=", orig}
    end
  end
  OneBuff(player, my_idx, buff):apply()
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
  local targets = player:deck_idxs_with_preds(function(card) return floor(card.id) == floor(my_card.id) end)
  for _,idx in ipairs(targets) do
    player:deck_to_exile(idx)
  end
  local n = #targets
  if n > 0 then
    OneBuff(player, my_idx, {atk={"+",n},def={"+",n},sta={"+",n*2}}):apply()
  end
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
  local n = 0
  for _,idx in ipairs(player.opponent:field_idxs_with_preds(pred.follower)) do
    buff.field[player.opponent][idx] = {sta={"-",1}}
    n = n + 1
  end
  buff.field[player][my_idx] = {sta={"+",ceil(n/2)}}
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
  if #player.grave + #player.opponent.grave >= 21 then
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

-- Student Council Support
[1176] = function(player)
  local idx = uniformly(player:field_idxs_with_preds(pred.follower, pred.student_council))
  if idx then
    OneBuff(player, idx, {sta={"+", 2}}):apply()
  end
end,

-- Search for a New Book
[1177] = function(player, my_idx, my_card, skill_idx)
  local mag = #player:hand_idxs_with_preds(pred.library_club) - 1
  mag = max(0, mag)
  OneBuff(player, my_idx, {atk={"+", mag},sta={"+", mag}}):apply()
  my_card:remove_skill_until_refresh(skill_idx)
end,

-- Overcome Adversities
[1178] = function(player, my_idx, my_card)
  if my_card.def <= 1 then
    OneBuff(player, my_idx, {def={"=", 1},sta={"+", 3}}):apply()
  end
end,

-- Cut in Two
[1179] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card then
    OneBuff(player.opponent, other_idx, {sta={"-",3}}):apply()
  end
  my_card.skills[skill_idx] = nil
end,

-- Group Use
[1180] = function(player, my_idx)
  local mag = #player.opponent:field_idxs_with_preds(pred.follower)
  OneBuff(player, my_idx, {sta={"+", mag}}):apply()
end,

-- Master Servant Pact
[1181] = function(player, my_idx, my_card, skill_idx)
  OneBuff(player, my_idx, {sta={"=", min(player.character.life, 15)}}):apply()
  my_card.skills[skill_idx] = nil
end,

-- Bleeding
[1182] = function(player, my_idx)
  local stat = uniformly({[1] = "atk", [2] = "def", [3] = "sta"})
  OneBuff(player, my_idx, {[stat]={"-",1}}):apply()
end,

-- Return
[1183] = function(player, my_idx)
  player:field_to_top_deck(my_idx)
end,

-- Amnesia
[1184] = function(player, my_idx, my_card)
  my_card.skills = {}
end,

-- Cycle of Defense
[1185] = function(player, my_idx, my_card)
  local mag = my_card.def <= 1 and 2 or my_card.def == 2 and 3 or 1
  OneBuff(player, my_idx, {def={"=", mag}}):apply()
end,

-- Dark Destruction
[1186] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if pred.D(player.character) and other_card then
    OneBuff(player.opponent, other_idx, {def={"-", 1}}):apply()
  end
end,

-- Peer Zone
[1187] = function(player, my_idx)
  if #player:hand_idxs_with_preds(pred.spell) < #player:hand_idxs_with_preds(pred.follower) then
    OneBuff(player, my_idx, {atk={"+", 1}, sta={"+", 1}}):apply()
  end
end,

-- Sacrificial Defense
[1188] = function(player, my_idx)
  OneBuff(player, my_idx, {sta={"-", 2}}):apply()
  local idx = uniformly(player:field_idxs_with_preds(pred.follower, pred.D))
  if idx then
    OneBuff(player, idx, {atk={"+", 2}, sta={"+", 2}}):apply()
  end
end,

-- Assistance
[1189] = function(player, my_idx, my_card, skill_idx)
  OneBuff(player, 0, {life={"+", 1}}):apply()
  my_card:remove_skill_until_refresh(skill_idx)
end,

-- Self-Sacrifice
[1190] = function(player, my_idx)
  OneBuff(player, my_idx, {atk={"-", 1}, def={"-", 1}, sta={"-", 1}}):apply()
end,

-- Self-Centered
[1191] = function(player, my_idx, my_card, skill_idx)
  local idxs = player:field_idxs_with_preds(pred.follower,
    function(card) return card ~= my_card end)
  local mag = 0
  local buff = OnePlayerBuff(player)
  for _,idx in ipairs(idxs) do
    buff[idx] = {def={"-", 1}}
    mag = mag + 1
  end
  buff[my_idx] = {atk={"+", mag}, sta={"+", mag}}
  buff:apply()
  my_card:remove_skill_until_refresh(skill_idx)
end,

-- sword girls sita, position change!
[1192] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local target_idx = player:deck_idxs_with_preds(pred.follower, pred.sword_girls)[1]
  local slot = player:first_empty_field_slot()
  if target_idx and slot then
    local target_card = player.deck[target_idx]
    if slot < my_idx then
      target_card:refresh()
    else
      target_card.skills = {1076}
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
  buff[my_idx].size = {"-",2}
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
      OneImpact(player.opponent, other_idx):apply()
      player.opponent:field_to_grave(other_idx)
    end
  end
end,

-- council press lyrica, guarantee!
[1223] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local target = player:grave_idxs_with_preds(pred.V, pred.follower)[1]
  if target then
    player:grave_to_exile(target)
  end
end,

-- dd lady tomo, lady ready!
[1224] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local n = #player:hand_idxs_with_preds(pred.lady) + #player:field_idxs_with_preds(pred.lady)
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
  if n >= 1 and n <= 2 then
    OneBuff(player, my_idx, {atk={"+",2},sta={"+",2}}):apply()
  elseif n >= 4 then
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
    buff.hand[player][1] = {size={"-",2}}
    buff.field[player][my_idx] = {sta={"+",1+target.size}}
    buff:apply()
    player:hand_to_top_deck(1)
  end
  my_card:remove_skill_until_refresh(skill_idx)
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

-- Mind Control
[1235] = function(player, my_idx, my_card, skill_idx)
  local op = player.opponent
  if not my_card.active or not op:first_empty_field_slot() then
    return
  end
  player.field[my_idx], op.field[op:first_empty_field_slot()] = nil, my_card
  my_card:remove_skill(skill_idx)
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
        local new_card = Card(my_card.id)
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
  my_card:remove_skill(skill_idx)
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
    if target == my_idx then
      buff[target] = {atk={"+",amt}, def={"=",0}, sta={"+",amt}}
    else
      buff[target] = {atk={"+",amt},sta={"+",amt}}
    end
  end
  buff:apply()
end,

-- shut-in lady neetness, phase shift!
[1246] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card and other_card.atk > my_card.def + my_card.sta then
    if my_card.size > 3 then
      local slot = player:first_empty_field_slot()
      if slot then
        local new_card = Card(my_card.id)
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
        local new_card = Card(my_card.id)
        player:field_to_exile(my_idx)
        player.field[slot] = new_card
        OneBuff(player, slot, {size={"=",my_card.size+1}}):apply()
        new_card.active = false
        local buff = OnePlayerBuff(player)
        local target = uniformly(player:field_idxs_with_preds(pred.follower,
            function(card) return card ~= new_card and card.size >= 2 end))
        if target then
          buff[target] = {size={"-",2}}
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
        local new_card = Card(my_card.id)
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

-- First Aid
[1258] = function(player, my_idx, my_card, skill_idx)
  OneBuff(player, my_idx, {sta={"+", 3}}):apply()
  local idx = uniformly(player:field_idxs_with_preds(pred.follower,
    function(card) return card.skills[1] ~= 1258 and card.skills[2] ~= 1258
      and card.skills[3] ~= 1258 end))
  -- TODO: if you play this with a follower with 3 skills,
  -- can the skil target that follower and vanish?
  if idx then
    my_card:remove_skill(skill_idx)
    player.field[idx]:gain_skill(1258)
  end
end,

-- Hemorrhage Curse
[1259] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card then
    other_card:gain_skill(1259)
    OneBuff(player.opponent, other_idx, {sta={"-", 2}}):apply()
  end
  my_card:remove_skill(skill_idx)
end,

-- Pierce
[1260] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if not player:first_empty_field_slot() then
    return
  end
  if other_card then
    OneBuff(player.opponent, other_idx, {sta={"-", my_card.atk - other_card.def}}):apply()
  end
  player.field[player:first_empty_field_slot()], player.field[my_idx] = my_card, nil
  my_card.active = false
  my_card:remove_skill_until_refresh(skill_idx)
end,

-- Song of Vitality
[1261] = function(player)
  if player.field[3] and pred.follower(player.field[3]) then
    OneBuff(player, 3, {atk={"+", 1}, sta={"+", 1}}):apply()
  end
end,

-- Burst
[1262] = function(player, my_idx, my_card, skill_idx)
  OneBuff(player, my_idx, {atk={"+", 2}, sta={"+", 2}}):apply()
  my_card:remove_skill(skill_idx)
end,

-- Curse
[1263] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if not other_card then
    return
  end
  OneBuff(player.opponent, other_idx, {atk={"-", 2}, sta={"-", 2}}):apply()
  my_card:remove_skill(skill_idx)
end,

-- Rewind
[1264] = function(player, my_idx, my_card, skill_idx)
  local idx = uniformly(player:grave_idxs_with_preds(pred.follower))
  if idx then
    player:grave_to_bottom_deck(idx)
  end
  my_card:remove_skill(skill_idx)
end,

-- Half Price
[1265] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if not other_card then
    return
  end
  local mag = ceil(my_card.size / 2)
  OneBuff(player.opponent, other_idx, {atk={"-", mag}, sta={"-", mag}}):apply()
end,

-- Sanctuary Press!
[1266] = function(player, my_idx, my_card, skill_idx)
  if player.opponent.deck[1] then
    local mag = min(#player:field_idxs_with_preds(pred.sanctuary), 2)
    local buff = GlobalBuff(player)
    buff.deck[player.opponent][#player.opponent.deck] = {size={"+", mag}}
    buff:apply()
  end
  my_card:remove_skill_until_refresh(skill_idx)
end,

-- Soul Bounce
[1267] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local idx = uniformly(player:field_idxs_with_preds(pred.neg(pred.active),
    function(card) return card ~= my_card end))
  if not idx then
    return
  end
  player:field_to_top_deck(idx)
  if other_card then
    player.opponent:field_to_top_deck(other_idx)
  end
  OneBuff(player, my_idx, {atk={"+", 2}, sta={"+", 2}}):apply()
end,

-- Curse of Unity
[1268] = function(player, my_idx)
  if #player:field_idxs_with_preds(pred.aletheian) == 0 then
    OneBuff(player, my_idx, {atk={"-", 1}, def={"-", 1}}):apply()
  end
end,

-- Cover
[1269] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if my_card.active then
    return
  end
  if other_card then
    player.opponent:field_to_bottom_deck(other_idx)
  end
  my_card:remove_skill(skill_idx)
end,

-- HP Boost
[1270] = function(player, my_idx)
  OneBuff(player, my_idx, {sta={"+", 1}}):apply()
end,

-- Blood Rebellion
[1271] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if my_card.sta < 7 then
    return
  end
  local buff = GlobalBuff(player)
  buff.field[player][my_idx] = {sta={"=", 6}}
  if other_card then
    local mag = my_card.sta - 6
    buff.field[player.opponent][other_idx] = {atk={"-", mag}, def={"-", mag}}
  end
  buff:apply()
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

-- Break
[1274] = function(player)
  local idxs = player:field_idxs_with_preds(pred.follower)
  local buff = OnePlayerBuff(player)
  for _,idx in ipairs(idxs) do
    buff[idx] = {def={"-", 1}}
  end
  buff:apply()
end,

-- Erupting Potential
[1275] = function(player, my_idx, my_card, skill_idx)
  OneBuff(player, my_idx, {atk={"+", 2}, def={"+", 2}, sta={"+", 2}}):apply()
  my_card:remove_skill(skill_idx)
end,

-- Dissonance
[1276] = function(player, my_idx, my_card)
  local buff = OnePlayerBuff(player)
  local idxs = player:field_idxs_with_preds(pred.follower, function(card)
    return card ~= my_card end)
  for _,idx in ipairs(idxs) do
    buff[idx] = {sta={"-", 1}}

  end
  buff:apply()
end,

-- Law of Nature
[1277] = function(player, my_idx, my_card, skill_idx, other_idx)
  local op = player.opponent
  local idx = op:field_idxs_with_least_and_preds(pred.sta, pred.follower)[1]
  if idx and idx ~= other_idx then
    op.field[other_idx], op.field[idx] = op.field[idx], op.field[other_idx]
  end
  local card = op.field[other_idx]
  if card and card.def + card.sta <= my_card.atk then
    OneBuff(player, my_idx, {atk={"+", 2}, sta={"+", 2}}):apply()
  end
end,

-- Strike Weakness!
[1278] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if not other_card then
    return
  end
  for i=1,3 do
    if skill_id_to_type[other_card.skills[i]] == "defend" then
      return
    end
  end
  OneBuff(player.opponent, other_idx, {def={"-", 1}, sta={"-", 1}}):apply()
end,

-- Defense Spin
[1279] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if not other_card then
    return
  end
  local op = player.opponent
  local buff = {}
  local orig = Card(other_card.id)
  local check = false
  for _,attr in ipairs({"def", "sta"}) do
    if other_card[attr] > orig[attr] then
      buff[attr] = {"=", orig[attr]}
      check = true
    end
  end
  OneBuff(op, other_idx, buff):apply()
  if check then
    my_card:remove_skill_until_refresh(skill_idx)
  end
end,

-- Attack Spin
[1280] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if not other_card then
    return
  end
  local op = player.opponent
  local buff = {}
  local orig = Card(other_card.id)
  local check = false
  for _,attr in ipairs({"atk", "def"}) do
    if other_card[attr] > orig[attr] then
      buff[attr] = {"=", orig[attr]}
      check = true
    end
  end
  OneBuff(op, other_idx, buff):apply()
  if check then
    my_card:remove_skill_until_refresh(skill_idx)
  end
end,

-- Diet Failure
[1281] = function(player, my_idx, my_card, skill_idx)
  if #player.hand <= 2 then
    OneBuff(player, my_idx, {size={"+", 2}}):apply()
  elseif #player.hand >= 4 then
    OneImpact(player, my_idx):apply()
    my_card:remove_skill(skill_idx)
  end
end,

-- Berserker
[1282] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if not other_card then
    return
  end
  local mag1 = ceil(other_card.atk / 2)
  local mag2 = floor(mag1 / 2)
  OneBuff(player, my_idx, {atk={"+", mag1}, sta={"+", mag2}}):apply()
end,

-- Disruption
[1283] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card and not my_card.active then
    OneBuff(player.opponent, other_idx, {atk={"-", 2}, sta={"+", 1}}):apply()
  end
end,

-- The Past is Now
[1284] = function(player)
  if not pred.D(player.character) then
    return
  end
  local idxs = player:field_idxs_with_preds(pred.follower)
  local buff = OnePlayerBuff(player)
  for i=1,#idxs do
    buff[idxs[i]] = {}
    player.field[idxs[i]]:refresh()
  end
  buff:apply()
end,

-- Knowledge Use
[1285] = function(player, my_idx, my_card, skill_idx)
  local idxs = player:field_idxs_with_preds(pred.follower, pred.witch)
  local buff = OnePlayerBuff(player)
  for i=1,#idxs do
    buff[idxs[i]] = {sta={"+", 2}}
  end
  buff:apply()
  my_card:remove_skill(skill_idx)
end,

-- forced tranformation!
[1286] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if not other_card then
    return
  end
  other_card.id = 300139
  other_card.faction = Card(300139).faction
  local amt = #player.opponent:field_idxs_with_preds(pred.rio)
  OneBuff(player.opponent, other_idx, {atk={"-",amt},def={"-",amt},sta={"-",amt}}):apply()
end,

-- fake slumber!
[1287] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card and other_card.atk > my_card.def then
    my_card.active = true
  end
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

-- Clone Technique
[1289] = function(player, my_idx, my_card)
  player:to_grave(deepcpy(my_card))
end,

-- Copy Evasion
[1290] = function(player, my_idx, my_card)
  local mag = min(3, #player:grave_idxs_with_preds(function(card) return card.name == my_card.name end))
  OneBuff(player, my_idx, {sta={"+", mag}}):apply()
end,

-- Summoning Magic
[1291] = function(player, my_idx, my_card)
  local idx = player:deck_idxs_with_preds(pred.follower, pred.dress_up,
    function(card) return card.name ~= my_card.name end)[1]
  local idx2 = player:first_empty_field_slot()
  if idx and idx2 then
    player:deck_to_field(idx, idx2)
    OneBuff(player, idx2, {size={"=", 5}, atk={"+", 3}, sta={"+", 3}}):apply()
    OneImpact(player, my_idx):apply()
    player:field_to_grave(my_idx)
  end
end,

-- Curse Attack
[1292] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local opponent = player.opponent
  local idx = opponent:hand_idxs_with_preds(pred.spell)[1]
  if idx then
    opponent:hand_to_top_deck(idx)
    if other_card then
      OneBuff(opponent, other_idx, {atk={"-",1},sta={"-",1}}):apply()
    end
  elseif other_card then
    OneBuff(opponent, other_idx, {atk={"-",1},sta={"-",1}}):apply()
    my_card:remove_skill_until_refresh(skill_idx)
  end
end,

-- Curse Shift
[1293] = function(player, my_idx, my_card, skill_idx)
  local idx = player:hand_idxs_with_preds(pred.follower)[1]
  if idx then
    player:hand_to_top_deck(idx)
    OneBuff(player, my_idx, {atk={"+", 1}, sta={"+", 1}}):apply()
  else
    OneBuff(player, my_idx, {sta={"+", 2}}):apply()
    my_card:remove_skill(skill_idx)
  end
end,

-- Letter of Curse
[1294] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local opponent = player.opponent
  local idx = uniformly(opponent:deck_idxs_with_preds(pred.follower))
  local buff = GlobalBuff(player)
  if idx then
    buff.deck[opponent][idx] = {atk={"-", 1}, sta={"-", 1}}
  end
  if pred.linus(player.character) and other_card then
    buff.field[opponent][other_idx] = {atk={"-", 1}, sta={"-", 1}}
  end
  my_card:remove_skill_until_refresh(skill_idx)
  buff:apply()
end,

-- Letter of Misfortune
[1295] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local opponent = player.opponent
  local idx = uniformly(opponent:deck_idxs_with_preds(pred.follower))
  local buff = GlobalBuff(player)
  if idx then
    buff.deck[opponent][idx] = {atk={"-", 1}, sta={"-", 1}}
  end
  if pred.linus(player.character) and other_card then
    buff.field[opponent][other_idx] = {atk={"-", 1}, sta={"-", 1}}
  end
  my_card:remove_skill_until_refresh(skill_idx)
  buff:apply()
end,

-- Defensive Formation
[1296] = function(player, my_idx, my_card, skill_idx)
  local mag = 0
  for i=1,3 do
    if player.hand[3] then
      player:hand_to_top_deck(3)
      mag = mag + 1
    end
  end
  local mag2 = pred.rose(player.character) and 1 or 0
  local idx = uniformly(player:field_idxs_with_preds(pred.follower,
    function(card) return card ~= my_card end))
  local buff = OnePlayerBuff(player)
  buff[my_idx] = {atk={"+", mag2}, def={"+", mag}}
  if idx then
    buff[idx] = {atk={"+", mag2}, def={"+", mag}}
  end
  buff:apply()
end,

-- Shaman's Majestic Dance
[1297] = function(player, my_idx, my_card, skill_idx)
  local opponent = player.opponent
  local idxs = opponent:hand_idxs_with_preds(pred.follower)
  if #idxs ~= 0 then
    local buff = GlobalBuff(player)
    for i=1,#idxs do
      buff.hand[opponent][idxs[i]] = {atk={"-", 1}}
    end
    buff:apply()
  else
    local mag = pred.helena(player.character) and 1 or 0
    OneBuff(player, my_idx, {atk={"+", mag}, sta={"+", 3}}):apply()
    my_card:remove_skill_until_refresh(skill_idx)
  end
end,

-- Shaman's Overwhelming Dance
[1298] = function(player, my_idx, my_card, skill_idx)
  local opponent = player.opponent
  local idxs = opponent:hand_idxs_with_preds(pred.follower)
  if #idxs ~= 0 then
    local buff = GlobalBuff(player)
    for i=1,#idxs do
      buff.hand[opponent][idxs[i]] = {atk={"-", 1}}
    end
    buff:apply()
  else
    local mag = pred.helena(player.character) and 1 or 0
    OneBuff(player, my_idx, {atk={"+", mag}, sta={"+", 3}}):apply()
    my_card:remove_skill_until_refresh(skill_idx)
  end
end,

-- Cook Club's Privilege
[1299] = function(player, my_idx, my_card, skill_idx)
  local check = pred.cook_club(my_card)
  if check then
    OneBuff(player, my_idx, {atk={"+", 2}, sta={"+", 2}}):apply()
  else
    OneBuff(player, my_idx, {atk={"-", 1}, sta={"-", 2}}):apply()
  end
  local idx = uniformly(player:field_idxs_with_preds(pred.follower,
    function(card) return card ~= my_card end))
  if idx then
    my_card:remove_skill(skill_idx)
    player.field[idx]:gain_skill(1299)
  end
end,

-- Ace Power Rise!
[1300] = function(player, my_idx)
  local mag_atk = math.random(0, 2)
  local mag_sta = math.random(0, 1)
  OneBuff(player, my_idx, {atk={"+", mag_atk}, sta={"+", mag_sta}}):apply()
end,

-- Ace Power!
[1301] = function(player, my_idx, my_card)
  local orig = Card(my_card.id).atk
  local mag = math.min(3, math.abs(orig - my_card.atk))
  local buff = GlobalBuff(player)
  buff.field[player][my_idx] = {atk={"=", orig}}
  local idx = player.opponent:deck_idxs_with_preds(pred.follower)[1]
  if idx then
    buff.deck[player.opponent][idx] = {atk={"-", mag}, sta={"-", mag}}
  end
  buff:apply()
end,

-- Erupting Fury!
[1302] = function(player, my_idx, my_card, skill_idx)
  if #player.opponent:field_idxs_with_preds(pred.spell) > 0 then
    OneBuff(player, my_idx, {atk={"+", 5}}):apply()
    my_card:remove_skill(skill_idx)
  end
end,

-- Maid Service
[1303] = function(player, my_idx, my_card, skill_idx)
  player:to_grave(Card(my_card.id))
  OneBuff(player, my_idx, {sta={"+", 1}}):apply()
  my_card:remove_skill_until_refresh(skill_idx)
end,

-- Maid Support
[1304] = function(player, my_idx, my_card, skill_idx)
  player:to_grave(Card(my_card.id))
  OneBuff(player, my_idx, {sta={"+", 1}}):apply()
  my_card:remove_skill_until_refresh(skill_idx)
end,

-- Iron Will!
[1305] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if not other_card then
    return
  end
  if other_card.size > my_card.size then
    OneBuff(player, my_idx, {atk={"+", 1}, def={"+", 1}}):apply()
  end
end,

-- Iron Defense!
[1306] = function(player, my_idx)
  OneBuff(player, my_idx, {def={"+", 1}}):apply()
end,

-- Fatal Strike!
[1307] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if not other_card then
    return
  end
  OneBuff(player, my_idx, {atk={"=", other_card.def + other_card.sta - 1}}):apply()
end,

-- Apostle's Skill
[1308] = function(player, my_idx)
  local mag = math.min(5, #player:grave_idxs_with_preds(pred.aletheian))
  OneBuff(player, my_idx, {atk={"+", mag}, sta={"+", math.ceil(mag / 2)}}):apply()
end,

-- Shining Star!
[1309] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if not other_card or other_card.def + other_card.sta > my_card.atk then
    OneBuff(player, my_idx, {atk={"+", 1}, sta={"+", 1}}):apply()
    return
  end
  OneBuff(player.opponent, 0, {life={"-", 1}}):apply()
end,

-- Accept my burder!
[1310] = function(player, my_idx)
  local mag = 0
  local f = function(card)
    if pred.follower(card) then
      mag = math.max(mag, card.sta + 1)
    end
    return false
  end
  player:field_idxs_with_preds(f)
  player.opponent:field_idxs_with_preds(f)
  OneBuff(player, my_idx, {atk={"=", mag}}):apply()
end,

-- You're an eyesore!
[1311] = function(player)
  local idx = player.opponent:field_idxs_with_preds(pred.spell)[1]
  if idx then
    player.opponent:field_to_grave(idx)
  end
end,

-- Dragon's Roar
[1312] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if not other_card then
    return
  end
  OneBuff(player.opponent, other_idx, {def={"-", 1}, sta={"-", 1}}):apply()
end,

-- Dragon's Strength
[1313] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if not other_card then
    return
  end
  OneBuff(player.opponent, other_idx, {atk={"-", 1}, def={"-", 1}}):apply()
end,

-- Let's do it together
[1314] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if not other_card then
    return
  end
  OneBuff(player, my_idx, {atk={"=", other_card.atk}}):apply()
end,

-- Coin of Desire
[1315] = function(player, my_idx, my_card, skill_idx)
  for i = 1, 5 do
    player:to_grave(Card(200349))
  end
  my_card:remove_skill(skill_idx)
end,

-- My Lucky Day
[1316] = function(player, my_idx, my_card)
  local idx = player:grave_idxs_with_preds(function(card) return floor(card.id) == 200349 end)[1]
  if not idx then
    return
  end
  player:grave_to_exile(idx)
  idx = player:first_empty_field_slot()
  if not idx then
    return
  end
  player.field[my_idx], player.field[idx] = nil, my_card
  my_card.active = false
  OneImpact(player, my_idx):apply()
end,

-- Defense Ward
[1317] = function(player, my_idx, my_card)
  if my_card.sta > 1 then
    OneBuff(player, my_idx, {def={"+", 1}, sta={"-", 1}}):apply()
  end
end,

-- Eyes of Future Sight
[1318] = function(player, my_idx, my_card)
  local mag = 0
  while #player.hand > 0 do
    mag = mag + (pred.lady(player.hand[1]) and 1 or 0)
    player:hand_to_bottom_deck(1)
  end
  local idxs = player:field_idxs_with_preds(function(card) return card ~= my_card end)
  for _, idx in ipairs(idxs) do
    mag = mag + (pred.lady(player.field[idx]) and 1 or 0)
    player:field_to_bottom_deck(idx)
  end
  OneBuff(player, my_idx, {atk={"+", mag}, sta={"+", mag}}):apply()
  while #player.hand < 4 and #player.deck > 0 do
    player:draw_a_card()
  end
end,

-- Battle Stance
[1319] = function(player, my_idx)
  OneBuff(player, my_idx, {def={"=", 2}}):apply()
end,

-- All Aboard!
[1320] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if not other_card then
    return
  end
  OneBuff(player.opponent, other_idx, {def={"-", 3}}):apply()
  OneBuff(player, my_idx, {def={"+", math.abs(other_card.def)}}):apply()
end,

-- Train Stop
[1321] = function(player)
  if floor(player.character.id) == 100117 and player.shuffles < 2 then
    player.shuffles = player.shuffles + 1
  end
end,

-- Synchro Life
[1322] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if not other_card or my_card.def + my_card.sta > other_card.atk then
    return
  end
  OneImpact(player, my_idx):apply()
  my_card:remove_skill(skill_idx)
  OneBuff(player.opponent, 0, {life={"-", math.ceil(my_card.size / 2)}}):apply()
end,

-- Overspending
[1323] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card and other_card.def + other_card.sta <= my_card.atk then
    OneBuff(player, 0, {life={"-", 1}}):apply()
  end
end,

-- crux knight ibis, balance of power!
[1324] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if player.character.faction == my_card.faction and other_card then
    local orig = Card(other_card.id)
    local buff = GlobalBuff(player)
    buff.field[player][my_idx] = {}
    buff.field[player.opponent][other_idx] = {}
    for _, stat in ipairs({"atk", "def", "sta"}) do
      if other_card[stat] > orig[stat] then
        local amt = floor((other_card[stat] - orig[stat]) / 2)
        buff.field[player][my_idx][stat] = {"+", ceil(amt / 2)}
        buff.field[player.opponent][other_idx][stat] = {"-", amt}
      end
    end
    buff:apply()
  end
  my_card:remove_skill_until_refresh(skill_idx)
end,

-- Power Change
[1325] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if not other_card then
    return
  end
  local idx = uniformly(player.opponent:field_idxs_with_preds(pred.follower))
  local mag = math.abs(other_card.atk)
  OneBuff(player.opponent, other_idx, {atk={"=", 0}}):apply()
  OneBuff(player.opponent, idx, {atk={"=", mag + player.opponent.field[idx].atk}}):apply()
end,

-- Song of Encouragement
[1326] = function(player)
  if player.field[2] and pred.follower(player.field[2]) then
    OneBuff(player, 2, {atk={"+", 1}, sta={"+", 1}}):apply()
  end
end,

-- Divine Attack!
[1327] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card then
    OneBuff(player.opponent, other_idx, {def={"-", 1}}):apply()
  end
end,

-- Clear a Path!
[1328] = function(player, my_idx, my_card, skill_idx)
  local idx = uniformly(player:field_idxs_with_preds(pred.follower,
    function(card) return card ~= my_card end))
  local buff = OnePlayerBuff(player)
  if idx then
    buff[idx] = {size={"-", 1}}
  end
  buff[my_idx] = {}
  my_card:remove_skill(skill_idx)
  buff:apply()
end,

-- Horizontal Slash
[1329] = function(player)
  local buff = OnePlayerBuff(player.opponent)
  for idx = 1, 3 do
    if player.opponent.field[idx] and pred.follower(player.opponent.field[idx]) then
      buff[idx] = {sta={"-", 1}}
    end
  end
  buff:apply()
end,

-- Curse
[1330] = function(player)
  local idx = uniformly(player.opponent:field_idxs_with_preds(pred.follower))
  if idx then
    OneBuff(player.opponent, idx, {atk={"-", 1}, sta={"-", 1}}):apply()
  end
end,

-- Knight's Pride
[1331] = function(player)
  local idx = uniformly(player:field_idxs_with_preds(pred.follower))
  if idx then
    OneBuff(player, idx, {atk={"+", 1}, sta={"+", 1}}):apply()
  end
end,

-- Overwhelm
[1332] = function(player)
  if player:field_size() > player.opponent:field_size() then
    OneBuff(player.opponent, 0, {life={"-", 1}}):apply()
  end
end,

-- Lend Power
-- Tea Time Student Council President Celine
[1333] = function(player, my_idx, my_card)
  OneBuff(player, my_idx, {atk={"-", 1}, def={"-", 1}, sta={"-", 1}}):apply()
  local idx = uniformly(player:field_idxs_with_preds(pred.follower))
  if idx then
    OneBuff(player, idx, {atk={"+", 1}, def={"+", 1}, sta={"+", 1}}):apply()
  end
end,

-- P.F. Academy
-- Transfer Student Storm Bringer Sis
[1334] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if pred.V(player.character) and other_card and pred.A(other_card) then
    OneBuff(player.opponent, other_idx, {atk={"-", 3}, sta={"-", 3}}):apply()
  end
end,

-- Shield Burst
-- Summer Uniform Sita, Dark Lady Seven, Youngest Knight Rotori, Crescent Conundrum, Child Sage
[1335] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if player.character.faction == my_card.faction and other_card then
    local mag = math.min(9, math.abs(my_card.def - other_card.def))
    OneBuff(player, my_idx, {atk={"+", mag}, sta={"+", mag}}):apply()
  end
end,

-- Shield of 4
-- Leering Witch
[1336] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card and other_card.size >= 4 then
    OneBuff(player, my_idx, {sta={"+", other_card.atk}}):apply()
  end
  my_card:remove_skill_until_refresh(skill_idx)
end,

-- P.F. Vita
-- Pure Maid
[1337] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if pred.A(player.character) and other_card and pred.V(other_card) then
    OneBuff(player.opponent, other_idx, {atk={"-", 3}, sta={"-", 3}}):apply()
  end
end,

-- Song of Power
-- Poison Luthica
[1338] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local idxs = player:field_idxs_with_preds(pred.follower)
  local buff = OnePlayerBuff(player)
  for i = 1, #idxs do
    buff[idxs[i]] = {atk={"+", 3}, sta={"-", 2}}
  end
  buff:apply()
  my_card:remove_skill_until_refresh(skill_idx)
end,

-- P.F. Darklore
-- Knight of Destruction Pintail
[1339] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if pred.C(player.character) and other_card and pred.D(other_card) then
    OneBuff(player.opponent, other_idx, {atk={"-", 3}, sta={"-", 3}}):apply()
  end
end,

-- All or Nothing
-- Reading Witch
[1340] = function(player, my_idx)
  if math.abs(player.character.life - player.opponent.character.life) >= 10 then
    local str = player.character.life < player.opponent.character.life and "+" or "-"
    OneBuff(player, my_idx, {atk={str, 2}, def={str, 2}, sta={str, 2}}):apply()
  end
end,

-- P.F. Crux
-- Witch Parfunte
[1341] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if pred.D(player.character) and other_card and pred.C(other_card) then
    OneBuff(player.opponent, other_idx, {atk={"-", 3}, sta={"-", 3}}):apply()
  end
end,

-- Life Change
-- Yellow Queen Cannelle
[1342] = function(player, my_idx, my_card)
  local idx = player:field_idxs_with_least_and_preds(pred.sta, pred.follower)[1]
  local buff = OnePlayerBuff(player)
  buff[idx] = {sta={"=", my_card.sta}}
  buff[my_idx] = {sta={"=", player.field[idx].sta}}
  buff:apply()
end,

-- P.F. Colorless
-- Legacy Sojourner
[1343] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card and pred.N(other_card) then
    OneBuff(player.opponent, other_idx, {atk={"-", 3}, sta={"-", 3}}):apply()
  end
end,

-- Counterattack
[1344] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card and player.character.faction == my_card.faction then
    OneBuff(player.opponent, other_idx, {atk={"-", 1}, sta={"-", 1}}):apply()
  end
end,

-- Healing Technique
-- Tennis Club Fiddle, Lady Cutie, Crux Knight Prea, Myo Informant
[1345] = function(player, my_idx)
  if player.opponent:is_npc() then
    OneBuff(player, my_idx, {sta={"+", 3}}):apply()
  else
    OneBuff(player, my_idx, {sta={"+", 1}}):apply()
  end
end,

-- Turnabout Technique
-- Tennis Club Advisor Miki
[1346] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card and other_card.atk > my_card.def + my_card.sta then
    local buff = GlobalBuff(player)
    buff.field[player][my_idx] = {sta={"=", other_card.sta}}
    buff.field[player.opponent][other_idx] = {sta={"=", my_card.sta}}
    buff:apply()
    my_card.skills[skill_idx] = nil
  end
end,

-- Disarm
-- Spirit of the Underground Library
[1347] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card then
    if other_card.def >= 1 then
      OneBuff(player.opponent, other_idx, {def={"=", math.floor(other_card.def / 2)}}):apply()
    end
    if other_card.def <= 1 then
      OneBuff(player.opponent, other_idx, {sta={"-", 1}}):apply()
    end
  end
end,

-- Curse Magic
-- Lady Detective
[1348] = function(player)
  local idxs = player.opponent:field_idxs_with_preds(pred.follower)
  local buff = OnePlayerBuff(player.opponent)
  for i = 1, 2 do
    if idxs[i] then
      buff[idxs[i]] = {atk={"-", 1}, sta={"-", 1}}
    end
  end
  buff:apply()
end,

-- Splash
-- Southern Lady
[1349] = function(player, my_idx, my_card, skill_idx, other_idx)
  local idxs = {}
  for i = -1, 1 do
    if other_idx + i >= 1 and other_idx + i <= 5 and player.opponent.field[other_idx + i]
        and pred.follower(player.opponent.field[other_idx + i]) then
      table.insert(idxs, other_idx + i)
    end
  end
  local mag = math.floor(math.floor(my_card.atk / 2) / #idxs)
  local buff = OnePlayerBuff(player.opponent)
  for _, idx in ipairs(idxs) do
    buff[idx] = {sta={"-", mag}}
  end
  buff:apply()
end,

-- The Power of Peers
-- Crux Knight Kraros
[1350] = function(player)
  if player.game.turn % 2 == 0 then
    local idxs = player:field_idxs_with_preds(pred.follower, pred.C)
    local buff = OnePlayerBuff(player)
    for _, idx in ipairs(idxs) do
      buff[idx] = {atk={"+", 2}, sta={"+", 2}}
    end
    buff:apply()
  end
end,

-- Weaken
-- Crux Knight Oclette
[1351] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card then
    other_card:gain_skill(1354)
    if other_card.skills[1] and other_card.skills[2] and other_card.skills[3] then
      OneBuff(player.opponent, other_idx, {atk={"-", 2}, sta={"-", 2}}):apply()
    end
  end
end,

-- Strike While the Iron's Hot!
-- GS 6th Star
[1352] = function(player, my_idx)
  if #player.grave >= 7 and player.game.turn <= 7 then
    local mag = math.min(4, 7 - player.game.turn)
    OneBuff(player, my_idx, {atk={"+", mag}, sta={"+", mag}}):apply()
  end
end,

-- Cowardice
-- The Forgotten Ancient God
[1353] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card then
    local mag = #player:field_idxs_with_preds()
    OneBuff(player.opponent, other_idx, {atk={"-", mag}}):apply()
  end
end,

-- idk
-- Crux Knight Oclette
[1354] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  OneBuff(player, my_idx, {atk={"-", 1}, sta={"-", 1}}):apply()
end,

-- Guide Rio
[1355] = function(player, my_idx, my_card)
  OneBuff(player, my_idx, {def={"+", 1}}):apply()
end,

-- Skill from Chance Meeting
[1356] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local buff = {}
  local orig = Card(my_card.id)
  for _,attr in ipairs({"atk", "def"}) do
    if my_card[attr] < orig[attr] then
      buff[attr] = {"=", orig[attr]}
    end
  end
  OneBuff(player, my_idx, buff):apply()
end,

-- Student Council Press Hermes
-- Equipment Rental!
[1357] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card then
    OneBuff(player.opponent, other_idx, {def={"+", 1}}):apply()
  end
end,

-- Student Council Press Hermes
-- Equipment Return!
[1358] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card and other_card.def >= 5 then
    OneImpact(player.opponent, other_idx):apply()
    player.opponent:field_to_grave(other_idx)
  end
end,

-- Cook Club Apprentice Iri
-- Charge!!
[1359] = function(player, my_idx)
  OneBuff(player, my_idx, {atk={"+", 2}, sta={"+", 1}}):apply()
end,

-- Restorative Infusion!
-- Lady on the Water
[1360] = function(player, my_idx, my_card, skill_idx)
  local mag = Card(my_card.id).sta
  if mag > my_card.sta then
    OneBuff(player, my_idx, {sta={"=", mag}}):apply()
  end
  my_card:remove_skill(skill_idx)
end,

-- Glasses Maid
-- Genius Control!
[1361] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card and (#other_card:squished_skills() >= 2) then
    other_card.skills = {1076}
    OneImpact(player.opponent, other_idx):apply()
    OneBuff(player, my_idx, {atk={"+", 1}, sta={"+", 2}}):apply()
  end
end,

-- Maid Producer
-- Equivalent Exchange
[1362] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local check = 0
  local idx = my_idx - 1
  if idx > 0 and player.field[idx] and pred.A(player.field[idx]) then
    OneImpact(player, idx):apply()
    player:field_to_bottom_deck(idx)
    check = check + 1
  end
  idx = my_idx + 1
  if idx < 6 and player.field[idx] and pred.A(player.field[idx]) then
    OneImpact(player, idx):apply()
    player:field_to_bottom_deck(idx)
    check = check + 1
  end
  if other_card and check == 2 then
    local impact = Impact(player)
    impact[player.opponent][other_idx] = true
    impact[player][my_idx] = true
    impact:apply()
    player.opponent:field_to_grave(other_idx)
    my_card:remove_skill(skill_idx)
  end
end,

-- Lady Vid and Ron
-- Trade!
[1363] = function(player, my_idx, my_card, skill_idx)
  local mag = 0
  for i = 1, 4 do
    if player.deck[1] then
      if pred.A(player.deck[1]) and pred.spell(player.deck[1]) then
        mag = mag + 1
      end
      player:deck_to_grave(1)
    end
  end
  for i = 1, mag do
    for i2 = 1, 2 do
      local idx = uniformly(player:grave_idxs_with_preds(pred.A, pred.follower))
      if idx then
        player:grave_to_bottom_deck(idx)
      end
    end
  end
  my_card:remove_skill(skill_idx)
end,

-- Blu e Rosso
-- Submission!
[1364] = function(player, my_idx, my_card, skill_idx)
  local idx = player.opponent:first_empty_field_slot()
  if idx then
    OneImpact(player, my_idx):apply()
    player.opponent.field[idx], player.field[my_idx] = my_card, nil
  end
  my_card:remove_skill_until_refresh(skill_idx)
end,

-- Knight Guard
-- Fair and Square
[1365] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card then
    local mag = Card(other_card.id).atk
    OneBuff(player.opponent, other_idx, {atk={"=", mag}}):apply()
  end
  my_card:remove_skill(skill_idx)
end,

-- Blue Cross L-eader
-- Power of Concentration!
[1366] = function(player, my_idx, my_card)
  local idx = uniformly(player:field_idxs_with_preds(pred.follower,
    function(card) return card ~= my_card end))
  if idx and #player.field[idx]:squished_skills() > 0 then
    local mag = #player.field[idx]:squished_skills() + 1
    local buff = OnePlayerBuff(player)
    buff[idx] = {atk={"+", mag}, sta={"+", mag}}
    buff[my_idx] = {atk={"+", mag}, sta={"+", mag}}
    buff:apply()
    player.field[idx].skills = {}
  end
end,

-- Blue Cross L-eader
-- Tactical Training!
[1367] = function(player, my_idx, my_card)
  local idx = uniformly(player:field_idxs_with_preds(pred.follower,
    function(card) return card ~= my_card end))
  if idx then
    player.field[idx]:gain_skill(1055)
  end
end,

-- Crescent Kris Flina
-- There can only be one!
[1368] = function(player, my_idx, my_card)
  local pred_name = function(card) return card.name == my_card.name end
  local idx = player:deck_idxs_with_preds(pred_name)[1]
  if idx then
    player:deck_to_grave(idx)
    local mag = #player:grave_idxs_with_preds(pred_name) + 3
    OneBuff(player, my_idx, {sta={"+", mag}}):apply()
  end
end,

-- Red Moon Aka Flina
-- Sacrifice! Red Moon!
[1369] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card then
    local mag = #player:grave_idxs_with_preds(
      function(card) return card.name == my_card.name end) + 1
    OneBuff(player.opponent, other_idx, {sta={"-", mag}}):apply()
  end
end,

-- Blue Moon Becky Flina
-- Sacrifice! Blue Moon!
[1370] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card then
    local mag = math.abs(other_card.size - other_card.def)
    local mag2 = math.ceil(mag / 2)
    OneBuff(player.opponent, other_idx, {sta={"-", mag}}):apply()
    OneBuff(player, my_idx, {atk={"+", mag2}, sta={"+", mag2}}):apply()
    my_card:remove_skill_until_refresh(skill_idx)
  end
end,

-- Cook Club Apprentice Iri
-- Prepare to Charge!
[1371] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  OneBuff(player, my_idx, {atk={"+",1}}):apply()
  if other_card and other_card.def + other_card.sta <= my_card.atk then
    my_card.skills[skill_idx] = 1359
  end
end,

-- Student Council Secretary Fran
-- Giant Growth
[1372] = function(player, my_idx, my_card, skill_idx)
  if my_card.size >= 4 then
    my_card:remove_skill(skill_idx)
  end
  local mag = my_card.size
  OneBuff(player, my_idx, {size={"+", 1}, atk={"+", mag}, sta={"+", mag}}):apply()
end,

-- Library Club Bernoulli
-- Incompetence
[1373] = function(player, my_idx)
  local mag = 0
  for i = 1, min(4, #player.deck) do
    if pred.spell(player.deck[i]) then
      mag = mag + 1
    end
  end
  OneBuff(player, my_idx, {sta={"-", mag}}):apply()
end,

-- Nanai Highcastle
-- Grave of All Creation
[1374] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card then
    local check = {}
    local mag = 1
    for i = 1, #player.grave do
      if not check[player.grave[i].size] then
        mag = mag + 1
        check[player.grave[i].size] = true
      end
    end
    OneBuff(player.opponent, other_idx, {sta={"-", mag}}):apply()
    if not player.opponent.field[other_idx] then
      local idx = player:first_empty_field_slot()
      if idx then
        OneImpact(player, my_idx):apply()
        player.field[idx], player.field[my_idx] = my_card, nil
        my_card.active = true
      end
    else
      local idx = uniformly(player:grave_idxs_with_preds())
      if idx then
        player:grave_to_exile(idx)
      end
    end
  end
end,

-- Jackpot Maid
-- Jackpot!
[1375] = function(player, my_idx)
  local check = uniformly({true, true, true, false, false,
    false, false, false, false, false})
  if check then
    OneBuff(player, my_idx, {atk={"+", 2}, sta={"+", 2}}):apply()
  end
end,

-- Jackpot Maid
-- Jackpot!
[1376] = function(player, my_idx)
  local check = uniformly({true, true, true, false, false,
    false, false, false, false, false})
  if check then
    OneBuff(player, my_idx, {atk={"+", 2}, sta={"+", 2}}):apply()
  end
end,

-- Lonely Maid
-- Discrimination
[1377] = function(player, my_idx, my_card)
  local check = #player:field_idxs_with_preds(pred.A,
    function(card) return card ~= my_card end) == 0
  if check then
    OneBuff(player, my_idx, {sta={"+", 3}}):apply()
  end
end,

-- Madness Maid
-- Maid Maid!
[1378] = function(player, my_idx)
  local mag = #player:hand_idxs_with_preds(pred.maid)
  OneBuff(player, my_idx, {atk={"+", mag}}):apply()
end,

-- Madness Maid
-- Forced Sacrifice
[1379] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card and other_card.atk >= my_card.def + my_card.sta then
    local idx = player:hand_idxs_with_preds(pred.follower, pred.maid)[1]
    if idx then
      OneBuff(player, my_idx, {sta={"+", player.hand[idx].sta}}):apply()
      player:hand_to_grave(idx)
    end
  end
end,

-- Blue Cross Member
-- Member's Protection
[1380] = function(player, my_idx, my_card, skill_idx)
  OneBuff(player, 0, {life={"+", 2}}):apply()
  my_card:remove_skill(skill_idx)
end,

-- Flag Knight Frett
-- Knight's Pride
[1381] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card then
    local mag_def = #player:field_idxs_with_preds(pred.follower, pred.knight)
    local mag_sta = mag_def + ((my_idx == 3) and 2 or 0)
    OneBuff(player.opponent, other_idx, {def={"-", mag_def}, sta={"-", mag_sta}}):apply()
    if pred.knight(player.character) then
      OneBuff(player, my_idx, {def={"=", 2}}):apply()
    end
  end
end,

-- Undertaker
-- Curse
[1382] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if player.grave[1] and pred.D(player.grave[#player.grave]) and other_card then
    local mag = math.ceil(player.grave[#player.grave].size / 2)
    player:grave_to_exile(#player.grave)
    OneBuff(player.opponent, other_idx, {atk={"-", mag}}):apply()
  end
end,

-- Ire Flina
-- Vampire Hunting
[1383] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  player:to_top_deck(Card(300062))
  local check = #player:grave_idxs_with_preds(pred.follower) >= 10
  if check then
    OneBuff(player, my_idx, {atk={"+", 1}}):apply()
  end
end,

-- GS 5th Star
-- Battlefield Ruler
[1384] = function(player, my_idx, my_card, skill_idx)
  if pred.D(player.character) then
    if player.grave[1] then
      player:grave_to_exile(1)
    end
    local mag = #player.grave
    OneBuff(player, my_idx, {atk={"=", mag}, sta={"=", mag}}):apply()
  end
  my_card:remove_skill_until_refresh(skill_idx)
end,

-- White Whale Crevasse
-- Holy Guardian's Power
[1385] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  OneBuff(player, my_idx, {atk={"+",1}}):apply()
  for i = 1, 5 do
    local idx = uniformly(player:deck_idxs_with_preds(pred.follower))
    if idx then
      local buff = GlobalBuff(player)
      buff.deck[player][idx] = {atk={"+", 1}}
      buff:apply()
    end
  end
end,

-- White Whale Crevasse
-- Holy Guardian's Blessing
[1386] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  OneBuff(player, my_idx, {sta={"+",1}}):apply()
  for i = 1, 5 do
    local idx = uniformly(player:deck_idxs_with_preds(pred.follower))
    if idx then
      local buff = GlobalBuff(player)
      buff.deck[player][idx] = {sta={"+", 1}}
      buff:apply()
    end
  end
end,

-- 1st Anniversary Power
[1387] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card and other_card.def + other_card.sta <= my_card.atk then
    player.opponent:to_top_deck(Card(200070))
  end
end,

-- Cook Club Jamie
-- Control Your Feelings
[1388] = function(player, my_idx, my_card)
  local orig = Card(my_card.id)
  if my_card.size ~= orig.size then
    local mag = math.abs(my_card.size - orig.size)
    OneBuff(player, my_idx, {size={"=", orig.size}, atk={"+", mag}, sta={"+", mag}}):apply()
  end
end,

-- l. esprit, quest for truth!
[1389] = lesprit,

-- l. esprit, quest for truth!
[1390] = lesprit,

-- Cook Club Jamie
-- Exploration Preparation
[1391] = function(player, my_idx, my_card, skill_idx)
  OneBuff(player, my_idx, {size={"+", 1}}):apply()
  my_card:remove_skill(skill_idx)
end,

-- Library Club Rangers
-- Awakening of Power!
[1392] = function(player, my_idx, my_card, skill_idx)
  OneBuff(player, my_idx, {atk={"+", 2}}):apply()
  my_card:remove_skill(skill_idx)
end,

-- Library Club Rangers
-- Applied Knowledge
[1393] = function(player, my_idx, my_card)
  local mag = 0
  for i = 1, min(4, #player.deck) do
    if pred.follower(player.deck[i]) then
      mag = mag + 1
    end
  end
  local idxs = player:field_idxs_with_preds(pred.follower)
  local buff = OnePlayerBuff(player)
  for _, idx in ipairs(idxs) do
    buff[idx] = {sta={"+", mag}}
  end
  buff:apply()
  if mag >= 2 then
    my_card:refresh()
  end
end,

-- Rich Lady
-- Hire Maids!
[1394] = function(player, my_idx, my_card, skill_idx)
  local idx = uniformly(player:grave_idxs_with_preds(pred.maid))
  if idx and #player.hand < 5 then
    local card = player.grave[idx]
    table.remove(player.grave, idx)
    player.hand[#player.hand + 1] = card
    my_card:remove_skill_until_refresh(skill_idx)
  end
end,

-- Broker Lady
-- Breach of Contract
[1395] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if player.character.life <= 8 then
    local impact = Impact(player)
    if other_card then
      impact[player.opponent][other_idx] = true
    end
    impact[player][my_idx] = true
    impact:apply()
    if other_card then
      player.opponent:field_to_grave(other_idx)
    end
    player:field_to_grave(my_idx)
  end
end,

-- Dress Up Lady Linus
-- Dress Up Time~
[1396] = function(player, my_idx, my_card, skill_idx)
  local idx = reverse(player:hand_idxs_with_preds(pred.dress_up))[1]
  if idx then
    local mag = player.hand[idx].size
    player:hand_to_bottom_deck(idx)
    local impact = Impact(player)
    local idxs = shuffle(player:field_idxs_with_preds(pred.neg(pred.dress_up)))
    for _, idx in ipairs(idxs) do
      impact[player][idx] = true
      player.field[idx].active = false
    end
    idxs = shuffle(player.opponent:field_idxs_with_preds(pred.neg(pred.dress_up)))
    for _, idx in ipairs(idxs) do
      impact[player.opponent][idx] = true
      player.opponent.field[idx].active = false
    end
    impact:apply()
  end
  my_card:remove_skill_until_refresh(skill_idx)
end,

-- Knight Lancer Shane
-- Power Thrust
[1397] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card and other_card.size < my_card.size then
    player.opponent:field_to_grave(other_idx)
  else
    player:field_to_grave(my_idx)
  end
  my_card:remove_skill(skill_idx)
end,

-- Seeker Melissa
-- Attack Stance
[1398] = function(player, my_idx)
  OneBuff(player, my_idx, {atk={"+", 1}, sta={"-", 1}}):apply()
end,

-- Seeker Melissa
-- Defensive Stance
[1399] = function(player, my_idx)
  OneBuff(player, my_idx, {atk={"-", 1}, def={"+", 1}}):apply()
end,

-- Knight Captain Eisenwane
-- Assimilate!
[1400] = function(player, my_idx)
  local mag = player.field[uniformly(player:field_idxs_with_preds(pred.follower))].atk + 1
  OneBuff(player, my_idx, {atk={"=", mag}}):apply()
end,

-- Knight Captain Eisenwane
-- Assimilate!
[1401] = function(player, my_idx)
  local mag = player.field[uniformly(player:field_idxs_with_preds(pred.follower))].def
  OneBuff(player, my_idx, {def={"=", mag}}):apply()
end,

-- Apostle Red Sun
-- Doubt
[1402] = function(player, my_idx, my_card, skill_idx)
  local check = #player.opponent:field_idxs_with_preds(pred.active) == 0
  if check then
    local mag = #player.opponent:empty_field_slots() + 1
    OneBuff(player, my_idx, {atk={"+", mag}, sta={"+", mag}}):apply()
    my_card:remove_skill_until_refresh(skill_idx)
  end
end,

-- Witch Herionne
-- Control Time
[1403] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card and pred[player.opponent.character.faction](other_card) then
    local buff = GlobalBuff(player)
    local mag = my_card.size
    buff.field[player.opponent][other_idx] = {atk={"-", mag}, sta={"-", mag}}
    mag = math.floor(mag /  2)
    buff.field[player][my_idx] = {atk={"+", mag}, sta={"+", mag}}
    buff:apply()
    my_card:remove_skill_until_refresh(skill_idx)
  end
end,

-- Head Luna Flina
-- Master's Resolve
[1404] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local check = #player:field_idxs_with_preds(pred.D,
      function(card) return card ~= my_card end) > 0
  if check then
    local idx = uniformly(player:empty_field_slots())
    if idx then
      OneImpact(player, my_idx):apply()
      player.field[my_idx], player.field[idx] = nil, my_card
      if other_card then
        local buff = GlobalBuff(player)
        buff.field[player.opponent][other_idx] = {atk={"-", idx}}
        buff.field[player][idx] = {sta={"+", idx}}
        buff:apply()
      end
    end
  end
  my_card:remove_skill_until_refresh(skill_idx)
end,

-- Captured Spirit
-- So tired...
[1405] = function(player, my_idx)
  OneBuff(player, my_idx, {sta={"-", 1}}):apply()
end,

-- Trace of Kana
-- Absorb Power
[1407] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card then
    my_card.skills[skill_idx] = other_card.skills[1]
    other_card:remove_skill(1)
  end
end,

-- resistance
[1408] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card then
    OneBuff(player, my_idx, {sta={"+",floor(other_card.atk/2)}}):apply()
  end
  my_card:remove_skill(skill_idx)
end,

-- Cook Club Sylphie
-- Neutralize Defense
[1409] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card then
    OneBuff(player.opponent, other_idx, {def={"=", 0}}):apply()
  end
  my_card:remove_skill_until_refresh(skill_idx)
end,

-- Student Council Weekly Weekly
-- Terror
[1410] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card then
    OneBuff(player.opponent, other_idx, {atk={"-", 1}}):apply()
  end
end,

-- Student Council Kingmakers
-- Trial of Strength
[1411] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card then
    OneBuff(player, my_idx, {atk={"=", other_card.def}}):apply()
  end
end,

-- Student Council KingMakers
-- Student Council's Potential
[1412] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card then
    local idx = player:hand_idxs_with_preds(pred.follower, pred.V)[1]
    local mag = 3 + ((idx and math.ceil(player.hand[idx].atk / 2)) or 0)
    OneBuff(player.opponent, other_idx, {sta={"-", mag}}):apply()
  end
end,

-- Maid Lesnoa
-- Maid Knowledge
[1413] = function(player, my_idx)
  local mag = #player:hand_idxs_with_preds(pred.maid)
  OneBuff(player, my_idx, {atk={"+", mag}}):apply()
end,

-- Maid Fio
-- Maintain Stamina
[1414] = function(player, my_idx)
  local mag = #player:empty_hand_slots()
  OneBuff(player, my_idx, {sta={"+", mag}}):apply()
  while (not player.hand[4]) and player.deck[1] do
    player:deck_to_hand(#player.deck)
  end
end,

-- Muzisitter Lady Sevia
-- Emergency Recovery
[1415] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card then
    if my_card.atk <= other_card.def + other_card.sta then
      local buff = GlobalBuff(player)
      local mag = other_card.size - 1
      buff.field[player.opponent][other_idx] = {size={"=", 1}}
      buff.field[player][0] = {life={"+", mag}}
      mag = math.ceil(mag / 2)
      buff.field[player][my_idx] = {atk={"+", mag}, sta={"+", mag}}
      buff:apply()
    end
  end
end,

-- Knight Marksman
-- Knight's Lesson
[1416] = function(player, my_idx, my_card, skill_idx)
  local idxs = player:field_idxs_with_preds(pred.follower, pred.knight)
  local buff = OnePlayerBuff(player)
  for _, idx in ipairs(idxs) do
    buff[idx] = {sta={"+", 2}}
  end
  buff:apply()
  my_card:remove_skill(skill_idx)
end,

-- Crux Knight Sillit
-- Counterattack
[1417] = function(player, my_idx, my_card, skill_idx)
  if not my_card.active then
    OneBuff(player, my_idx, {sta={"+", 3}}):apply()
    my_card.active = true
    my_card:remove_skill(skill_idx)
  end
end,

-- Crux Knight Lukif
-- Fine Tuning
[1418] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card and other_card.atk >= 1 then
    OneBuff(player, my_idx, {sta={"=", other_card.atk}}):apply()
  end
end,

-- Aletheian G-NUSA
-- Seeds of Misfortune
[1419] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card and other_card.sta >= Card(other_card.id).sta and
      other_card.skills[1] ~= 1354 and other_card.skills[2] ~= 1354 and other_card.skills[3] ~= 1354 then
    OneImpact(player.opponent, other_idx):apply()
    other_card:gain_skill(1354)
  end
end,

-- GS 7th Star
-- Restrained Fury
[1420] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card and other_card.sta > my_card.atk then
    local mag = 1 + other_card.sta - my_card.atk
    OneBuff(player, my_idx, {atk={"+", mag}, sta={"-", mag}}):apply()
    my_card:remove_skill(skill_idx)
  end
end,

-- Dark Sword Master A-GA
-- Dark Sword
[1421] = function(player, my_idx, my_card)
  local buff = GlobalBuff(player)
  local idxs = player.opponent:field_idxs_with_preds(pred.follower)
  local mag = 0
  for _, idx in ipairs(idxs) do
    buff.field[player.opponent][idx] = {atk={"-", 1}}
    mag = mag + 1
  end
  buff.field[player][my_idx] = {atk={"+", mag}}
  buff:apply()
  buff = OnePlayerBuff(player)
  idxs = player:field_idxs_with_preds(pred.follower)
  local mag = math.floor(math.abs(my_card.atk) / 10) % 10
  for _, idx in ipairs(idxs) do
    buff[idx] = {sta={"+", mag}}
  end
  buff:apply()
end,

-- Tigress Felpix
-- I'm on your side.
[1422] = function(player, my_idx, my_card)
  local idx = player.opponent:first_empty_field_slot()
  if my_card.size <= 4 and idx then
    OneBuff(player, my_idx, {size={"=", 7}, sta={"+", 2}}):apply()
    player.field[my_idx], player.opponent.field[idx] = nil, my_card
    my_card.active = false
  end
end,

-- Tigress Felpix
-- Sorry. That was a mistake
[1423] = function(player, my_idx, my_card)
  local idx = player.opponent:first_empty_field_slot()
  if my_card.size >= 5 and idx then
    local idxs = player:field_idxs_with_preds(pred.follower)
    local buff = OnePlayerBuff(player)
    for _, idx in ipairs(idxs) do
      buff[idx] = {atk={"-", 2}, sta={"-", 2}}
    end
    buff[my_idx] = {size={"=", 3}}
    buff:apply()
    player.field[my_idx], player.opponent.field[idx] = nil, my_card
    my_card.active = false
  end
end,

-- L. Sita, Cinia, Luthica, Iri
-- Cocoon
[1424] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card then
    local check = false
    for i = 1, 3 do
      if skill_id_to_type[other_card.skills[i]] == "attack" then
        check = true
      end
    end
    if check and pred[player.character.faction](my_card) then
      OneBuff(player, my_idx, {sta={"+", other_card.atk}}):apply()
    end
  end
end,

-- girls' harmony, chrysalis!
[1425] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card and pred.skill(other_card) then
    OneBuff(player, my_idx, {sta={"+",other_card.atk}}):apply()
  end
end,

-- Library Club Snowty
-- Forgetfulness
[1427] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card and other_card:squished_skills()[1] then
    OneImpact(player.opponent, other_idx):apply()
    other_card.skills = {}
    my_card:remove_skill(skill_idx)
  end
end,

-- Cook Club's Glutton
-- Cook Club Summon
[1428] = function(player, my_idx)
  local idx = player:hand_idxs_with_preds(pred.cook_club)[1]
  if idx then
    player:hand_to_top_deck(idx)
    OneBuff(player, my_idx, {atk={"+", 1}, sta={"+", 2}}):apply()
  end
end,

-- Girl Detective Asmis
-- Begin the deduction
[1429] = function(player)
  local idxs = player:field_idxs_with_preds(pred.follower)
  local buff = OnePlayerBuff(player)
  for _, idx in ipairs(idxs) do
    buff[idx] = {size={"-", 0}, atk={"+", 0}, def={"+", 0}, sta={"+", 0}}
    local check = true
    if pred.library_club(player.field[idx]) then
      buff[idx].atk[2] = buff[idx].atk[2] + 1
      check = false
    end
    if pred.student_council(player.field[idx]) then
      buff[idx].def[2] = buff[idx].def[2] + 1
      check = false
    end
    if pred.cook_club(player.field[idx]) then
      buff[idx].size[2] = buff[idx].size[2] + 1
      check = false
    end
    if pred.asmis(player.field[idx]) then
      buff[idx].atk[2] = buff[idx].atk[2] + 1
      buff[idx].sta[2] = buff[idx].sta[2] + 1
      check = false
    end
    if check then
      buff[idx].sta[2] = buff[idx].sta[2] + 2
    end
  end
  buff:apply()
end,

-- Night Lady
-- Defense Technique
[1430] = function(player, my_idx, my_card)
  if my_card.active then
    OneBuff(player, my_idx, {def={"+", 1}, sta={"+", 2}}):apply()
    my_card.active = false
  end
end,

-- Lady Elbert
-- Reverse Attack!
[1431] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card then
    local mag_atk = other_card.sta
    local mag_sta = other_card.atk
    OneBuff(player.opponent, other_idx, {atk={"=", mag_atk}, sta={"=", mag_sta}}):apply()
  end
  my_card:remove_skill_until_refresh(skill_idx)
end,

-- Guitar Witch Maid
-- Maid's Performance
[1432] = function(player, my_idx)
  if player.grave[1] then
    local check = pred.maid(player.grave[#player.grave])
    player:grave_to_exile(#player.grave)
    OneBuff(player, my_idx, {atk={"+", check and 1 or 0}, sta={"+", check and 3 or 2}}):apply()
  end
end,

-- Knight's Parrot Kocchan
-- Messenger!
[1433] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card then
    local mag = floor(other_card.sta / 2)
    local buff = GlobalBuff(player)
    buff.field[player][my_idx] = {}
    buff.field[player.opponent][other_idx] = {atk={"+", mag}, sta={"=", other_card.sta - mag}}
    buff:apply()
    my_card:remove_skill(skill_idx)
  end
end,

-- Knight Manager
-- Management
[1434] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card and my_card.atk < other_card.def + other_card.sta then
    OneBuff(player, my_idx, {atk={"+", other_card.def}}):apply()
  end
end,

-- Seeker Beryl
-- Artifact Use
[1435] = function(player)
  if pred.C(player.character) then
    local idx = player.opponent:first_empty_hand_slot()
    if player.opponent.deck[1] and idx then
      player.opponent:deck_to_hand(#player.opponent.deck)
      local buff = GlobalBuff(player)
      if pred.follower(player.opponent.hand[idx]) then
        buff.hand[player.opponent][idx] = {def={"-", 1}}
      else
        buff.field[player][0] = {life={"+", 1}}
      end
      buff:apply()
    end
  end
end,

-- Scardel Unit Tyrfing
-- Restlessness
[1436] = function(player, my_idx)
  local buff = OnePlayerBuff(player)
  for i = max(my_idx - 1, 1), min(my_idx + 1, 5) do
    if player.field[i] and pred.follower(player.field[i]) then
      buff[i] = {atk={"+", 1}}
    end
  end
  buff:apply()
end,

-- Apostle Reshuri
-- Aletheian Deployment
[1437] = function(player)
  local idx = player:first_empty_field_slot()
  if idx then
    player.field[idx] = Card(300529)
    OneBuff(player, idx, {size={"-", 1}}):apply()
  end
end,

-- Apostle Red Sun
-- Proof of Miracles
[1438] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card and other_card.active then
    OneBuff(player.opponent, other_idx, {atk={"-", 1}, sta={"-", 1}}):apply()
  else
    OneBuff(player, my_idx, {atk={"+", 1}, sta={"+", 1}}):apply()
  end
end,

-- 5th Witness Kana DDD
-- I will eliminate you
[1439] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card then
    local mag = other_card.size
    local buff = GlobalBuff(player)
    buff.field[player.opponent][other_idx] = {}
    buff.field[player][my_idx] = {sta={"+", mag}}
    buff:apply()
    player.opponent:field_to_bottom_deck(other_idx)
  end
end,

-- Isfeldt's Threat
-- Terror
[1440] = function(player, my_idx)
  OneImpact(player, my_idx):apply()
  player:field_to_bottom_deck(my_idx)
end,

-- Library Club Researcher Albert
-- Relativity Impetus!
[1441] = function(player, my_idx, my_card, skill_idx)
  local idxs = player:deck_idxs_with_preds(pred.library_club, pred.follower)
  local buff = GlobalBuff(player)
  for _, idx in ipairs(idxs) do
    buff.deck[player][idx] = {atk={"+", 1}, sta={"+", 1}}
  end
  buff.field[player][my_idx] = {}
  buff:apply()
  my_card:remove_skill(skill_idx)
end,

-- Library Club Head Researcher Von
-- Book Search
[1442] = function(player, my_idx)
  local idxs = player:deck_idxs_with_preds(pred.spell)
  if idxs[1] then
    local idx = idxs[#idxs]
    player:deck_to_top_deck(idx)
    local mag = min(player.deck[#player.deck].size, 3)
    OneBuff(player, my_idx, {atk={"+", mag}}):apply()
  end
end,

-- Library Club Head Researcher Von
-- Book Return
[1443] = function(player, my_idx)
  local idxs = player:deck_idxs_with_preds(pred.follower)
  if idxs[1] then
    local idx = idxs[#idxs]
    player:deck_to_top_deck(idx)
    local mag = ceil(player.deck[#player.deck].size / 2)
    OneBuff(player, my_idx, {sta={"+", mag}}):apply()
  end
end,

-- Northern Lady
-- Liberation
[1444] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card and other_card.atk >= my_card.def + my_card.sta then
    local buff = OnePlayerBuff(player)
    buff[0] = {life={"-", 1}}
    buff[my_idx] = {size={"=", 1}, atk={"-", 1}, sta={"-", 1}}
    buff:apply()
    local idx = player.opponent:first_empty_field_slot()
    if idx and player.field[my_idx] then
      player.field[my_idx], player.opponent.field[idx] = nil, my_card
    end
    my_card:remove_skill(skill_idx)
  end
end,

-- Liberated Maid
-- Waiting
[1445] = function(player, my_idx, my_card, skill_idx)
  local idxs = player:field_idxs_with_preds(pred.follower)
  local buff = OnePlayerBuff(player)
  for _, idx in ipairs(idxs) do
    buff[idx] = {atk={"+", 1}, sta={"+", 1}}
  end
  buff:apply()
  my_card:remove_skill_until_refresh(skill_idx)
end,

-- Maid Scientist
-- Eye Level
[1446] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card then
    OneBuff(player, my_idx, {atk={"+", other_card.def}}):apply()
  end
end,

-- Maid Scientist
-- Division
[1447] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local idx = uniformly(player:field_idxs_with_preds(pred.follower, function(card) return card ~= my_card end))
  if idx and other_card then
    local buff = OnePlayerBuff(player)
    buff[idx] = {sta={"-", floor(other_card.atk / 2)}}
    buff[my_idx] = {sta={"+", ceil(other_card.atk / 2)}}
    buff:apply()
  end
end,

-- Youngest Knight Rotori
-- Stamina Distribution
[1448] = function(player, my_idx, my_card, skill_idx)
  if my_card.atk > my_card.sta then
    local mag_atk = ceil(my_card.atk / 2)
    local mag_sta = (my_card.atk - mag_atk) * 2
    OneBuff(player, my_idx, {atk={"=", mag_atk}, sta={"+", mag_sta}}):apply()
    my_card:remove_skill(skill_idx)
  end
end,

-- Knight Supplier
-- Change Self
[1449] = function(player, my_idx, my_card, skill_idx)
  if my_card.sta > my_card.atk then
    OneBuff(player, my_idx, {atk={"=", my_card.sta}, sta={"=", my_card.atk}}):apply()
    my_card:remove_skill(skill_idx)
  end
end,

-- Seeker Odien
-- Research Start
[1450] = function(player, my_idx)
  if player.opponent.hand[1] then
    local buff = pred.follower(player.opponent.hand[1]) and {atk={"+", 2}} or {sta={"+", 3}}
    player.opponent:hand_to_bottom_deck(1)
    OneBuff(player, my_idx, buff):apply()
  end
end,

-- Seeker Odien
-- Don't get in my way.
[1451] = function(player, my_idx, my_card, skill_idx)
  if not player.opponent.hand[2] then
    OneBuff(player, my_idx, {def={"+", 2}}):apply()
    my_card:remove_skill_until_refresh(skill_idx)
  end
end,

-- GS Agent
-- GS Comeback
[1452] = function(player)
  local idx = uniformly(player:grave_idxs_with_preds(pred.gs))
  if idx then
    player:grave_to_bottom_deck(idx)
  end
end,

-- Witch Parfunte
-- Shock Change
[1453] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card then
    local buff = GlobalBuff(player)
    buff.field[player][my_idx] = {def={"=", other_card.def}}
    buff.field[player.opponent][other_idx] = {def={"=", my_card.def}}
    buff:apply()
    my_card:remove_skill(skill_idx)
  end
end,

-- Witch Parfunte
-- Lightning Curse
[1454] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card then
    OneBuff(player.opponent, other_idx, {sta={"+", other_card.def}}):apply()
  end
end,

-- Helena's Right Hand Rue
-- Domination
[1455] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if pred.D(player.character) and other_card then
    if abs(my_card.size - other_card.size) >= 3 then
      local buff = GlobalBuff(player)
      buff.field[player.opponent][other_idx] = {}
      buff.field[player][my_idx] = {atk={"+", 1}, sta={"+", 1}}
      buff:apply()
      player.opponent:field_to_grave(other_idx)
    else
      OneBuff(player, my_idx, {sta={"+", 1 + abs(my_card.size - other_card.size)}}):apply()
    end
  end
end,

-- Riftwatcher Schrodinger
-- Reflection
[1456] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card then
    local idx = player.opponent:field_idxs_with_most_and_preds(
        function(card) return card.atk + card.def + card.sta end, pred.follower)
    local buff = GlobalBuff(player)
    buff.field[player][my_idx] = {atk={"=", other_card.atk}, def={"=", other_card.def}, sta={"=", other_card.sta}}
    buff.field[player.opponent][other_idx] = {atk={"=", my_card.atk}, def={"=", my_card.def}, sta={"=", my_card.sta}}
    buff:apply()
    my_card.skills, other_card.skills = other_card.skills, {}
  end
end,

-- Situation Resolved
-- Attack Reversal
[1457] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card then
    local mag = ceil(other_card.atk / 2)
    OneBuff(player.opponent, other_idx, {sta={"-", mag}}):apply()
  end
  my_card:remove_skill(skill_idx)
end,

-- Infiltrator Witch Parfunte
-- Deliver Knowledge
[1458] = function(player, my_idx, my_card, skill_idx)
  local idx = player:deck_idxs_with_preds(pred.follower)[1]
  if idx then
    local buff = GlobalBuff(player)
    buff.deck[player][idx] = {atk={"+", 1}, def={"+", 1}, sta={"+", 1}}
    buff:apply()
    OneImpact(player, my_idx):apply()
    my_card:remove_skill(skill_idx)
  end
end,

-- Animal Suit Layna
-- Animal Regeneration
[1459] = function(player, my_idx, my_card, skill_idx)
  local mag = my_card.sta * 2
  OneBuff(player, my_idx, {sta={"=", mag}}):apply()
  my_card:remove_skill_until_refresh(skill_idx)
end,

-- Cafe Sita
-- Rest Time
[1460] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card and pred.skill(other_card) then
    local skill_idx = other_card:first_skill_idx()
    other_card:remove_skill(skill_idx)
    other_card:gain_skill(1476)
    OneImpact(player.opponent, other_idx):apply()
  end
end,

-- Garden Lady
-- Appreciation
[1461] = function(player, my_idx, my_card, skill_idx)
  local idx = uniformly(player.opponent:field_idxs_with_preds(pred.follower, pred.active))
  if idx then
    OneImpact(player.opponent, idx):apply()
    player.opponent.field[idx].active = false
  end
  my_card:remove_skill_until_refresh(skill_idx)
end,

-- Bamboo Scent Lady Panica
-- Grow!
[1462] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card and my_card.atk >= other_card.def + other_card.sta then
    OneBuff(player, my_idx, {size={"+", 1}}):apply()
  end
end,

-- Bamboo Scent Lady Panica
-- Fattened Uup
[1463] = function(player, my_idx, my_card)
  local mag = floor(my_card.size / 2)
  OneBuff(player, my_idx, {atk={"+", mag}, sta={"+", mag}}):apply()
end,

-- Cinia-cherishing Linia
-- Secret Sharing
[1464] = function(player, my_idx)
  local idx = uniformly(player:field_idxs_with_preds(pred.follower))
  local mag = max(min(player.field[idx]. size - 1, 2), 1)
  local buff = OnePlayerBuff(player)
  if idx ~= my_idx then
    buff[idx] = {size={"-", 1}}
    buff[my_idx] = {atk={"+", mag}, sta={"+", mag}}
  else
    buff[my_idx] = {size={"-", 1}, atk={"+", mag}, sta={"+", mag}}
  end
  buff:apply()
end,

-- Seeker Odien
-- Seeker Summon
[1465] = function(player)
  local idx = uniformly(player:grave_idxs_with_preds(pred.seeker))
  if idx then
    player:grave_to_bottom_deck(idx)
  end
end,

-- Knight Pintail
-- Decoy
[1466] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local pred_diff = function(card) return card ~= my_card end
  local idx = uniformly(player:field_idxs_with_preds(pred_diff))
  if idx then
    local mag = ceil(player.field[idx].size / 2)
    OneImpact(player, idx):apply()
    player:field_to_bottom_deck(idx)
    local opponent = player.opponent
    local pred_diff = function(card) return card ~= other_card end
    local idx = uniformly(opponent:field_idxs_with_preds(pred.follower, pred_diff))
    local buff = OnePlayerBuff(opponent)
    if other_card then
      buff[other_idx] = {atk={"-", mag}, sta={"-", mag}}
    end
    if idx then
      buff[idx] = {atk={"-", mag}, sta={"-", mag}}
    end
    buff:apply()
  end
end,

-- Luthica of Crux
-- Attack Preparation
[1467] = function(player, my_idx)
  if my_idx % 2 == 1 then
    OneBuff(player, my_idx, {atk={"+", 2}, sta={"+", 2}}):apply()
  end
end,

-- Luthica of Crux
-- Defense Preparation
[1468] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card and (my_idx % 2 == 0 or my_idx == 5) then
    OneBuff(player.opponent, other_idx, {atk={"-", 2}, sta={"-", 2}}):apply()
  end
end,

-- Luthica of Crux
-- Tactical Movement
[1469] = function(player, my_idx, my_card)
  local slots = {1, 2, 3, 4, 5}
  table.remove(slots, my_idx)
  local idx = uniformly(slots)
  local impact = Impact(player)
  impact[player][my_idx] = true
  if player.field[idx] then
    impact[player][idx] = true
  end
  player.field[my_idx], player.field[idx] = player.field[idx], my_card
end,

-- Crescent Conundrum
-- Sky Broom
[1470] = function(player, my_idx, my_card)
  local idx = player:first_empty_field_slot()
  local check = uniformly({false, false, false, false, false, false, true, true, true, true})
  if check and idx then
    OneImpact(player, my_idx):apply()
    player.field[my_idx], player.field[idx] = nil, my_card
  end
end,

-- Shaman Helena
-- Shaman's Cheer
[1471] = function(player, my_idx)
  for i = 1, 1 + (my_idx == 2 and 1 or 0) do
    local idx = uniformly(player:field_idxs_with_preds(pred.follower))
    OneBuff(player, idx, {atk={"+", 1}, sta={"+", 1}}):apply()
  end
end,

-- Trainer Iri
-- Training Start
[1472] = function(player, my_idx, my_card, skill_idx)
  local idx1 = reverse(player:deck_idxs_with_preds(pred.follower))[1]
  local idx2 = player:first_empty_field_slot()
  if idx1 and idx2 then
    OneImpact(player, idx2):apply()
    player:deck_to_field(idx1)
    player.field[idx2].active = false
  end
  local mag = #player:field_idxs_with_preds(pred.neg(pred.active))
  OneBuff(player, my_idx, {atk={"+", mag}, sta={"+", mag}}):apply()
  my_card:remove_skill_until_refresh(skill_idx)
end,

-- Swimming Pool Cannelle
-- Invigorate
[1473] = function(player, my_idx, my_card)
  local mag = Card(my_card.id).sta
  local idx = player:first_empty_field_slot()
  if my_card.sta <= mag and idx then
    OneBuff(player, my_idx, {sta={"=", mag}}):apply()
    player.field[my_idx], player.field[idx] = nil, my_card
    my_card.active = false
  end
end,

-- Senpai Muzisitter
-- Senpai's Summon
[1474] = function(player, my_idx, my_card)
  local idx = uniformly(player:deck_idxs_with_preds(pred.follower))
  if idx then
    local buff = GlobalBuff(player)
    buff.deck[player][idx] = {size={"+", 2}}
    buff:apply()
    if player.deck[idx].size >= 10 then
      local buff = GlobalBuff(player)
      buff.deck[player][idx] = {size={"=", my_card.size}, atk={"+", 3}, sta={"+", 3}}
      buff:apply()
      local idx2 = player:first_empty_field_slot()
      if idx2 then
        OneImpact(player, idx2):apply()
        player:deck_to_field(idx)
      end
    end
  end
end,

-- Smiling Vernika
-- Balance
[1475] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local check = #player:field_idxs_with_preds(pred.N) >= 2
  if check and other_card then
    local mag = abs(other_card.def)
    local buff = GlobalBuff(player)
    buff.field[player.opponent][other_idx] = {def={"=", 0}}
    local idxs = player:field_idxs_with_preds(pred.follower)
    for _, idx in ipairs(idxs) do
      buff.field[player][idx] = {atk={"+", mag}, sta={"+", mag}}
    end
    buff:apply()
    my_card:remove_skill_until_refresh(skill_idx)
  end
end,

-- Cafe Sita
-- Let's take a break
[1476] = function(player, my_idx, my_card, skill_idx)
  OneBuff(player, my_idx, {sta={"-", 2}}):apply()
  local pred_diff = function(card) return card ~= my_card end
  local idx = uniformly(player:field_idxs_with_preds(pred.follower, pred_diff))
  if idx then
    local impact = Impact(player)
    impact[player][my_idx] = true
    impact[player][idx] = true
    impact:apply()
    my_card:remove_skill(skill_idx)
    player.field[idx]:gain_skill(1476)
  end
end,

-- Defense
[1477] = function(player, my_idx)
  if player.opponent:is_npc() then
    OneBuff(player, my_idx, {sta={"+", 2}}):apply()
  end
end,

-- Boot of Darkness
-- Dark Soul Unleashed
[1478] = function(player, my_idx, my_card, skill_idx)
  local mag = player.game.turn
  OneBuff(player, my_idx, {atk={"+", mag}, sta={"+", mag}}):apply()
  my_card:remove_skill(skill_idx)
end,

-- Nold of Darkness
-- Dark Soul Attack
[1479] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card and other_card.size >= 6 then
    OneImpact(player.opponent, other_idx):apply()
    player.opponent:field_to_bottom_deck(other_idx)
  end
end,

-- Dark Soul Nold
-- Dark Soul Attack
[1480] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card and other_card.size >= 6 then
    OneImpact(player.opponent, other_idx):apply()
    player.opponent:field_to_grave(other_idx)
  end
  local mag = ceil(player.game.turn / 2)
  OneBuff(player, my_idx, {atk={"+", mag}, sta={"+", mag}}):apply()
end,

-- Dark Soul Nold
-- Dark Soul Unleashed
[1481] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local buff = GlobalBuff(player)
  local idx = uniformly(player:field_idxs_with_preds(pred.follower))
  if idx then
    buff.field[player][idx] = {size={"-", 1}}
  end
  if other_card then
    buff.field[player.opponent][other_idx] = {size={"+", 1}}
  end
  buff:apply()
end,

-- Gauntlet of Darkness
-- Dark Soul Attack
[1482] = function(player, my_idx)
  local idxs = player.opponent:field_idxs_with_preds(pred.follower)
  local buff = GlobalBuff(player)
  local mag = 0
  for _, idx in ipairs(idxs) do
    buff.field[player.opponent][idx] = {sta={"-", 1}}
    mag = mag + 1
  end
  buff.field[player][my_idx] = {atk={"+", mag}}
  buff:apply()
end,

-- Cook Club Director Jamie if NPC, +1/+1
[1483] = function(player, my_idx)
  if player.opponent:is_npc() then
    OneBuff(player, my_idx, {sta={"+",1},atk={"+",1}}):apply()
  end
end,

-- Nold of Darkness
-- Dark Soul Unleashed
[1484] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card then
    OneBuff(player.opponent, other_idx, {size={"+", 1}}):apply()
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

-- Muzisitter's Fan Layna
-- Deadly Charm
[1486] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card then
    OneBuff(player.opponent, other_idx, {sta={"-", 1}}):apply()
  end
end,

-- Library Club Librarian's Assistant Jin
-- Storage
[1487] = function(player)
  local idxs = shuffle(player:field_idxs_with_preds(pred.library_club, pred.follower))
  local buff = OnePlayerBuff(player)
  for i = 1, min(2, #idxs) do
    buff[idxs[i]] = {size={"-", 1}}
  end
  buff:apply()
end,

-- Student Council Casey
-- Heavy Strike
[1488] = function(player, my_idx, my_card, skill_idx)
  local pred_diff = function(card) return card ~= my_card end
  local check = player:field_idxs_with_preds(pred.follower, pred_diff)[1]
  if check then
    local buff = GlobalBuff(player)
    buff.field[player.opponent][0] = {life={"-", 3}}
    buff.field[player][my_idx] = {}
    buff:apply()
    my_card:remove_skill(skill_idx)
  end
end,

-- Twin Lady Shion and Rion
-- Chaos
[1489] = function(player)
  local idx = uniformly(player.opponent:hand_idxs_with_preds())
  if idx then
    player.opponent:hand_to_bottom_deck(idx)
  end
end,

-- Lady Cox
-- Equip Dress
[1490] = function(player, my_idx, my_card, skill_idx)
  local buff = OnePlayerBuff(player)
  buff[my_idx] = {}
  for _, idx in ipairs(player:field_idxs_with_preds(pred.A, pred.follower)) do
    buff[idx] = {def={"+", 1}}
  end
  buff:apply()
  my_card:remove_skill(skill_idx)
end,

-- Muzisitter Lady Irea
-- HP Drain
[1491] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card and other_card.sta > Card(other_card.id).sta then
    local orig = Card(other_card.id)
    local buff = GlobalBuff(player)
    buff.field[player.opponent][other_idx] = {sta={"=", orig.sta}}
    buff.field[player][my_idx] = {sta={"+", other_card.sta - orig.sta}}
    buff:apply()
    my_card:remove_skill_until_refresh(skill_idx)
  end
end,

-- Seeker Kano
-- Report Results
[1492] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card and my_card.def + my_card.sta <= other_card.atk then
    local idx = player:hand_idxs_with_preds(pred.follower)[1]
    if idx then
      local buff = GlobalBuff(player)
      buff.hand[player][idx] = {atk={"+", 3}, sta={"+", 3}}
      buff:apply()
    end
  end
end,

-- Silent Knight
-- Silent Pressure
[1493] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card then
    local buff = GlobalBuff(player)
    buff.field[player.opponent][other_idx] = {}
    buff.field[player][my_idx] = {size={"+", 1}}
    buff:apply()
    other_card.skills = {}
    if my_card.size >= 5 then
      player:field_to_grave(my_idx)
    end
  end
end,

-- Double Agent Luthica
-- Defende
[1494] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card then
    local buff = GlobalBuff(player)
    buff.field[player.opponent][other_idx] = {atk={"-", 1}, sta={"-", 1}}
    buff.field[player][my_idx] = {}
    buff:apply()
    my_card:remove_skill_until_refresh(skill_idx)
  end
end,

-- SS Informant
-- Timing
[1495] = function(player, my_idx)
  if player.character.life >= 15 then
    OneBuff(player, my_idx, {atk={"-", 1}, sta={"-", 1}}):apply()
  else
    OneBuff(player, my_idx, {atk={"+", 2}}):apply()
  end
end,

-- Alethian Hania
-- Sacrifice
[1496] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card then
    local mag = abs((other_card.atk + other_card.def + other_card.sta) - (my_card.atk + my_card.def + my_card.sta))
    if mag > 0 then
      local buff = GlobalBuff(player)
      buff.field[player][my_idx] = {}
      buff.field[player.opponent][other_idx] = {size={"-", mag}, sta={"-", mag}}
      buff:apply()
      player:destroy(my_idx)
    end
  end
end,

-- GS Leader Schindler
-- GS Command
[1497] = function(player, my_idx)
  local idx = uniformly(player:hand_idxs_with_preds(pred.gs))
  if idx then
    local buff = GlobalBuff(player)
    buff.field[player][my_idx] = {atk={"+", 1}, sta={"+", 1}}
    buff.hand[player][idx] = {size={"-", 1}}
    buff:apply()
  end
end,

-- Shionrion Extreme
-- Transformation Expired
[1498] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local shion = 300595
  local rion = 300596
  if other_card and other_card.atk >= my_card.def + my_card.sta then
    OneImpact(player, my_idx):apply()
    player:field_to_exile(my_idx)
    local idxs = player:empty_field_slots()
    local buff = OnePlayerBuff(player)
    buff[idxs[1]] = {size={"=", 2}}
    player.field[idxs[1]] = Card(shion)
    if idxs[2] then
      buff[idxs[1]] = {size={"=", 2}}
      player.field[idxs[1]] = Card(rion)
    end
    buff:apply()
  end
end,

-- Dress Up Shion
-- Twin Attack!
[1499] = function(player)
  local shion = 300595
  local rion = 300596
  local pred = function(card) return card.id == 300595 or card.id == 300596 end
  local buff = OnePlayerBuff(player)
  for _, idx in ipairs(player:field_idxs_with_preds(pred)) do
    buff[idx] = {atk={"+", 2}}
  end
  buff:apply()
end,

-- Dress Up Rion
-- Twin Defense!
[1500] = function(player)
  local shion = 300595
  local rion = 300596
  local pred = function(card) return card.id == 300595 or card.id == 300596 end
  local buff = OnePlayerBuff(player)
  for _, idx in ipairs(player:field_idxs_with_preds(pred)) do
    buff[idx] = {sta={"+", 2}}
  end
  buff:apply()
end,

-- Double Agent Luthica
-- Attack
[1501] = function(player, my_idx)
  OneBuff(player, my_idx, {atk={"+", 1}, sta={"+", 1}}):apply()
end,

-- Cook Club Baker Svia
-- Strike Weakness
[1502] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card then
    OneBuff(player.opponent, other_idx, {atk={"-", 2}, def={"-", 2}}):apply()
  end
  my_card:remove_skill(skill_idx)
end,

-- Summer Student Council Susie
-- Pilfer
[1503] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card then
    local impact = Impact(player)
    impact[player][my_idx] = true
    impact[player.opponent][other_idx] = true
    impact:apply()
    for i = 1, 3 do
      if skill_id_to_type[my_card.skills[i]] == "defend" and other_card:first_empty_skill_slot() then
        other_card:gain_skill(my_card.skills[i])
        my_card:remove_skill(i)
      end
    end
    for i = 1, 3 do
      if skill_id_to_type[other_card.skills[i]] == "attack" and my_card:first_empty_skill_slot() then
        my_card:gain_skill(other_card.skills[i])
        other_card:remove_skill(i)
      end
    end
  end
end,

-- Summer Student Council Susie
-- Enemy Cheer
[1504] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card and not pred.V(my_card) then
    OneBuff(player.opponent, other_idx, {atk={"+", 2}, sta={"+", 2}}):apply()
  end
end,

-- Part-Time Maid
-- Recover
[1505] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card and other_card.atk >= my_card.def + my_card.sta then
    local idx = uniformly(player:field_idxs_with_preds(pred.follower))
    local buff = OnePlayerBuff(player)
    buff[my_idx] = {}
    buff[idx] = {sta={"+", my_card.sta}}
    buff:apply()
    my_card:remove_skill(skill_idx)
  end
end,

-- Marionette Witch
-- Confidence
[1506] = function(player, my_idx, my_card)
  local check = false
  for i = 1, 3 do
    check = check or my_card.skills[i] ~= 1506
  end
  if check then
    OneBuff(player, my_idx, {atk={"+", 1}, sta={"+", 1}}):apply()
    my_card:refresh()
  end
end,

-- Blue Cross Rose
-- Comparison
[1507] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card and my_card.def >= 0 then
    local buff = GlobalBuff(player)
    buff.field[player.opponent][other_idx] = {def={"-", my_card.def}}
    buff.field[player][my_idx] = {}
    buff:apply()
  end
  my_card:remove_skill(skill_idx)
end,

-- Blue Cross Rose
-- Comparison
[1508] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card and my_card.def >= 0 then
    local mag = my_card.def
    OneBuff(player.opponent, other_idx, {atk={"-", mag}, sta={"-", mag}}):apply()
  end
  my_card:remove_skill(skill_idx)
end,

-- Blue Cross Rose
-- Restore Confidence
[1509] = function(player, my_idx, my_card)
  OneBuff(player, my_idx, {def={"=", Card(my_card.id).def}}):apply()
  my_card:refresh()
end,

-- Aletheian Deputy Cook
-- Cooking Preparations
[1510] = function(player, my_idx, my_card)
  if my_card.sta > Card(my_card.id).sta then
    local buff = OnePlayerBuff(player)
    local mag = min(floor((my_card.sta - 5) / 2), 9)
    buff[0] = {life={"+", mag}}
    buff[my_idx] = {sta={"=", 5}}
    buff:apply()
  end
end,

-- Muzisitter Lady Linus
-- Shockwave
[1511] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card then
    local pred_diff = function(card) return card ~= other_card end
    local idx = uniformly(player.opponent:field_idxs_with_preds(pred.follower, pred_diff))
    local mag = idx and ceil(player.opponent.field[idx].atk / 2) or 3
    OneBuff(player.opponent, other_idx, {sta={"-", mag}}):apply()
  end
end,

-- Muzisitter Lady Linus
-- Energy Drain
[1512] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card then
    OneBuff(player.opponent, other_idx, {atk={"-", my_card.def}}):apply()
  end
end,

-- Crux Knight Sophia
-- Defiance
[1513] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card and player.character.faction == my_card.faction then
    OneBuff(player, my_idx, {sta={"+", other_card.atk}}):apply()
  end
end,

-- Crux Knight Sophia
-- Abandonment
[1514] = function(player, my_idx)
  player:destroy(my_idx)
end,

-- Blue Cross Scribe
-- Life or Death
[1515] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if player.hand[4] and other_card then
    OneImpact(player.opponent, other_idx):apply()
    player.opponent:field_to_top_deck(other_idx)
    my_card:remove_skill(skill_idx)
  elseif not player.hand[3] then
    OneImpact(player, my_idx):apply()
    player:field_to_grave(my_idx)
  end
end,

-- Wise Witch
-- Reaper
[1516] = function(player, my_idx)
  if #player.grave + #player.opponent.grave >= 15 then
    OneBuff(player, my_idx, {atk={"+", 2}, sta={"+", 2}}):apply()
  end
end,

-- Fugitive Aletheian A-GA
-- Natural Selection
[1517] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  local mag = other_card and other_card.size >= my_card.size and 2 or 1
  OneBuff(player, my_idx, {atk={"+", mag}, sta={"+", mag}}):apply()
end,

-- Summer Tesla
-- Book's Wisdom
[1518] = function(player, my_idx, my_card, skill_idx)
  local buff = OnePlayerBuff(player)
  buff[my_idx] = {}
  local mag = my_card.size
  for _, idx in ipairs(player:field_idxs_with_preds(pred.V, pred.follower)) do
    buff[idx] = {atk={"+", mag}, sta={"+", mag}}
  end
  buff:apply()
  my_card:remove_skill_until_refresh(skill_idx)
end,

-- Summer Linia
-- Master's Command
[1519] = function(player, my_idx, my_card, skill_idx)
  local mag = ceil(my_card.size / 2)
  local buff = OnePlayerBuff(player)
  for i = max(1, my_idx - 1), min(5, my_idx + 1) do
    if player.field[i] and pred.follower(player.field[i]) then
      buff[i] = {atk={"+", mag}, sta={"+", mag}}
    end
  end
  buff:apply()
  my_card:remove_skill_until_refresh(skill_idx)
end,

-- Summer Vanguard
-- Orders From Above
[1520] = function(player, my_idx, my_card, skill_idx)
  while player.deck[1] and not player.hand[4] do
    player:draw_a_card()
  end
  local mag = #player:hand_idxs_with_preds(pred.C)
  OneBuff(player, my_idx, {atk={"+", mag}, sta={"+", mag}}):apply()
  my_card:remove_skill_until_refresh(skill_idx)
end,

-- Summer Cabernet
-- Two and One
[1521] = function(player, my_idx, my_card, skill_idx)
  local buff = OnePlayerBuff(player)
  for _, idx in ipairs(player:field_idxs_with_preds(pred.D, pred.follower)) do
    buff[idx] = {atk={"+", 2}, sta={"+", 2}}
  end
  buff:apply()
  my_card:remove_skill_until_refresh(skill_idx)
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

-- Cook Club Advisor
-- Show Leadership
[1526] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card then
    local mag = reduce(function(a, h) return a + abs(Card(h.id).size - h.size) end, player:field_cards_with_preds(), 0)
    OneBuff(player.opponent, other_idx, {sta={"-", mag}}):apply()
  end
end,

-- Cook Club Member
-- Fruits of Research
[1527] = function(player, my_idx, my_card, skill_idx)
  local mag_def = #player:field_idxs_with_preds(pred.cook_club, pred.follower)
  local mag_atk = ceil(#player:field_idxs_with_preds(pred.V, pred.follower) / 2)
  local mag_sta = #player:field_idxs_with_preds(pred.follower)
  player:field_buff_n_random_followers_with_preds(5, {atk={"+", mag_atk}, def={"+", mag_def}, sta={"+", mag_sta}})
  my_card:remove_skill(skill_idx)
end,

-- Inspiration Lady
-- Lady Meeting
[1528] = function(player, my_idx, my_card, skill_idx)
  local pred_diff = function(card) return card ~= my_card end
  local buff = player:field_cards_with_preds(pred_diff, pred.lady, pred.follower)[1] and {atk={"+", 1}, sta={"+", 2}} or {atk={"+", 1}, sta={"+", 1}}
  player:field_buff_n_random_followers_with_preds(5, buff)
  my_card:remove_skill_until_refresh(skill_idx)
end,

-- Senpai Maid
-- Call me Senpai
[1529] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card and my_card.atk < other_card.atk then
    local buff = GlobalBuff(player)
    buff.field[player][my_idx] = {atk={"=", other_card.atk}}
    buff.field[player.opponent][other_idx] = {atk={"=", my_card.atk}}
    buff:apply()
    my_card:remove_skill_until_refresh(skill_idx)
  end
end,

-- Crux Knight Pintail
-- Threat
[1530] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card and other_card.size <= my_card.size then
    OneBuff(player.opponent, other_idx, {atk={"-", 1}, def={"-", 1}}):apply()
  end
end,

-- Crescent Conundrum
-- Vampirism
[1531] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card and other_card.def + other_card.sta <= my_card.atk then
    OneBuff(player, my_idx, {def={"+", 1}}):apply()
  end
end,

-- Iri Flina
-- Dignity
[1532] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card and other_card.size <= my_card.size then
    local mag_atk = uniformly({1, 2, 3, 4})
    local mag_sta = uniformly({1, 2, 3, 4})
    OneBuff(player.opponent, other_idx, {atk={"-", mag_atk}, sta={"-", mag_sta}}):apply()
  end
end,

-- Seeker Lydia
-- Record Observations
[1533] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card then
    if other_card.active then
      OneBuff(player, my_idx, {sta={"+", 2}}):apply()
    else
      local buff = GlobalBuff(player)
      buff.field[player.opponent][other_idx] = {def={"=", 0}}
      buff.field[player][my_idx] = {sta={"+", abs(other_card.def)}}
      buff:apply()
    end
  end
end,

-- Wind Girl Hu
-- Medicine-rabi!
[1534] = function(player, my_idx)
  local buff = OnePlayerBuff(player)
  buff[0] = {life={"+", 1}}
  buff[my_idx] = {sta={"+", 2}}
  buff:apply()
end,

-- Wind Girl Hu
-- It's good for you-rabi!
[1535] = function(player, my_idx)
  OneBuff(player, my_idx, {atk={"+", 2}, def={"+", 2}, sta={"+", 2}}):apply()
end,

-- Maid Sita
-- Panda Kick!
[1536] = function(player, my_idx, my_card)
  OneBuff(player, my_idx, my_card.atk % 2 == 0 and {atk={"+", 3}} or {atk={"-", 1}}):apply()
end,

-- Clothes Thieves Shion and Rion
-- Mutual Destruction
[1537] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card then
    local impact = Impact(player)
    impact[player][my_idx] = true
    impact[player.opponent][other_idx] = true
    impact:apply()
    my_card.skills = {}
    other_card:gain_skill(1538)
  end
end,

-- ???
-- Self-Destruct
[1538] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card and other_card.atk >= my_card.def + my_card.sta then
    local pred_diff = function(card) return card ~= my_card end
    local idx = uniformly(player:field_idxs_with_preds(pred.follower, pred_diff))
    if idx then
      OneBuff(player, idx, {sta={"=", 0}}):apply()
    end
  end
end,

-- Lady Lig Nijes
-- Total Recall
[1539] = function(player, my_idx, my_card)
  OneBuff(player, my_idx, {sta={"=", Card(my_card.id).sta}}):apply()
end,

-- Witch Rianna
-- Equalize
[1540] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card and pred.A(player) and other_card.atk > Card(other_card.id).atk then
    local mag = ceil((my_card.atk + other_card.atk) / 2)
    local buff = GlobalBuff(player)
    buff.field[player][my_idx] = {atk={"=", mag}}
    buff.field[player.opponent][other_idx] = {atk={"=", mag}}
    buff:apply()
    my_card:remove_skill(skill_idx)
  end
end,

-- Lady Nexia
-- We are the one
[1541] = function(player, my_idx, my_card)
  local buff = OnePlayerBuff(player)
  local mag = 1
  for idx = my_idx-1,my_idx+1,2 do
    local card = player.field[idx]
    if card and pred.A(card) and pred.follower(card) then
      buff[idx] = {sta={"+", 1}}
      mag = mag + 1
    end
  end
  buff[my_idx] = {atk={"+", mag}, sta={"+", mag}}
  buff:apply()
end,

-- Blue Cross Sunny
-- Will of the Gloves
[1542] = function(player, my_idx, my_card, skill_idx)
  if player.hand[4] then
    OneImpact(player, my_idx):apply()
    my_card:remove_skill(skill_idx)
  elseif not player.hand[3] then
    local mag_atk = uniformly({0, 1, 2, 3})
    local mag_sta = uniformly({0, 1, 2, 3})
    OneBuff(player, my_idx, {atk={"-", mag_atk}, sta={"-", mag_sta}}):apply()
  end
end,

-- Blue Cross Gart
-- Wings of the Gloves
[1543] = function(player, my_idx, my_card, skill_idx)
  if player.hand[4] then
    OneImpact(player, my_idx):apply()
    my_card:remove_skill(skill_idx)
  elseif not player.hand[3] then
    for i = 1, min(4, #player.grave) do
      player:grave_to_exile(#player.grave)
    end
  end
end,

-- Blue Cross Parfunte
-- Witch's Gloves
[1544] = function(player, my_idx, my_card, skill_idx)
  local pred_diff = function(card) return card ~= my_card end
  local idx = uniformly(player:field_idxs_with_preds(pred.follower, pred_diff))
  local mag = floor(#player.hand / 2)
  local buff = OnePlayerBuff(player)
  buff[my_idx] = {atk={"+", mag}, sta={"+", mag}}
  if idx then
    buff[idx] = {atk={"+", mag}, sta={"+", mag}}
  end
  buff:apply()
end,

-- Blue Cross Parfunte
-- Witch's Overcoat
[1545] = function(player, my_idx, my_card, skill_idx)
  if not player.hand[3] then
    for i = 1, min(#player.deck, 4 - #player.hand) do
      player:draw_a_card()
    end
  end
  my_card:remove_skill_until_refresh(skill_idx)
end,

-- Blue Cross Parfunte
-- Witch's Greeting
[1546] = function(player, my_idx, my_card)
  OneImpact(player, my_idx):apply()
  my_card:refresh()
end,

-- Dark Sword's Spirit Menelgart
-- Handstand
[1547] = function(player, my_idx, my_card)
  if my_card.sta > my_card.atk then
    OneBuff(player, my_idx, {atk={"=", my_card.sta}, sta={"=", my_card.atk}}):apply()
  end
end,

-- GS 7th Star
-- Dignity!
[1548] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card and other_card.atk < my_card.size then
    OneBuff(player.opponent, other_idx, {atk={"-", my_card.atk}}):apply()
  end
end,

-- Night's Holy Guardian Sigma
-- Reverse Power
[1549] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card and Card(other_card.id).sta > other_card.sta then
    local mag_sta = Card(other_card.id).sta - other_card.sta
    local mag_atk = floor(mag_sta / 2)
    OneBuff(player, my_idx, {atk={"+", mag_atk}, sta={"+", mag_sta}}):apply()
  end
end,

-- ???
-- Return
[1550] = function(player, my_idx, my_card)
  OneImpact(player, my_idx):apply()
  my_card:refresh()
end,

-- Master of Games
-- Game Mastery
[1551] = function(player, my_idx, my_card, skill_idx)
  local idx = player:first_empty_field_slot()
  if idx then
    local card = Card(300000 + random(336))
    player.field[idx] = card
    local buff = OnePlayerBuff(player)
    buff[idx] = {}
    buff[my_idx] = {}
    buff:apply()
    my_card:remove_skill(skill_idx)
  end
end,

-- Cook Club Linfield
-- Cold
[1552] = function(player, my_idx, my_card, skill_idx)
  OneBuff(player, my_idx, {atk={"-", 1}, def={"-", 1}, sta={"-", 1}}):apply()
  my_card:remove_skill_until_refresh(skill_idx)
end,

-- Surrounded Asmis
-- No Escape
[1553] = function(player, my_idx, my_card, skill_idx)
  player.opponent.shuffles = max(0, player.opponent.shuffles - 1)
  my_card:remove_skill(skill_idx)
end,

-- Observer of the past and future
-- Future's Moment
[1554] = function(player, my_idx, my_card, skill_idx)
  OneImpact(player, my_idx):apply()
  my_card.skills[skill_idx] = 1555 -- Impending Future
end,

-- Observer of the past and future
-- Impending Future
[1555] = function(player, my_idx)
  OneBuff(player, my_idx, {atk={"-", 2}, sta={"-", 2}}):apply()
end,

-- Observer of the past and future
-- Sage's Moment
[1556] = function(player, my_idx)
  OneBuff(player, my_idx, {atk={"+", 3}, sta={"+", 3}}):apply()
end,

-- Potion Witch Cultist
-- Magic of 3
[1557] = function(player, my_idx, my_card, skill_idx, op_idx, op_card)
  if op_card then
    local mag = 0
    for _, stat in ipairs({"atk", "def", "sta"}) do
      local n = my_card[stat]
      while n > 0 do
        if n % 10 == 3 then
          mag = mag + 1
        end
        n = floor(n / 10)
      end
    end
    if mag >= 3 then
      OneImpact(player.opponent, op_idx):apply()
      player.opponent:destroy(op_idx)
    end
  end
end,

-- Pursuer Linus Falco
-- Assistance
[1558] = function(player)
  local pred_sta = function(card) return card.sta >= 3 end
  local buff = OnePlayerBuff(player)
  for _, idx in ipairs(player:field_idxs_with_preds(pred.follower, pred_sta)) do
    buff[idx] = {sta={"+", 3}}
  end
  buff:apply()
end,

-- Space Time Witch Cinia
-- Carpet Bombing
[1559] = function(player, my_idx, my_card)
  local idxs = player.opponent:field_idxs_with_preds(pred.follower)
  local mag = floor(my_card.size / #idxs)
  player.opponent:field_buff_n_random_followers_with_preds(5, {sta={"-", mag}})
end,

-- Counselor Soma
-- Lock
[1560] = function(player, my_idx, my_card, skill_idx, op_idx, op_card)
  local impact = Impact(player)
  impact[player][my_idx] = true
  if op_card then
    impact[player.opponent][my_idx] = true
  end
  impact:apply()
  my_card:remove_skill_until_refresh(skill_idx)
  if op_card then
    op_card.skills = {1076}
  end
end,

-- Anti-Witch Queen Rose
-- Victory
[1561] = function(player, my_idx, my_card, skill_idx, op_idx, op_card)
  local buff = GlobalBuff(player)
  buff.field[player][my_idx] = {atk={"=", 6}}
  if op_card then
    buff.field[player.opponent][op_idx] = {def={"=", 1}}
  end
  buff:apply()
end,

-- Seeker Luthica
-- Stamina Training
[1562] = function(player, my_idx, my_card)
  OneBuff(player, my_idx, {atk={"=", 2 + my_card.sta}}):apply()
end,

-- Seeker Luthica
-- Spirit Training
[1563] = function(player, my_idx, my_card)
  OneBuff(player, my_idx, {sta={"=", 3 + my_card.atk}}):apply()
end,

-- GS Special Ops
-- Request Aid
[1564] = function(player, my_idx, my_card, skill_idx)
  OneImpact(player, my_idx):apply()
  my_card:remove_skill(skill_idx)
  player.grave[#player.grave + 1] = Card(300193) -- GS Fighter
end,

-- GS 8th Star
-- Trespassing
[1565] = function(player, my_idx, my_card, skill_idx, op_idx, op_card)
  if op_card then
    local mag = min(3, ceil(#player:grave_idxs_with_preds(pred.gs) / 2))
    OneBuff(player.opponent, op_idx, {def={"-", mag}}):apply()
  end
end,

-- GS 9th Star
-- Mind's Eye
[1566] = function(player, my_idx, my_card, skill_idx)
  if pred.follower(player.deck[#player.deck]) then
    OneBuff(player, my_idx, {atk={"+", 2}, sta={"+", 2}}):apply()
  else
    local impact = Impact(player)
    impact[player][my_idx] = true
    local idx = player.opponent:field_idxs_with_preds(pred.spell)[1]
    if idx then
      impact[player.opponent][idx] = true
    end
    impact:apply()
    if idx then
      player.opponent:field_to_grave(idx)
    end
  end
  my_card:remove_skill_until_refresh(skill_idx)
end,

-- Magical Girl Layna
-- Magical Force
[1567] = function(player, my_idx)
  local mag = #player:field_idxs_with_preds(pred.follower)
  OneBuff(player, my_idx, {atk={"+", mag}}):apply()
end,

-- Magical Girl Layna
-- Magical Force
[1568] = function(player, my_idx)
  OneBuff(player, my_idx, {atk={"+", #player.hand}}):apply()
end,

-- Magical Girl Layna
-- Divine Crash
[1569] = function(player, my_idx, my_card)
  local buff = GlobalBuff(player)
  local idx = uniformly(player.opponent:field_idxs_with_preds(pred.follower))
  if idx then
    buff.field[player.opponent][idx] = {}
    buff.field[player][my_idx] = {}
    local orig = Card(my_card.id)
    for _, stat in ipairs({"atk", "def", "sta"}) do
      if my_card[stat] > orig[stat] then
        buff.field[player][my_idx][stat] = {"=", orig[stat]}
      end
    end
  end
  buff:apply()
end,

-- Amrita's Lost Property
-- Comeback
[1570] = function(player, my_idx, my_card, skill_idx)
  OneBuff(player, my_idx, {atk={"=", Card(my_card.id).atk + 3}}):apply()
  my_card:remove_skill(skill_idx)
end,

-- Training
[1571] = function(player, my_idx)
  OneBuff(player, my_idx, {atk={"+", 1}, sta={"+", 1}}):apply()
end,

-- Discoverer Orte
-- Unification
[1572] = function(player, my_idx, my_card, skill_idx, op_idx, op_card)
  if op_card then
    OneBuff(player, my_idx, {atk={"=", op_card.atk}}):apply()
  end
end,

-- Discoverer Orte
-- Weaken
[1573] = function(player, my_idx)
  OneBuff(player, my_idx, {atk={"-", 1}}):apply()
end,

-- Fugitive Amrita
-- Zero
[1574] = function() end,

-- Fugitive Amrita
-- Zero
[1575] = function() end,

-- Detectives Linus and Asmis
-- Welcome!
[1576] = function(player)
  local idx = player:first_empty_field_slot()
  if idx then
    OneImpact(player, idx):apply()
    player.field[idx] = Card(200002) -- New Student Orientation
  end
end,

-- Detectives Linus and Asmis
-- Cleanup
[1577] = function(player, my_idx)
  local pred_name = function(card) return card.name == Card(200002).name end -- New Student Orientation
  local idx = player:grave_idxs_with_preds(pred_name)[1]
  if idx then
    player:grave_to_exile(idx)
    OneBuff(player, my_idx, {atk={"+", 1}, sta={"+", 1}}):apply()
  end
end,

-- Crux Knight Swimie
-- Unity
[1578] = function(player, my_idx, my_card, skill_idx, op_idx, op_card)
  if op_card and op_card.def + op_card.sta <= my_card.atk then
    player:field_buff_n_random_followers_with_preds(5, {def={"+", 1}})
    my_card:remove_skill_until_refresh(skill_idx)
  end
end,

-- Return of the King, Jaina
-- Power of Will
[1579] = function(player, my_idx)
  local mag = #player:field_idxs_with_preds(pred.C, pred.follower)
  OneBuff(player, my_idx, {atk={"+", mag}, sta={"+", mag}}):apply()
end,

-- Return of the King, Jaina
-- Knight Summon
[1580] = function(player, my_idx, my_card, skill_idx, op_idx, op_card)
  if player.grave[1] then
    player:grave_to_bottom_deck(#player.grave)
    local mag = floor(player.deck[1].size / 2)
    local buff = GlobalBuff(player)
    buff.field[player][my_idx] = {sta={"-", mag}}
    if op_card then
      buff.field[player.opponent][op_idx] = {sta={"-", mag}}
    end
    buff:apply()
  end
end,

-- Crimson Witch Cinia
-- Crimson Magic
[1581] = function(player, my_idx, my_card, skill_idx, op_idx, op_card)
  if op_card then
    local buff = GlobalBuff(player)
    buff.field[player.opponent][op_idx] = {}
    local mag = #Card(op_card.id).skills
    buff.field[player][my_idx] = pred.A(player.character) and {atk={"+", mag}, sta={"+", mag}} or {}
    buff:apply()
    op_card.skills = {1076}
    my_card:remove_skill_until_refresh(skill_idx)
  end
end,

-- Scardel Kirie
-- Addition
[1582] = function(player, my_idx, my_card, skill_idx)
  OneImpact(player, my_idx):apply()
  player.shuffles = player.shuffles + (pred.D(player.character) and 1 or 0)
  my_card:remove_skill(skill_idx)
end,

-- Aletheian Missionary B-NA
-- Painful Attack
[1583] = function(player, my_idx, my_card, skill_idx, op_idx, op_card)
  local buff = GlobalBuff(player)
  buff.field[player][my_idx] = {atk={"+", 1}}
  if op_card then
    buff.field[player.opponent][op_idx] = {sta={"-", 1}}
  end
  buff:apply()
end,

-- Mother Demon
-- Advent
[1584] = function(player, my_idx)
  OneBuff(player, my_idx, {size={"+", 1}, atk={"+", 1}, sta={"+", 1}}):apply()
end,

-- Mother Demon
-- Materialization
[1585] = function(player, my_idx, my_card, skill_idx, op_idx, op_card)
  local buff = GlobalBuff(player)
  buff.field[player][my_idx] = {size={"=", 1}}
  if op_card then
    local mag = ceil((my_card.size - 1) / 2)
    buff.field[player.opponent][op_idx] = {atk={"-", mag}, def={"-", mag}, sta={"-", mag}}
  end
  buff:apply()
end,

-- Mother Demon
-- Initialization
[1586] = function(player, my_idx, my_card)
  OneBuff(player, my_idx, pred.D(player.character) and {size={"=", Card(my_card.id).size}} or {}):apply()
  if not pred.D(player.character) then
    my_card.skills = {}
  end
end,

-- Unity
-- Extinction
[1587] = function(player, my_idx, my_card, skill_idx, op_idx, op_card)
  local impact = Impact(player)
  impact[player][my_idx] = true
  if op_card then
    impact[player.opponent][op_idx] = true
  end
  impact:apply()
  player:field_to_grave(my_idx)
  player.opponent:field_to_exile(op_idx)
end,

-- Celine and Nanai in the calm before the storm
-- Tea Time
[1588] = function(player, my_idx, my_card, skill_idx)
  if player.opponent:is_npc() then
    OneBuff(player, my_idx, {atk={"+", 2}, sta={"+", 2}}):apply()
  else
    local buff = GlobalBuff(player)
    buff.field[player][0] = {life={"+", 1}}
    buff.field[player.opponent][0] = {life={"-", 1}}
    buff.field[player][my_idx] = {}
    buff:apply()
  end
  my_card:remove_skill(skill_idx)
end,

-- Captured Spirit
-- Growth
[1589] = function(player, my_idx)
  OneBuff(player, my_idx, {size={"+", 1}}):apply()
end,

-- Discouraged Ritafarit
-- Truth
[1590] = function(player, my_idx)
  OneBuff(player, my_idx, {atk={"+", 2}, sta={"+", 2}}):apply()
end,

-- Discouraged Ritafarit
-- Fake!
[1591] = function(player, my_idx)
  OneBuff(player, my_idx, {atk={"-", 2}, sta={"-", 2}}):apply()
end,

-- Witness of the End
-- Book Appreciation
[1592] = function(player, my_idx, my_card, skill_idx, op_idx, op_card)
  if op_card then
    OneBuff(player, my_idx, op_card:squished_skills()[1] and {atk={"+", 2}, def={"+", 2}, sta={"+", 2}} or {atk={"-", 1}, def={"-", 1}, sta={"-", 1}}):apply()
  end
end,

-- Inspiration Lady
-- Philosophy of Action
[1593] = function(player, my_idx, my_card, skill_idx, op_idx, op_card)
  local idx = player:first_empty_field_slot()
  if my_card.active and idx then
    local buff = GlobalBuff(player)
    buff.field[player][my_idx] = {}
    if op_card then
      buff.field[player.opponent][op_idx] = {sta={"-", 5}}
    end
    buff:apply()
    player.field[idx], player.field[my_idx] = my_card, nil
  end
end,

-- Maid Lesnoa
-- Master Linia
[1594] = function(player, my_idx, my_card, skill_idx)
  local buff = GlobalBuff(player)
  for _, idx in ipairs(player:deck_idxs_with_preds(pred.linia, pred.follower)) do
    buff.deck[player][idx] = {atk={"+", 1}, def={"+", 1}, sta={"+", 1}}
  end
  buff.field[player][my_idx] = {}
  buff:apply()
  my_card:remove_skill(skill_idx)
end,

-- Lady Cinia and Rose
-- Spell Search
[1595] = function(player, my_idx)
  local idx = uniformly(player.opponent:hand_idxs_with_preds(pred.spell))
  if idx then
    OneBuff(player, my_idx, {atk={"+", player.opponent.hand[idx].size}}):apply()
    player.opponent:hand_to_bottom_deck(idx)
  end
end,

-- Lady Cinia and Rose
-- Shuffling
[1596] = function(player, my_idx)
  OneBuff(player, my_idx, {sta={"+", player.shuffles}}):apply()
end,

-- Blue Cross Toto
-- PIMFY
[1597] = function(player, my_idx, my_card, skill_idx)
  local buff = OnePlayerBuff(player)
  buff[my_idx] = {}
  for i = -1, 1, 2 do
    if pred.inter(pred.exists, pred.follower)(player.field[my_idx + i]) then
      buff[my_idx + i] = {atk={"+", 1}, sta={"+", 1}}
    end
  end
  buff:apply()
  my_card:remove_skill_until_refresh(skill_idx)
end,

-- Blue Cross Toto
-- PIMFY
[1598] = function(player, my_idx, my_card, skill_idx)
  local buff = OnePlayerBuff(player)
  buff[my_idx] = {}
  for i = -1, 1, 2 do
    if pred.inter(pred.exists, pred.follower)(player.field[my_idx + i]) then
      buff[my_idx + i] = {atk={"+", 1}, sta={"+", 1}}
    end
  end
  buff:apply()
  my_card:remove_skill_until_refresh(skill_idx)
end,

-- Seeker Ragafelt
-- Teleport
[1599] = function(player, my_idx, my_card, skill_idx, op_idx, op_card)
  local idx = uniformly(player:empty_field_slots())
  if op_card and (op_card.atk >= my_card.def + my_card.sta) and idx then
    OneImpact(player, my_idx):apply()
    my_card:remove_skill(skill_idx)
    player.field[idx], player.field[my_idx] = my_card, nil
  end
end,

-- Knight Jaina and Luthica
-- Tough Stamina
[1600] = function(player, my_idx, my_card, skill_idx)
  local mag = min(player.character.life, 20)
  OneBuff(player, my_idx, {sta={"=", mag}}):apply()
  my_card:remove_skill(skill_idx)
end,

-- Knight Jaina and Luthica
-- Iron Will
[1601] = function(player, my_idx, my_card, skill_idx)
  local mag = floor(abs(player.character.life - player.opponent.character.life) / 2)
  OneBuff(player, my_idx, {atk={"+", mag}}):apply()
  my_card.skills[skill_idx] = 1602 -- Rearm
end,

-- Knight Jaina and Luthica
-- Rearm
[1602] = function(player, my_idx, my_card, skill_idx)
  local orig = Card(my_card.id)
  for i = 1, 3 do
    if skill_id_to_type[orig.skills[i]] == "attack" then
      OneImpact(player, my_idx):apply()
      my_card.skills[skill_idx] = orig.skills[i]
      break
    end
  end
end,

-- GS 9th Star
-- Endure
[1603] = function(player, my_idx, my_card, skill_idx)
  OneBuff(player, my_idx, {sta={"=", Card(my_card.id).sta}}):apply()
  my_card:remove_skill_until_refresh(skill_idx)
end,

-- GS Advisor Ardita
-- Comradeship
[1604] = function(player, my_idx)
  local mag = #player:field_idxs_with_preds(pred.gs)
  OneBuff(player, my_idx, {sta={"+", mag}}):apply()
end,

-- GS Advisor Ardita
-- Countdown
[1605] = function(player)
  local idx = uniformly(player.opponent:field_idxs_with_preds(pred.follower))
  if idx then
    OneBuff(player.opponent, idx, {atk={"-", 2}, sta={"-", 2}}):apply()
    if player.opponent.field[idx] then
      player.opponent.field[idx].skills = {1076} -- Refresh
    end
  end
end,

-- Praying Helena
-- Evacuation Command
[1606] = function(player, my_idx, my_card)
  local pred_diff = function(card) return card ~= my_card end
  local idx = uniformly(player:field_idxs_with_preds(pred.follower, pred_diff))
  if idx then
    local buff = OnePlayerBuff(player)
    buff[idx] = {atk={"+", 1}, sta={"+", 1}}
    local mag = floor(player.field[idx].size / 2)
    buff[my_idx] = {atk={"+", mag}, sta={"+", mag}}
    buff:apply()
  end
end,

-- Praying Helena
-- Summoning Command
[1607] = function(player)
  local idx = player:deck_idxs_with_preds(pred.follower)[1]
  local idx2 = player:first_empty_field_slot()
  if idx and idx2 then
    player:deck_to_field(idx)
    OneBuff(player, idx2, {size={"-", 1}}):apply()
  end
end,

-- Chuseok Asmis
-- Moonlight Division!
[1611] = function(player, my_idx, my_card, skill_idx, op_idx, op_card)
  local buff = GlobalBuff(player)
  local mag = abs(Card(my_card.id).size - max(my_card.size - 1, 1))
  buff.field[player][my_idx] = {size={"-", 1}}
  if op_card then
    buff.field[player.opponent][op_idx] = {def={"-", mag}}
  end
  buff:apply()
end,

-- Chuseok Linus
-- Rice Cake's Power
[1612] = function(player, my_idx, my_card, skill_idx, op_idx, op_card)
  if op_card then
    local mag = abs(Card(op_card.id).atk - op_card.atk)
    OneBuff(player, my_idx, {atk={"+", mag}}):apply()
  end
end,

-- Chuseok Rose
-- Round and Round
[1613] = function(player, my_idx, my_card)
  local orig = Card(my_card.id)
  local mag = abs(orig.def - my_card.def)
  OneBuff(player, my_idx, {atk={"+", mag}, def={"=", orig.def}, sta={"+", mag}}):apply()
end,

-- Chuseok Helena
-- For the moon!
[1614] = function(player, my_idx, my_card, skill_idx, op_idx, op_card)
  if op_card then
    local buff = GlobalBuff(player)
    buff.field[player.opponent][op_idx] = {def={"-", 1}}
    buff.field[player][my_idx] = {atk={"+", abs(Card(op_card.id).def - op_card.def)}}
    buff:apply()
  end
end,

-- Chuseok Asmis
-- Moonlight Addition!
[1616] = function(player, my_idx, my_card)
  local orig = Card(my_card.id)
  local mag = abs(orig.def - my_card.def)
  OneBuff(player, my_idx, {atk={"+", mag}, def={"=", orig.def}, sta={"+", mag}}):apply()
end,

-- Chuseok Linus
-- Rice Cake's Power
[1617] = function(player, my_idx, my_card, skill_idx, op_idx, op_card)
  local buff = GlobalBuff(player)
  local orig = Card(my_card.id)
  local mag = floor(abs(orig.atk - my_card.atk) / 2)
  buff.field[player][my_idx] = {atk={"=", orig.atk}, sta={"+", mag}}
  if op_card then
    buff.field[player.opponent][op_idx] = {atk={"-", mag}}
  end
  buff:apply()
end,

-- Chuseok Rose
-- Hand in Hand
[1618] = function(player, my_idx, my_card, skill_idx, op_idx, op_card)
  local buff = GlobalBuff(player)
  if op_card then
    buff.field[player.opponent][op_idx] = {atk={"-", abs(Card(my_card.id).def - my_card.def)}}
  end
  buff.field[player][my_idx] = {def={"+", 1}}
  buff:apply()
end,

-- Chuseok Helena
-- In the name of the moon!
[1619] = function(player, my_idx, my_card, skill_idx, op_idx, op_card)
  if op_card then
    OneBuff(player, my_idx, {sta={"+", abs(Card(op_card.id).atk - op_card.atk)}}):apply()
  end
end,

-- Cook Club Svia
[1626] = function(player, my_idx)
  local buff = GlobalBuff(player)
  buff.field[player][my_idx] = {atk={"+",player.field[my_idx].def}}
  buff:apply()
end,

-- Master of Games
-- Game Mastery
[1659] = function(player, my_idx, my_card, skill_idx)
  local idx = player:first_empty_field_slot()
  if idx then
    local card = Card(300000 + random(336))
    player.field[idx] = card
    local buff = OnePlayerBuff(player)
    buff[idx] = {}
    buff[my_idx] = {}
    buff:apply()
    my_card:remove_skill(skill_idx)
  end
end,

-- DTD (Muspelheim)
[1663] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  OneBuff(player.opponent, 0, {life={"=",0}}):apply()
end,

-- Strong Attack!
[1704] = function(player, my_idx, my_card, skill_idx, other_idx, other_card)
  if other_card then
    OneBuff(player.opponent, other_idx, {atk={"-", 1}, sta={"-", 1}}):apply()
  end
end,

-- Adjustment Preparation
[1705] = function(player, my_idx)
  OneBuff(player, my_idx, {atk={"+",1}, sta={"+",2}}):apply()
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
  if my_card.sta < Card(my_card.id).sta then
    OneBuff(player, my_idx, {sta={"+",3}}):apply()
  elseif my_card.sta > Card(my_card.id).sta then
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
end
}


setmetatable(skill_func, {__index = function() return function() end end})
