local tinymaids = require("tinymaids")

local floor,ceil,min,max = math.floor, math.ceil, math.min, math.max
local abs = math.abs
local random = math.random

local new_student_orientation = function(player, opponent, my_idx, my_card)
  local target_idxs = shuffle(player:field_idxs_with_preds({pred.follower,
      pred.faction[my_card.faction]}))
  local buff = OnePlayerBuff(player)
  for i=1,2 do
    if target_idxs[i] then
      buff[target_idxs[i]] = {atk={"+",2},sta={"+",2}}
    end
  end
  buff:apply()
end

local court_jester = function(group_pred)
  return function(player, opponent, my_idx, my_card)
    local target_idxs = shuffle(player:field_idxs_with_preds({pred.follower,
        pred.faction[my_card.faction]}))
    local group_idxs = player:field_idxs_with_preds({pred.follower,
        pred.faction[my_card.faction], group_pred})
    if #group_idxs ~= 0 and #group_idxs ~= #target_idxs then
      local buff = OnePlayerBuff(player)
      for i=1,2 do
        buff[target_idxs[i]] = {atk={"+",3},sta={"+",3}}
      end
      buff:apply()
    end
  end
end

local sitas_suit = function(group_pred)
  return function(player, opponent, my_idx, my_card)
    local amt = 2
    for _,tar_pred in ipairs({pred[my_card.faction], group_pred}) do
      local target_idxs = shuffle(player:field_idxs_with_preds({pred.follower,
          tar_pred}))
      local buff = OnePlayerBuff(player)
      --print("Sita's suit found "..#target_idxs.." followers")
      for i=1,2 do
        if target_idxs[i] then
          buff[target_idxs[i]] = {atk={"+",amt},sta={"+",amt}}
        end
      end
      buff:apply()
      amt = amt - 1
    end
  end
end

local halloween = function(player, opponent)
  local target = opponent:hand_idxs_with_preds(pred.spell, pred.neg(pred.halloween))[1]
  local slot = player:first_empty_field_slot()
  if target and slot then
    player.field[slot] = Card(opponent.hand[target].id)
  end
end

spell_func = {
-- heartless blow
[200001] = function(player, opponent)
  local first_dmg = 4
  local second_dmg = 2
  if #player:field_idxs_with_preds() <= #player.opponent:field_idxs_with_preds() then
    first_dmg = 5
    second_dmg = 3
  end
  local target_idxs = shuffle(opponent:field_idxs_with_preds({pred.follower}))
  if target_idxs[1] then
    OneBuff(opponent, target_idxs[1], {sta={"-",first_dmg}}):apply()
  end
  if pred.sita(player.character) then
    if target_idxs[2] then
      target_idxs[1] = target_idxs[2]
    end
    if target_idxs[1] and opponent.field[target_idxs[1]] then
      OneBuff(opponent, target_idxs[1], {sta={"-",second_dmg}}):apply()
    end
  end
end,

-- new student orientation
[200002] = new_student_orientation,

-- cooking failure
[200003] = function(player)
  if #player:field_idxs_with_preds({pred.cook_club}) > 0 then
    local target_idxs = shuffle(player:field_idxs_with_preds({pred.follower, pred.faction.V}))
    local buff = OnePlayerBuff(player)
    local atk_up, sta_up = 1,2
    if #target_idxs >= 2 and
        pred.cook_club(player.field[target_idxs[1]]) and
        pred.cook_club(player.field[target_idxs[2]]) then
      atk_up, sta_up = 2,3
    end
    for i=1,min(2,#target_idxs) do
      buff[target_idxs[i]] = {atk={"+",atk_up},def={"+",1},sta={"+",sta_up},size={"+",1}}
    end
    buff:apply()
  end
end,

-- ward rupture
[200004] = function(player, opponent)
  local card, other_card = player.field[3], opponent.field[3]
  if card and other_card and pred.faction.V(card) and pred.follower(card) then
    local amount = abs(card.size - other_card.size)
    OneBuff(player, 3, {atk={"+",amount},def={"+",amount},sta={"+",amount}}):apply()
  end
end,

-- new recipe
[200005] = function(player)
  OneBuff(player,0,{life={"+",bound(0,8-player:field_size(),5)}}):apply()
end,

-- shrink
[200006] = function(player, opponent)
  local target_idx = opponent:field_idxs_with_most_and_preds(
      pred.size, {pred.follower})[1]
  if target_idx then
    local card = opponent.field[target_idx]
    OneBuff(opponent,target_idx,{sta={"=",floor(card.sta/2)},
      atk={"=",floor(card.atk/2)},def={"=",floor(card.def/2)},
      size={"=",floor(card.size/2)}}):apply()
  end
end,

-- balance
[200007] = function(player, opponent)
  if abs(player.character.life - opponent.character.life) <= 20 then
    -- set life equal
    local buff = GlobalBuff(player)
    local new_life = ceil((player.character.life + opponent.character.life)/2)
    buff.field[player][0] = {life={"=",new_life}}
    buff.field[opponent][0] = {life={"=",new_life}}
    buff:apply()

    -- send cards to grave
    local more_stuff,less_stuff = player, opponent
    if less_stuff:ncards_in_field() > more_stuff:ncards_in_field() then
      more_stuff,less_stuff = less_stuff,more_stuff
    end
    while less_stuff:ncards_in_field() < more_stuff:ncards_in_field() do
      more_stuff:field_to_grave(more_stuff:field_idxs_with_preds({})[1])
    end

    -- discard cards from hand
    local hand_pred = pred.t
    if pred.faction.V(player.character) then
      hand_pred = pred.follower
    end
    for i=1,#player.hand do
      while player.hand[i] and hand_pred(player.hand[i]) do
        player:hand_to_grave(i)
      end
    end
  end
end,

-- rumored order
[200008] = function(player)
  local target_idx = player:field_idxs_with_most_and_preds(pred.size,
    {pred.faction.V, pred.follower})[1]
  if target_idx then
    OneBuff(player,target_idx,{size={"-",2},sta={"+",2}}):apply()
  end
end,

-- omnivore
[200009] = function(player)
  local target_idxs = shuffle(player:field_idxs_with_preds(pred.follower))
  local sizes = {}
  local buff_amount = 1
  for i=1,#player.hand do
    if not sizes[player.hand[i].size] then
      sizes[player.hand[i].size] = true
      buff_amount = buff_amount + 1
    end
  end
  if #target_idxs > 0 then
    local buff = OnePlayerBuff(player)
    for i=1,min(#target_idxs,2) do
      buff[target_idxs[i]] = {sta={"+",buff_amount}}
    end
    buff:apply()
  end
end,

-- volcano
[200010] = function(player, opponent)
  local target_idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if target_idx then
    local x = #player:hand_idxs_with_preds(pred.faction.V, pred.follower)
    OneBuff(opponent, target_idx, {atk={"-",x},def={"-",x},sta={"-",x}}):apply()
  end
end,

-- accident
[200011] = function(player, opponent)
  local debuff_amount = #player:field_idxs_with_preds({pred.maid,pred.follower})
  local target_idxs = shuffle(opponent:field_idxs_with_preds(pred.follower))
  local def_amt = 0
  if debuff_amount == 2 then
    def_amt = 1
  end
  local buff = OnePlayerBuff(opponent)
  for i=1,min(2,#target_idxs) do
    buff[target_idxs[i]] = {atk={"-",debuff_amount},def={"-",def_amt},sta={"-",debuff_amount}}
  end
  buff:apply()
end,

-- new maid training
[200012] = new_student_orientation,

-- she did it
[200013] = function(player)
  if #player:field_idxs_with_preds({pred.maid,pred.follower}) > 0 then
    local buff = OnePlayerBuff(player)
    local target_idxs = player:field_idxs_with_preds(pred.follower)
    local reduced_amount = 0
    for _,idx in ipairs(target_idxs) do
      reduced_amount = reduced_amount + player.field[idx].size - 1
      buff[idx] = {size={"=",1}}
    end
    buff:apply()
    local target_idx = uniformly(target_idxs)
    local atk_amt = 0
    if pred.maid(player.field[target_idx]) then
      atk_amt = floor(reduced_amount/2)
    end
    OneBuff(player,target_idx,{size={"+",reduced_amount},
      sta={"+",floor(reduced_amount/2)}, atk={"+",atk_amt}}):apply()
  end
end,

-- noble sacrifice
[200014] = function(player)
  local target_idx = player:field_idxs_with_most_and_preds(pred.size,
      {pred.follower, pred.faction.A})[1]
  if target_idx then
    local life_gain = player.field[target_idx].size*2
    player:field_to_grave(target_idx)
    OneBuff(player,0,{life={"+",min(life_gain,9)}}):apply()
  end
end,

-- tighten security
[200015] = function(player)
  local target_idx = player:field_idxs_with_preds({pred.faction.A, pred.follower})[1]
  if target_idx then
    local buff = GlobalBuff(player)
    local def_amt = #(player:hand_idxs_with_preds({pred.faction.A}))
    local other_amt = ceil(abs(def_amt - player.field[target_idx].def)/2)
    buff.field[player][target_idx] = {def={"=", def_amt},atk={"+", other_amt},
      sta={"+", other_amt}}
    buff:apply()
  end
end,

-- bondage
[200016] = function(player, opponent)
  local buff = OnePlayerBuff(opponent)
  local target_idxs = shuffle(opponent:field_idxs_with_preds(pred.follower))
  for i=1,min(3,#target_idxs) do
    buff[target_idxs[i]] = {size={"+",1}}
  end
  buff:apply()
end,

-- curse
[200017] = function(player, opponent)
  if player.character.faction == "A" then
    local debuff = GlobalBuff(player)
    local tar1, tar2 = unpack(shuffled(
        opponent:field_idxs_with_preds({pred.follower})))
    for _,idx in ipairs({tar1,tar2}) do
      debuff.field[opponent][idx] = {atk={"-",2},sta={"-",2}}
    end
    debuff:apply()
  end
end,

-- swap spell
[200018] = function(player, opponent)
  local card = player.field[3]
  local idx = opponent:field_idxs_with_preds(pred.follower)[1]
  if card and pred.follower(card) and idx then
    local other_card = opponent.field[idx]
    local buff = GlobalBuff(player)
    buff.field[player][3],buff.field[opponent][idx] = {},{}
    for _,stat in ipairs({"atk","def","sta","size"}) do
      buff.field[player][3][stat] = {"=",other_card[stat]}
      buff.field[opponent][idx][stat] = {"=",card[stat]}
    end
    buff:apply()
  end
end,

-- mass recall
[200019] = function(player, opponent)
  for i=1,5 do
    if opponent.field[i] and opponent.field[i].size <= 3 then
      opponent:field_to_grave(i)
    end
    if player.field[i] and player.field[i].faction ~= "A" then
      player:field_to_grave(i)
    end
  end
end,

-- forced entry
[200020] = function(player, opponent)
  if player.field[3] and opponent.field[3] then
    if player.field[3].size < opponent.field[3].size then
      player:destroy(3)
    elseif player.field[3].size > opponent.field[3].size then
      opponent:destroy(3)
    else
      opponent:field_to_grave(3)
    end
  end
end,

-- saint's blessing
[200021] = function(player)
  local target_idxs = player:field_idxs_with_preds(pred.C, pred.follower)
  local buff = OnePlayerBuff(player)
  for _,idx in ipairs(target_idxs) do
    buff[idx] = {sta={"+",3}}
    if pred.luthica(player.character) then
      buff[idx].atk = {"+",3}
    end
  end
  buff:apply()
end,

-- close encounter
[200022] = new_student_orientation,

-- entry denied
[200023] = function(player, opponent)
  local my_idx = player:field_idxs_with_preds({pred.follower})[1]
  local other_idx = opponent:field_idxs_with_most_and_preds(
    pred.size, {pred.follower})[1]
  if my_idx then
    player.field[my_idx].active = false
    OneBuff(player,my_idx,{atk={"+",3}}):apply()
  end
  if my_idx and other_idx then
    opponent.field[other_idx].active = false
    OneImpact(opponent, other_idx):apply()
  end
end,

-- healing magic
[200024] = function(player)
  OneBuff(player, 0, {life = {"+", #player.hand}}):apply()
end,

-- sky surprise
[200025] = function(player, opponent)
  local old_idx = player:get_follower_idxs()[1]
  local new_idx = opponent:first_empty_field_slot()
  if old_idx and new_idx then
    local card = player.field[old_idx]
    opponent.field[new_idx] = card
    player.field[old_idx] = nil
    card.active = false
    OneBuff(opponent, 0, {life={"-",ceil(card.size/2)}}):apply()
    OneBuff(opponent, new_idx, {size={"=",1}}):apply()
  end
end,

-- meadow leisure
[200026] = function(player)
  local target_idx = uniformly(player:field_idxs_with_preds(pred.follower))
  if target_idx then
    local ncards = player:ncards_in_field()
    OneBuff(player, target_idx, {atk={"+",ncards-1},sta={"+",ncards+1}}):apply()
  end
end,

-- knight's letter
[200027] = function(player, opponent)
  if player:ncards_in_field() == opponent:ncards_in_field() then
    local target_idxs = shuffle(opponent:field_idxs_with_preds())
    for i=1,min(2,#target_idxs) do
      opponent:field_to_bottom_deck(target_idxs[i])
    end
  end
end,

-- shield break
[200028] = function(player, opponent)
  local target_idx = opponent:field_idxs_with_most_and_preds(pred.def,pred.follower)[1]
  if target_idx then
    local def = opponent.field[target_idx].def
    if def > 0 then
      OneBuff(opponent,target_idx,{def={"-",2*def}}):apply()
    end
  end
end,

-- sentry's testimony
[200029] = function(player)
  local knight_idxs = player:grave_idxs_with_preds(pred.follower, pred.knight)
  local target_idx = uniformly(player:field_idxs_with_preds(pred.follower))
  if target_idx then
    OneBuff(player,target_idx,{atk={"+",#knight_idxs},sta={"+",#knight_idxs}}):apply()
  end
  for i = #player.grave, 1, -1 do
    player:grave_to_exile(i)
  end
end,

-- pacifism
[200030] = function(player, opponent)
  local buff = OnePlayerBuff(player)
  for i=1,5 do
    if player.field[i] and pred.follower(player.field[i]) then
      player.field[i].active = false
      if pred.faction.C(player.field[i]) then
        buff[i]={size={"-",1},atk={"+",2},sta={"+",2}}
      end
    end
    if opponent.field[i] then
      opponent.field[i].active = false
    end
  end
  buff:apply()
end,

-- flina's command
[200031] = function(player)
  local target_idxs = shuffle(player:field_idxs_with_preds({pred.faction.D, pred.follower}))
  local buff = OnePlayerBuff(player)
  for i=1,2 do
    if target_idxs[i] then
      buff[target_idxs[i]] = {sta={"+",3}}
    end
  end
  buff:apply()
  local target_idxs2 = shuffle(player:field_idxs_with_preds({pred.follower}))
  local buff2 = OnePlayerBuff(player)
  for i=1,2 do
    if target_idxs2[i] then
      buff2[target_idxs2[i]] = {atk={"+",1}}
    end
  end
  buff2:apply()
end,

-- blood reversal
[200032] = new_student_orientation,

-- vampiric rites
[200033] = function(player)
  local idxs = player:get_follower_idxs()
  local debuff= GlobalBuff(player)
  local buff_stats = {sta={"+",0}, atk={"+",0}, size={"+",0}}
  for _,idx in ipairs(idxs) do
    local card = player.field[idx]
    local debuff_stats = {sta={"-", card.sta-1}, size={"-", card.size-1}}
    debuff.field[player][idx] = debuff_stats
    if player.field[idx].atk > 0 then
      debuff_stats.atk = {"-", player.field[idx].atk - 1}
    end
    for k,v in pairs(debuff_stats) do
      buff_stats[k][2] = buff_stats[k][2] + debuff_stats[k][2]
    end
  end
  local target_idx = player:field_idxs_with_least_and_preds(
    pred.size, {pred.follower, pred.faction.D})[1]
  debuff:apply()
  if target_idx then
    local buff = GlobalBuff(player)
    buff.field[player][target_idx] = buff_stats
    buff:apply()
  end
end,

-- blood target
[200034] = function(player)
  local target_idx = player:field_idxs_with_preds({pred.follower,pred.faction.D})[1]
  if target_idx then
    local life = min(10,player.field[target_idx].sta-1)
    local buff = OnePlayerBuff(player)
    buff[target_idx] = {sta={"=",1}, atk={"+",min(floor(life/2),3)}}
    buff[0] = {life = {"+",life}}
    buff:apply()
  end
end,

-- sacrifice
[200035] = function(player, opponent)
  local buff = GlobalBuff(player)
  buff.field[player][0] = {life={"-",1}}
  buff.field[opponent][0] = {life={"-",4}}
  buff:apply()
end,

-- full moon power
[200036] = function(player)
  local targets = player:field_idxs_with_preds(pred.follower,
      pred.union(pred.scardel, pred.crescent, pred.flina))
  local buff = OnePlayerBuff(player)
  for _,idx in ipairs(targets) do
    buff[idx] = {atk={"+",3}}
  end
  buff:apply()
end,

-- pass the blood
[200037] = function(player)
  local card = player.field[3]
  if card and pred.follower(card) and pred.faction.D(card) then
    local def = 0
    for i=1,5 do
      if player.field[i] and pred.follower(player.field[i]) then
        def = def + player.field[i].def
      end
    end
    def = min(def,5)
    OneBuff(player,3,{atk={"+",def},sta={"+",def}}):apply()
  end
end,

-- overwhelm
[200038] = function(player,opponent)
  local life = opponent.character.life
  local buff = OnePlayerBuff(opponent)
  for i=1,5 do
    if opponent.field[i] and pred.follower(opponent.field[i]) and
        opponent.field[i].sta + opponent.field[i].def > life then
      buff[i]={def={"-",floor(life/2)}}
    end
  end
  buff:apply()
end,

-- forced confinement
[200039] = function(player, opponent)
  local target = opponent:field_idxs_with_most_and_preds(pred.sta,pred.follower)[1]
  if player.character.faction == "D" and target then
    OneBuff(player,0,{life={"-",ceil(opponent.field[target].size/2)}}):apply()
    opponent:field_to_bottom_deck(target)
  end
end,

-- evil eye
[200040] = function(player,opponent)
  local idxs = opponent:field_idxs_with_preds(pred.follower)
  local buff = OnePlayerBuff(opponent)
  for _,idx in ipairs(idxs) do
    buff[idx] = {atk={"-",2},def={"-",2}}
    if pred.faction.D(player.character) then
      buff[idx].sta={"-",2}
    end
  end
  buff:apply()
  -- this card is actually supposed to be able to kill something
  -- with the first clause, then check the 2nd clause against the new
  -- number of followers!
  local idxs = opponent:field_idxs_with_preds(pred.follower)
  if #idxs <= 2 then
    local buff = OnePlayerBuff(opponent)
    for _,idx in ipairs(idxs) do
      buff[idx] = {atk={"-",1},def={"-",1}}
    end
    buff:apply()
  end
end,

-- student council justice
[200041] = function(player, opponent)
  local n_council = #player:field_idxs_with_preds({pred.follower, pred.student_council})
  local n_vita = #player:field_idxs_with_preds({pred.follower, pred.faction.V})
  if n_council > 0 then
    local targets = shuffle(opponent:field_idxs_with_preds(pred.follower))
    local buff = OnePlayerBuff(opponent)
    for i=1,min(2,#targets) do
      if n_vita == 1 then
        buff[targets[i]] = {atk={"-",2}}
      elseif n_vita == 2 then
        buff[targets[i]] = {sta={"-",3}}
      elseif n_vita >= 3 then
        buff[targets[i]] = {atk={"-",2},def={"-",1},sta={"-",2}}
      end
    end
    buff:apply()
  end
end,

-- student council kick
[200042] = function(player, opponent)
  local kicker = player:field_idxs_with_preds({pred.follower, pred.active, pred.student_council})[1]
  local target = opponent:field_idxs_with_most_and_preds(pred.size, pred.follower)[1]
  if kicker then
    player.field[kicker].active = false
    if target then
      -- TODO: can this spell heal the enemy follower??
      OneBuff(opponent, target, {sta={"-",player.field[kicker].atk + 1}}):apply()
    end
  end
end,

-- book thief
[200043] = function(player, opponent)
  local nlibrarians = #player:field_idxs_with_preds({pred.follower, pred.library_club})
  local spells = opponent:field_idxs_with_preds(pred.spell)
  local new_idx = player:first_empty_field_slot()
  if nlibrarians >= #spells and new_idx then
    local old_idx = uniformly(spells)
    if old_idx then
      player.field[new_idx] = opponent.field[old_idx]
      opponent.field[old_idx] = nil
    end
  end
end,

-- tower of books
[200044] = function(player, opponent)
  local nvita = #player:field_idxs_with_preds({pred.follower, pred.faction.V})
  local spell = opponent:hand_idxs_with_preds({pred.spell,
    function(card) return card.size < 3 end})[1]
  if spell and nvita > 0 then
    local buff = GlobalBuff(player)
    buff.hand[opponent][spell] = {size={"+",nvita}}
    buff:apply()
  end
end,

-- empowering chant
[200045] = function(player, opponent)
  local card = player.field[2]
  if card and card.type == "follower" then
    OneBuff(player,2,{atk={"+",2},sta={"+",5}}):apply()
    if player.character.faction ~= "V" then
      card.skills = {}
    end
  end
end,

-- feast
[200046] = function(player, opponent)
  if pred.sita(player.character) then
    OneBuff(player,0,{life={"+",4}}):apply()
  end
end,

-- reunion
[200047] = function(player, opponent)
  local maxsize = #player.hand
  if player.character.faction == "V" then
    maxsize = maxsize + 1
  end
  local old_idx = uniformly(opponent:field_idxs_with_preds({pred.follower,
    function(card) return card.size <= maxsize end}))
  local new_idx = player:first_empty_field_slot()
  if old_idx and new_idx then
    player.field[new_idx] = opponent.field[old_idx]
    opponent.field[old_idx] = nil
    OneBuff(player,new_idx,{size={"-",1}}):apply()
  end
end,

-- unwilling sacrifice
[200048] = function(player, opponent)
  local sac = player:field_idxs_with_least_and_preds(pred.sta, pred.follower, pred.A)[1]
  if sac then
    local sta = player.field[sac].sta
    player:field_to_grave(sac)
    local target = opponent:field_idxs_with_preds({pred.follower,
      function(card) return card.atk > sta end})[1]
    if target then
      OneBuff(opponent,target,{atk={"-",sta}}):apply()
    end
  end
end,

-- shoddy magic
[200049] = function(player, opponent)
  local targets = shuffle(opponent:field_idxs_with_preds(pred.follower))
  local buff = OnePlayerBuff(opponent)
  for i=1,min(#targets,2) do
    buff[targets[i]] = {sta={"-",uniformly({2,4})}}
  end
  buff:apply()
end,

-- lineage maintenance
[200050] = function(player, opponent)
  local buff = OnePlayerBuff(player)
  for i=1,5 do
    local card = player.field[i]
    if card and pred.faction.A(card) and pred.follower(card) and
        card.size == i then
      buff[i] = {atk={"+",3},sta={"+",3}}
    end
  end
  buff:apply()
end,

-- magic stone found
[200051] = function(player, opponent)
  local idx = player:hand_idxs_with_preds(pred.faction.A)[1]
  if idx then
    player:hand_to_grave(idx)
    local targets = shuffle(opponent:field_idxs_with_preds(pred.follower))
    local buff = OnePlayerBuff(opponent)
    for i=1,min(#targets,2) do
      buff[targets[i]] = {atk={"-",1},def={"-",2}}
    end
    buff:apply()
  end
end,

-- magic summit invite
[200052] = function(player, opponent)
  local target = player:field_idxs_with_preds({pred.follower, pred.faction.A})[2]
  local first = player.field[1]
  if target and first and pred.follower(first) then
    OneBuff(player,target,{def={"=",first.def},sta={"=",first.sta}}):apply()
  end
end,

-- sister's letter
[200053] = function(player, opponent)
  local targets = opponent:field_idxs_with_most_and_preds(pred.size,pred.follower)
  local buff = OnePlayerBuff(opponent)
  for _,idx in ipairs(targets) do
    buff[idx] = {atk={"-",idx},def={"-",idx},sta={"-",idx}}
  end
  buff:apply()
end,

-- dark secret
-- note: it does nothing if sizes are equal...
[200054] = function(player, opponent)
  local fake = {size = 0}
  local larger = opponent.field[2] or fake
  local smaller = opponent.field[4] or fake
  local lidx, sidx = 2, 4
  if smaller.size > larger.size then
    smaller, larger = larger, smaller
    sidx, lidx = lidx, sidx
  end
  if larger.size ~= smaller.size then
    if larger ~= fake then
      if pred.faction.A(player.character) then
        opponent:destroy(lidx)
      else
        opponent:field_to_grave(lidx)
      end
    end
    if smaller ~= fake then
      if pred.faction.A(player.character) then
        opponent:field_to_grave(sidx)
      else
        opponent:field_to_bottom_deck(sidx)
      end
    end
  end
end,

-- no turning back
[200055] = function(player, opponent)
  local idx1 = uniformly(player:field_idxs_with_preds(pred.follower))
  local idx2 = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if idx1 then
    if opponent:field_size() % 2 == 1 then
      if idx2 then
        OneImpact(opponent, idx2):apply()
        opponent:destroy(idx2)
      end
    else
      OneImpact(player, idx1):apply()
      player:field_to_grave(idx1)
    end
  end
end,

-- sense of belonging
[200056] = function(player, opponent)
  local old_idx = uniformly(opponent:field_idxs_with_preds(pred.follower,
    function(card) return card.faction ~= opponent.character.faction end))
  local new_idx = player:first_empty_field_slot()
  if old_idx and new_idx then
    OneImpact(opponent, old_idx):apply()
    player.field[new_idx] = opponent.field[old_idx]
    opponent.field[old_idx] = nil
    player.field[new_idx].active = false
  end
end,

-- study of miracles
[200057] = function(player, opponent)
  local targets = player:field_idxs_with_preds({pred.follower, pred.seeker})
  local buff = OnePlayerBuff(player)
  for _,idx in ipairs(targets) do
    buff[idx] = {atk={"+",2},sta={"+",1}}
  end
  buff:apply()
end,

-- proof of miracles
[200058] = function(player, opponent)
  local ncards = #player.hand
  local target = uniformly(player:field_idxs_with_preds({pred.follower,pred.faction.C}))
  local buff = OnePlayerBuff(player)
  buff[0] = {life={"-",floor(ncards/2)}}
  if target then
    buff[target] = {atk={"+",ncards},sta={"+",ncards}}
  end
  buff:apply()
end,

-- quick service
[200059] = function(player, opponent)
  local followers = player:field_idxs_with_preds(pred.follower)
  for _,idx in ipairs(followers) do
    player:field_to_grave(idx)
  end
  -- TODO: does this pick first or at random?
  local target = player:hand_idxs_with_preds({pred.follower, pred.faction.C,
    function(card) return card.size <= #followers + 2 end })[1]
  if target and player.field[4] == nil then
    local card = player:remove_from_hand(target)
    player.field[4] = card
    local buff_size = ceil(#player:grave_idxs_with_preds(pred.faction.C) / 2)
    OneBuff(player, 4, {atk={"+",buff_size},sta={"+",buff_size}}):apply()
  end
end,

-- mother demon rumor
[200060] = function(player, opponent)
  local fake = {size=0}
  local card1 = opponent.field[1] or fake
  local card2 = opponent.field[2]
  if card2 and card1.size + card2.size >= 6 then
    OneImpact(opponent, 2):apply()
    opponent:destroy(2)
  end
end,

-- luthica's ward
[200061] = function(player, opponent)
  local amt = 0
  for i=1,4 do
    local idx = uniformly(player:grave_idxs_with_preds())
    if idx then
      player:grave_to_exile(idx)
      amt = amt + 1
    end
  end
  local targets = shuffle(player:field_idxs_with_preds(pred.follower))
  local buff = OnePlayerBuff(player)
  for i=1,min(#targets,2) do
    if pred.C(player.field[targets[i]]) then
      buff[targets[i]] = {atk={"+",2*amt},sta={"+",2*amt}}
    else
      buff[targets[i]] = {atk={"+",2+amt},sta={"+",2+amt}}
    end
  end
  buff:apply()
end,

-- spell change
[200062] = function(player, opponent)
  local my_idx = player:hand_idxs_with_preds(pred.spell)[1]
  local other_idx = opponent:hand_idxs_with_preds(pred.spell)[1]
  if my_idx and other_idx then
    player.hand[my_idx], opponent.hand[other_idx] =
      opponent.hand[other_idx], player.hand[my_idx]
  end
end,

-- prank's price
[200063] = function(player, opponent)
  if #player.hand >= 2 and #opponent.hand >= 2 then
    player:hand_to_grave(1)
    player:hand_to_grave(1)
    opponent:hand_to_grave(1)
    opponent:hand_to_grave(1)
  end
end,

-- strega blood
[200064] = function(player, opponent)
  local targets = player:field_idxs_with_preds({pred.follower, pred.witch})
  local buff = OnePlayerBuff(player)
  for _,idx in ipairs(targets) do
    buff[idx] = {atk={"+",1}, sta={"+",3}}
  end
  buff[0] = {life={"-",1}}
  buff:apply()
end,

-- strega blade
[200065] = function(player, opponent)
  local witch = player:field_idxs_with_least_and_preds(pred.size,
    {pred.follower, pred.witch})[1]
  if witch then
    local buff = GlobalBuff(player)
    -- TODO: determine whether this card can increase atk.
    local reduced_amount = player.field[witch].sta-1
    buff.field[player][witch] = {sta={"=",1}}
    if player.field[witch].atk > 0 then
      reduced_amount = reduced_amount + player.field[witch].atk-1
      buff.field[player][witch].atk = {"=",1}
    end
    local target = opponent:field_idxs_with_preds(pred.follower)[1]
    if target then
      buff.field[opponent][target] = {sta={"-",math.floor(reduced_amount / 2)}}
    end
    buff:apply()
  end
end,

-- tower visitor
[200066] = function(player, opponent)
  local big_idx = player:field_idxs_with_most_and_preds(pred.size,
    {pred.follower, pred.faction.D})[1]
  if big_idx then
    local cutoff = player.field[big_idx].size
    local targets = opponent:field_idxs_with_preds({pred.follower,
      function(card) return card.size < cutoff end})
    local buff = OnePlayerBuff(opponent)
    for _,idx in ipairs(targets) do
      buff[idx] = {def={"-",2},sta={"-",2}}
    end
    buff:apply()
  end
end,

-- vampiric education
[200067] = function(player, opponent)
  local total_size = 0
  for i=1,#player.hand do
    total_size = total_size + player.hand[i].size
  end
  local targets = shuffle(player:field_idxs_with_preds({pred.follower, pred.faction.D}))
  local buff = OnePlayerBuff(player)
  for i=1,min(#targets,2) do
    buff[targets[i]] = {sta={"+",ceil(total_size/2)}}
  end
  buff:apply()
end,

-- fatal blow
[200068] = function(player, opponent)
  local maxsize = #player.hand + player:ncards_in_field()
  local life = 0
  for i=1,5 do
    if player.field[i] and player.field[i].size <= maxsize then
      player:field_to_grave(i)
    end
    if opponent.field[i] and opponent.field[i].size <= maxsize then
      opponent:field_to_grave(i)
      life = life + 1
    end
  end
  OneBuff(player,0,{life={"-",life}}):apply()
end,

-- good job
[200069] = function(player, opponent)
  local buff = GlobalBuff(player)
  for i=1,5 do
    if player.field[i] and pred.follower(player.field[i]) then
      buff.field[player][i] = {atk = {"+",1}}
    end
    if opponent.field[i] and pred.follower(opponent.field[i]) then
      buff.field[opponent][i] = {atk = {"+",1}}
    end
  end
  buff:apply()
end,

-- thank you
[200070] = function(player, opponent)
  local buff = GlobalBuff(player)
  for i=1,5 do
    if player.field[i] and pred.follower(player.field[i]) then
      buff.field[player][i] = {def = {"+",1}}
    end
    if opponent.field[i] and pred.follower(opponent.field[i]) then
      buff.field[opponent][i] = {def = {"+",1}}
    end
  end
  buff:apply()
end,

-- pleased to meet you
[200071] = function(player, opponent)
  local buff = GlobalBuff(player)
  for i=1,5 do
    if player.field[i] and pred.follower(player.field[i]) then
      buff.field[player][i] = {sta = {"+",1}}
    end
    if opponent.field[i] and pred.follower(opponent.field[i]) then
      buff.field[opponent][i] = {sta = {"+",1}}
    end
  end
  buff:apply()
end,

-- cord ball
[200072] = function(player, opponent, idx)
  if #player.grave >= 6 then
    local ncards = #player.hand
    local nfollowers = #player:hand_idxs_with_preds(pred.follower)
    while #player.hand ~= 0 do
      player:hand_to_bottom_deck(1)
    end
    if ncards >= 3 and nfollowers >= 1 and #player.grave > 0 then
      player:grave_to_bottom_deck(math.random(#player.grave))
    end
  end
  player:field_to_exile(idx)
end,

-- troubleshooting
[200073] = function(player, opponent)
  local sta_amt = 3
  if #player.deck <= 10 then
    sta_amt = 5
  end
  local idxs = player:field_idxs_with_preds({pred.faction.V, pred.follower})
  local buff = OnePlayerBuff(player)
  for _,idx in ipairs(idxs) do
    buff[idx] = {sta={"+",sta_amt}}
  end
  buff:apply()
end,

-- court jester
[200074] = court_jester(pred.student_council),

-- sage's sermon
[200075] = function(player, opponent)
  local target_idx = uniformly(opponent:field_idxs_with_preds({pred.follower, pred.skill}))
  if target_idx then
    opponent.field[target_idx].skills = {}
    OneImpact(opponent, target_idx):apply()
  end
end,

-- shameless ambition
[200076] = function(player, opponent)
  local nvita = 0
  for i=1,3 do
    if #player.deck ~= 0 then
      local card = player.deck[#player.deck]
      if pred.faction.V(card) and pred.follower(card) then
        nvita = nvita + 1
      end
      player:deck_to_grave(#player.deck)
    end
  end
  OneBuff(player,0,{life={"+",3*nvita}}):apply()
end,

-- night's beckoning
[200077] = function(player, opponent, idx, card)
  local nfollowers = #player:grave_idxs_with_preds(pred.follower)
  local nvita = #player:grave_idxs_with_preds({pred.follower, pred.faction.V})
  if nvita ~= 0 and nvita ~= nfollowers then
    local target_idxs = opponent:field_idxs_with_preds(pred.spell)
    if #target_idxs ~= 0 then
      for _,idx in ipairs(target_idxs) do
        opponent:field_to_grave(idx)
      end
    else
      card.active = false
      player.send_spell_to_grave = false
    end
  end
end,

-- visitor
[200078] = function(player, opponent)
  local target_idx = player:hand_idxs_with_preds({pred.follower, pred.faction.V})[1]
  local new_idx = player:first_empty_field_slot()
  if new_idx and target_idx then
    player.field[new_idx] = player.hand[target_idx]
    player.hand[target_idx] = nil
    player:squish_hand()
    -- TODO: does it always give the same atk and sta??
    local stabuff = math.random(3,5)
    OneBuff(player, new_idx, {size={"=",math.random(1,2)},
        atk={"+",stabuff},sta={"+",stabuff}}):apply()
  end
end,

-- black magic plot
[200079] = function(player, opponent, my_idx, my_card)
  local target_idxs = shuffle(player:field_idxs_with_preds({pred.follower, pred.faction.A}))
  local buff = OnePlayerBuff(player)
  for i=1,2 do
    if target_idxs[i] then
      buff[target_idxs[i]] = {atk={"+",4},sta={"-",1}}
    end
  end
  buff:apply()
end,

-- unmasked lie
[200080] = function(player, opponent, my_idx, my_card)
  local target_idxs = shuffle(opponent:field_idxs_with_preds({pred.follower}))
  local amt = #opponent:hand_idxs_with_preds(pred.spell)
  local buff = OnePlayerBuff(opponent)
  for i=1,2 do
    if target_idxs[i] then
      buff[target_idxs[i]] = {def={"-",amt}}
    end
  end
  buff:apply()
end,

-- bargaining table
[200081] = function(player, opponent, my_idx, my_card)
  local target_idxs = shuffle(player:field_idxs_with_preds({pred.follower}))
  local buff = OnePlayerBuff(player)
  for i=1,2 do
    if target_idxs[i] then
      buff[target_idxs[i]] = {sta={"+",player.field[target_idxs[i]].size}}
    end
  end
  buff:apply()
end,

-- maid revolution
[200082] = court_jester(pred.maid),

-- suicide mission
[200083] = function(player, opponent)
  local spell_target = uniformly(opponent:field_idxs_with_preds(pred.spell))
  local hand_target = player:hand_idxs_with_preds({pred.faction.A, pred.follower})[1]
  if spell_target and hand_target then
    player:hand_to_bottom_deck(hand_target)
    opponent:field_to_grave(spell_target)
  end
end,

-- linia's tastes
[200084] = function(player, opponent, my_idx, my_card)
  local my_follower = player:field_idxs_with_preds(pred.follower)[1]
  local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if my_follower and target then
    opponent:field_to_grave(target)
    if my_card.size > 1 then
      my_card.size = 1
      player.field[my_idx] = nil
      opponent:to_top_deck(my_card)
    else
      player:field_to_exile(my_idx)
    end
  end
end,

-- say no evil
[200085] = function(player, opponent)
  local acad = player:hand_idxs_with_preds(pred.faction.A)[1]
  if acad then
    local sent = 0
    while acad do
      player.hand[acad].size = max(player.hand[acad].size-1, 1)
      player:hand_to_bottom_deck(acad)
      sent = sent + 1
      acad = player:hand_idxs_with_preds(pred.faction.A)[1]
    end
    if sent >= 2 then
      for i=1,5 do
        if opponent.field[i] then
          opponent.field[i].active = false
        end
      end
    end
    local target = opponent:hand_idxs_with_preds(pred.spell)[1]
    if target then
      player.hand[#player.hand+1] = opponent.hand[target]
      opponent.hand[target] = nil
      opponent:squish_hand()
    end
  end
end,

-- chrono clock
[200086] = function(player, opponent)
  local target = uniformly(player:field_idxs_with_preds({pred.faction.C, pred.follower}))
  if target then
    OneBuff(player, target, {size={"-",math.random(1,3)},
        atk={"+",math.random(1,3)}}):apply()
  end
end,

-- power control
[200087] = court_jester(pred.seeker),

-- undercover work
[200088] = function(player)
  local ncrux = #player:grave_idxs_with_preds(pred.faction.C)
  local target = uniformly(player:field_idxs_with_preds({pred.faction.C, pred.follower}))
  if ncrux >= 6 and target then
    OneBuff(player, target, {sta={"+",6}}):apply()
  end
end,

-- conversion
[200089] = function(player, opponent)
  local my_guy = player:field_idxs_with_preds(pred.follower)[1]
  if my_guy then
    local size_cap = player.field[my_guy].size
    local target = uniformly(opponent:field_idxs_with_preds({pred.follower,
        function(card) return card.size < size_cap end}))
    local new_slot = player:first_empty_field_slot()
    if target and new_slot then
      player.field[new_slot] = opponent.field[target]
      player.field[new_slot].active = false
      opponent.field[target] = nil
      player.field[new_slot]:gain_skill(1056)
    end
  end
end,

-- recluse
[200090] = function(player, opponent)
  local my_follower = player:field_idxs_with_preds(pred.follower)
  if #my_follower == 1 then
    my_follower = my_follower[1]
    local buff = GlobalBuff(player)
    buff.field[player][my_follower] = {atk={"=",0},def={"=",0}}
    local debuff_amt = floor((player.field[my_follower].atk +
        player.field[my_follower].def)/2)
    local targets = shuffle(opponent:field_idxs_with_preds(pred.follower))
    for i=1,min(2,#targets) do
      buff.field[opponent][targets[i]] = {atk={"-",debuff_amt}}
    end
    buff:apply()
  end
end,

-- arrest
[200091] = function(player, opponent)
  local ncards = #player.hand
  local target = uniformly(opponent:field_idxs_with_preds({pred.follower,
      function(card) return card.size >= 4 end}))
  while player.hand[1] do
    --print("hand to bottom deck 1")
    --print("foo "..#player.hand)
    player:hand_to_bottom_deck(1)
  end
  if ncards >= 2 and target then
    opponent:field_to_bottom_deck(target)
  end
end,

-- crux command
[200092] = function(player, opponent)
  local targets = shuffle(player:field_idxs_with_preds(pred.follower))
  local normal_buff = {def={"+",2},sta={"+",2}}
  local c_buff = {atk={"+",2},def={"+",2},sta={"+",2}}
  if #player.deck < 10 then
    normal_buff = {size={"+",1},atk={"+",6},sta={"+",6}}
    c_buff = normal_buff
  end
  local buff = OnePlayerBuff(player)
  for i=1,min(2,#targets) do
    if pred.C(player.field[targets[i]]) then
      buff[targets[i]] = c_buff
    else
      buff[targets[i]] = normal_buff
    end
  end
  buff:apply()
end,

-- dollmaster
[200093] = function(player, opponent)
  if opponent.field[3] and pred.follower(opponent.field[3]) then
    local debuff_amt = opponent.field[3].size
    OneBuff(opponent, 3, {atk={"-",debuff_amt},sta={"-",debuff_amt}}):apply()
  end
end,

-- bad apple
[200094] = court_jester(pred.witch),

-- midnight doll show
[200095] = function(player, opponent)
  local ncards = #player:grave_idxs_with_preds({pred.follower,pred.faction.D})
  if ncards >= 7 then
    local buff = OnePlayerBuff(opponent)
    for i=1,5 do
      if opponent.field[i] and pred.follower(opponent.field[i]) then
        buff[i] = {def={"-",2},sta={"-",2}}
      end
    end
    buff:apply()
  end
end,

-- misfortune
[200096] = function(player, opponent)
  local cards = shuffle(player:grave_idxs_with_preds(pred.spell))
  if #cards >= 6 then
    for i=1,6 do
      local card = uniformly(player:grave_idxs_with_preds(pred.spell))
      player:grave_to_exile(card)
    end
    local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
    if target then
      OneBuff(opponent, target, {size={"+",3}}):apply()
    end
  end
end,

-- alluring whisper
[200097] = function(player, opponent)
  local ndebuff = 0
  for i=1,3 do
    if #player.deck > 0 then
      local card = player.deck[1]
      if pred.faction.D(card) and pred.follower(card) then
        ndebuff = ndebuff + 1
      end
      player:deck_to_grave(1)
    end
  end
  local targets = shuffle(opponent:field_idxs_with_preds(pred.follower))
  local buff = OnePlayerBuff(opponent)
  for i=1,min(ndebuff,#targets) do
    buff[targets[i]] = {atk={"-",1},def={"-",1},sta={"-",1}}
  end
  buff:apply()
end,

-- impulse
[200098] = function(player, opponent)
  if pred.faction.D(player.character) then
    OneBuff(player, 0, {life={"-",1}}):apply()
    local target_idxs = shuffle(opponent:field_idxs_with_preds({pred.follower}))
    if target_idxs[1] then
      OneBuff(opponent, target_idxs[1], {sta={"-",5}}):apply()
    end
    if #player.grave >= 8 then
      if target_idxs[2] then
        target_idxs[1] = target_idxs[2]
      end
      if opponent.field[target_idxs[1]] then
        OneBuff(opponent, target_idxs[1], {sta={"-",5}}):apply()
      end
      for i=1,2 do
        local spell = uniformly(player:grave_idxs_with_preds(pred.spell))
        if spell then
          player:grave_to_exile(spell)
        end
      end
    end
  end
end,

-- vernika's world
[200099] = function(player, opponent)
  local myspells = player:hand_idxs_with_preds(pred.spell)
  local opspells = opponent:hand_idxs_with_preds(pred.spell)
  local debuff_amt = #myspells + #opspells
  local buff = OnePlayerBuff(opponent)
  for i=1,5 do
    if opponent.field[i] and pred.follower(opponent.field[i]) then
      buff[i] = {atk={"-",debuff_amt},sta={"-",debuff_amt}}
    end
  end
  buff:apply()
  if pred.D(player.character) then
    if myspells[1] then
      player:hand_to_grave(myspells[1])
    end
    if opspells[1] then
      opponent:hand_to_grave(opspells[1])
    end
    local targets = opponent:field_idxs_with_preds(pred.spell)
    for i=1,#targets do
      opponent:field_to_grave(targets[i])
    end
  end
end,

-- uniform tweak
[200100] = function(player, opponent, my_idx, my_card)
  local target_idxs = shuffle(player:field_idxs_with_preds({pred.follower, pred.faction.V}))
  local buff = OnePlayerBuff(player)
  for i=1,2 do
    if target_idxs[i] then
      local def = player.field[target_idxs[i]].def
      buff[target_idxs[i]] = {atk={"+",def*2},sta={"-",math.floor(def/2)}}
    end
  end
  buff:apply()
end,

-- dress up change
[200101] = function(player, opponent)
  local map = {[300142]=300143,[300156]=300157}
  local target = player:field_idxs_with_preds(
      function(card) return map[floor(card.id)] ~= nil end)[1]
  if target then
    local dressup_id = map[player.field[target].id]
    player:field_to_grave(target)
    local deck_target = player:deck_idxs_with_preds(
        function(card) return floor(card.id) == dressup_id end)[1]
    if deck_target then
      local idx = player:first_empty_field_slot()
      player:deck_to_field(deck_target)
      OneBuff(player, idx, {size={"=",5},atk={"+",2},sta={"+",4}}):apply()
    end
  end
end,

-- wall climb
[200102] = function(player, opponent)
  local target = player:field_idxs_with_preds({pred.follower, pred.faction.V})[1]
  if target and not player.field[5] then
    player.field[5] = player.field[target]
    player.field[target] = nil
    local buff_amt = 0
    if player.field[2] then buff_amt = buff_amt + player.field[2].size end
    if player.field[4] then buff_amt = buff_amt + player.field[4].size end
    buff_amt = min(buff_amt, 8)
    OneBuff(player, 5, {atk={"+",buff_amt},sta={"+",buff_amt}}):apply()
  end
end,

-- unionize
[200103] = function(player, opponent, my_idx, my_card)
  local sz = 5 - #player.hand + my_card.size
  local target = opponent:field_idxs_with_preds(
      function(card) return card.size == sz end)[1]
  if target then
    opponent:field_to_bottom_deck(target)
  end
end,

-- tea time
[200104] = function(player)
  local targets = shuffle(player:field_idxs_with_preds({pred.faction.A,pred.follower}))
  if #targets >= 2 then
    local buff_amt = math.abs(player.field[targets[1]].size - player.field[targets[2]].size)
    local buff = OnePlayerBuff(player)
    for i=1,2 do
      buff[targets[i]] = {atk={"+",buff_amt},sta={"+",buff_amt}}
    end
    buff:apply()
  end
end,

-- adjustment
[200105] = function(player, opponent, my_idx)
  if player:has_follower() then
    if #player.hand > 0 then
      player:hand_to_grave(1)
    end
    local n = #player.hand
    for i=1,n do
      if opponent.hand[1] then
        opponent:hand_to_grave(1)
      end
    end
    local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
    if target then
      OneBuff(opponent, target, {atk={"-",n}}):apply()
    end
    player:field_to_exile(my_idx)
  end
end,

-- education results
[200106] = function(player)
  local hand_target = player:hand_idxs_with_preds(pred.faction.C)[1]
  if hand_target then
    player:hand_to_grave(hand_target)
    local target = uniformly(player:field_idxs_with_preds({pred.faction.C, pred.follower}))
    if target then
      OneBuff(player, target, {atk={"+",4},sta={"+",4}}):apply()
    end
  end
end,

-- brilliant brain
[200107] = function(player, opponent)
  if pred.faction.C(player.character) then
    local target = uniformly(opponent:field_idxs_with_preds(pred.spell))
    if target then
      local size = opponent.field[target].size
      opponent:field_to_bottom_deck(target)
      local hand_target = player:hand_idxs_with_preds(pred.follower)[1]
      if hand_target then
        local buff = GlobalBuff(player)
        buff.hand[player][hand_target] = {atk={"+",size},sta={"+",size}}
        buff:apply()
      end
    end
  end
end,

-- vivid world of kana
[200108] = function(player, opponent, my_idx, my_card)
  for i=1,2 do
    if #player.deck > 0 then
      if player.character.faction == player.deck[#player.deck].faction then
        local idx = player:first_empty_field_slot()
        if idx then
          player:deck_to_field(#player.deck)
          OneBuff(player, idx, {size={"=",my_card.size}}):apply()
        end
      else
        player:deck_to_grave(#player.deck)
      end
    end
  end
  player:field_to_exile(my_idx)
end,

-- the crescent enigmas
[200109] = function(player)
  local n = #player:hand_idxs_with_preds(pred.faction.D)
  if n >= 2 then
    for i=1,2 do
      local idx = uniformly(player:hand_idxs_with_preds(pred.faction.D))
      player:hand_to_grave(idx)
    end
    local target = uniformly(player:field_idxs_with_preds(pred.follower))
    if target then
      local buff_amt = math.abs(player.field[target].atk - player.field[target].sta)
      OneBuff(player, target, {atk={"+",buff_amt}}):apply()
    end
  end
end,

-- scardel rite
[200110] = function(player)
  local dl_in_grave = player:grave_idxs_with_preds(pred.follower, pred.faction.D)
  if dl_in_grave[1] then
    local card = Card(player.grave[dl_in_grave[1]].id)
    player:grave_to_exile(dl_in_grave[1])
    -- For the rest of the spell to happen, we need a vampire and an empty slot.
    local slot = player:first_empty_field_slot()
    local vampires = player:field_idxs_with_preds(pred.follower,
      pred.union(pred.scardel, pred.crescent, pred.flina))
    if slot and #vampires > 0 then
      player.field[slot] = card
      local buff_amt = 0
      local buff = OnePlayerBuff(player)
      for _,idx in ipairs(vampires) do
        buff[idx] = {size={"=",1}}
        buff_amt = buff_amt + player.field[idx].size - 1
      end
      buff[slot] = {size={"+",buff_amt},atk={"+",buff_amt},sta={"+",buff_amt}}
      buff:apply()
    end
  end
end,

-- final answer
[200111] = function(player, opponent)
  if not pred.D(player.character) then
    return
  end
  local target = opponent:field_idxs_with_most_and_preds(
      function(card) return card.atk + card.sta end, pred.follower)[1]
  local amt = #player.hand + #opponent.hand
  if target then
    OneBuff(opponent, target, {size={"-",amt},atk={"-",amt},sta={"-",amt}}):apply()
  end
end,

-- seize
[200112] = function(player, opponent, my_idx)
  local idx = nil
  for i=5,1,-1 do
    if i ~= my_idx and player.field[i] then
      idx = i
    end
  end
  if #opponent.hand < 5 and idx then
    local card = player.field[idx]
    player.field[idx] = nil
    opponent.hand[#opponent.hand+1] = card
    local op_idx = opponent:field_idxs_with_preds()[1]
    if #player.hand < 5 and op_idx then
      card = opponent.field[op_idx]
      opponent.field[op_idx] = nil
      player.hand[#player.hand+1] = card
    end
  end
end,

-- medusa glasses
[200113] = function(player, opponent)
  local buff = GlobalBuff(player)
  local buff_amt = 0
  for _,idx in ipairs(opponent:field_idxs_with_preds(pred.follower)) do
    buff.field[opponent][idx] = {atk={"-",1}}
    buff_amt = buff_amt + 1
  end
  local vita_guy = uniformly(player:field_idxs_with_preds({pred.faction.V, pred.follower}))
  if vita_guy then
    buff.field[player][vita_guy] = {sta={"+",buff_amt}}
  end
  buff:apply()
end,

-- comparison
[200114] = function(player, opponent)
  local my_idx = player:field_idxs_with_least_and_preds(pred.size,
      {pred.faction.V, pred.follower})[1]
  if my_idx then
    local my_card = player.field[my_idx]
    local other_idx = opponent:field_idxs_with_preds(pred.follower,
        function(card) return card.size == my_card.size end)[1]
    if other_idx then
      local other_card = opponent.field[other_idx]
      local buff = GlobalBuff(player)
      buff.field[player][my_idx] = {atk={"=",other_card.atk},
          def={"=",other_card.def},sta={"=",other_card.sta}}
      buff.field[opponent][other_idx] = {atk={"=",my_card.atk},
          def={"=",my_card.def},sta={"=",my_card.sta}}
      buff:apply()
    end
  end
end,

-- breakdown
[200115] = function(player, opponent)
  local my_idx = player:field_idxs_with_preds({pred.follower, pred.neg(pred.skill)})[1]
  local other_idx = opponent:field_idxs_with_preds({pred.follower, pred.skill})[1]
  if my_idx and other_idx then
    player.field[my_idx].skills = {opponent.field[other_idx]:squished_skills()[1]}
  end
end,

-- spring fever
[200116] = function(player)
  local idxs = shuffle(player:field_idxs_with_preds(pred.follower))
  local buff = OnePlayerBuff(player)
  for i=1,2 do
    if idxs[i] then
      local def = abs(player.field[idxs[i]].def)
      buff[idxs[i]] = {def={"=",0},sta={"+",2*def}}
    end
  end
  buff:apply()
end,

-- absolute control
[200117] = function(player, opponent)
  if player.character.faction == "V" and player:has_follower() then
    local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
    if target then
      opponent:field_to_grave(target)
      target = uniformly(opponent:field_idxs_with_preds(pred.spell))
      if target then
        opponent:field_to_bottom_deck(target)
      end
    end
  end
end,

-- one way trip
[200118] = function(player)
  local teh_buff = {size={"-",0},atk={"+",0},def={"+",0},sta={"+",0}}
  local buff = OnePlayerBuff(player)
  for i=1,5 do
    local card = player.field[i]
    if card and pred.follower(card) then
      buff[i] = teh_buff
      if pred.cook_club(card) then
        teh_buff.size[2] = teh_buff.size[2] + 1
        teh_buff.sta[2] = teh_buff.sta[2] + 2
      elseif pred.library_club(card) then
        teh_buff.atk[2] = teh_buff.atk[2] + 1
        teh_buff.sta[2] = teh_buff.sta[2] + 1
      elseif pred.student_council(card) then
        teh_buff.def[2] = teh_buff.def[2] + 1
        teh_buff.sta[2] = teh_buff.sta[2] + 1
      elseif pred.faction.V(card) then
        teh_buff.atk[2] = teh_buff.atk[2] + 1
        teh_buff.def[2] = teh_buff.def[2] + 1
      end
    end
  end
  buff:apply()
end,

-- shift change
[200119] = function(player)
  local idx = player:field_idxs_with_preds(pred.follower, pred.maid)[1]
  if idx then
    OneBuff(player, idx, {atk={"+",2},sta={"+",2}}):apply()
    player:field_to_top_deck(idx)
    local hand_idx = player:hand_idxs_with_preds(pred.faction.A, pred.follower)[1]
    if hand_idx then
      local field_idx = player:first_empty_field_slot()
      player:hand_to_field(hand_idx)
      OneBuff(player, field_idx, {atk={"+",2},sta={"+",2}}):apply()
    end
  end
end,

-- dress up rise
[200120] = function(player, opponent)
  if player:field_idxs_with_preds({pred.follower, pred.dress_up})[1] then
    local target = uniformly(opponent:field_idxs_with_preds())
    if target then
      opponent:field_to_bottom_deck(target)
    end
  end
end,

-- refreshments
[200121] = function(player, opponent)
  local nmoved = 0
  for i=1,5 do
    while player.hand[i] and pred.follower(player.hand[i]) and
        pred.faction.A(player.hand[i]) do
      player:hand_to_bottom_deck(i)
      nmoved = nmoved + 1
    end
  end
  for i=1,nmoved do
    -- TODO: how is this targeted?
    local idx = opponent:hand_idxs_with_preds(pred.spell)[1]
    if idx then
      local card = table.remove(opponent.hand, idx)
      card.size = card.size + 1
      opponent:to_bottom_deck(card)
    end
  end
end,

-- obedience
[200122] = function(player, opponent)
  if pred.faction.A(player.character) then
    local target = uniformly(opponent:field_idxs_with_preds({pred.follower,
        function(card) return card.size < 5 end}))
    if target then
      if opponent.field[target].size >= 3 then
        OneBuff(opponent, target, {size={"+",2},sta={"-",3}}):apply()
      else
        OneBuff(opponent, target, {size={"+",2}}):apply()
      end
    end
  end
end,

-- meteor call
[200123] = function(player, opponent)
  local my_idxs = player:field_idxs_with_preds(pred.follower)
  local op_idxs = opponent:field_idxs_with_preds(pred.follower)
  local buff = GlobalBuff(player)
  for _,idx in ipairs(my_idxs) do
    buff.field[player][idx] = {sta={"-",#op_idxs}}
  end
  for _,idx in ipairs(op_idxs) do
    buff.field[opponent][idx] = {sta={"-",#my_idxs + #op_idxs}}
  end
  buff:apply()
end,

-- servant's ward
[200124] = function(player, opponent)
  if pred.faction.A(player.character) then
    local idx = opponent:field_idxs_with_most_and_preds(pred.size,
        {pred.follower, function(card) return card.size > 1 end})[1]
    if idx then
      local sz = opponent.field[idx].size
      OneBuff(opponent, idx, {size={"=",1}}):apply()
      local buff = OnePlayerBuff(opponent)
      local idxs = shuffle(opponent:field_idxs_with_preds(pred.follower))
      for i=1,2 do
        if idxs[i] then
          buff[idxs[i]] = {atk={"-",sz},sta={"-",sz}}
        end
      end
      buff:apply()
    end
  end
end,

-- doubt
[200125] = function(player, opponent)
  local my_idx = player:field_idxs_with_preds({pred.faction.A, pred.follower})[1]
  if my_idx and pred.faction.A(player.character) then
    player:field_to_grave(my_idx)
    local idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
    if idx then
      OneBuff(opponent, idx, {atk={"=",1},sta={"=",1}}):apply()
    end
    idx = uniformly(opponent:field_idxs_with_preds({pred.follower, pred.skill,
        function(card) return card.sta > 1 end}))
    if pred.cinia(player.character) and idx then
      OneBuff(opponent, idx, {atk={"=",1},sta={"=",1}}):apply()
    end
  end
end,

-- extreme acceleration
[200126] = function(player, opponent, my_idx, my_card)
  local buff_amt = 0
  for i=1,5 do
    while player.hand[i] and pred.C(player.hand[i]) and pred.follower(player.hand[i]) do
      player:hand_to_grave(i)
      buff_amt = buff_amt + 2
    end
  end
  local targets = player:field_idxs_with_preds(pred.follower)
  local target = targets[#targets]
  if target then
    OneBuff(player, target, {atk={"+",buff_amt},sta={"+",buff_amt}}):apply()
  end
end,

-- cross cut
[200127] = function(player, opponent, my_idx, my_card)
  local hand_idxs = player:hand_idxs_with_preds(pred.C)
  if #hand_idxs >= 2 then
    player:hand_to_bottom_deck(hand_idxs[#hand_idxs-1])
    player:hand_to_bottom_deck(hand_idxs[#hand_idxs]-1)
    local targets = opponent:field_idxs_with_preds(pred.follower)
    for i=1,2 do
      if targets[i] then
        opponent.field[targets[i]].active = false
      end
    end
    if #player:field_idxs_with_preds(pred.union(pred.knight, pred.blue_cross)) > 0 then
      local buff = OnePlayerBuff(opponent)
      for i=1,2 do
        if targets[i] then
          buff[targets[i]] = {sta={"-",2}}
        end
      end
      buff:apply()
    end
  end
end,

-- planned misfortune
[200128] = function(player, opponent, my_idx, my_card)
  local opp_idx = opponent:field_idxs_with_least_and_preds(pred.size, pred.follower)[1]
  if opp_idx then
    local min_size = opponent.field[opp_idx].size
    local buff = OnePlayerBuff(player)
    local targets = player:field_idxs_with_preds(pred.follower,
        function(card) return card.size >= min_size end)
    for _,idx in ipairs(targets) do
      buff[idx] = {atk={"+",1},def={"+",1},sta={"+",1}}
    end
    buff:apply()
  end
end,

-- azure cross meeting
[200129] = function(player, opponent, my_idx, my_card)
  local targets = shuffle(opponent:field_idxs_with_preds(pred.neg(pred.C), pred.follower))
  local buff = OnePlayerBuff(opponent)
  for i=1,2 do
    if targets[i] then
      buff[targets[i]] = {atk={"-",2},sta={"-",2}}
    end
  end
  buff:apply()
  for i=1,min(4-#player.hand, #player.deck) do
    player:draw_a_card()
  end
end,

-- escape
-- TODO: this puts the cards in the wrong order
[200130] = function(player, opponent, my_idx, my_card)
  if #player:field_idxs_with_preds(pred.follower) > 0 then
    local ncards = #player.hand
    for i=#player.hand,1,-1 do
      player:hand_to_top_deck(i)
    end
    --[[
    while player.hand[1] do
      player:hand_to_top_deck(1)
    end
    ]]
    OneBuff(player, 0, {life={"+",ceil(ncards*1.5)}}):apply()
  end
end,

-- false delivery
[200131] = function(player, opponent, my_idx, my_card)
  for _,p in ipairs({player, opponent}) do
    for i=1,5 do
      while p.hand[i] and p.hand[i].faction ~= p.character.faction do
        p:hand_to_grave(i)
      end
    end
  end
end,

-- comeback
[200132] = function(player, opponent, my_idx, my_card)
  if pred.C(player.character) then
    while #player.hand > 0 and player:first_empty_field_slot() do
      local slot = player:first_empty_field_slot()
      player:hand_to_field(1)
      player.field[slot].size = random(2,3)
      if pred.spell(player.field[slot]) then
        player.field[slot].active = false
      end
    end
  end
end,

-- dark meeting
[200133] = function(player, opponent, my_idx, my_card)
  local ncards = #player.hand
  while player.hand[1] do
    player:hand_to_grave(1)
  end
  local target = opponent:field_idxs_with_most_and_preds(pred.add(pred.atk,pred.sta), pred.follower)[1]
  if target then
    OneBuff(opponent, target, {atk={"-",ceil(1.5*ncards)},sta={"-",ceil(1.5*ncards)}}):apply()
  end
end,

-- dark convocation
[200134] = function(player, opponent, my_idx, my_card)
  local buff = {atk={"+",3},sta={"+",1}}
  local target = uniformly(player:field_idxs_with_preds(pred.D,pred.follower))
  if target then
    if pred.gs(player.field[target]) then
      buff.sta[2] = 3
    end
    OneBuff(player, target, buff):apply()
    player.field[target].active = false
  end
end,

-- pupil becomes master
[200135] = function(player, opponent, my_idx, my_card)
  local denom = #opponent:field_idxs_with_preds()
  local targets = opponent:field_idxs_with_preds(pred.follower)
  local buff = OnePlayerBuff(opponent)
  for _,idx in ipairs(targets) do
    buff[idx] = {sta={"-",floor(player.game.turn/denom)}}
  end
  buff:apply()
end,

-- agent visit
[200136] = function(player, opponent, my_idx, my_card)
  local size3 = function(card) return card.size == 3 end
  if #player:field_idxs_with_preds(pred.follower) > 0 and
      #player:hand_idxs_with_preds(size3) > 0 then
    local target = opponent:field_idxs_with_preds(size3)[1]
    if target then
      opponent:field_to_grave(target)
    end
  end
end,

-- dress up ride
[200137] = function(player, opponent, my_idx, my_card)
  if #player:field_idxs_with_preds(pred.dress_up, pred.follower) > 0 then
    local target = player:deck_idxs_with_preds(pred.dress_up, pred.follower)[1]
    local slot = player:first_empty_field_slot()
    if slot and target then
      player:deck_to_field(target)
      OneBuff(player, slot, {size={"=",5},atk={"+",3},sta={"+",3}}):apply()
    end
  end
end,

-- tranquility
[200138] = function(player, opponent, my_idx, my_card)
  local opp_spell = opponent:field_idxs_with_preds(pred.spell)
  local my_spell = player:field_idxs_with_preds(pred.spell)
  if #player:field_idxs_with_preds(pred.follower) > 0 and
      #opp_spell > 0 then
    local nlife = #opp_spell
    for _,idx in ipairs(opp_spell) do
      opponent:field_to_bottom_deck(idx)
    end
    OneBuff(player, 0, {life={"-",nlife}}):apply()
  elseif #opp_spell == 0 then
    local nlife = #my_spell
    for _,idx in ipairs(my_spell) do
      if idx ~= my_idx then
        player:field_to_bottom_deck(idx)
      end
    end
    OneBuff(player, 0, {life={"-",nlife}}):apply()
  end
end,

-- night conqueror
[200139] = function(player, opponent, my_idx, my_card)
  if pred.D(player.character) then
    local targets = opponent:field_idxs_with_preds(
        function(card) return card.size >= 3 and card.size <= 5 end)
    for _,idx in ipairs(targets) do
      opponent:field_to_grave(idx)
    end
    targets = player:field_idxs_with_preds(pred.neg(pred.D), pred.follower)
    for _,idx in ipairs(targets) do
      player:field_to_grave(idx)
    end
  end
end,

-- summer machine gun
[200140] = function(player, opponent, my_idx, my_card)
  local go = true
  for _,name in ipairs({"lucca","milka","serie"}) do
    go = go and (#player:field_idxs_with_preds(pred[name]) > 0 or
        #player:hand_idxs_with_preds(pred[name]) > 0)
  end
  if go then
    local any_pred = pred.union(pred.lucca, pred.milka, pred.serie)
    local buff = GlobalBuff(player)
    local idxs = player:field_idxs_with_preds(pred.follower, any_pred)
    for _,idx in ipairs(idxs) do
      buff.field[player][idx] = {atk={"+",3},sta={"+",3}}
    end
    idxs = player:hand_idxs_with_preds(pred.follower)
    for _,idx in ipairs(idxs) do
      buff.hand[player][idx] = {atk={"+",3},sta={"+",3}}
    end
    buff:apply()
  end
end,

-- detection
[200141] = function(player, opponent, my_idx, my_card)
  local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if target then
    OneBuff(opponent, target, {def={"-",1},sta={"-",opponent.field[target].size}}):apply()
  end
end,

-- golden pair
[200142] = function(player, opponent, my_idx, my_card)
  local idxs = player:field_idxs_with_preds(pred.follower)
  for _,idx in ipairs(idxs) do
    local samename = player:field_idxs_with_preds(pred.follower,
        function(card) return card.name == player.field[idx].name end)
    if #samename > 1 then
      local buff = OnePlayerBuff(player)
      for _,target in ipairs(samename) do
        buff[target] = {atk={"+",3},sta={"+",3}}
      end
      buff:apply()
      return
    end
  end
end,

-- fault
[200143] = function(player, opponent, my_idx, my_card)
  if #player:field_idxs_with_preds(pred.follower, pred.tennis_club) > 1 then
    OneBuff(opponent, 0, {life={"-",3}}):apply()
  end
end,

-- infighting
[200144] = function(player, opponent, my_idx, my_card)
  local my_first_idx = player:field_idxs_with_preds(pred.follower)[1]
  if my_first_idx then
    local my_faction = player.field[my_first_idx].faction
    local my_followers = player:field_idxs_with_preds(pred.follower, pred[my_faction])
    for _,idx in ipairs(my_followers) do
      player:field_to_grave(idx)
    end
    local op_first_idx = opponent:field_idxs_with_preds(pred.follower)[1]
    if op_first_idx then
      local op_faction = opponent.field[op_first_idx].faction
      local op_followers = opponent:field_idxs_with_preds(pred.follower, pred[op_faction])
      for i=2,#op_followers do
        opponent:field_to_grave(op_followers[i])
      end
    end
  end
end,

-- minds in conflict
[200145] = function(player, opponent, my_idx, my_card)
  local my_idx = player:field_idxs_with_preds(pred.follower, pred.skill)[1]
  local op_idx = opponent:field_idxs_with_preds(pred.follower, pred.skill)[1]
  if my_idx and op_idx then
    local my_card, op_card = player.field[my_idx], opponent.field[op_idx]
    local buff = GlobalBuff(player)
    buff.field[player][my_idx],buff.field[opponent][op_idx] = {},{}
    my_card.skills, op_card.skills = op_card.skills, my_card.skills
    for _,stat in ipairs({"atk","def","sta","size"}) do
      buff.field[player][my_idx][stat] = {"=",op_card[stat]}
      buff.field[opponent][op_idx][stat] = {"=",my_card[stat]}
    end
    buff:apply()
  end
end,

-- secret art: wind slash
[200146] = function(player, opponent, my_idx, my_card)
  local cards = shuffle(opponent:field_idxs_with_preds())
  local followers = opponent:field_idxs_with_preds(pred.follower)
  local teh_buff = {}
  if pred.sita(player.character) then
    teh_buff.def = {"-", #cards}
    for _,idx in ipairs(cards) do
      opponent.field[idx].active = false
    end
  else
    teh_buff.sta = {"-", min(2, #cards)}
    for i=1,min(2, #cards) do
      opponent.field[cards[i]].active = false
    end
  end
  local buff = OnePlayerBuff(opponent)
  for _,idx in ipairs(followers) do
    buff[idx]=teh_buff
  end
  buff:apply()
end,

-- home study
[200147] = function(player, opponent, my_idx, my_card)
  local same_pred = function(card)
      return card.id == player.field[my_idx].id
    end
  local buff_amt = 1 + #player:grave_idxs_with_preds(same_pred) +
      #player:hand_idxs_with_preds(same_pred)
  local buff = GlobalBuff(player)
  local idxs = player:hand_idxs_with_preds(pred.follower)
  for _,idx in ipairs(idxs) do
    buff.hand[player][idx] = {atk={"+",buff_amt},sta={"+",buff_amt}}
  end
  buff:apply()
end,

-- maid experience
[200148] = function(player, opponent, my_idx, my_card)
  local ncards = 0
  local func = function(card) return card.id == 200147 end
  local idx = player:hand_idxs_with_preds(func)[1]
  while idx do
    ncards = ncards + 1
    player:hand_to_exile(idx)
    idx = player:hand_idxs_with_preds(func)[1]
  end
  idx = player:grave_idxs_with_preds(func)[1]
  while idx do
    ncards = ncards + 1
    player:grave_to_exile(idx)
    idx = player:grave_idxs_with_preds(func)[1]
  end
  local targets = shuffle(opponent:field_idxs_with_preds(pred.follower))
  local buff = OnePlayerBuff(opponent)
  for i=1,2 do
    if targets[i] then
      buff[targets[i]] = {atk={"-",2*ncards},sta={"-",2*ncards}}
    end
  end
  buff:apply()
end,

-- defeat
[200149] = function(player, opponent, my_idx, my_card)
  local amt = #opponent:field_idxs_with_preds(pred.follower, pred.skill)
  local target = uniformly(player:field_idxs_with_preds(pred.A, pred.follower))
  if target then
    OneBuff(player, target, {def={"+",min(amt,3)}}):apply()
  end
end,

-- meeting master
[200150] = function(player, opponent, my_idx, my_card)
  local maid = player:field_idxs_with_preds(pred.follower, pred.maid)[1]
  local lady = player:field_idxs_with_preds(pred.follower, pred.lady)[1]
  if maid then
    player.field[maid].active = false
    if lady then
      local amt = player.field[maid].size
      OneBuff(player, lady, {atk={"+",amt},sta={"+",amt}}):apply()
    end
  end
end,

-- comfort
[200151] = function(player, opponent, my_idx, my_card)
  local idx = player:field_idxs_with_preds(pred.follower)[1]
  if idx then
    player.field[idx].active = false
    OneBuff(player, 0, {life={"+",3}}):apply()
  end
end,

-- curse of mistrust
[200152] = function(player, opponent, my_idx, my_card)
  local my_idx = player:field_idxs_with_preds(pred.follower)[1]
  if my_idx then
    local my_card = player.field[my_idx]
    player.field[my_idx] = nil
    opponent:to_bottom_deck(my_card)
    local faction = my_card.faction
    local op_idx = opponent:field_idxs_with_most_and_preds(pred.size,
        pred.follower, pred.neg(pred[faction]))[1]
    if op_idx then
      local op_card = opponent.field[op_idx]
      opponent.field[op_idx] = nil
      player:to_bottom_deck(op_card)
    end
  end
end,

-- el mundo (ZA WARUDO)
[200153] = function(player, opponent, my_idx, my_card)
  if pred.A(player.character) then
    local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
    if target then
      opponent.field[target].active = false
      OneBuff(opponent, target, {sta={"-",8-my_card.size}}):apply()
    end
    if my_card.size < 3 and #player.hand < 5 then
      my_card.size = my_card.size + 1
      player.hand[#player.hand+1] = my_card
      player.field[my_idx] = nil
    elseif my_card.size >= 3 then
      player.field[my_idx] = nil
    end
  end
end,

-- unity march
[200154] = function(player, opponent, my_idx, my_card)
  local target = player:field_idxs_with_preds(pred.follower)[1]
  if #player:field_idxs_with_preds(pred.follower, pred.C) >= 2 then
    OneBuff(player, target, {sta={"+",6}}):apply()
  end
end,

-- a single flower
[200155] = function(player, opponent, my_idx, my_card)
  local amt = abs(#player.hand - #opponent.hand)
  for _,p in ipairs({player, opponent}) do
    while #p.hand > 0 do
      p:hand_to_bottom_deck(1)
    end
  end
  OneBuff(player, 0, {life={"+",amt}}):apply()
end,

-- protective chant
[200156] = function(player, opponent, my_idx, my_card)
  local nfollowers = #player:field_idxs_with_preds(pred.follower)
  local targets = player:field_idxs_with_preds(pred.follower,
      function(card) return card.size == nfollowers end)
  local buff = OnePlayerBuff(player)
  for _,idx in ipairs(targets) do
    buff[idx] = {atk={"+",3},sta={"+",3}}
  end
  buff:apply()
end,

-- blossoming skill
[200157] = function(player, opponent, my_idx, my_card)
  local amt = bound(0, opponent.character.life - player.character.life, 9)
  local target = uniformly(player:field_idxs_with_preds(pred.follower))
  if target then
    OneBuff(player, target, {atk={"+",amt}}):apply()
  end
end,

-- degradation
[200158] = function(player, opponent, my_idx, my_card)
  local targets = shuffle(player:field_idxs_with_preds(pred.follower, pred.neg(pred.skill)))
  local buff = OnePlayerBuff(player)
  for i=1,2 do
    if targets[i] then
      buff[targets[i]] = {atk={"+",3},sta={"+",3}}
    end
  end
  buff:apply()
end,

-- pilgrimage of proof
[200159] = function(player, opponent, my_idx, my_card)
  if #player:field_idxs_with_preds(pred.follower) > 0 then
    local targets = shuffle(opponent:field_idxs_with_preds(pred.follower))
    local buff = OnePlayerBuff(opponent)
    for i=1,2 do
      if targets[i] then
        buff[targets[i]] = {def={"-",4-my_card.size}}
      end
    end
    buff:apply()
  end
  if my_card.size > 1 then
    my_card.size = my_card.size - 1
    player.send_spell_to_grave = false
    my_card.active = false
  end
end,

-- lightning blade
[200160] = function(player, opponent, my_idx, my_card)
  if pred.C(player.character) and #player:field_idxs_with_preds(pred.follower) > 0 then
    local nlife = 0
    local impact = Impact(opponent)
    for i = 1, 5 do
      local card = opponent.field[i]
      if card and (card.size + player.game.turn + i) % 2 == 1 then
        impact[opponent][i] = true
        nlife = nlife + 1
      end
    end
    impact:apply()
    for i = 1, 5 do
      local card = opponent.field[i]
      if card and (card.size + player.game.turn + i) % 2 == 1 then
        opponent:field_to_grave(i)
      end
    end
    OneBuff(player, 0, {life={"-", nlife}}):apply()
  end
end,

-- doctor play
[200161] = function(player, opponent, my_idx, my_card)
  if #player:field_idxs_with_preds(pred.follower) > 0 then
    local target = opponent:field_idxs_with_preds(pred.follower)[1]
    if target then
      local amt = abs(#player.deck - #opponent.deck) % 10
      OneBuff(opponent, target, {sta={"-",amt}}):apply()
    end
  end
end,

-- tick time
[200162] = function(player, opponent, my_idx, my_card)
  local amt = floor((player.game.turn % 10) / 2)
  local targets = shuffle(player:field_idxs_with_preds(pred.follower))
  local buff = OnePlayerBuff(player)
  for i=1,2 do
    if targets[i] then
      buff[targets[i]] = {atk={"+",amt},sta={"+",amt}}
    end
  end
  buff:apply()
end,

-- maximum drive
[200163] = function(player, opponent, my_idx, my_card)
  local my_idx = player:field_idxs_with_preds(pred.follower)[1]
  if my_idx then
    local size = player.field[my_idx].size
    player:field_to_grave(my_idx)
    if opponent.field[size] then
      opponent:field_to_grave(size)
    end
  end
end,

-- intrusion
[200164] = function(player, opponent, my_idx, my_card)
  local targets = shuffle(player:field_idxs_with_preds(pred.follower))
  if #targets > 0 then
    local buff = OnePlayerBuff(player)
    for i=1,2 do
      if targets[i] then
        buff[targets[i]] = {sta={"+",3}}
      end
    end
    buff:apply()
    for i=1,min(5-#opponent.hand, #opponent.deck) do
      opponent:draw_a_card()
    end
  end
end,

-- absolute power
[200165] = function(player, opponent, my_idx, my_card)
  if opponent.hand[1] then
    local teh_buff = {atk={"+",3},def={"-",1}}
    if pred.spell(opponent.hand[1]) then
      teh_buff = {def={"-",1},sta={"+",5}}
    end
    local buff = OnePlayerBuff(player)
    for _,idx in ipairs(player:field_idxs_with_preds(pred.follower)) do
      buff[idx] = teh_buff
    end
    buff:apply()
  end
end,

-- misfit
[200166] = function(player, opponent, my_idx, my_card)
  local amt = player:field_size()
  if pred.D(player.character) then
    amt = floor(amt/2)
  end
  local target = opponent:field_idxs_with_preds(pred.follower,
      function(card)
        local sz = Card(card.id).size
        if sz >= 6 then
          return card.atk + card.sta >= 32
        end
        return card.atk + card.sta >= 22
      end)[1]
  if target then
    local buff = OnePlayerBuff(opponent)
    buff[target] = {atk={"=",amt},sta={"=",amt}}
    buff:apply()
  end
end,

-- lago de cisnes
[200167] = function(player, opponent, my_idx, my_card)
  local targets = opponent:field_idxs_with_most_and_preds(
      pred.add(pred.atk, pred.sta), pred.follower)
  local buff = OnePlayerBuff(opponent)
  for _,idx in ipairs(targets) do
    local card = opponent.field[idx]
    buff[idx] = {atk={"=",ceil(card.atk/2)},sta={"=",ceil(card.sta/2)}}
  end
  buff:apply()
  if pred.iri(player.character) then
    local buff = OnePlayerBuff(opponent)
    for _,idx in ipairs(targets) do
      buff[idx] = {atk={"-",2},def={"-",2},sta={"-",2}}
    end
    buff:apply()
  end
end,

-- dream conversation
[200168] = function(player, opponent, my_idx, my_card)
  local target = player:field_idxs_with_most_and_preds(pred.size, pred.follower)[1]
  if target then
    local size = player.field[target].size
    OneBuff(player, target, {size={"=",1},atk={"+",size-1},sta={"+",size-1}}):apply()
  end
end,

-- event preparation
[200172] = function(player, opponent, my_idx, my_card)
  local my_faction = #player:field_idxs_with_preds(pred.follower, pred[player.character.faction])
  if my_faction > 0 and #player:field_idxs_with_preds(pred.follower) > my_faction then
    local targets = shuffle(player:field_idxs_with_preds(pred.follower))
    local buff = OnePlayerBuff(player)
    for i=1,2 do
      buff[targets[i]] = {atk={"+",3},sta={"+",3}}
    end
    buff:apply()
  end
end,

-- victory proclamation
[200173] = function(player, opponent, my_idx, my_card)
  if #player.hand > 0 and #opponent.hand > 0 then
    player.hand[1], opponent.hand[1] = opponent.hand[1], player.hand[1]
  end
end,

-- topsy turvy
[200174] = function(player, opponent, my_idx, my_card)
  local target = uniformly(player:field_idxs_with_preds(pred.follower))
  if target then
    local factions = {}
    local amt = 1
    for i=1,#player.hand do
      if not factions[player.hand[i].faction] then
        factions[player.hand[i].faction] = true
        amt = amt + 1
      end
    end
    OneBuff(player, target, {atk={"+",amt},sta={"+",amt}}):apply()
  end
end,

-- inhuman creature
[200175] = function(player, opponent, my_idx, my_card)
  local my_guy = uniformly(player:field_idxs_with_preds(pred.follower))
  local op_guy = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if my_guy and op_guy then
    player:field_to_grave(my_guy)
    opponent:field_to_grave(op_guy)
  end
end,

-- preserver of rules
[200176] = function(player, opponent, my_idx, my_card)
  local target = uniformly(player:field_idxs_with_preds(pred.follower, pred.V))
  if target then
    OneBuff(player, target, {atk={"+",#player.hand+1},sta={"+",#player.hand-1}}):apply()
  end
end,

-- morals crackdown
[200177] = function(player, opponent, my_idx, my_card)
  if #player:field_idxs_with_preds(pred.follower) > 0 then
    local teh_buff = {def={"=",0}, sta={"-",0}}
    local buff = GlobalBuff(player)
    for _,p in ipairs({player, opponent}) do
      local idxs = p:field_idxs_with_preds(pred.follower)
      for _,idx in ipairs(idxs) do
        buff.field[p][idx] = teh_buff
        teh_buff.sta[2] = teh_buff.sta[2] + abs(p.field[idx].def)
      end
    end
    buff:apply()
  end
end,

-- encounter
[200178] = function(player, opponent, my_idx, my_card)
  local amt = 2
  local idxs = opponent:field_idxs_with_preds(pred.spell)
  for _,idx in ipairs(idxs) do
    amt = amt + 1
    if pred.V(player.character) then
      opponent:field_to_exile(idx)
    end
  end
  local targets = player:field_idxs_with_preds(pred.follower)
  local buff = OnePlayerBuff(player)
  for i=1,2 do
    if targets[i] then
      buff[targets[i]] = {atk={"+",amt},sta={"+",amt}}
    end
  end
  buff:apply()
end,

-- pursuit of perfection
[200179] = function(player, opponent, my_idx, my_card)
  local target = player:hand_idxs_with_preds(pred.follower, pred.A)[1]
  if target then
    local idxs = player:field_idxs_with_preds(pred.follower, pred.A,
        function(card) return card.size <= 2 end)
    local buff = GlobalBuff(player)
    local atk,sta = 0,0
    for _,idx in ipairs(idxs) do
      buff.field[player][idx] = {atk={"=",1},sta={"=",1}}
      atk = atk + (player.field[idx].atk - 1)
      sta = sta + (player.field[idx].sta - 1)
    end
    buff.hand[player][target] = {atk={"+",ceil(atk/2)},sta={"+",ceil(sta/2)}}
    buff:apply()
  end
end,

-- black magic preparation
[200180] = function(player, opponent, my_idx, my_card)
  local idxs = player:hand_idxs_with_preds(pred.spell)
  local buff = GlobalBuff(player)
  for _,idx in ipairs(idxs) do
    buff.hand[player][idx] = {size={"-",1}}
  end
  buff:apply()
end,

-- lady's wrath
[200181] = function(player, opponent, my_idx, my_card)
  local hand_target = player:hand_idxs_with_preds(pred.faction.A)
  hand_target = hand_target[#hand_target]
  if hand_target then
    player:hand_to_grave(hand_target)
    local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
    if target then
      OneBuff(opponent, target, {atk={"-",4},sta={"-",4}}):apply()
    end
  end
end,

-- shoot
[200182] = function(player, opponent, my_idx, my_card)
  if #player.hand > 0 then
    player.hand[#player.hand] = nil
    if #opponent.hand > 0 then
      player.hand[#player.hand + 1] = deepcpy(opponent.hand[1])
    end
  end
end,

-- servant of clarice
[200183] = function(player, opponent, my_idx, my_card)
  if #player.deck > 1 then
    player:deck_to_grave(#player.deck)
    if #player.deck > 1 then
      local card = player.deck[#player.deck]
      player.deck[#player.deck] = nil
      player:to_bottom_deck(card)
      local target = uniformly(opponent:field_idxs_with_preds())
      if target then
        opponent:field_to_bottom_deck(target)
      end
    end
  end
end,

-- lady's attendant
[200184] = function(player, opponent, my_idx, my_card)
  local atk = #player.hand
  local sta = #opponent.hand + 1
  local targets = shuffle(player:field_idxs_with_preds(pred.follower, pred.A))
  local buff = OnePlayerBuff(player)
  for i=1,2 do
    if targets[i] then
      buff[targets[i]] = {atk={"+",atk},sta={"+",sta}}
    end
  end
  buff:apply()
end,

-- push forward
[200185] = function(player, opponent, my_idx, my_card)
  local targets = shuffle(opponent:field_idxs_with_preds(pred.follower))
  local buff = OnePlayerBuff(opponent)
  for i=1,2 do
    if targets[i] then
      buff[targets[i]] = {atk={"-",4},sta={"-",4}}
    end
  end
  buff:apply()
  player.send_spell_to_grave = false
  if my_card.size == 1 then
    player.field[my_idx] = nil
  else
    my_card.size = 1
    my_card.active = false
  end
end,

-- supply request
[200186] = function(player, opponent, my_idx, my_card)
  local target = player:field_idxs_with_most_and_preds(pred.size, pred.follower)[1]
  if target and #player.hand > 0 then
    OneBuff(player, target, {size={"-",
        abs(player.field[target].size - player.hand[1].size)}}):apply()
  end
end,

-- miscalculation
[200187] = function(player, opponent, my_idx, my_card)
  local idxs = player:deck_idxs_with_preds(pred.follower)
  for i=1,min(#idxs, 4-#player.hand) do
    player:deck_to_hand(idxs[i])
  end
end,

-- passcode
[200188] = function(player, opponent, my_idx, my_card)
  local size_to_count = {}
  for i=1,5 do
    local card = player.field[i]
    if card then
      size_to_count[card.size] = (size_to_count[card.size] or 0) + 1
    end
  end
  for sz, count in pairs(size_to_count) do
    if count >= 3 then
      local targets = player:field_idxs_with_preds(pred.follower,
          function(card) return card.size == sz end)
      local buff = OnePlayerBuff(player)
      for _,idx in ipairs(targets) do
        buff[idx] = {atk={"+",3},sta={"+",3}}
      end
      buff:apply()
    end
  end
end,

-- vacation
[200189] = function(player, opponent, my_idx, my_card)
  local target = player:field_idxs_with_most_and_preds(pred.sta, pred.C, pred.follower)[1]
  if target then
    local reduced_sta = floor(player.field[target].sta/2)
    OneBuff(player, target, {def={"+",ceil(reduced_sta/2)},sta={"-",reduced_sta}}):apply()
  end
end,

-- warrior's resolve
[200190] = function(player, opponent, my_idx, my_card)
  local hi,lo = #player.hand, 5-#player.hand
  if lo > hi then
    hi,lo = lo,hi
  end
  local targets = shuffle(player:field_idxs_with_preds(pred.follower, pred.C))
  local buff = OnePlayerBuff(player)
  for i=1,2 do
    if targets[i] then
      buff[targets[i]] = {atk={"+",hi},sta={"+",max(lo-1,0)}}
    end
  end
  buff:apply()
end,

-- beach research
[200191] = function(player, opponent, my_idx, my_card)
  local targets = shuffle(player:field_idxs_with_preds(pred.follower))
  local buff = OnePlayerBuff(player)
  for i=1,2 do
    if targets[i] then
      buff[targets[i]] = {size={"-",1},atk={"+",1},def={"+",1},sta={"+",1}}
    end
  end
  buff:apply()
end,

-- shock
[200192] = function(player, opponent, my_idx, my_card)
  local my_buff = {sta={"+",5}}
  if pred.C(player.character) then
    my_buff.atk = {"+",2}
  end
  local buff = GlobalBuff(player)
  local my_idxs = player:field_idxs_with_preds(pred.follower)
  for _,idx in ipairs(my_idxs) do
    buff.field[player][idx] = my_buff
  end
  local op_idxs = opponent:field_idxs_with_preds(pred.follower)
  for _,idx in ipairs(op_idxs) do
    buff.field[opponent][idx] = {atk={"-",2}}
  end
  buff:apply()
end,

-- crux underground
[200193] = function(player, opponent, my_idx, my_card)
  local first = opponent:field_idxs_with_preds(pred.follower)[1]
  if first then
    local sz = opponent.field[first].size
    local targets = opponent:field_idxs_with_preds(pred.follower,
        function(card) return card.size == sz end)
    local buff = OnePlayerBuff(opponent)
    for _,idx in ipairs(targets) do
      buff[idx] = {atk={"-",#targets},sta={"-",#targets}}
    end
    buff:apply()
  end
end,

-- recruitment ad
[200194] = function(player, opponent, my_idx, my_card)
  local target = uniformly(player:field_idxs_with_preds(pred.follower))
  if target then
    player:field_to_grave(target)
    OneBuff(opponent, 0, {life={"-",1}}):apply()
    opponent.shuffles = max(0, opponent.shuffles-1)
    OneBuff(player, 0, {life={"+",1}}):apply()
  end
end,

-- marionette
[200195] = function(player, opponent, my_idx, my_card)
  local target = player:field_idxs_with_preds(pred.follower)[1]
  if target then
    local amt = ceil((player.field[target].atk + player.field[target].sta)/2)
    OneBuff(player, target, {atk={"=",amt},sta={"=",amt}}):apply()
  end
end,

-- mischief
[200196] = function(player, opponent, my_idx, my_card)
  local amt = 3 * #player:grave_idxs_with_preds(
      function(card) return card.id == 200196 end)
  local buff = OnePlayerBuff(opponent)
  local targets = opponent:field_idxs_with_preds(pred.follower)
  for _,idx in ipairs(targets) do
    buff[idx] = {sta={"-",amt}}
  end
  buff:apply()
end,

-- night is coming
[200197] = function(player, opponent, my_idx, my_card)
  for i=1,2 do
    local gs = player:grave_idxs_with_preds(pred.follower, pred.gs)[1]
    if gs then
      player:grave_to_exile(gs)
    end
  end
  for i=1,3 do
    local gs = uniformly(player:grave_idxs_with_preds(pred.follower, pred.gs))
    if gs then
      player:grave_to_bottom_deck(gs)
    end
  end
end,

-- query
[200198] = function(player, opponent, my_idx, my_card)
  if my_card.size > 3 then
    my_card.size = 3
  end
  OneBuff(opponent, 0, {life={"-",my_card.size}}):apply()
  if my_card.size == 1 then
    player.send_spell_to_grave = false
    player.field[my_idx] = nil
  else
    local idx = opponent:first_empty_field_slot()
    if idx then
      player.send_spell_to_grave = false
      player.field[my_idx] = nil
      opponent.field[idx] = my_card
      my_card.active = false
      my_card.size = my_card.size - 1
    end
  end
end,

-- showdown
[200199] = function(player, opponent, my_idx, my_card)
  if pred.D(player.character) and
      #player:field_idxs_with_preds(pred.follower, pred.D) > 0 then
    local buff = GlobalBuff(player)
    for _,idx in ipairs(player:field_idxs_with_preds(pred.follower)) do
      buff.field[player][idx] = {size={"=",1},atk={"=",6},sta={"=",6}}
    end
    for _,idx in ipairs(opponent:field_idxs_with_preds(pred.follower)) do
      buff.field[opponent][idx] = {size={"=",1},atk={"=",6},def={"=",0},sta={"=",6}}
    end
    buff:apply()
  end
end,



-- hot item
[200201] = function(player, opponent, my_idx, my_card)
  local buff = OnePlayerBuff(player)
  for i=1,5 do
    local card = player.field[i]
    if card and pred.follower(card) then
      buff[i] = {atk={"+",2},sta={"+",3}}
    end
  end
  buff:apply()
end,

-- principal's story
[200202] = function(player, opponent, my_idx, my_card)
  if #player.hand < 5 then
    local card
    for i=1,#opponent.hand do
      card = opponent.hand[i]
      if opponent.character.faction ~= card.faction then
        player.hand[#player.hand+1] = card
        opponent.hand[i] = nil
        opponent:squish_hand()
        break
      end
    end
  end
end,

-- low turnout
[200203] = function(player, opponent, my_idx, my_card)
  local idx = nil
  for i=1,5 do
    local card = player.field[i]
    if card and card.faction == "V" and pred.follower(card) then
      if not idx then
        idx = i
      elseif idx and card.def > player.field[idx].def then
        idx = i
      end
    end
  end
  if idx then
    OneBuff(player, idx, {sta={"+",player.field[idx].def*2}}):apply()
  end
  for i=1,#player.hand do
    local card = player.field[i]
    if card and card.faction == "V" then
      player:hand_to_bottom_deck(i)
      break
    end
  end
end,

-- broken land
[200204] = function(player, opponent, my_idx, my_card)
  local target_idxs = shuffle(player:field_idxs_with_preds({pred.follower, pred.V}))
  for i=1,2 do
    if target_idxs[i] then
      player.field[target_idxs[i]]:gain_skill(1149)
    end
  end
end,

-- keepsake
[200205] = function(player, opponent, my_idx, my_card)
  local first_card, idx = nil, nil
  for i=1,5 do
    local card = player.field[i]
    if card and pred.follower(card) and not first_card then
      first_card = player.field[i]
      idx = i
    elseif card and pred.follower(card) and first_card then
      OneBuff(player, i, {atk={"+",first_card.size},def={"+",first_card.size},sta={"+",first_card.size}}):apply()
      if player.character.faction == "V" then
        player:field_to_bottom_deck(idx)
      else
        player:field_to_grave(idx)
      end
      break
    end
  end
end,

-- everyday discovery
[200206] = function(player, opponent, my_idx, my_card)
  for i=1,5 do
    local fcard = player.field[i]
    if fcard and pred.follower(fcard) then
      for i=player.game.turn%2,5,2 do
        local card = player.field[i]
        local o_card = opponent.field[i]
        if card and pred.follower(card) then
          player:field_to_bottom_deck(i)
        end
        if o_card and pred.follower(o_card) then
          opponent:field_to_bottom_deck(i)
        end
      end
      break
    end
  end
end,

-- negotiation breakdown
[200207] = function(player, opponent, my_idx, my_card)
  local target = uniformly(player:hand_idxs_with_preds(pred.maid, pred.faction.A))
  if target then
    local buff = player.hand[target].size
    local f_target = uniformly(player:field_idxs_with_preds(pred.follower, pred.faction.A))
    player:hand_to_exile(target)
    if f_target then
      OneBuff(player, f_target, {atk={"+",buff},sta={"+",buff}}):apply()
    end
  end
end,

-- inevitable choice
[200208] = function(player, opponent, my_idx, my_card)
  if pred.A(player.character) then
    local target = player:field_idxs_with_preds(pred.follower, pred.A)[1]
    if target then
      local n_acad = #player:field_idxs_with_preds(pred.A)
      local n_lady = #player:field_idxs_with_preds(pred.lady)
      OneBuff(player, target, {size={"-",n_lady},atk={"+",n_acad},sta={"+",n_acad}}):apply()
    end
  end
end,

-- table manners
[200209] = function(player, opponent, my_idx, my_card)
  local target_size = my_card.size + my_idx
  local target = opponent:field_idxs_with_preds(
      function(card) return card.size == target_size end)[1]
  if target then
    OneImpact(opponent, target):apply()
    opponent:field_to_grave(target)
    player.field[my_idx].active = false
    player.send_spell_to_grave = false
  end
end,

-- royle academy
[200210] = function(player, opponent, my_idx, my_card)
  for i=1,5 do
    local card = player.field[i]
    if card and pred.follower(card) and
    card.faction == player.character.faction then
      OneBuff(player, i, {atk={"=",card.atk*2},def={"=",card.def*2},sta={"=",card.sta*2}}):apply()
      player.field[i]:gain_skill(1150)
      break
    end
  end
end,

-- crux conference
[200211] = function(player, opponent, my_idx, my_card)
  local target_idxs = shuffle(opponent:field_idxs_with_preds({pred.follower}))
  local buff = OnePlayerBuff(opponent)
  for i=1,2 do
    if target_idxs[i] then
      buff[target_idxs[i]] = {atk={"-",1},sta={"-",3}}
    end
  end
  buff:apply()
end,

-- enemy within
[200212] = function(player, opponent, my_idx, my_card)
  local amt = 0
  local to_buff = {}
  for i=1,5 do
    local card = player.field[i]
    if card and pred.follower(card) and card.faction == "C" then
      for j=1,3 do
        if card.skills[j] then
          amt = amt + 1
          to_buff[i] = true
        end
      end
      card.skills = {}
    end
  end
  local buff = OnePlayerBuff(player)
  for i,_ in pairs(to_buff) do
    buff[i] = {atk={"+",amt},sta={"+",amt}}
  end
  buff:apply()
end,

-- commissioned research
[200213] = function(player, opponent, my_idx, my_card)
  local size = nil
  for i=1,5 do
    local card = player.field[i]
    if card and pred.follower(card) and card.faction == "C" then
      size = card.size
      break
    end
  end
  if size then
    for i=1,5 do
      local card = opponent.field[i]
      if card and pred.spell(card) and card.size <= size then
        opponent:field_to_bottom_deck(i)
      end
    end
  end
end,

-- supply transfer
[200214] = function(player, opponent, my_idx, my_card)
  for i=1,5 do
    local card = player.field[i]
    local buff = 2
    if card and pred.follower(card) and card.faction == player.character.faction then
      for j=1,5 do
        local other_card = player.field[j]
        if j ~= i and other_card and pred.follower(other_card) then
          buff = buff + other_card.size
        end
      end
      buff = min(buff, 8)
      OneBuff(player, i, {atk={"+",buff},sta={"+",buff}}):apply()
      break
    end
  end
end,

-- relieve post
[200215] = function(player, opponent, my_idx, my_card)
  local targets = shuffle(player:field_idxs_with_preds(pred.follower))
  local buff = OnePlayerBuff(player)
  for i=1,2 do
    if targets[i] then
      buff[targets[i]] = {atk={"+",4},sta={"+",4}}
    end
  end
  buff:apply()
  player.send_spell_to_grave = false
  if my_card.size == 1 then
    player.field[my_idx] = nil
  else
    my_card.size = 1
    my_card.active = false
  end
end,

-- stakeout
[200216] = function(player, opponent, my_idx, my_card)
  local target = opponent.field[my_idx]
  if target and pred.follower(target) then
    OneBuff(opponent, my_idx, {def={"=",0},sta={"-",2}}):apply()
  end
end,

-- heart barrier
[200217] = function(player, opponent, my_idx, my_card)
  for i=1,5 do
    local first_card = player.field[i]
    if first_card and pred.follower(first_card) then
      for j=i,5 do
        local second_card = player.field[j]
        if second_card and pred.follower(second_card) and
        first_card.faction ~= second_card.faction then
          second_card.active = false
          OneBuff(player, j, {sta={"+",6}}):apply()
          break
        end
      end
      break
    end
  end
end,

-- flare
[200218] = function(player, opponent, my_idx, my_card)
  local target = uniformly(player:field_idxs_with_preds(pred.follower, pred.faction.D))
  if target then
    OneBuff(player, target, {def={"+",1},sta={"+",4}}):apply()
  end
end,

-- crux in flames
[200219] = function(player, opponent, my_idx, my_card)
  local target = opponent:field_idxs_with_most_and_preds(
      pred.add(pred.atk, pred.def, pred.sta), pred.follower)[1]
  local slot = player:first_empty_field_slot()
  if #player:field_idxs_with_preds(pred.follower) == 0 and target and slot then
    player.field[slot] = deepcpy(opponent.field[target])
    player.field[slot]:refresh()
    player.field[slot].active = true
    player.field[slot]:gain_skill(1151)
  end
end,

-- devastation
[200220] = function(player, opponent, my_idx, my_card)
  if #player:field_idxs_with_preds(pred.follower) > 0 then
    local m_atk = player:field_idxs_with_most_and_preds(pred.atk, pred.follower)[1]
    local m_def = player:field_idxs_with_most_and_preds(pred.def, pred.follower)[1]
    local m_sta = player:field_idxs_with_most_and_preds(pred.sta, pred.follower)[1]
    local o_atk = opponent:field_idxs_with_most_and_preds(pred.atk, pred.follower)[1]
    local o_def = opponent:field_idxs_with_most_and_preds(pred.def, pred.follower)[1]
    local o_sta = opponent:field_idxs_with_most_and_preds(pred.sta, pred.follower)[1]
    local b_atk = player.field[m_atk].atk
    local b_def = player.field[m_def].def
    local b_sta = player.field[m_sta].sta
    if o_atk then
      if b_atk < opponent.field[o_atk].atk then
        b_atk = opponent.field[o_atk].atk
      end
      if b_def < opponent.field[o_def].def then
        b_def = opponent.field[o_def].def
      end
      if b_sta < opponent.field[o_sta].sta then
        b_sta = opponent.field[o_sta].sta
      end
    end
    for i=1,5 do
      local card = player.field[i]
      if card and pred.follower(card) and
          card.faction == player.character.faction then
        OneBuff(player, i, {atk={"=",b_atk},def={"=",b_def},sta={"=",b_sta}}):apply()
        break
      end
    end
  end
end,

-- ruin's end
[200221] = function(player, opponent, my_idx, my_card)
  local buff = GlobalBuff(player)
  local idxs = player:hand_idxs_with_preds()
  for _, idx in ipairs(idxs) do
    buff.hand[player][idx] = {size={"-", 1}}
  end
  local idxs = opponent:field_idxs_with_preds()
  for _, idx in ipairs(idxs) do
    buff.field[opponent][idx] = {size={"+", 1}}
  end
  buff:apply()
  for i=1,5 do
    local myfield = player.field[i]
    local oppfield = opponent.field[i]
    if myfield and i ~= my_idx then
      player:field_to_bottom_deck(i)
    end
    if oppfield then
      opponent:field_to_bottom_deck(i)
    end
  end
  for _,p in ipairs({player, opponent}) do
    for i=1,5 do
      if p.hand[1] then
        p:hand_to_bottom_deck(1)
      end
    end
  end
  opponent.shuffles = max(0, opponent.shuffles-1)
end,

-- vernika's nightmare
[200223] = function(player, opponent, my_idx, my_card)
  OneBuff(player, 0, {life={"+",1}}):apply()
  player.shuffles = player.shuffles + 1
  local target = uniformly(player:field_idxs_with_preds(pred.follower))
  if target then
    OneBuff(player, target, {atk={"+",1},sta={"+",1}}):apply()
  end
  if #player.grave >= 5 then
    player:grave_to_bottom_deck(math.random(#player.grave))
  end
end,

-- ominous sky
[200224] = function(player, opponent, my_idx, my_card)
  local my_guys = shuffle(player:field_idxs_with_preds(pred.follower))
  local op_guys = shuffle(opponent:field_idxs_with_preds(pred.follower))
  if #my_guys > 0 then
    local buff = GlobalBuff(player)
    for i=1,min(2,#my_guys) do
      buff.field[player][my_guys[i]] = {def={"+",1}}
    end
    for i=1,min(2,#op_guys) do
      buff.field[opponent][op_guys[i]] = {atk={"-",2}}
    end
    buff:apply()
  end
end,

-- Nightmare
-- A random Follower on your Field gets ATK +1.
-- That Follower's ATK and a random Follower on the enemy Field's STA
-- are swapped.
[200225] = function(player, opponent)
  -- get my random follower and opponent's random follower
  local my_target = uniformly(player:field_idxs_with_preds(pred.follower))
  local op_target = uniformly(opponent:field_idxs_with_preds(pred.follower))
  local buff = GlobalBuff(player)
  if my_target and op_target then
    -- store my follower's ATK and opponent's STA
    local my_atk = player.field[my_target].atk + 1
    local op_sta = opponent.field[op_target].sta
    -- swap ATK and STA
    buff.field[player][my_target] = {atk={"=",op_sta}}
    buff.field[opponent][op_target] = {sta={"=",my_atk}}
  elseif my_target then
    buff.field[player][my_target] = {atk={"+",1}}
  end
  buff:apply()
end,

-- One Afternoon
-- All followers on your Field get DEF -3. The first Vita Follower
-- on your Field with the highest SIZE gets DEF increased by 1
-- plus half the total DEF reduction (rounding up).
[200226] = function(player)
  local folls = player:field_idxs_with_preds(pred.follower)
  local target = player:field_idxs_with_most_and_preds(pred.size, pred.follower, pred.V)[1]
  local buff = OnePlayerBuff(player)
  local buff_amt = ceil((3*#folls)/2) + 1
  for _,idx in ipairs(folls) do
    buff[idx] = {def={"-",3}}
  end
  buff:apply()
  if target then
    OneBuff(player, target, {def={"+",buff_amt}}):apply()
  end
end,

-- TODO: Beginning of a Lady
-- Any of the first Academy Follower on your Field's ATK/DEF/STA
-- that are lower than their original values are changed to their
-- original values.
[200227] = function(player)
  local target = player:field_idxs_with_preds(pred.follower, pred.A)[1]
  if target then
    local buff = {}
    local orig = Card(player.field[target].id)
    for _,stat in ipairs({"atk","def","sta"}) do
      if player.field[target][stat] < orig[stat] then
        buff[stat] = {"=",orig[stat]}
      end
    end
    OneBuff(player, target, buff):apply()
  end
end,

--[[
Everyday Life
Lose life equal to half the size of random follower in hand
All followers in your field +ATK/+STA equal to life lost
]]
[200228] = function(player)
  local foll = uniformly(player:hand_idxs_with_preds(pred.follower))
  if not foll then
    return
  end
  local lifeloss = floor(player.hand[foll].size / 2)
  OneBuff(player, 0, {life={"-",lifeloss}}):apply()
  local buff = OnePlayerBuff(player)
  for _,idx in ipairs(player:field_idxs_with_preds(pred.follower)) do
    buff[idx] = {atk={"+",lifeloss},sta={"+",lifeloss}}
  end
  buff:apply()
end,

--[[
Meeting
Random enemy follower with same faction as your character
is moved to your first empty slot and deactivated
]]
[200229] = function(player, opponent)
  local old_idx = uniformly(opponent:field_idxs_with_preds(pred.follower,
      function(card) return card.faction == player.character.faction end))
  local new_idx = player:first_empty_field_slot()
  if old_idx and new_idx then
    player.field[new_idx], opponent.field[old_idx] = opponent.field[old_idx], nil
    player.field[new_idx].active = false
  end
end,

--[[
Summer Day Memory
3 random allied followers get +ATK/+STA equal to difference between
their Size and 4
]]
[200230] = function(player)
  local buff = OnePlayerBuff(player)
  local idxs = shuffle(player:field_idxs_with_preds(pred.follower))
  for i=1,min(3,#idxs) do
    buff[idxs[i]] = {atk={"+",abs(4-player.field[idxs[i]].size)},
        sta={"+",abs(4-player.field[idxs[i]].size)}}
  end
  buff:apply()
end,

-- string of emotion
[200231] = function(player, opponent, my_idx, my_card)
  local target = player:field_idxs_with_least_and_preds(pred.size, pred.follower)[1]
  if target then
    OneBuff(player, target, {size={"+",2},atk={"+",2},def={"+",2},sta={"+",2}}):apply()
  end
end,

-- fellowship
[200232] = function(player, opponent, my_idx, my_card)
  if #player:field_idxs_with_preds(pred.follower) > 0 then
    local buff = GlobalBuff(player)
    for _,p in ipairs({player, opponent}) do
      for _,idx in ipairs(p:field_idxs_with_preds(pred.follower, pred.neg(pred.C))) do
        buff.field[p][idx] = {sta={"-",3}}
      end
    end
    buff:apply()
  end
end,

--[[
Summoning Ritual
The first card in the enemy Grave is removed from the game
If the card's SIZE <= 3 a Follower named Zombie with the skill Death is created in your first empty Slot
Otherwise, a Follower named Devil Lady is created in your first empty slot
]]
[200233] = function(player, opponent)
  if #opponent.grave == 0 then
    return
  end
  local mag = opponent.grave[#opponent.grave].size
  opponent:grave_to_exile(#opponent.grave)
  local idx = player:first_empty_field_slot()
  if not idx then
    return
  end
  if mag <= 3 then
    player.field[idx] = Card(300072)
    player.field[idx]:gain_skill(1175)
  else
    player.field[idx] = Card(300319)
  end
end,

--[[
Sisters
The first 3 cards in your Grave are exiled
2 random allied followers get ATK+/STA+ equal to the number of exiled Darklore Followers
]]
[200234] = function(player)
  local mag = 0
  for i=1,min(3,#player.grave) do
    if pred.D(player.grave[#player.grave]) and pred.follower(player.grave[#player.grave]) then
      mag = mag + 1
    end
    player:grave_to_exile(#player.grave)
  end
  local buff = OnePlayerBuff(player)
  local idxs = shuffle(player:field_idxs_with_preds(pred.follower))
  for i=1,min(2,#idxs) do
    buff[idxs[i]] = {atk={"+",mag},sta={"+",mag}}
  end
  buff:apply()
end,

--[[
Master of the Night
All Darklore Followers in your Grave are exiled
A random enemy Follower gets STA- equal to the number of exiled cards
]]
[200235] = function(player, opponent)
  local mag = 0
  for i=#player.grave,1,-1 do
    if pred.follower(player.grave[i]) and pred.D(player.grave[i]) then
      player:grave_to_exile(i)
      mag = mag + 1
    end
  end
  local idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if idx then
    OneBuff(opponent, idx, {sta={"-",mag}}):apply()
  end
end,

--[[
Born in Nature
x = total number of cards on the Field
x cards are sent from each player's hand to the bottom of their Deck
A random allied Follower gets STA+ equal to the number of cards sent
]]
[200236] = function(player, opponent)
  local count = player:ncards_in_field() + opponent:ncards_in_field()
  local mag = 0
  for i=1,min(count,#player.hand) do
    player:hand_to_bottom_deck(1)
    mag = mag + 1
  end
  for i=1,min(count,#opponent.hand) do
    opponent:hand_to_bottom_deck(1)
    mag = mag + 1
  end
  local idx = uniformly(player:field_idxs_with_preds(pred.follower))
  if idx then
    OneBuff(player, idx, {sta={"+",mag}}):apply()
  end
end,

--[[
True Vampire God
Your Character gains life and all allied Followers get +STA equal to
number of Neutral cards in your Hand and Field - 1
]]
[200237] = function(player)
  local count = #player:hand_idxs_with_preds(pred.faction.N) +
      #player:field_idxs_with_preds(pred.faction.N) - 1
  local buff = OnePlayerBuff(player)
  for _,idx in ipairs(player:field_idxs_with_preds(pred.follower)) do
    buff[idx] = {sta={"+",count}}
  end
  buff[0] = {life={"+",count}}
  buff:apply()
end,

--[[
Red and White
A random Follower gets effects depending on factions present in your Hand
Vita: ATK+ 2
Academy: STA+ 2
Crux: ATK+ 1/STA+ 1
Darklore: SIZE- 1
Neutral: ATK+ 2/STA+ 2
]]
[200238] = function(player)
  local count = {}
  local idx = uniformly(player:field_idxs_with_preds(pred.follower))
  if idx then
    for i=1,#player.hand do
      if player.hand[i] then
        count[player.hand[i].faction] = true
      end
    end
    local size_m = 0
    local atk_m = 0
    local sta_m = 0
    if count["V"] then
      atk_m = atk_m + 2
    end
    if count["A"] then
      sta_m = sta_m + 2
    end
    if count["C"] then
      atk_m = atk_m + 1
      sta_m = sta_m + 1
    end
    if count["D"] then
      size_m = size_m + 1
    end
    if count["N"] then
      atk_m = atk_m + 2
      sta_m = sta_m + 2
    end
    OneBuff(player, idx, {size={"-",size_m},atk={"+",atk_m},sta={"+",sta_m}}):apply()
  end
end,

-- sita's suit
[200239] = sitas_suit(pred.sita),

-- perky girl
[200240] = function(player, opponent, my_idx, my_card)
  for i=1,2 do
    if #player.hand < 5 then
      local target = player:deck_idxs_with_preds(pred.sita)[1]
      if target then
        player:deck_to_hand(target)
        player.hand[#player.hand].size = max(1, player.hand[#player.hand].size - 2)
      end
    end
  end
end,

-- halloween minidevil
[200241] = function(player, opponent, my_idx, my_card)
  local my_guy = player:hand_idxs_with_preds(pred.follower)[1]
  local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if my_guy and target then
    local amt = ceil(player.hand[my_guy].atk/2)
    OneBuff(opponent, target, {sta={"-",amt}}):apply()
    halloween(player, opponent)
  end
end,

-- cinia's suit
[200242] = sitas_suit(pred.cinia),

-- working girl
[200243] = function(player, opponent, my_idx, my_card)
  local total_sz = 0
  for i=1,2 do
    if #player.hand < 5 then
      local target = player:deck_idxs_with_preds(pred.cinia)[1]
      if target then
        player:deck_to_hand(target)
        total_sz = total_sz + player.hand[#player.hand].size
      end
    end
  end
  local target = opponent:field_idxs_with_preds(pred.follower,
      function(card) return card.sta <= total_sz end)[1]
  if target then
    opponent:field_to_grave(target)
  end
end,

-- halloween countess
[200244] = function(player, opponent, my_idx, my_card)
  local target = uniformly(opponent:field_idxs_with_preds(pred.follower, pred.skill))
  if target and #player:field_idxs_with_preds(pred.follower) > 0 then
    local idx = opponent.field[target]:first_skill_idx()
    opponent.field[target]:remove_skill(idx)
    opponent.field[target]:gain_skill(uniformly({1201, 1202}))
    halloween(player, opponent)
  end
end,

-- luthica's suit
[200245] = sitas_suit(pred.luthica),

-- the hazing
[200246] = function(player, opponent, my_idx, my_card)
  local target_idxs = shuffle(player:field_idxs_with_preds({pred.follower}))
  local buff = OnePlayerBuff(player)
  for i=1,2 do
    if target_idxs[i] then
      buff[target_idxs[i]] = {def={"+",ceil((5-#player.hand)/2)}}
    end
  end
  buff:apply()
  for i=1,2 do
    if #player.hand < 5 then
      local target = player:deck_idxs_with_preds(pred.luthica)[1]
      if target then
        player:deck_to_hand(target)
      end
    end
  end
end,

-- halloween witch
[200247] = function(player, opponent, my_idx, my_card)
  local target = uniformly(player:field_idxs_with_preds(pred.follower))
  if target then
    player.field[target]:gain_skill(uniformly({1203, 1204, 1257}))
    halloween(player, opponent)
  end
end,

-- iri's suit
[200248] = sitas_suit(pred.iri),

-- carefree heart
[200249] = function(player, opponent, my_idx, my_card)
  if #player:field_idxs_with_preds(pred.follower) > 0 then
    local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
    if target then
      OneBuff(opponent, target, {sta={"-",6-#player.hand}}):apply()
    end
  end
  for i=1,2 do
    if #player.hand < 5 then
      local target = player:deck_idxs_with_preds(pred.iri)[1]
      if target then
        player:deck_to_hand(target)
      end
    end
  end
end,

--[[
Halloween Wolf
The first card in your Hand is sent to the first empty Slot
of your Field and has its SIZE halved (rounding down). If this happens,
the first Spell in the enemy Hand without "Halloween" in the name is copied to
the first empty Slot of your Field.
]]
[200250] = function(player, opponent, my_idx, my_card)
  local idx = player:first_empty_field_slot()
  if idx then
    local myhand = player.hand[1]
    if myhand then
      player:hand_to_field(1)
      OneBuff(player, idx, {size={"=", floor(player.field[idx].size / 2)}}):apply()
      halloween(player, opponent)
    end
  end
end,

-- double student council kick
[200251] = function(player, opponent, my_idx, my_card)
  local kicker = shuffle(player:field_idxs_with_preds({pred.follower, pred.active, pred.student_council}))
  local damage = 0
  for i=1,2 do
    if kicker[i] then
      player.field[kicker[i]].active = false
      damage = damage + player.field[kicker[i]].atk
    end
  end
  local target = opponent:field_idxs_with_most_and_preds(pred.sta, pred.follower)[1]
  if target and #kicker > 0 then
    OneBuff(opponent, target, {sta={"-",damage}}):apply()
  end
end,

-- comfort room
[200252] = function(player, opponent, my_idx, my_card)
  local target = player:field_idxs_with_least_and_preds(pred.size, pred.follower, pred.maid)[1]
  if target then
    local size = player.field[target].size
    if #player.hand < 5 then
      player.hand[#player.hand+1] = player.field[target]
      player.field[target] = nil
      OneBuff(player, 0, {life={"-",size}}):apply()
      for i=1,#player.hand do
        local card = player.hand[i]
        if card and pred.follower(card) and card.faction == "A" then
          card.atk = card.atk + 2
          card.sta = card.sta + 2
        end
      end
      for i=1,5 do
        local card = player.field[i]
        if card and pred.follower(card) and card.faction == "A" then
          OneBuff(player, i, {atk={"+",2}, sta={"+",2}}):apply()
        end
      end
    end
  end
end,

-- flash shield
[200253] = function(player, opponent, my_idx, my_card)
  local targets = player:field_idxs_with_preds({pred.follower, pred.seeker})
  for i=1,5 do
    if targets[i] then
      player.field[targets[i]]:gain_skill(1205)
    end
  end
end,

-- strega think tank
[200254] = function(player, opponent, my_idx, my_card)
  local targets = player:field_idxs_with_preds({pred.follower, pred.witch})
  local buff = OnePlayerBuff(opponent)
  for i=1,5 do
    local card = opponent.field[i]
    if card and pred.follower(card) then
      buff[i] = {atk={"-",#targets + 1}}
    end
  end
  buff:apply()
  buff = OnePlayerBuff(player)
  for i=1,5 do
    if targets[i] then
      buff[targets[i]] = {atk={"+",#targets + 1}}
    end
  end
  buff:apply()
end,

-- rio's ward
[200255] = function(player, opponent, my_idx, my_card)
  local targets = player:field_idxs_with_preds(pred.follower)
  local buff = OnePlayerBuff(player)
  for _,idx in ipairs(targets) do
    buff[idx] = {atk={"+",4},sta={"+",4}}
  end
  buff:apply()
end,

-- original reader
[200256] = function(player, opponent, my_idx, my_card)
  local spells = opponent:deck_idxs_with_preds(pred.spell)
  for i=1,min(5-#opponent.hand, #spells) do
    opponent:deck_to_hand(spells[i])
  end
end,

-- awakened lady
[200257] = function(player, opponent, my_idx, my_card)
  local targets = opponent:field_idxs_with_preds(pred.follower)
  local buff = OnePlayerBuff(opponent)
  for _,idx in ipairs(targets) do
    buff[idx] = {sta={"-",4}}
  end
  buff:apply()
end,

-- meltdown
[200258] = function(player, opponent, my_idx, my_card)
  local targets = opponent:field_idxs_with_preds(pred.follower)
  local buff = OnePlayerBuff(opponent)
  for _,idx in ipairs(targets) do
    buff[idx] = {def={"-",5}}
  end
  buff:apply()
end,

-- restored origins
[200259] = function(player, opponent, my_idx, my_card)
  local buff = GlobalBuff(player)
  for _,p in ipairs({player, opponent}) do
    for _,idx in ipairs(p:field_idxs_with_preds()) do
      buff.field[p][idx] = {size={"=",1}}
    end
  end
  buff:apply()
end,

-- sage's slipper
[200260] = function(player, opponent, my_idx, my_card)
  local targets = opponent:field_idxs_with_preds(pred.union(pred.shion, pred.rion))
  for _,idx in ipairs(targets) do
    opponent:destroy(idx)
  end
end,

-- third impact
[200261] = function(player, opponent, my_idx, my_card)
  local targets = opponent:field_idxs_with_preds(pred.follower)
  local buff = OnePlayerBuff(opponent)
  for _,idx in ipairs(targets) do
    buff[idx] = {size={"=",random(1,10)}}
  end
  buff:apply()
end,

-- arc light
[200262] = function(player, opponent, my_idx, my_card)
  local targets = opponent:field_idxs_with_preds(pred.follower)
  for _,idx in ipairs(targets) do
    opponent.field[idx]:gain_skill(1003)
  end
end,

-- charming aura
[200263] = function(player, opponent, my_idx, my_card)
  local targets = opponent:field_idxs_with_preds(pred.follower)
  for _,idx in ipairs(targets) do
    opponent.field[idx].skills = {}
  end
end,

-- trap book
[200264] = function(player, opponent, my_idx, my_card)
  if not opponent:first_empty_field_slot() then
    for i=1,5 do
      opponent:field_to_grave(i)
    end
  end
end,

-- student council unveiling
[200265] = function(player, opponent, my_idx, my_card)
  if #player:field_idxs_with_preds(pred.follower, pred.student_council) > 0 and
      #player.hand > 0 then
    local sz = player.hand[1].size
    player:hand_to_grave(1)
    local target = opponent:field_idxs_with_preds(function(card) return card.size == sz end)[1]
    if target then
      opponent:field_to_grave(target)
    end
  end
end,

-- freezing room
[200266] = function(player, opponent, my_idx, my_card)
  local targets = opponent:field_idxs_with_preds(pred.follower)
  local amt = min(5, floor(player.game.turn/2) + 1)
  local buff = OnePlayerBuff(opponent)
  for _,idx in ipairs(targets) do
    buff[idx] = {atk={"-",amt},sta={"-",amt}}
  end
  buff:apply()
  player.shuffles = player.shuffles + 1
  opponent.shuffles = max(0, opponent.shuffles-1)
end,

-- witch cadet
[200267] = function(player, opponent, my_idx, my_card)
  local targets = shuffle(player:field_idxs_with_preds(pred.follower))
  local buff = OnePlayerBuff(player)
  for i=1,2 do
    if targets[i] then
      buff[targets[i]] = {atk={"+",1},sta={"+",1}}
    end
  end
  buff:apply()
  targets = shuffle(player:field_idxs_with_preds(pred.follower, pred.witch))
  buff = OnePlayerBuff(player)
  for i=1,2 do
    if targets[i] then
      buff[targets[i]] = {atk={"+",2},sta={"+",2}}
    end
  end
  buff:apply()
end,

-- lady's selection
[200268] = function(player, opponent, my_idx, my_card)
  local ladies = player:field_idxs_with_preds(pred.follower, pred.lady)
  local target = uniformly(opponent:field_idxs_with_preds(pred.spell))
  if #ladies > 0 and target then
    local sz = opponent.field[target].size
    local buff = OnePlayerBuff(player)
    opponent:field_to_grave(target)
    for _,idx in ipairs(ladies) do
      buff[idx] = {sta={"+",sz}}
    end
    buff:apply()
  end
end,

-- elbert impact
[200269] = function(player, opponent, my_idx, my_card)
  if pred.A(player.character) then
    local targets = opponent:field_idxs_with_preds(pred.spell)
    for _,idx in ipairs(targets) do
      opponent:field_to_bottom_deck(idx)
    end
    for i=1,max(#targets, 1) do
      local idx = opponent:last_empty_field_slot()
      if idx then
        opponent.field[idx] = Card(200071)
        opponent.field[idx].active = false
      end
    end
    player.send_spell_to_grave = false
    player.field[my_idx] = nil
  end
end,

-- artificer
[200270] = function(player, opponent, my_idx, my_card)
  local targets = shuffle(player:field_idxs_with_preds(pred.follower, pred.seeker))
  local buff = OnePlayerBuff(player)
  for i=1,2 do
    if targets[i] then
      local amt = #player.field[targets[i]]:squished_skills() + 1
      buff[targets[i]] = {atk={"+",amt},sta={"+",amt}}
    end
  end
  buff:apply()
end,

-- joining the knights
[200271] = function(player, opponent, my_idx, my_card)
  local target = player:field_idxs_with_most_and_preds(pred.sta, pred.follower)[1]
  if target then
    local card = player.field[target]
    OneBuff(player, target, {atk={"=",card.sta},sta={"=",card.atk+2}}):apply()
  end
end,

-- sanctuary pillar
[200272] = function(player, opponent, my_idx, my_card)
  local buff = OnePlayerBuff(player)
  local targets = player:field_idxs_with_preds(pred.C, pred.follower)
  for _,idx in ipairs(targets) do
    local card = player.field[idx]
    buff[idx] = {sta={"+",3}}
    if pred.seeker(card) then
      buff[idx].atk={"+",2}
    end
  end
  buff:apply()
  if player.game.turn % 2 == 0 then
    local target = uniformly(opponent:field_idxs_with_preds(pred.spell))
    if target then
      opponent.field[target].active = false
      OneImpact(opponent, target):apply()
    end
  end
  my_card.active = false
  player.send_spell_to_grave = false
end,

-- meaningless research
[200273] = function(player, opponent, my_idx, my_card)
  if #player:field_idxs_with_preds(pred.follower) > 0 then
    for i=1,3 do
      local my_guys = player:field_idxs_with_preds(pred.follower)
      local op_guys = opponent:field_idxs_with_preds(pred.follower)
      if #my_guys + #op_guys > 0 then
        local which = random(1,#my_guys + #op_guys)
        if which <= #my_guys then
          OneBuff(player, my_guys[which], {atk={"-",1},sta={"-",3}}):apply()
        else
          OneBuff(opponent, op_guys[which - #my_guys], {atk={"-",1},sta={"-",3}}):apply()
        end
      end
    end
  end
end,

-- nether deal
[200274] = function(player, opponent, my_idx, my_card)
  local card = opponent.field[3]
  local idx = player:field_idxs_with_preds(pred.follower)[1]
  if card and pred.follower(card) and idx then
    local other_card = player.field[idx]
    local buff = GlobalBuff(player)
    buff.field[opponent][3],buff.field[player][idx] = {},{}
    for _,stat in ipairs({"def","sta"}) do
      buff.field[opponent][3][stat] = {"=",other_card[stat]}
      buff.field[player][idx][stat] = {"=",card[stat]}
    end
    buff.field[player][0] = {life={"-",1}}
    buff:apply()
  end
end,

-- cursed totem
[200275] = function(player, opponent, my_idx, my_card)
  local atk,sta = {0,1,1,2,2}, {2,1,2,2,3}
  local my_ncards = #player:field_idxs_with_preds()
  local targets = shuffle(opponent:field_idxs_with_preds(pred.follower))
  local buff = OnePlayerBuff(player.opponent)
  for i=1,min(2, #targets) do
    buff[targets[i]] = {atk={"-",atk[my_ncards]},sta={"-",sta[my_ncards]}}
  end
  buff:apply()
  if player.game.turn % 2 == 1 then
    local target = uniformly(opponent:field_idxs_with_preds(pred.spell))
    if target then
      opponent.field[target].active = false
      OneImpact(opponent, target):apply()
    end
  end
  my_card.active = false
  player.send_spell_to_grave = false
end,

-- sacred tutor
[200276] = function(player, opponent, my_idx, my_card)
  local hand_idx = uniformly(opponent:hand_idxs_with_preds(pred.follower))
  if hand_idx and opponent:first_empty_field_slot() then
    opponent:hand_to_field(hand_idx)
  end
end,

-- rainy day
[200277] = function(player, opponent, my_idx, my_card)
  player.game.turn = player.game.turn + 2
  local targets = opponent:field_idxs_with_preds(pred.follower)
  local buff = OnePlayerBuff(opponent)
  for _,idx in ipairs(targets) do
    buff[idx] = {atk={"-",2},sta={"-",2}}
  end
  buff:apply()
end,

-- flee
[200278] = function(player, opponent, my_idx, my_card)
  for i=1,5 do
    local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
    if target then
      OneBuff(opponent, target, {sta={"-",5}}):apply()
    end
  end
end,

-- burning crusade
[200279] = function(player, opponent, my_idx, my_card)
  local targets = opponent:field_idxs_with_preds(pred.follower)
  for _,idx in ipairs(targets) do
    opponent.field[idx]:gain_skill(1237)
  end
end,

-- library explorer
[200280] = function(player, opponent, my_idx, my_card)
  local cards = player:hand_idxs_with_preds(pred.library_club)
  for _,idx in ipairs(cards) do
    player:to_bottom_deck(player.hand[idx])
    player.hand[idx] = nil
  end
  player:squish_hand()
  local targets = opponent:field_idxs_with_preds()
  for i=1,min(#cards, #targets) do
    opponent.field[targets[i]].active = false
  end
end,

-- rookie's appearance
[200281] = function(player, opponent, my_idx, my_card)
  local targets = player:field_idxs_with_preds(pred.follower,
      function(card) return card.atk == card.sta end)
  local buff = OnePlayerBuff(player)
  for _,idx in ipairs(targets) do
    buff[idx] = {atk={"+",4},sta={"+",4}}
  end
  buff:apply()
end,

-- returnee
[200282] = function(player, opponent, my_idx, my_card)
  local target = player:grave_idxs_with_preds(pred.follower, pred[player.character.faction])[1]
  local slot = player:first_empty_field_slot()
  if target and slot then
    player:grave_to_field(target)
    player.field[slot].active = false
    OneBuff(player, slot, {atk={"+",2},sta={"+",2}}):apply()
    player.field[slot].skills = {1076}
  end
end,

-- lady radar
[200283] = function(player, opponent, my_idx, my_card)
  local targets = player:field_idxs_with_preds(pred.follower, pred.A, function(card)
        for _,id in pairs(card.skills) do
          if skill_id_to_type[id] == "defend" then
            return false
          end
        end
        return true
      end)
  local buff = OnePlayerBuff(player)
  for _,idx in ipairs(targets) do
    buff[idx] = {def={"+",1},sta={"+",3}}
  end
  buff:apply()
  local target = player:deck_idxs_with_preds(pred.lady)[1]
  if target and #player.hand < 5 then
    player:deck_to_hand(target)
  end
end,

-- strega memory
[200284] = function(player, opponent, my_idx, my_card)
  local my_guys = player:field_idxs_with_preds(pred.follower, pred.witch)
  local amt = 0
  for _,idx in ipairs(my_guys) do
    amt = amt + player.field[idx].size
  end
  local targets = shuffle(opponent:field_idxs_with_preds(pred.follower))
  local buff = OnePlayerBuff(opponent)
  for i=1,min(2,#targets) do
    buff[targets[i]] = {atk={"-",floor(amt/2)},def={"-",floor(amt/2)}}
  end
  buff:apply()
end,

-- 14th request
[200285] = function(player, opponent, my_idx, my_card)
  if #player:field_idxs_with_preds(pred.follower) > 0 and
      ((#player:field_idxs_with_preds(pred.follower) +
        #opponent:field_idxs_with_preds(pred.follower) == 4) or
        (player.game.turn % 4 == 0) or
        (#player.hand + #opponent.hand == 6)) then
    for i=1,4 do
      local my_guys = player:field_idxs_with_preds()
      local op_guys = opponent:field_idxs_with_preds()
      if #my_guys + #op_guys > 0 then
        local which = random(1,#my_guys + #op_guys)
        if which <= #my_guys then
          player:field_to_grave(my_guys[which])
        else
          opponent:field_to_grave(op_guys[which - #my_guys])
        end
      end
    end
    if player.field[my_idx] then
      player.field[my_idx] = nil
      player.send_spell_to_grave = false
    end
  end
end,

-- artificial sanctuary experiment
[200286] = function(player, opponent, my_idx, my_card)
  if my_card.size == 1 then
    if #player:field_idxs_with_preds(pred.follower, pred.seeker) > 0 then
      local targets = opponent:field_idxs_with_preds(pred.follower)
      local buff = OnePlayerBuff(opponent)
      for _,idx in ipairs(targets) do
        buff[idx] = {sta={"-",4}}
      end
      buff:apply()
      opponent.shuffles = max(0, opponent.shuffles-1)
      local idx = uniformly(opponent:hand_idxs_with_preds())
      if idx then
        opponent:hand_to_grave(idx)
      end
    end
  else
    my_card.size = my_card.size - 1
    my_card.active = false
    player.send_spell_to_grave = false
  end
end,

-- really quick service
[200287] = function(player, opponent, my_idx, my_card)
  local hand_idxs = opponent:hand_idxs_with_preds(pred.follower)
  local field_idxs = opponent:field_idxs_with_preds(pred.follower)
  for i=1,min(2, #hand_idxs, #field_idxs) do
    opponent.field[field_idxs[i]], opponent.hand[hand_idxs[i]] =
        opponent.hand[hand_idxs[i]], opponent.field[field_idxs[i]]
  end
end,

-- discovery of a girl
[200288] = function(player, opponent, my_idx, my_card)
  if pred.C(player.character) then
    local n = min(#opponent.grave, 10)
    for i=1,n do
      opponent.grave[#opponent.grave] = nil
    end
    local targets = opponent:field_idxs_with_preds(pred.follower)
    local buff = OnePlayerBuff(opponent)
    local amt = floor(n / (1+#targets))
    for _,idx in ipairs(targets) do
      buff[idx] = {sta={"-",amt}}
    end
    buff:apply()
  end
end,

-- 3rd laboratory
[200289] = function(player, opponent, my_idx, my_card)
  local size_to_count = {}
  for i=1,5 do
    local card = opponent.field[i]
    if card and pred.follower(card) then
      size_to_count[card.size] = (size_to_count[card.size] or 0) + 1
    end
  end
  for sz, count in pairs(size_to_count) do
    if count >= 3 then
      local target = opponent:field_idxs_with_preds(pred.follower,
          function(card) return card.size == sz end)[1]
      opponent:destroy(target)
    end
  end
end,

-- dream
[200290] = function(player, opponent, my_idx, my_card)
  if #player:field_idxs_with_preds(pred.follower) >= 3 then
    local target = opponent:field_idxs_with_most_and_preds(pred.atk, pred.follower)[1]
    if target then
      OneBuff(opponent, target, {atk={"=",Card(opponent.field[target].id).atk}}):apply()
    end
  end
end,

-- resistance formation
[200291] = function(player, opponent, my_idx, my_card)
  player:to_grave(Card(300194))
  player:to_grave(Card(300346))
  opponent:to_grave(Card(300194))
  opponent:to_grave(Card(300346))
  player:to_bottom_deck(Card(300194))
  player:to_bottom_deck(Card(300346))
end,

-- suggested reading
[200292] = function(player, opponent, my_idx, my_card)
  local targets = player:field_idxs_with_preds(pred.follower)
  local buff = OnePlayerBuff(player)
  for _,idx in ipairs(targets) do
    buff[idx] = {sta={"-",5}}
  end
  buff:apply()
end,

-- last one
[200293] = function(player, opponent, my_idx, my_card)
  local amt = random(-5,5)
  OneBuff(player, 0, {life={"+",amt}}):apply()
end,

-- spearhead
[200294] = function(player, opponent, my_idx, my_card)
  local targets = opponent:field_idxs_with_preds(pred.follower)
  local buff = OnePlayerBuff(opponent)
  for _,idx in ipairs(targets) do
    local atk = ceil(opponent.field[idx].atk/2)
    local sta = ceil(opponent.field[idx].sta/2)
    buff[idx] = {atk={"=",atk},sta={"=",sta}}
  end
  buff:apply()
end,

-- book meets girl
[200295] = function(player, opponent, my_idx, my_card)
  local targets = player:field_idxs_with_preds(pred.follower)
  local buff = OnePlayerBuff(player)
  for _,idx in ipairs(targets) do
    local def = player.field[idx].def*2
    buff[idx] = {def={"=",def}}
  end
  buff:apply()
  targets = opponent:field_idxs_with_preds(pred.follower)
  for _,idx in ipairs(targets) do
    opponent.field[idx].skills = {}
  end
  targets = opponent:hand_idxs_with_preds(pred.follower)
  for _,idx in ipairs(targets) do
    opponent.hand[idx].skills = {}
  end
end,

-- wrathful reversal
[200296] = function(player, opponent, my_idx, my_card)
  local targets = player:field_idxs_with_preds(pred.follower)
  local buff = GlobalBuff(player)
  for _,idx in ipairs(targets) do
    buff.field[player][idx] = {atk={"+",2},sta={"+",2}}
  end
  targets = opponent:field_idxs_with_preds(pred.follower)
  for _,idx in ipairs(targets) do
    buff.field[opponent][idx] = {atk={"-",2},sta={"-",2}}
  end
  buff:apply()
end,

-- perfect sleep
[200297] = function(player, opponent, my_idx, my_card)
  while #player.hand > 0 do
    player:hand_to_top_deck(1)
  end
  local targets = player:field_idxs_with_preds()
  for _,idx in ipairs(targets) do
    player:field_to_top_deck(idx)
  end
  targets = opponent:field_idxs_with_preds()
  for _,idx in ipairs(targets) do
    opponent.field[idx].active = false
  end
end,

-- destroy evidence
[200298] = function(player, opponent, my_idx, my_card)
  while #opponent.grave > 0 do
    opponent:grave_to_exile(#opponent.grave)
  end
end,

-- producing
[200299] = function(player, opponent, my_idx, my_card)
  for _,p in ipairs({player, opponent}) do
    while p:first_empty_field_slot() do
      p.field[p:first_empty_field_slot()] = Card(200069)
    end
  end
end,

-- youngest's day
[200300] = function(player, opponent, my_idx, my_card)
  local buff = OnePlayerBuff(opponent)
  local sz_amt = 5-#opponent:field_idxs_with_preds()
  local targets = opponent:field_idxs_with_preds(pred.follower)
  for _,idx in ipairs(targets) do
    local amt = min(sz_amt, opponent.field[idx].size - 1)
    buff[idx] = {size={"-",sz_amt},atk={"-",amt},def={"-",amt},sta={"-",amt}}
  end
  buff:apply()
end,

--[[
Cobalt Book
Allied Follower with lowest DEF has DEF set to DEF of enemy Follower with highest DEF
]]
[200301] = function(player, opponent)
  local my_idx = player:field_idxs_with_least_and_preds(pred.def, pred.follower)[1]
  local op_idx = opponent:field_idxs_with_most_and_preds(pred.def, pred.follower)[1]
  if my_idx and op_idx then
    OneBuff(player, my_idx, {def={"=",opponent.field[op_idx].def}}):apply()
  end
end,

--[[
Hiking Lesson
All enemy Followers get -STA equal to average SIZE on your Field
]]
[200302] = function(player, opponent)
  local mag = floor(player:field_size() / #player:field_idxs_with_preds())
  local idxs = opponent:field_idxs_with_preds(pred.follower)
  local buff = OnePlayerBuff(opponent)
  for _, idx in ipairs(idxs) do
    buff[idx] = {sta={"-", mag}}
  end
  buff:apply()
end,

--[[
Nostalgia
The first 5 Vita Followers in your Deck get ATK+/STA+ 5,4,3,2,1 starting from the top
You get Shuffles +1
]]
[200303] = function(player)
  local mag = 5
  local buff = GlobalBuff(player)
  local idxs = player:deck_idxs_with_preds(pred.follower, pred.V)
  for i=1,min(mag,#idxs) do
    buff.deck[player][idxs[i]] = {atk={"+",mag},sta={"+",mag}}
    mag = mag - 1
  end
  buff:apply()
  player.shuffles = player.shuffles + 1
end,

--[[
Protection
If there is an enemy Spell on the Field, a random enemy Follower gets -4 DEF
]]
[200304] = function(player, opponent)
  if #opponent:field_idxs_with_preds(pred.spell) == 0 then
    return
  end
  local op_idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if op_idx then
    OneBuff(opponent, op_idx, {def={"-",4}}):apply()
  end
end,

--[[
Lady's Rest
For each allied Lady Follower, the first Spell in the enemy Deck is sent to the bottom of the enemy Deck
]]
[200305] = function(player, opponent)
  local mag = #player:field_idxs_with_preds(pred.follower, pred.lady)
  for i=1,min(mag,#opponent:deck_idxs_with_preds(pred.spell)) do
    local idx = opponent:deck_idxs_with_preds(pred.spell)[1]
    if idx then
      opponent:deck_to_bottom_deck(idx)
    end
  end
end,

--[[
Crossroads of Chaos
If you have an Academy Character and your Field SIZE is at least 3, all cards on the Field are randomly
rearranged
The number of movements will not exceed the total number of cards on the Field
]]
[200306] = function(player, opponent, my_idx, my_card)
  if not pred.A(player.character) or player:field_size() < 3 then
    return
  end
  local card_locations = {}
  for i=1,5 do
    for _,p in ipairs({player, opponent}) do
      if p.field[i] then
        card_locations[#card_locations+1] = {p, i}
      end
    end
  end
  local mag = #card_locations
  local old_arrangement = {}
  for i=1,#card_locations do
    old_arrangement[i] = card_locations[i][1].field[card_locations[i][2]]
  end
  local new_arrangement = shuffled(old_arrangement)
  local impact = Impact(player)
  for i=1,#card_locations do
    if new_arrangement[i] ~= old_arrangement[i] then
      local p, idx = card_locations[i][1], card_locations[i][2]
      p.field[idx] = new_arrangement[i]
      impact[p][idx] = true
    end
  end
  impact:apply()
  for _,p in pairs({player, player.opponent}) do
    for i=1,5 do
      if p.field[i] == my_card then
        p:field_to_grave(i)
      end
    end
  end
end,

--[[
Sanctuary Exploration
The first Sanctuary card in your Deck is sent to the top
If this happens, your Character gets LIFE+ equal to the card's SIZE / 2 rounded up
]]
[200307] = function(player)
  local idx = player:deck_idxs_with_preds(pred.sanctuary)[1]
  if not idx then
    return
  end
  local mag = ceil(player.deck[idx].size / 2)
  player:deck_to_top_deck(idx)
  OneBuff(player, 0, {life={"+",mag}}):apply()
end,

--[[
Quick as the Wind
2 allied Followers get SIZE-/STA+ equal to the number of allied Spells
]]
[200308] = function(player)
  local mag = #player:field_idxs_with_preds(pred.spell)
  local idxs = shuffle(player:field_idxs_with_preds(pred.follower))
  local buff = OnePlayerBuff(player)
  for i=1,min(2,#idxs) do
    local card = player.field[idxs[i]]
    buff[idxs[i]] = {size={"-",mag},sta={"+",min(mag,card.size-1)}}
  end
  buff:apply()
end,

--[[
Towards Sanctuary
If you have a Crux Character, all Spells are sent to the Grave
If that happens, the first Spell in your hand is sent to the Field
Artificial Sanctuary Experiment with SIZE=2 is created on the enemy Field
]]
[200309] = function(player, opponent)
  if not pred.faction.C(player.character) then
    return
  end
  local idxs = player:field_idxs_with_preds(pred.spell)
  for _,idx in ipairs(idxs) do
    player:field_to_grave(idx)
  end
  idxs = opponent:field_idxs_with_preds(pred.spell)
  for _,idx in ipairs(idxs) do
    opponent:field_to_grave(idx)
  end
  local idx = player:hand_idxs_with_preds(pred.spell)[1]
  if idx then
    if player:first_empty_field_slot() then
      player:hand_to_field(idx)
    end
  end
  idx = opponent:first_empty_field_slot()
  if not idx then
    return
  end
  opponent.field[idx] = Card(200286)
  opponent.field[idx].size = 2
end,

--[[
Protective Instinct
The first allied Follower is sent to the top of the Deck
If that happens, the next allied Follower gets ATK+4/STA+x x = the sent card's DEF
That Follower also gets SIZE-1 if the sent card was an Aletheian
]]
[200310] = function(player)
  local idx = player:field_idxs_with_preds(pred.follower)[1]
  if not idx then
    return
  end
  local size_mag = 0
  if pred.aletheian(player.field[idx]) then
    size_mag = 1
  end
  local s_mag = player.field[idx].def
  player:field_to_top_deck(idx)
  idx = player:field_idxs_with_preds(pred.follower)[1]
  if idx then
    OneBuff(player, idx, {size={"-",size_mag},atk={"+",4},sta={"+",s_mag}}):apply()
  end
end,

--[[
GS Attack Formation
The first allied GS Follower is sent to the enemy Field, gets ATK=0/STA+ its old ATK / 2 rounded down
Its skills become Break and Death
]]
[200311] = function(player, opponent)
  local pl_idx = player:field_idxs_with_preds(pred.follower, pred.gs)[1]
  local op_idx = opponent:first_empty_field_slot()
  if not pl_idx or not op_idx then
    return
  end
  local card = player.field[pl_idx]
  player.field[pl_idx], opponent.field[op_idx] = nil, player.field[pl_idx]
  OneBuff(opponent, op_idx, {atk={"=",0},sta={"+",floor(card.atk/2)}}):apply()
  card:remove_skill(1)
  card:remove_skill(2)
  card:remove_skill(3)
  card:gain_skill(1274)
  card:gain_skill(1175)
end,

--[[
Phantasmal Image
Copy skills from the second allied Follower to the first allied Follower
If this happens, the first allied Follower gets ATK+/DEF+/STA+ equal to the number of skills copied
]]
[200312] = function(player)
  local idx1 = player:field_idxs_with_preds(pred.follower)[1]
  local idx2 = player:field_idxs_with_preds(pred.follower)[2]
  if not pred.D(player.character) or not idx1 or not idx2 then
    return
  end
  local card1 = player.field[idx1]
  local card2 = player.field[idx2]
  local mag = 0
  for i=1,3 do
    if card1:first_empty_skill_slot() and card2.skills[i] then
      card1:gain_skill(card2.skills[i])
      mag = mag + 1
    end
  end
  OneBuff(player, idx1, {atk={"+",mag},def={"+",mag},sta={"+",mag}}):apply()
end,

-- forbidden research
[200313] = function(player, opponent, my_idx, my_card)
  local targets = opponent:field_idxs_with_preds()
  local buff = OnePlayerBuff(opponent)
  for _,idx in ipairs(targets) do
    opponent.field[idx].active = false
    if pred.spell(opponent.field[idx]) then
      buff[idx] = {size={"+",1}}
    else
      opponent.field[idx].skills = {}
    end
  end
  buff:apply()
  opponent.shuffles = max(0, opponent.shuffles-1)
end,

-- shutter chance
[200314] = function(player, opponent, my_idx, my_card)
  local targets = player:field_idxs_with_preds(pred.follower)
  for _,idx in ipairs(targets) do
    player.field[idx]:gain_skill(1273)
  end
end,

-- try being me
[200315] = function(player, opponent, my_idx, my_card)
  local buff = GlobalBuff(player)
  for _,p in ipairs({player, opponent}) do
    local copy_idx = p:field_idxs_with_preds(pred.follower, pred.conundrum)[1]
    local targets = p:hand_idxs_with_preds(pred.follower)
    if copy_idx then
      local card = p.field[copy_idx]
      local the_buff = {size={"=",card.size},atk={"=",card.atk},def={"=",card.def},sta={"=",card.sta}}
      for _,idx in ipairs(targets) do
        buff.hand[p][idx] = the_buff
      end
    end
  end
  buff:apply()
end,

-- disciple's box
[200317] = function(player, opponent, my_idx, my_card)
  -- I don't know what cards this can spawn.
  -- These are sacrifice, push forward, relieve post, reunion
  local cards = {200035, 200185, 200215, 200047}
  local slot = player:first_empty_field_slot()
  if slot then
    player.field[slot] = Card(uniformly(cards))
  end
end,

-- infinite thanks
[200318] = function(player, opponent, my_idx, my_card)
  local slot = opponent:first_empty_field_slot()
  while slot do
    opponent.field[slot] = Card(200070)
    opponent.field[slot].active = false
    slot = opponent:first_empty_field_slot()
  end
end,

-- curse of decay
[200319] = function(player, opponent, my_idx, my_card)
  local targets = opponent:field_idxs_with_preds(pred.follower)
  local buff = OnePlayerBuff(opponent)
  for _,idx in ipairs(targets) do
    buff[idx] = {atk={"-",2},def={"-",2},sta={"-",2}}
  end
  buff:apply()
  player.send_spell_to_grave = false
  my_card.active = false
end,

-- worries
[200320] = function(player, opponent, my_idx, my_card)
  opponent.field[1], opponent.field[5] = opponent.field[5], opponent.field[1]
  opponent.field[2], opponent.field[4] = opponent.field[4], opponent.field[2]
  local buff = OnePlayerBuff(opponent)
  for i=1,2 do
    if opponent.field[i] and pred.follower(opponent.field[i]) then
      buff[i] = {sta={"-",2}}
    end
  end
  buff:apply()
end,

-- event
[200321] = function(player, opponent, my_idx, my_card)
  local target_size = 10-player:field_size()
  local func = function(card) return card.size == target_size end
  local target = opponent:field_idxs_with_preds(func)[1]
  if target then
    if pred.follower(opponent.field[target]) then
      OneBuff(opponent, target, {atk={"-",2},sta={"-",2}}):apply()
    end
    if opponent.field[target] then
      opponent:field_to_top_deck(target)
    end
  end
end,

--[[
Enrollment
A random allied Follower gets ATK+1/STA+1
If there are any active cards on the enemy Field and no cards on the enemy Field with the same name, this card remains active on your Field.
]]
[200322] = function(player, opponent, my_idx, my_card)
  local idx = uniformly(player:field_idxs_with_preds(pred.follower))
  if idx then
    OneBuff(player, idx, {atk={"+",1},sta={"+",1}}):apply()
  end
  local check1 = #opponent:field_idxs_with_preds(pred.active) > 0
  local check2 = #opponent:field_idxs_with_preds(function(card) return card.name == my_card.name end) == 0
  if check1 and check2 then
    my_card.active = true
    player.send_spell_to_grave = false
  end
end,

--[[
Meeting the Chair
Two enemy Followers get -1 ATK/-1 STA
If their remaining STA is even, they get another -2 ATK/-2 STA
]]
[200323] = function(player, opponent)
  local idxs = shuffle(opponent:field_idxs_with_preds(pred.follower))
  local buff = OnePlayerBuff(opponent)
  for i=1,min(2,#idxs) do
    buff[idxs[i]] = {atk={"-",1},sta={"-",1}}
  end
  buff:apply()
  local buff2 = OnePlayerBuff(opponent)
  for i=1,min(2,#idxs) do
    if opponent.field[idxs[i]] and opponent.field[idxs[i]].sta % 2 == 0 then
      buff2[idxs[i]] = {atk={"-",2},sta={"-",2}}
    end
  end
  buff2:apply()
end,

--[[
Personal Investigation
For each allied Lady Follower, the first Follower in the enemy Deck is sent to their hand
If at least 3 cards are sent, a random enemy card is sent to the top of their deck
]]
[200324] = function(player, opponent)
  local mag = #player:field_idxs_with_preds(pred.follower, pred.lady)
  local count = 0
  local idxs = opponent:deck_idxs_with_preds(pred.follower)
  for i=1,min(mag,#idxs) do
    if #opponent.hand < 5 then
      opponent:deck_to_hand(idxs[i])
      count = count + 1
    end
  end
  if count < 3 then
    return
  end
  local idx = uniformly(opponent:field_idxs_with_preds())
  if idx then
    opponent:field_to_top_deck(idx)
  end
end,

--[[
Warning
All enemy Followers get ATK-/STA- equal to empty Slots in your Hand
All cards in both Hands are sent to the bottom of the Decks
]]
[200325] = function(player, opponent)
  local mag = 5 - #player.hand
  local idxs = opponent:field_idxs_with_preds(pred.follower)
  local buff = OnePlayerBuff(opponent)
  for _,idx in ipairs(idxs) do
    buff[idx] = {atk={"-",mag},sta={"-",mag}}
  end
  buff:apply()
  for i=1,#player.hand do
    player:hand_to_bottom_deck(1)
  end
  for i=1,#opponent.hand do
    opponent:hand_to_bottom_deck(1)
  end
end,

--[[
Crossing Sanctuary
If you have Crux Character and this card's SIZE is 1, this card gets SIZE=2 and is sent to the enemy Field and deactivated
If this card's SIZE is 2, it gets SIZE=1 and is sent to the enemy Field
]]
[200326] = function(player, opponent, my_idx, my_card)
  if pred.C(player.character) and my_card.size == 1 then
    local new_idx = opponent:first_empty_field_slot()
    if not new_idx then
      return
    end
    my_card.active = false
    player.field[my_idx], opponent.field[new_idx] = nil, my_card
    OneBuff(opponent, new_idx, {size={"=",2}}):apply()
  elseif my_card.size == 2 then
    local new_idx = opponent:first_empty_field_slot()
    if not new_idx then
      return
    end
    my_card.active = false
    player.field[my_idx], opponent.field[new_idx] = nil, my_card
    OneBuff(opponent, new_idx, {size={"=",1}}):apply()
  end
end,

--[[
Holy Researcher
The first Follower in your Hand is sent to the Grave
The Follower in your Field with the lowest STA gets STA changed equal to the sent Follower's STA
]]
[200327] = function(player)
  local idx = player:hand_idxs_with_preds(pred.follower)[1]
  if not idx then
    return
  end
  local mag = player.hand[idx].sta
  player:hand_to_grave(idx)
  idx = player:field_idxs_with_least_and_preds(pred.sta, pred.follower)[1]
  if idx then
    OneBuff(player, idx, {sta={"=",mag}}):apply()
  end
end,

-- Sanctuary Returnee
[200328] = function(player, opponent)
  local op_idx = opponent:field_idxs_with_preds(pred.follower)[1]
  if not op_idx then
    return
  end
  local mag = opponent.field[op_idx].atk
  local buff = OnePlayerBuff(player)
  local idxs = shuffle(player:field_idxs_with_preds(pred.follower, pred.C))
  for i=1,min(2,#idxs) do
    buff[idxs[i]] = {sta={"+",mag}}
  end
  buff:apply()
end,

--[[
Mystic Tutor
All cards in both Fields except for this card and the first Follower in your Field get SIZE -1
The first Follower in your Field gets ATK/STA increased by the total SIZE reduction
]]
[200329] = function(player, opponent, my_idx, my_card)
  local tar_idx = player:field_idxs_with_preds(pred.follower)[1]
  --If I recall correctly, it downsizes everyone even if you have no Follower to buff
  local mag = 0
  local buff = GlobalBuff(player)
  local idxs = player:field_idxs_with_preds()
  for _,idx in ipairs(idxs) do
    if idx ~= tar_idx and idx ~= my_idx then
      if player.field[idx].size > 1 then
        mag = mag + 1
      end
      buff.field[player][idx] = {size={"-",1}}
    end
  end
  idxs = opponent:field_idxs_with_preds()
  for _,idx in ipairs(idxs) do
    if opponent.field[idx].size > 1 then
      mag = mag + 1
    end
    buff.field[opponent][idx] = {size={"-",1}}
  end
  buff:apply()
  if tar_idx then
     OneBuff(player, tar_idx, {atk={"+",mag},sta={"+",mag}}):apply()
  end
end,

--[[
Comrades
If the total SIZE of all Followers in your Field is greater than the total SIZE of all Followers in the enemy Field,
a random Follower in the enemy Field gets ATK/DEF/SIZE halved (rounding up).
]]
[200330] = function(player, opponent)
  local my_size = 0
  local op_size = 0
  local my_idxs = player:field_idxs_with_preds(pred.follower)
  local op_idxs = opponent:field_idxs_with_preds(pred.follower)
  for i=1,5 do
    if my_idxs[i] then
      my_size = my_size + player.field[my_idxs[i]].size
    end
    if op_idxs[i] then
      op_size = op_size + opponent.field[op_idxs[i]].size
    end
  end
  if my_size > op_size then
    local op_idx = uniformly(op_idxs)
    if op_idx then
      local op_card = opponent.field[op_idx]
      OneBuff(opponent, op_idx, {atk={"=",floor(op_card.atk / 2)},def={"=",floor(op_card.def / 2)},
        sta={"=",floor(op_card.sta / 2)}}):apply()
    end
  end
end,

--[[
Forgotten God's Ritual
If there is an enemy Spell, the first Follower in your Deck is sent to the field and gets ATK+ 4/STA +4
If the Follower is not the same faction as your Character, it gets SIZE- 1
]]
[200331] = function(player, opponent)
  local check = opponent:field_idxs_with_preds(pred.spell)[1]
  if not check then
    return
  end
  local idx = player:deck_idxs_with_preds(pred.follower)[1]
  local new_idx = player:first_empty_field_slot()
  if not idx or not new_idx then
    return
  end
  player:deck_to_field(idx)
  if player.field[new_idx].faction ~= player.character.faction then
    OneBuff(player, new_idx, {size={"-",1},atk={"+",4},sta={"+",4}}):apply()
  else
    OneBuff(player, new_idx, {atk={"+",4},sta={"+",4}}):apply()
  end
end,

--[[
Musiciter Mentor
All cards in your Hand/Deck with SIZE= 10 are sent to the bottom of your Deck
For each card sent, a random enemy card is sent to the top of their Deck and all allied
  Followers get STA+ 1
All allied Followers are deactivated
]]
[200332] = function(player, opponent)
  local mag = 0
  local idxs = player:deck_idxs_with_preds(function(card) return card.size == 10 end)
  for i=1,#idxs do
    player:deck_to_bottom_deck(idxs[i])
    mag = mag + 1
  end
  idxs = reverse(player:hand_idxs_with_preds(function(card) return card.size == 10 end))
  for i=1,#idxs do
    player:hand_to_bottom_deck(idxs[i])
    mag = mag + 1
  end
  idxs = shuffle(opponent:field_idxs_with_preds())
  for i=1,min(mag,#idxs) do
    opponent:field_to_top_deck(idxs[i])
  end
  local buff = OnePlayerBuff(player)
  idxs = player:field_idxs_with_preds(pred.follower)
  for _,idx in ipairs(idxs) do
    buff[idx] = {sta={"+",mag}}
    player.field[idx].active = false
  end
  buff:apply()
end,

-- forbidden book
[200333] = function(player, opponent, my_idx, my_card)
  if #opponent.hand > 0 then
    for i=1,2 do
      if #opponent.hand < 5 and #opponent.deck > 0 then
        local card = opponent.deck[#opponent.deck]
        card.size = card.size + 1
        opponent:draw_a_card()
      end
    end
  end
end,

-- endless appetite
[200334] = function(player, opponent, my_idx, my_card)
  for _,p in ipairs({player, opponent}) do
    local targets = p:field_idxs_with_preds(pred.follower,
        function(card) return card.size ~= 1 end)
    for _,idx in ipairs(targets) do
      p.field[idx].active = false
    end
    targets = p:field_idxs_with_preds(pred.follower,
        function(card) return card.size == 5 end)
    for _,idx in ipairs(targets) do
      p:destroy(idx)
    end
  end
end,

-- knight selection
[200335] = function(player, opponent, my_idx, my_card)
  for _,p in ipairs({player, opponent}) do
    local targets = p:field_idxs_with_preds(pred.neg(pred.knight))
    for _,idx in ipairs(targets) do
      p.field[idx].size = p.field[idx].size + 3
    end
  end
end,

--[[
Nom Nom Nom
The first Spell in your Deck is sent to the Field
If the Spell's SIZE is odd, it is sent to the Grave
The first Spell in the enemy Deck is sent to the Field
If the Spell's SIZE is odd, it is sent to the Grave
]]
[200336] = function(player, opponent)
  local pl_idx = player:deck_idxs_with_preds(pred.spell)[1]
  local pl_new_idx = player:first_empty_field_slot()
  if pl_idx and pl_new_idx then
    player:deck_to_field(pl_idx)
    if player.field[pl_new_idx].size % 2 == 1 then
      player:field_to_grave(pl_new_idx)
    end
  end
  local op_idx = opponent:deck_idxs_with_preds(pred.spell)[1]
  local op_new_idx = opponent:first_empty_field_slot()
  if op_idx and op_new_idx then
    opponent:deck_to_field(op_idx)
    if opponent.field[op_new_idx].size % 2 == 1 then
      opponent:field_to_grave(op_new_idx)
    end
  end
end,

--[[
Final Decision
The first allied Follower and a random enemy Follower with a SIZE
less than or equal to twice the allied SIZE both have their ATK/STA
set equal to half (rounding down) the sum of both Followers' ATK/STA.
]]
[200337] = function(player, opponent)
  local pl_idx = player:field_idxs_with_preds(pred.follower)[1]
  if not pl_idx then
    return
  end
  local pl_card = player.field[pl_idx]
  local op_idx = uniformly(opponent:field_idxs_with_preds({pred.follower,
      function(card) return card.size <= pl_card.size * 2 end}))
  if not op_idx then
    return
  end
  local op_card = opponent.field[op_idx]
  local a_mag = floor((pl_card.atk + op_card.atk) / 2)
  local s_mag = floor((pl_card.sta + op_card.sta) / 2)
  local buff = GlobalBuff(player)
  buff.field[player][pl_idx] = {atk={"=",a_mag},sta={"=",s_mag}}
  buff.field[opponent][op_idx] = {atk={"=",a_mag},sta={"=",s_mag}}
  buff:apply()
end,

--[[
Petrification Curse
If you have a Vita Character, all Followers with a SIZE < this card's SIZE are exiled
If this card's SIZE >= 6, this card is exiled
Otherwise, this card gets SIZE+ 2 and is sent to the top of your Deck
]]
[200338] = function(player, opponent, my_idx, my_card)
  if not pred.V(player.character) then
    return
  end
  local idxs = player:field_idxs_with_preds(pred.follower,
      function(card) return card.size < my_card.size end)
  for _,idx in ipairs(idxs) do
    player:field_to_exile(idx)
  end
  idxs = opponent:field_idxs_with_preds(pred.follower,
      function(card) return card.size < my_card.size end)
  for _,idx in ipairs(idxs) do
    opponent:field_to_exile(idx)
  end
  if my_card.size >= 6 then
    player:field_to_exile(my_idx)
  else
    my_card.size = my_card.size + 2
    player:field_to_top_deck(my_idx)
  end
end,

--[[
Mass Polymorph
All cards have their SIZE randomly redistributed.
]]
[200339] = function(player, opponent, my_idx, my_card)
  local card_locations = {}
  local sizes = {}
  for i=1,5 do
    for _,p in ipairs({player, opponent}) do
      if p.field[i] and p.field[i] ~= my_card then
        card_locations[#card_locations+1] = {p, i}
        sizes[#sizes+1] = p.field[i].size
      end
    end
  end
  sizes = tinymaids(sizes)
  local buff = GlobalBuff(player)
  for i=1,#card_locations do
    local p, idx = card_locations[i][1], card_locations[i][2]
    buff.field[p][idx] = {size={"=",sizes[i]}}
  end
  buff:apply()
end,

--[[
Appointment
Check the top 5 cards of your Deck
2 random allied Followers get ATK+ the number of Followers and STA+ the number of Spells
]]
[200340] = function(player)
  local atk_m = 0
  local sta_m = 0
  for i=1,min(5,#player.deck) do
    if pred.follower(player.deck[#player.deck + 1 - i]) then
      atk_m = atk_m + 1
    else
      sta_m = sta_m + 1
    end
  end
  local idxs = shuffle(player:field_idxs_with_preds(pred.follower))
  local buff = OnePlayerBuff(player)
  for i=1,min(2,#idxs) do
    buff[idxs[i]] = {atk={"+",atk_m},sta={"+",sta_m}}
  end
  buff:apply()
end,

--[[
Chair's Conspiracy
If you have an Academy Character and the enemy has more Spells than Followers,
a random enemy Follower is sent to the Grave and the enemy Character loses Life equal to double its Size
]]
[200341] = function(player, opponent)
  local f_count = #opponent:field_idxs_with_preds(pred.follower)
  local s_count = #opponent:field_idxs_with_preds(pred.spell)
  if not pred.A(player.character) or s_count < f_count then
    return
  end
  local op_idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if not op_idx then
    return
  end
  local mag = min(10, opponent.field[op_idx].size * 2)
  opponent:field_to_grave(op_idx)
  OneBuff(opponent, 0, {life={"-",mag}}):apply()
end,

--[[
Excavation
If you have a Follower, a random enemy Follower gets SIZE+ 1/ATK- 1 happens x times where x is
the difference in the number of cards in your and the enemy Fields
]]
[200342] = function(player, opponent)
  if not player:field_idxs_with_preds(pred.follower)[1] then
    return
  end
  local mag = abs(player:ncards_in_field() - opponent:ncards_in_field())
  for i=1,mag do
    local op_idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
    if op_idx then
      OneBuff(opponent, op_idx, {size={"+",1},atk={"-",1}}):apply()
    end
  end
end,

--[[
Armor Break
The allied Follower with the lowest STA is destroyed
If your LIFE is less than the enemy LIFE, Follower's SIZE / 2 random enemy Followers are sent to the Grave
]]
[200343] = function(player, opponent)
  local pl_idx = player:field_idxs_with_least_and_preds(pred.sta, pred.follower)[1]
  if not pl_idx then
    return
  end
  local mag = floor(player.field[pl_idx].size / 2)
  player:destroy(pl_idx)
  if player.character.life >= opponent.character.life then
    return
  end
  local op_idxs = shuffle(opponent:field_idxs_with_preds(pred.follower))
  for i=1,min(mag,#op_idxs) do
    opponent:field_to_grave(op_idxs[i])
  end
end,

--[[
Understanding
All enemy cards with odd SIZE and all non-Crux allied cards are sent to the Grave
]]
[200344] = function(player, opponent)
  for i=1,5 do
    if opponent.field[i] and opponent.field[i].size % 2 == 1 then
      opponent:field_to_grave(i)
    end
    if player.field[i] and player.field[i].faction ~= "C" then
      player:field_to_grave(i)
    end
  end
end,

--[[
Scout's Attitude
The first allied Follower regains its original skills and gets ATK+ 1/STA+ 1
]]
[200345] = function(player)
  local idx = player:field_idxs_with_preds(pred.follower)[1]
  if not idx then
    return
  end
  local card = player.field[idx]
  OneBuff(player, idx, {atk={"+",1},sta={"+",1}}):apply()
  card:refresh()
end,

--[[
Shaman's Prayer
2 random allied Darklore Followers get ATK + total DEF of all enemy Followers and
STA - total DEF of all enemy Followers / 2 rounded up + 1
]]
[200346] = function(player, opponent)
  local mag = 0
  local idxs = opponent:field_idxs_with_preds(pred.follower)
  for _,idx in ipairs(idxs) do
    mag = mag + opponent.field[idx].def
  end
  idxs = player:field_idxs_with_preds(pred.follower, pred.faction.D)
  local buff = OnePlayerBuff(player)
  for i=1,min(2,#idxs) do
    buff[idxs[i]] = {atk={"+",mag},sta={"-",ceil(mag/2)-1}}
  end
  buff:apply()
end,

-- dark sword refinement
[200347] = function(player, opponent, my_idx, my_card)
  if pred.D(player.character) then
    player.shuffles = player.shuffles + 5
    local target = uniformly(player:field_idxs_with_preds(pred.follower))
    if target then
      local amt = opponent.shuffles
      OneBuff(player, target,
          {atk={"-",amt},def={"-",amt},sta={"-",amt}}):apply()
      opponent.shuffles = max(opponent.shuffles - 1, 0)
    end
  end
  player.field[my_idx] = nil
end,

-- sage's counsel
[200348] = function(player, opponent, my_idx, my_card)
  local targets = shuffle(player:field_idxs_with_preds(pred.follower))
  local buff = OnePlayerBuff(player)
  for i=1,2 do
    if targets[i] then
      buff[targets[i]] = {atk={"+",3},sta={"+",3}}
    end
  end
  buff:apply()
end,

--[[
Lucky Coin
No effect
]]
[200349] = function()
end,

-- obstinance
[200350] = function(player, opponent, my_idx, my_card)
  local targets = opponent:field_idxs_with_preds()
  for _,idx in ipairs(targets) do
    opponent.field[idx].size = 4
  end
end,

--[[
Nether Visitor
All allied Followers in Field/Hand/Deck get ATK +1/STA +1
You get LIFE +1 and Shuffle +1
All enemy Followers in Field/Hand/Deck get ATK -1/STA -1
]]
[200351] = function(player, opponent, my_idx)
  local buff = GlobalBuff(player)
  local idxs = player:field_idxs_with_preds(pred.follower)
  for _,idx in ipairs(idxs) do
    buff.field[player][idx] = {atk={"+",1},sta={"+",1}}
  end
  idxs = player:hand_idxs_with_preds(pred.follower)
  for _,idx in ipairs(idxs) do
    buff.hand[player][idx] = {atk={"+",1},sta={"+",1}}
  end
  idxs = player:deck_idxs_with_preds(pred.follower)
  for _,idx in ipairs(idxs) do
    buff.deck[player][idx] = {atk={"+",1},sta={"+",1}}
  end
  idxs = opponent:field_idxs_with_preds(pred.follower)
  for _,idx in ipairs(idxs) do
    buff.field[opponent][idx] = {atk={"-",1},sta={"-",1}}
  end
  idxs = opponent:hand_idxs_with_preds(pred.follower)
  for _,idx in ipairs(idxs) do
    buff.hand[opponent][idx] = {atk={"-",1},sta={"-",1}}
  end
  idxs = opponent:deck_idxs_with_preds(pred.follower)
  for _,idx in ipairs(idxs) do
    buff.deck[opponent][idx] = {atk={"-",1},sta={"-",1}}
  end
  buff.field[player][0] = {life={"+",1}}
  buff:apply()
  player.shuffles = player.shuffles + 1
  player:field_to_exile(my_idx)
end,

--[[
Message
All cards in your Grave with the same name as the first card on your Field that is not this card
  are sent to the top of your Deck
This card is exiled
]]
[200352] = function(player, opponent, my_idx, my_card)
  local idx = player:field_idxs_with_preds(
      function(card) return card ~= my_card end)[1]
  if not idx then
    player:field_to_exile(my_idx)
    return
  end
  local name = player.field[idx].name
  local idxs = player:grave_idxs_with_preds(function(card) return card.name == name end)
  for _,idx in ipairs(idxs) do
    player:grave_to_top_deck(idx)
  end
  player:field_to_exile(my_idx)
end,

--[[
4 Messages
2 random allied Followers get SIZE =4
All Followers whose SIZE was increased get ATK+/DEF+/STA+ the difference
]]
[200353] = function(player)
  local idxs = shuffle(player:field_idxs_with_preds(pred.follower))
  local buff = OnePlayerBuff(player)
  for i=1,min(2,#idxs) do
    local mag = max(4 - player.field[idxs[i]].size, 0)
    buff[idxs[i]] = {size={"=",4},atk={"+",mag},def={"+",mag},sta={"+",mag}}
  end
  buff:apply()
end,

--[[
Organization Failure
All enemy cards except the first and last are sent to the Grave
]]
[200354] = function(player, opponent)
  local idxs = opponent:field_idxs_with_preds()
  for i=2,#idxs - 1 do
    opponent:field_to_grave(idxs[i])
  end
end,

--[[
Take a Break
The first enemy card with SIZE >= 6 is moved to your field and deactivated
This card is removed from the game
]]
[200355] = function(player, opponent, my_idx)
  local pl_idx = player:first_empty_field_slot()
  local op_idx = opponent:field_idxs_with_preds(function(card) return card.size >= 6 end)[1]
  if not pl_idx or not op_idx then
    player:field_to_exile(my_idx)
    return
  end
  player.field[pl_idx], opponent.field[op_idx] = opponent.field[op_idx], nil
  player.field[pl_idx].active = false
  player:field_to_exile(my_idx)
end,

--[[
Fairy Borrowers
The first enemy card with DEF + SIZE = 5 is destroyed
You get LIFE - half the card's DEF
]]
[200356] = function(player, opponent)
  local idx = opponent:field_idxs_with_preds(function(card)
      return pred.follower(card) and card.def + card.size == 5 end)[1]
  if idx then
    opponent:field_to_grave(idx)
  end
end,

--[[
Musiciter Appears!
The first 10 cards of each Deck are sent to the Grave
If that happens, 10 random cards that are not this card's type are sent from the Grave
  to the bottom of your deck
10 random cards are sent from the enemy Grave to the bottom of their Deck
This card is exiled
]]
[200357] = function(player, opponent, my_idx, my_card)
  local check = false
  for i=1,10 do
    if player.deck[1] then
      player:deck_to_grave(#player.deck)
      check = true
    end
    if opponent.deck[1] then
      opponent:deck_to_grave(#opponent.deck)
      check = true
    end
  end
  if not check then
    player:field_to_exile(my_idx)
    return
  end
  for i=1,10 do
    local idx = uniformly(player:grave_idxs_with_preds(function(card)
        return card.name ~= my_card.name end))
    if idx and player.grave[idx].name ~= my_card.name then
      player:grave_to_bottom_deck(idx)
    end
  end
  for i=1,10 do
    local idx = uniformly(opponent:grave_idxs_with_preds())
    if idx then
      opponent:grave_to_bottom_deck(idx)
    end
  end
  player:field_to_exile(my_idx)
end,

-- sanctuary trip
[200358] = function(player, opponent, my_idx, my_card)
  if my_card.size > 3 then
    my_card.size = 3
  end
  OneBuff(player, 0, {life={"+", my_card.size}}):apply()
  if my_card.size > 1 then
    player.send_spell_to_grave = false
    my_card.size = 1
    my_card.active = false
  end
end,

--[[
Kinship
If all cards in your Hand/Field other than this shares your Character's faction, 2 random
enemy Followers get ATK-/DEF- equal to the number of cards in your Hand/Field / 2
]]
[200359] = function(player, opponent, my_idx, my_card)
  local pred_filter = function(card) return card ~= my_card and card.faction ~= player.character.faction end
  if #player:field_idxs_with_preds(pred_filter) ~= 0 or #player:hand_idxs_with_preds(pred_filter) ~= 0 then
    return
  end
  local mag = floor((#player:field_idxs_with_preds() + #player.hand) / 2)
  local idxs = shuffle(opponent:field_idxs_with_preds(pred.follower))
  local buff = OnePlayerBuff(opponent)
  for i = 1, 2 do
    if idxs[i] then
      buff[idxs[i]] = {atk={"-",mag}, def={"-",mag}}
    end
  end
  buff:apply()
end,

--[[
Sudden News
If the enemy Hand has a Spell, all enemy Followers get ATK-4/STA-4.
Otherwise, all allied Followers get ATK-2/STA-2
]]
[200360] = function(player, opponent)
  local check = opponent:hand_idxs_with_preds(pred.spell)[1]
  if check then
    local buff = OnePlayerBuff(opponent)
    local idxs = opponent:field_idxs_with_preds(pred.follower)
    for _,idx in ipairs(idxs) do
      buff[idx] = {atk={"-",4},sta={"-",4}}
    end
    buff:apply()
  else
    local buff = OnePlayerBuff(player)
    local idxs = player:field_idxs_with_preds(pred.follower)
    for _,idx in ipairs(idxs) do
      buff[idx] = {atk={"-", 2}, sta={"-", 2}}
    end
    buff:apply()
  end
end,

--[[
Lonely Operation
All allied GS, Aletheian, and Apostle Followers get ATK+3
]]
[200361] = function(player)
  local idxs = player:field_idxs_with_preds(pred.follower,
      pred.union(pred.gs, pred.aletheian, pred.apostle))
  local buff = OnePlayerBuff(player)
  for _,idx in ipairs(idxs) do
    buff[idx] = {atk={"+",3}}
  end
  buff:apply()
end,

--[[
Dream Curse
All allied Darklore Followers are deactivated
A random enemy card with SIZE less then or equal to the number of Followers is sent to the bottom
of the Deck if it is a Follower, or sent to the Grave if it is a Spell
]]
[200362] = function(player, opponent)
  local pl_idxs = player:field_idxs_with_preds(pred.follower, pred.D)
  local mag = 0
  for _,idx in ipairs(pl_idxs) do
    player.field[idx].active = false
    mag = mag + 1
  end
  local op_idx = uniformly(opponent:field_idxs_with_preds(function(card) return card.size <= mag end))
  if not op_idx then
    return
  end
  if pred.follower(opponent.field[op_idx]) then
    opponent:field_to_bottom_deck(op_idx)
  else
    opponent:field_to_grave(op_idx)
  end
end,

--[[
Ritual's Final Step
The last Follower in your Deck is sent to the Grave
If that happens, a random allied Follower gets SIZE- 1/ATK+ 4/STA+ 4
]]
[200363] = function(player)
  local idx = reverse(player:deck_idxs_with_preds(pred.follower))[1]
  if not idx then
    return
  end
  player:deck_to_grave(idx)
  idx = uniformly(player:field_idxs_with_preds(pred.follower))
  if idx then
    OneBuff(player, idx, {size={"-",1},atk={"+",4},sta={"+",4}}):apply()
  end
end,

--[[
Nether Cafe
Exile the first card in your Hand
If that happens, destroy a random enemy Follower
]]
[200364] = function(player, opponent)
  if player.hand[1] then
    player:hand_to_exile(1)
    local idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
    if idx then
      opponent:destroy(idx)
    end
  end
end,

--[[
Think Twice Seal
]]
[200365] = function(player, opponent)
  local idxs = shuffle(opponent:field_idxs_with_preds(pred.follower))
  local buff = OnePlayerBuff(opponent)
  for i=1,min(2,#idxs) do
    local idx = idxs[i]
    buff[idx] = {}
    local orig = Card(opponent.field[idx].id, opponent.field[idx].upgrade_lvl)
    for _,attr in ipairs({"atk","def","sta"}) do
      if opponent.field[idx][attr] > orig[attr] then
        buff[idx][attr] = {"=", orig[attr]}
      end
    end
  end
  buff:apply()
end,

-- time spiral
[200366] = function(player, opponent, my_idx, my_card)
  local targets = opponent:field_idxs_with_preds(pred.follower)
  local buff = OnePlayerBuff(opponent)
  for _,idx in ipairs(targets) do
    buff[idx] = {}
    local orig = Card(opponent.field[idx].id, opponent.field[idx].upgrade_lvl)
    for _,attr in ipairs({"atk","def","sta"}) do
      if opponent.field[idx][attr] > orig[attr] then
        buff[idx][attr] = {"-", 2*(opponent.field[idx][attr] - orig[attr])}
      end
    end
  end
  buff:apply()
end,

--[[
Vacation Plans
The first Follower in the enemy hand is changed into Game Starter
]]
[200367] = function(player, opponent)
  local idx = opponent:hand_idxs_with_preds(pred.follower)[1]
  if idx then
    opponent.hand[idx] = Card(300236)
  end
end,

--[[
Inspiration
All cards in your Hand are sent to the bottom of your Deck
The first 2 Spells and first 2 Followers are sent from your Deck to your Hand
]]
[200368] = function(player)
  while player.hand[1] do
    player:hand_to_bottom_deck(1)
  end
  local idxs = player:deck_idxs_with_preds(pred.follower)
  for i=1,min(2,#idxs) do
    player:deck_to_hand(idxs[i])
  end
  idxs = player:deck_idxs_with_preds(pred.spell)
  for i=1,min(2,#idxs) do
    player:deck_to_hand(idxs[i])
  end
end,

--[[
!!!!
2 random allied non-Student Council/non-Lib Vita Followers get effects depending on the coin flip
Heads: ATK+ 3/DEF+ 1/STA+ 1
Tails: ATK+ 1/DEF+ 1/STA+ 3
]]
[200369] = function(player)
  local slot_buff = {atk={"+",1},def={"+",1},sta={"+",3}}
  if player.won_flip then
    slot_buff = {atk={"+",3},def={"+",1},sta={"+",1}}
  end
  local idxs = shuffle(player:field_idxs_with_preds({pred.follower, pred.neg(pred.student_council),
      pred.neg(pred.library_club), pred.V}))
  local buff = OnePlayerBuff(player)
  for i=1,min(2,#idxs) do
    buff[idxs[i]] = slot_buff
  end
  buff:apply()
end,

--[[
Preference
The first 3 cards other than this card in your Field/Hand/Deck that share your Character's faction
  and have SIZE > 1 get SIZE- 1
]]
[200370] = function(player, opponent, my_idx, my_card)
  local pred_size = function(card) return card.size > 1 end
  local pred_fact = function(card) return card.faction == player.character.faction end
  local f_idxs = player:field_idxs_with_preds(pred_size, pred_fact,
      function(card) return card ~= my_card end)
  local h_idxs = player:hand_idxs_with_preds(pred_size, pred_fact)
  local d_idxs = player:deck_idxs_with_preds(pred_size, pred_fact)
  local buff = GlobalBuff(player)
  for i=1,3 do
    if f_idxs[i] then
      buff.field[player][f_idxs[i]] = {size={"-",1}}
    end
    if h_idxs[i] then
      buff.hand[player][h_idxs[i]] = {size={"-",1}}
    end
    if d_idxs[i] then
      buff.deck[player][d_idxs[i]] = {size={"-",1}}
    end
  end
  buff:apply()
end,

--[[
Lady's Dinner
If you have a card with SIZE >= 6 on the Field, 2 random enemy Followers get ATK-2/STA-4
Otherwise, they get ATK-1/STA-2
]]
[200371] = function(player, opponent)
  local check = player:field_idxs_with_preds(function(card) return card.size >= 6 end)[1]
  local mag = check and {atk={"-",2},sta={"-",4}} or {atk={"-",1},sta={"-",2}}
  local buff = OnePlayerBuff(opponent)
  local idxs = shuffle(opponent:field_idxs_with_preds(pred.follower))
  for i=1,min(2,#idxs) do
    buff[idxs[i]] = mag
  end
  buff:apply()
end,

--[[
Eldest Sister's Hobby
2 random allied non-Maid/non-Lady Academy Followers get effects depending on the coin flip
Heads: ATK+ 3/DEF+ 1/STA+ 1
Tails: ATK+ 1/DEF+ 1/STA+ 3
]]
[200372] = function(player)
  local slot_buff = {atk={"+",1},def={"+",1},sta={"+",3}}
  if player.won_flip then
    slot_buff = {atk={"+",3},def={"+",1},sta={"+",1}}
  end
  local idxs = shuffle(player:field_idxs_with_preds(pred.follower, pred.neg(pred.maid),
      pred.neg(pred.lady), pred.A))
  local buff = OnePlayerBuff(player)
  for i=1,min(2,#idxs) do
    buff[idxs[i]] = slot_buff
  end
  buff:apply()
end,

--[[
Triforce Ready
]]
[200373] = function(player)
  local idxs = player:field_idxs_with_preds(pred.follower,
      function(card) return card.faction == player.character.faction end)
  local buff = OnePlayerBuff(player)
  for _,idx in ipairs(idxs) do
    buff[idx] = {}
    local orig = Card(player.field[idx].id, player.field[idx].upgrade_lvl)
    for _,attr in ipairs({"atk","def","sta"}) do
      if player.field[idx][attr] < orig[attr] then
        buff[idx][attr] = {"=", orig[attr]}
      end
      player.field[idx]:refresh()
    end
  end
  buff:apply()
end,

--[[
Strength of Determination
2 random allied Crux Followers with DEF >= 1 get ATK + their DEF * 4/DEF - their DEF * 2
]]
[200374] = function(player)
  local idxs = shuffle(player:field_idxs_with_preds(pred.follower, pred.C,
      function(card) return card.def >= 1 end))
  local buff = OnePlayerBuff(player)
  for i=1,min(2,#idxs) do
    local card = player.field[idxs[i]]
    buff[idxs[i]] = {atk={"+",card.def * 4},def={"-",card.def * 2}}
  end
  buff:apply()
end,

--[[
Rumor
2 random allied non-Student Council/non-Lib Vita Followers get effects depending on the coin flip
Heads: ATK+ 3/DEF+ 1/STA+ 1
Tails: ATK+ 1/DEF+ 1/STA+ 3
]]
[200375] = function(player)
  local slot_buff = {atk={"+",1},def={"+",1},sta={"+",3}}
  if player.won_flip then
    slot_buff = {atk={"+",3},def={"+",1},sta={"+",1}}
  end
  local idxs = shuffle(player:field_idxs_with_preds(pred.follower, pred.neg(pred.knight),
      pred.neg(pred.seeker), pred.C))
  local buff = OnePlayerBuff(player)
  for i=1,min(2,#idxs) do
    buff[idxs[i]] = slot_buff
  end
  buff:apply()
end,

--[[
Dignity
x = number of allied Crux Followers
x random enemy Followers get ATK/DEF/STA / (x + 1) rounding down
]]
[200376] = function(player, opponent)
  local mag = #player:field_idxs_with_preds(pred.follower, pred.faction.C)
  local idxs = opponent:field_idxs_with_preds(pred.follower)
  local buff = OnePlayerBuff(opponent)
  for i=1,min(mag,#idxs) do
    local card = opponent.field[idxs[i]]
    buff[idxs[i]] = {atk={"=",floor(card.atk / (mag + 1))},def={"=",floor(card.def / (mag + 1))},
        sta={"=",floor(card.sta / (mag + 1))}}
  end
  buff:apply()
end,

--[[
She who stands at the top
If your Shuffles >= 1, then all Followers in your Field/Hand get ATK +2/STA +2
]]
[200377] = function(player)
  if player.shuffles < 1 then
    return
  end
  player.shuffles = player.shuffles - 1
  local buff = GlobalBuff(player)
  local idxs = player:field_idxs_with_preds(pred.follower)
  for _,idx in ipairs(idxs) do
    buff.field[player][idx] = {atk={"+",2},sta={"+",2}}
  end
  idxs = player:hand_idxs_with_preds(pred.follower)
  for _,idx in ipairs(idxs) do
    buff.hand[player][idx] = {atk={"+",2},sta={"+",2}}
  end
  buff:apply()
end,

--[[
Iri's Nursing
2 random allied non-Witch/non-GS Darklore Followers get effects depending on the coin flip
Heads: ATK+ 3/DEF+ 1/STA+ 1
Tails: ATK+ 1/DEF+ 1/STA+ 3
]]
[200378] = function(player)
  local slot_buff = {atk={"+",1},def={"+",1},sta={"+",3}}
  if player.won_flip then
    slot_buff = {atk={"+",3},def={"+",1},sta={"+",1}}
  end
  local idxs = shuffle(player:field_idxs_with_preds(pred.follower, pred.neg(pred.witch),
      pred.neg(pred.gs), pred.D))
  local buff = OnePlayerBuff(player)
  for i=1,min(2,#idxs) do
    buff[idxs[i]] = slot_buff
  end
  buff:apply()
end,

--[[
Phone Chance
Good Job is created on the top and bottom of the enemy Deck
If you have a Darklore Character, two Good Job is created in the enemy Field
The second Good Job is deactivated
]]
[200379] = function(player, opponent)
  opponent:to_top_deck(Card(200069))
  opponent:to_bottom_deck(Card(200069))
  if not pred.D(player.character) then
    return
  end
  local idx = opponent:first_empty_field_slot()
  if not idx then
    return
  end
  opponent.field[idx] = Card(200069)
  idx = opponent:first_empty_field_slot()
  if idx then
    opponent.field[idx] = Card(200069)
    opponent.field[idx].active = false
  end
end,

--[[
Blissful Moment
2 random allied Followers get ATK +2/STA +2
]]
[200380] = function(player)
  local idxs = shuffle(player:field_idxs_with_preds(pred.follower))
  local buff = OnePlayerBuff(player)
  for i=1,min(2,#idxs) do
    buff[idxs[i]] = {atk={"+",2},sta={"+",2}}
  end
  buff:apply()
end,

--[[
Twisted Memory
The first Follower in the enemy Hand loses its skills, then that Follower and a random enemy Follower
  swap skills
]]
[200381] = function(player, opponent)
  local h_idx = opponent:hand_idxs_with_preds(pred.follower)[1]
  if not h_idx then
    return
  end
  opponent.hand[h_idx].skills = {}
  local f_idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if not f_idx then
    return
  end
  local h_card = opponent.hand[h_idx]
  local f_card = opponent.field[f_idx]
  OneImpact(opponent, f_idx):apply()
  h_card.skills, f_card.skills = f_card.skills, h_card.skills
end,

--[[
Curse of Atrophy
All Spells in the enemy Hand/Field are changed to the following cards depending on their faction
  and get SIZE=2
  V: "New Student Orientation"
  A: "New Maid Training"
  C: "Close Encounter"
  D: "Blood Reversal"
  N: "Blissful Moment".
]]
[200382] = function(player, opponent)
  local map = {V=200002, A=200012, C=200022, D=200032, N=200380}
  local buff = GlobalBuff(opponent)
  local idxs = opponent:field_idxs_with_preds(pred.spell)
  for _,idx in ipairs(idxs) do
    opponent.field[idx] = Card(map[opponent.field[idx].faction] or
          opponent.field[idx].id)
    buff.field[opponent][idx] = {size={"=",2}}
  end
  idxs = opponent:hand_idxs_with_preds(pred.spell)
  for _,idx in ipairs(idxs) do
    opponent.hand[idx] = Card(map[opponent.hand[idx].faction] or
          opponent.hand[idx].id)
    buff.hand[opponent][idx] = {size={"=",2}}
  end
  buff:apply()
end,

--[[
Asmis's Insight
The enemy gets Shuffles- 1 and LIFE- 1
A random enemy Follower gets ATK- 1/STA- 1
If your Grave has >= 5 cards, a random card is sent from your Grave to the bottom of your Deck
]]
[200383] = function(player, opponent)
  local buff = GlobalBuff(opponent)
  buff.field[opponent][0] = {life={"-",1}}
  local idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if idx then
    buff.field[opponent][idx] = {atk={"-",1},sta={"-",1}}
  end
  buff:apply()
  opponent.shuffles = max(opponent.shuffles - 1, 0)
  if #player.grave < 5 then
    return
  end
  idx = uniformly(player:grave_idxs_with_preds())
  player:grave_to_bottom_deck(idx)
end,

--[[
Messy Business
A random allied Follower is moved to this card's Slot and gets ATK/STA + new Slot number
]]
[200384] = function(player, opponent, my_idx)
  local idx = uniformly(player:field_idxs_with_preds(pred.follower))
  if not idx then
    return
  end
  player.field[my_idx], player.field[idx] = player.field[idx], nil
  OneBuff(player, my_idx, {atk={"+",my_idx},sta={"+",my_idx}}):apply()
end,

--[[
Personal Relationship
]]
[200385] = function(player, opponent)
  local pl_idxs = player:field_idxs_with_preds(pred.follower, pred.V)
  local op_idxs = opponent:field_idxs_with_preds(pred.follower)
  local buff = GlobalBuff(player)
  for i=1,min(2,#pl_idxs) do
    buff.field[player][pl_idxs[i]] = {atk={"+",2},sta={"+",2}}
  end
  if opponent:is_npc() then
    for i=1,min(2,#op_idxs) do
      buff.field[opponent][op_idxs[i]] = {atk={"-",2},sta={"-",2}}
    end
  end
  buff:apply()
end,

--[[
Chance Meeting
2 random allied Followers gain Reorganization
]]
[200386] = function(player)
  local idxs = shuffle(player:field_idxs_with_preds(pred.follower))
  for i=1,min(2,#idxs) do
    if player.field[idxs[i]]:first_empty_skill_slot() then
      player.field[idxs[i]]:gain_skill(1356)
    end
  end
end,

--[[
Secret Room
If you have a Vita Character, all enemy Followers in their Hand/Field/Deck get ATK-/DEF-/STA- 1
A random enemy Follower is sent to the bottom of their Deck
This card is exiled
]]
[200387] = function(player, opponent, my_idx)
  if not pred.faction.V(player.character) then
    return
  end
  local buff = GlobalBuff(opponent)
  for _,idx in ipairs(opponent:field_idxs_with_preds(pred.follower)) do
    buff.field[opponent][idx] = {atk={"-",1},def={"-",1},sta={"-",1}}
  end
  for _,idx in ipairs(opponent:hand_idxs_with_preds(pred.follower)) do
    buff.hand[opponent][idx] = {atk={"-",1},def={"-",1},sta={"-",1}}
  end
  for _,idx in ipairs(opponent:deck_idxs_with_preds(pred.follower)) do
    buff.deck[opponent][idx] = {atk={"-",1},def={"-",1},sta={"-",1}}
  end
  buff:apply()
  local idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if idx then
    opponent:field_to_bottom_deck(idx)
  end
  player:field_to_exile(my_idx)
end,

--[[
Linus's Wrath
A random enemy card is deactivated
If you have an Academy Character, do it again
(can target same follower twice)
]]
[200388] = function(player, opponent)
  for i=1,pred.A(player.character) and 2 or 1 do
    local idx = uniformly(opponent:field_idxs_with_preds())
    if idx then
      OneImpact(opponent, idx):apply()
      opponent.field[idx].active = false
    end
  end
end,

--[[
Myo Clan's Aid
]]
[200389] = function(player, opponent)
  local pl_idxs = player:field_idxs_with_preds(pred.follower, pred.A)
  local op_idxs = opponent:field_idxs_with_preds(pred.follower)
  local buff = GlobalBuff(player)
  for i=1,min(2,#pl_idxs) do
    buff.field[player][pl_idxs[i]] = {atk={"+",2},sta={"+",2}}
  end
  if opponent:is_npc() then
    for i=1,min(2,#op_idxs) do
      buff.field[opponent][op_idxs[i]] = {atk={"-",2},sta={"-",2}}
    end
  end
  buff:apply()
end,

--[[
Messenger
The first 2 cards in the enemy Deck are copied to your Hand
]]
[200390] = function(player, opponent)
  local d = opponent.deck
  for i=1,min(2,#d) do
    if d[#d + 1 - i] and #player.hand < 5 then
      table.insert(player.hand, deepcpy(d[#d + 1 - i]))
    end
  end
end,

--[[
The Maybe Garden
If you have an Academy Character,
  All Spells in the enemy Grave are exiled
  All enemy Spells and one random enemy Follower are deactivated
  All Spells in the enemy Hand and Deck get SIZE+ 1
  This card is exiled
]]
[200391] = function(player, opponent, my_idx)
  if not pred.A(player.character) then
    return
  end
  -- grave exile
  local idxs = opponent:grave_idxs_with_preds(pred.spell)
  for _,idx in ipairs(idxs) do
    opponent:grave_to_exile(idx)
  end
  -- deactivate
  idxs = opponent:field_idxs_with_preds(pred.spell)
  for _,idx in ipairs(idxs) do
    opponent.field[idx].active = false
  end
  local idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if idx then
    opponent.field[idx].active = false
  end
  -- debuff
  local buff = GlobalBuff(opponent)
  idxs = opponent:hand_idxs_with_preds(pred.spell)
  for _,idx in ipairs(idxs) do
    buff.hand[opponent][idx] = {size={"+",1}}
  end
  idxs = opponent:deck_idxs_with_preds(pred.spell)
  for _,idx in ipairs(idxs) do
    buff.deck[opponent][idx] = {size={"+",1}}
  end
  buff:apply()
  -- self exile
  player:field_to_exile(my_idx)
end,

--[[
Sword of Future Sight
2 random allied Followers get ATK+/STA+ 2 + the number of enemy Spells
]]
[200392] = function(player, opponent)
  local mag = 2 + #opponent:field_idxs_with_preds(pred.spell)
  local idxs = shuffle(player:field_idxs_with_preds(pred.follower))
  local buff = OnePlayerBuff(player)
  for i=1,min(2,#idxs) do
    buff[idxs[i]] = {atk={"+",mag},sta={"+",mag}}
  end
  buff:apply()
end,

--[[
No Gain
]]
[200393] = function(player, opponent)
  local pl_idxs = player:field_idxs_with_preds(pred.follower, pred.C)
  local op_idxs = opponent:field_idxs_with_preds(pred.follower)
  local buff = GlobalBuff(player)
  for i=1,min(2,#pl_idxs) do
    buff.field[player][pl_idxs[i]] = {atk={"+",2},sta={"+",2}}
  end
  if opponent:is_npc() then
    for i=1,min(2,#op_idxs) do
      buff.field[opponent][op_idxs[i]] = {atk={"-",2},sta={"-",2}}
    end
  end
  buff:apply()
end,

--[[
Nevermove
If you have a Crux Character
  If the Turn is even, a random allied follower gets ATK+ 5/STA+ 5
  If the Turn is divisible by 3, a random enemy follower gets ATK- 5/STA- 5
]]
[200394] = function(player, opponent)
  if not pred.C(player.character) then
    return
  end
  local buff = GlobalBuff(player)
  local idx = uniformly(player:field_idxs_with_preds(pred.follower))
  if player.game.turn % 2 == 0 and idx then
    buff.field[player][idx] = {atk={"+",5},sta={"+",5}}
  end
  idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if player.game.turn % 3 == 0 and idx then
    buff.field[opponent][idx] = {atk={"-",5},sta={"-",5}}
  end
  buff:apply()
end,

--[[
Sanctuary Door
If you have a Crux Character
  All enemy Followers get STA- 9
  All Followers in the enemy Hand get STA- 3
  All Followers in the enemy Deck get STA- 1
  This card is exiled
]]
[200395] = function(player, opponent)
  if not pred.C(player.character) then
    return
  end
  local buff = GlobalBuff(opponent)
  local idxs = opponent:field_idxs_with_preds(pred.follower)
  for _,idx in ipairs(idxs) do
    buff.field[opponent][idx] = {sta={"-",9}}
  end
  idxs = opponent:hand_idxs_with_preds(pred.follower)
  for _,idx in ipairs(idxs) do
    buff.hand[opponent][idx] = {sta={"-",3}}
  end
  idxs = opponent:deck_idxs_with_preds(pred.follower)
  for _,idx in ipairs(idxs) do
    buff.deck[opponent][idx] = {sta={"-",1}}
  end
  buff:apply()
end,

--[[
Iri and Vernika
]]
[200396] = function(player)
  local mag = 0
  local idx = player:field_idxs_with_preds(pred.follower)[1]
  if not idx then
    return
  end
  local pred_name = function(card) return card.name == player.field[idx].name end
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
  OneBuff(player, idx, {atk={"+",mag},def={"+",ceil(mag/2)},sta={"+",mag}}):apply()
end,

--[[
Iri's Enjoyment
]]
[200397] = function(player, opponent)
  local pl_idxs = player:field_idxs_with_preds(pred.follower, pred.D)
  local op_idxs = opponent:field_idxs_with_preds(pred.follower)
  local buff = GlobalBuff(player)
  for i=1,min(2,#pl_idxs) do
    buff.field[player][pl_idxs[i]] = {atk={"+",2},sta={"+",2}}
  end
  if opponent:is_npc() then
    for i=1,min(2,#op_idxs) do
      buff.field[opponent][op_idxs[i]] = {atk={"-",2},sta={"-",2}}
    end
  end
  buff:apply()
end,

--[[
Water Play
]]
[200398] = function(player, opponent)
  local pred_def = function(card) return card.def >= 2 end
  local idxs = opponent:field_idxs_with_preds(pred.follower, pred_def)
  local buff = OnePlayerBuff(opponent)
  for _,idx in ipairs(idxs) do
    buff[idx] = {def={"-",opponent.field[idx].def*2}}
  end
  buff:apply()
end,

--[[
Shaman's Message
]]
[200399] = function(player, opponent, my_idx)
  if not pred.D(player.character) then
    return
  end
  while opponent.grave[1] do
    player:to_grave(table.remove(opponent.grave, 1))
  end
  local mag = #player.grave
  local a_mag = mag % 10
  local s_mag = floor(mag / 10)
  local buff = GlobalBuff(player)
  local idx = player:hand_idxs_with_preds(pred.follower)[1]
  if idx then
    buff.hand[player][idx] = {atk={"+",a_mag},sta={"+",s_mag}}
  end
  idx = player:deck_idxs_with_preds(pred.follower)[1]
  if idx then
    buff.deck[player][idx] = {atk={"+",a_mag},sta={"+",s_mag}}
  end
  buff:apply()
  player:field_to_exile(my_idx)
end,

--[[
Veltier's Dream
]]
[200400] = function(player, opponent, my_idx, my_card)
  if my_card.size <= 2 then
    player:field_to_exile(my_idx)
    return
  end
  if player.character.life > opponent.character.life then
    return
  end
  local idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if not idx then
    return
  end
  player.field[my_idx], opponent.field[idx] = opponent.field[idx], player.field[my_idx]
  OneBuff(opponent, idx, {size={"-",1}}):apply()
  opponent.field[idx].active = false
end,

--[[
Lib. Assistant
]]
[200401] = function(player, opponent, my_idx)
  player:field_to_exile(my_idx)
  player.field[my_idx] = Card(300206)
  OneBuff(player, my_idx, {size={"=",my_idx},atk={"=",my_idx*2},sta={"=",my_idx*2}}):apply()
end,

--[[
Accompaniment
]]
[200402] = function(player, opponent, my_idx, my_card)
  local buff = GlobalBuff(player)
  for i=1,min(2,#player.hand) do
    buff.hand[player][i] = {size={"=",my_card.size}}
  end
  if my_card.size <= 2 then
    player:field_to_grave(my_idx)
  else
    buff.field[player][my_idx] = {size={"=",random(5)}}
  end
  buff:apply()
  if #player.hand < 5 and player.field[my_idx] then
    player:field_to_hand(my_idx)
  end
end,

--[[
Spirit Encounter
]]
[200403] = function(player, opponent)
  if not pred.V(player.character) then
    return
  end
  local idxs = opponent:field_idxs_with_preds(pred.follower)
  local buff = OnePlayerBuff(opponent)
  for i=1,min(2,#idxs) do
    buff[idxs[i]] = {atk={"-",2}}
    for i1=1,3 do
      opponent.field[idxs[i]]:remove_skill(i1)
    end
    opponent.field[idxs[i]]:gain_skill(1151)
  end
  buff:apply()
end,

--[[
Anywhere Service
]]
[200404] = function(player, opponent)
  if player.won_flip then
    if opponent.hand[1] then
      opponent:hand_to_exile(1)
    end
  else
    for i=1,min(5,#player.grave) do
      player:grave_to_exile(#player.grave)
    end
  end
end,

--[[
Lady on the Water
]]
[200405] = function(player)
  local idxs = shuffle(player:field_idxs_with_preds(pred.follower))
  for i=1,min(2,#idxs) do
    player.field[idxs[i]]:gain_skill(1360)
  end
end,

--[[
Limit Break
]]
[200406] = function(player, opponent)
  if not pred.A(player.character) then
    return
  end
  local f_idx = player:first_empty_field_slot()
  local d_idx = #player.deck - 8
  if not f_idx or d_idx < 1 then
    return
  end
  player:deck_to_field(d_idx)
  if pred.follower(player.field[f_idx]) then
    local buff = OnePlayerBuff(opponent)
    local idxs = shuffle(opponent:field_idxs_with_preds(pred.follower))
    for i=1,min(2,#idxs) do
      buff[idxs[i]] = {atk={"-",4},sta={"-",4}}
    end
    buff:apply()
  else
    local idxs = opponent:field_idxs_with_preds(pred.spell)
    for _,idx in ipairs(idxs) do
      opponent:field_to_grave(idx)
    end
  end
end,

-- relaxation
[200407] = function(player, opponent, my_idx, my_card)
  local my_idx = player:field_idxs_with_preds(pred.follower)[1]
  local op_guys = opponent:field_idxs_with_preds(pred.follower)
  local op_idx = op_guys[#op_guys]
  if my_idx and op_idx then
    local my_card = player.field[my_idx]
    local op_card = opponent.field[op_idx]
    local buff = GlobalBuff(player)
    buff.field[player][my_idx],buff.field[opponent][op_idx] = {},{}
    for _,stat in ipairs({"atk","def","sta","size"}) do
      buff.field[player][my_idx][stat] = {"=",op_card[stat]}
      buff.field[opponent][op_idx][stat] = {"=",my_card[stat]}
    end
    buff:apply()
  end
end,

--[[
Smallification
]]
[200408] = function(player, opponent)
  local check = player:field_idxs_with_preds(pred.follower, pred.blue_cross)[1]
  if not check then
    return
  end
  local buff = GlobalBuff(player)
  local idx = uniformly(player:field_idxs_with_preds(pred.follower))
  buff.field[player][idx] = {sta={"=",1}}
  idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if idx then
    buff.field[opponent][idx] = {sta={"=",1}}
  end
  buff:apply()
end,

--[[
Blu E Rosso
]]
[200409] = function(player, opponent)
  if not pred.C(player.character) then
    return
  end
  local pred_faction = function(card) return opponent.character.faction ~= card.faction end
  for i=1,3 do
    local card = nil
    if i == 1 then
      card = opponent.field[uniformly(opponent:field_idxs_with_preds(pred.follower, pred_faction))]
    elseif i == 2 then
      card = opponent.hand[uniformly(opponent:hand_idxs_with_preds(pred.follower, pred_faction))]
    else
      card = opponent.deck[uniformly(opponent:deck_idxs_with_preds(pred.follower, pred_faction))]
    end
    if card then
      for i=1,3 do
        card:remove_skill(i)
      end
      card:gain_skill(1364)
      card:gain_skill(1892)
    end
  end
end,

--[[
Underground City
]]
[200410] = function(player)
  local pred_vampire = function(card) return pred.crescent(card) or
      pred.flina(card) or pred.scardel(card) end
  local mag = #player:field_idxs_with_preds(pred.follower, pred_vampire)
      + #player:hand_idxs_with_preds(pred.follower, pred_vampire)
  local idxs = player:field_idxs_with_preds(pred.follower, pred_vampire)
  local buff = OnePlayerBuff(player)
  for _,idx in ipairs(idxs) do
    buff[idx] = {atk={"+",ceil(mag/2)},sta={"+",mag}}
  end
  buff:apply()
end,

--[[
Divine Clue
]]
[200411] = function(player, opponent)
  local pl_count = #player:grave_idxs_with_preds(pred.follower)
  if not pl_count and not player:field_idxs_with_preds(pred.follower)[1] then
    return
  end
  local op_count = #opponent:grave_idxs_with_preds(pred.follower)
  local buff = OnePlayerBuff(opponent)
  local idxs = shuffle(opponent:field_idxs_with_preds(pred.follower))
  local mag = min(6, abs(pl_count-op_count))
  for i=1,min(2,#idxs) do
    buff[idxs[i]] = {sta={"-",mag}}
  end
  buff:apply()
end,

--[[
Butterfly Brand
]]
[200412] = function(player, opponent)
  if not pred.D(player.character) then
    return
  end
  local impact = Impact(player)
  local idxs = opponent:field_idxs_with_preds(pred.follower)
  for _,idx in ipairs(idxs) do
    for i=1,3 do
      if opponent.field[idx].skills[i] and skill_id_to_type[opponent.field[idx].skills[i]] ~= "defend" then
        impact[player.opponent][idx] = true
        opponent.field[idx].skills[i] = 1201
      end
    end
  end
  idxs = player:field_idxs_with_preds(pred.follower)
  for _,idx in ipairs(idxs) do
    if player.field[idx]:first_empty_skill_slot() then
      impact[player][idx] = true
      player.field[idx]:gain_skill(1003)
    end
  end
  idxs = player:hand_idxs_with_preds(pred.follower)
  for _,idx in ipairs(idxs) do
    if player.hand[idx]:first_empty_skill_slot() then
      impact[player][idx] = true
      player.hand[idx]:gain_skill(1003)
    end
  end
  impact:apply()
end,

--[[
Eternal Witness
]]
[200413] = function(player, opponent, my_idx, my_card)
  local mag = player.shuffles + 1
  local idxs = player:field_idxs_with_preds(pred.follower)
  local buff = OnePlayerBuff(player)
  for _,idx in ipairs(idxs) do
    buff[idx] = {atk={"+",mag},sta={"+",mag}}
  end
  buff:apply()
  player.shuffles = player.shuffles + 2
  if my_card.size >= 3 then
    player:field_to_exile(my_idx)
    return
  end
  OneBuff(player, my_idx, {size={"+",1}}):apply()
  if player.deck[1] then
    table.insert(player.deck, #player.deck, my_card)
  else
    table.insert(player.deck, 1, my_card)
  end
  --player.deck[#player.deck], player.deck[#player.deck + 1] = my_card, player.deck[#player.deck]
  player.field[my_idx] = nil
  player:check_hand()
end,

-- Welcome!
[200414] = function(player, opponent, my_idx, my_card)
  local targets = shuffle(player:field_idxs_with_preds(pred.follower))
  local buff = OnePlayerBuff(player)
  for i=1,2 do
    if targets[i] then
      buff[targets[i]] = {atk={"+",2},sta={"+",2}}
    end
  end
  buff:apply()
end,

--[[
Disappearance
]]
[200415] = function(player, opponent)
  local idxs = shuffle(player:field_idxs_with_preds(pred.follower))
  local buff = GlobalBuff(player)
  for i=1,min(2,#idxs) do
    buff.field[player][idxs[i]] = {atk={"+",3},sta={"+",3}}
  end
  idxs = shuffle(opponent:field_idxs_with_preds(pred.follower))
  for i=1,min(2,#idxs) do
    buff.field[opponent][idxs[i]] = {atk={"-",1},sta={"-",1}}
  end
  buff:apply()
end,

--[[
Finding the Library
]]
[200416] = function(player)
  local mag = 0
  for i=1,5 do
    local idx = player:hand_idxs_with_preds(pred.follower, pred.library_club)[1]
    if idx then
      player:hand_to_bottom_deck(idx)
      mag = mag + 1
    end
  end
  local idxs = player:field_idxs_with_preds(pred.follower, pred.library, pred.active)
  for _,idx in ipairs(idxs) do
    player:field_to_bottom_deck(idx)
    mag = mag + 1
  end
  local buff = OnePlayerBuff(player)
  idxs = player:deck_idxs_with_preds(pred.follower, pred.library, pred.active)
  for i=1,min(1 + floor(mag / 2),#idxs) do
    local idx = player:first_empty_field_slot()
    if idx then
      player:deck_to_field(idxs[i])
      buff[idx] = {atk={"+",floor(mag/2)},sta={"+",floor(mag/2)}}
    end
  end
  buff:apply()
end,

--[[
Library Elusion
]]
[200417] = function(player, opponent)
  local idx = opponent:field_idxs_with_preds(pred.follower)[2]
  if not idx then
    return
  end
  local idxs = opponent:field_idxs_with_preds()
  local mag = idxs[#idxs]
  local card = opponent.field[idx]
  OneBuff(opponent, idx, {atk={"+",floor((card.sta-mag)/2)},sta={"=",mag}}):apply()
end,

--[[
Surprise Attack
]]
[200418] = function(player)
  local idx = uniformly(player:field_idxs_with_preds(pred.follower))
  if not idx then
    return
  end
  if random(4) == 1 then
    OneBuff(player, idx, {atk={"+",player.game.turn%10}}):apply()
  else
    OneBuff(player, idx, {sta={"+",player.game.turn%10}}):apply()
  end
end,

--[[
Cosmo Drive
]]
[200419] = function(player, opponent)
  if not pred.A(player.character) then
    return
  end
  local pl_idx = player:field_idxs_with_least_and_preds(pred.size, pred.follower)[1]
  local op_idxs = opponent:field_idxs_with_most_and_preds(pred.size, pred.follower)
  if pl_idx and op_idxs[1] then
    local mag = abs(player.field[pl_idx].size - opponent.field[op_idxs[1]].size)
    local buff = OnePlayerBuff(opponent)
    for _,idx in ipairs(op_idxs) do
      buff[idx] = {atk={"-",mag},sta={"-",mag}}
    end
    buff:apply()
  end
end,

--[[
  Exiled Witch
]]
[200420] = function(player, opponent, my_idx, my_card)
  local idx1 = player:field_idxs_with_preds(function(card) return card ~= my_card end)[1]
  if idx1 then
    local impact = Impact(player)
    impact[player][idx1] = true
    local idx2 = opponent:field_idxs_with_preds(function(card) return card.size <= 10 end)[1]
    if idx2 then
      impact[opponent][idx2] = true
      impact:apply()
      opponent:destroy(idx2)
    else
      impact:apply()
    end
    player:destroy(idx1)
  end
end,

--[[
Head Knight's Rest
]]
[200421] = function(player, opponent)
  local pl_non = #player:field_idxs_with_preds(pred.neg(pred.knight))
  local pl_knight = #player:field_idxs_with_preds(pred.knight)
  local op_non = #opponent:field_idxs_with_preds(pred.neg(pred.knight))
  local op_knight = #opponent:field_idxs_with_preds(pred.knight)
  local buff = GlobalBuff(player)
  for _,idx in ipairs(player:field_idxs_with_preds(pred.follower)) do
    buff.field[player][idx] = {size={"-",pl_knight},sta={"-",pl_non}}
  end
  for _,idx in ipairs(opponent:field_idxs_with_preds(pred.follower)) do
    buff.field[opponent][idx] = {size={"-",op_knight},sta={"-",op_non}}
  end
  buff:apply()
end,

--[[
Clairvoyance
]]
[200422] = function(player)
  for _,idx in ipairs(player:field_idxs_with_preds(pred.follower)) do
    for i=1,3 do
      if player.field[idx].skills[i] then
        player.field[idx].skills[i] = 1003
      end
    end
  end
  for _,idx in ipairs(player:hand_idxs_with_preds(pred.follower)) do
    for i=1,3 do
      if player.hand[idx].skills[i] then
        player.hand[idx].skills[i] = 1003
      end
    end
  end
end,

--[[
Elusion
]]
[200423] = function(player, opponent, my_idx)
  if not pred.C(player.character) then
    return
  end
  if not opponent.deck[1] or not opponent:first_empty_field_slot() then
    player:field_to_exile(my_idx)
    return
  end
  opponent:deck_to_field(#opponent.deck)
  if #opponent:field_idxs_with_preds(pred.spell) >= 2 then
    for _,idx in ipairs(opponent:field_idxs_with_preds(pred.spell)) do
      opponent:field_to_bottom_deck(idx)
    end
  end
  if #opponent:field_idxs_with_preds(pred.follower) >= 3 then
    for _,idx in ipairs(opponent:field_idxs_with_preds(pred.follower)) do
      opponent:field_to_bottom_deck(idx)
    end
  end
  player:field_to_exile(my_idx)
end,

--[[
Ritual of Unity
]]
[200424] = function(player, opponent, my_idx, my_card)
  local pred_vampire = function(card) return pred.crescent(card) or
      pred.flina(card) or pred.scardel(card) end
  local mag = #player:grave_idxs_with_preds(pred.union(pred_vampire,
      function(card) return card.name == my_card.name end))
  local idxs = shuffle(player:field_idxs_with_preds(pred.follower))
  local buff = OnePlayerBuff(player)
  for i=1,min(2,#idxs) do
    buff[idxs[i]] = {atk={"+",mag}}
  end
  buff:apply()
end,

--[[
Mediation
]]
[200425] = function(player, opponent)
  local op_idx = uniformly(opponent:field_idxs_with_preds())
  if not op_idx then
    return
  end
  opponent.field[op_idx].active = false
  local pl_idx = uniformly(player:field_idxs_with_preds(pred.follower))
  if not pl_idx then
    return
  end
  if pred.follower(opponent.field[op_idx]) then
    OneBuff(player, pl_idx, {sta={"+",opponent.field[op_idx].size}}):apply()
  else
    OneBuff(player, pl_idx, {atk={"+",opponent.field[op_idx].size}}):apply()
  end
end,

--[[
Intervention
]]
[200426] = function(player, opponent, my_idx, my_card)
  if my_card.size >= 5 then
    player:field_to_grave(my_idx)
    return
  end
  if not opponent.hand[1] then
    player:field_to_exile(my_idx)
    return
  end
  opponent.hand[1] = Card(my_card.id)
  local buff = GlobalBuff(opponent)
  buff.hand[opponent][1] = {size={"=",my_card.size+1}}
  buff:apply()
  player:field_to_exile(my_idx)
end,

--[[
Panel Rise
]]
[200427] = function(player, opponent)
  local idx = player:field_idxs_with_preds(pred.follower)[1]
  if not idx then
    return
  end
  if player.field[idx].def ~= 1 then
    OneBuff(player, idx, {def={"=",1}}):apply()
    return
  end
  local idxs = shuffle(opponent:field_idxs_with_preds(pred.follower))
  local buff = OnePlayerBuff(opponent)
  for i=1,min(2,#idxs) do
    buff[idxs[i]] = {atk={"-",1},sta={"-",3}}
  end
  buff:apply()
end,

--[[
Friendship after the Rain
]]
[200428] = function(player)
  local mag = 0
  local buff = GlobalBuff(player)
  for _,idx in ipairs(player:field_idxs_with_preds(pred.follower, pred.library_club)) do
    if player.field[idx].size > 1 then
      mag = mag + 1
    end
    buff.field[player][idx] = {size={"-",1}}
  end
  local idx = player:hand_idxs_with_preds(pred.follower, pred.library_club)[1]
  if idx then
    buff.hand[player][idx] = {size={"-",mag}}
  end
  buff:apply()
end,

--[[
Window Shopping
]]
[200429] = function(player, opponent)
  local idxs = opponent:deck_idxs_with_preds(pred.spell)
  local offset = 0
  for i=1,min(5,#idxs) do
    opponent:deck_to_bottom_deck(idxs[i] + offset)
    offset = offset + 1
  end
  idxs = opponent:hand_idxs_with_preds()
  offset = 0
  for i=1,min(5,#idxs) do
    opponent:hand_to_bottom_deck(idxs[i] - offset)
    offset = offset + 1
  end
  if pred.V(player.character) then
    opponent.shuffles = max(opponent.shuffles - 1, 0)
  end
end,

--[[
Witchification Plans
]]
[200430] = function(player, opponent)
  local pred_faction = function(card) return card.faction ~= opponent.character.faction end
  local mag = 0
  local idxs = opponent:grave_idxs_with_preds(pred_faction)
  for i=1,min(3,#idxs) do
    opponent:grave_to_exile(idxs[i])
    mag = mag + 1
  end
  OneBuff(player, 0, {life={"+",mag}}):apply()
end,

--[[
Down with the Queen
]]
[200431] = function(player, opponent, my_idx, my_card)
  local idxs = shuffle(opponent:field_idxs_with_preds(pred.follower))
  local mag = abs(3 - my_card.size)
  local buff = OnePlayerBuff(opponent)
  for i=1,min(2,#idxs) do
    buff[idxs[i]] = {atk={"+",mag},sta={"+",mag}}
  end
  buff:apply()
  if my_card.size == 1 then
    player:field_to_exile(my_idx)
    return
  end
  local idx = opponent:last_empty_field_slot()
  if not idx then
    return
  end
  my_card.active = false
  player.field[my_idx], opponent.field[idx] = nil, my_card
  OneBuff(opponent, idx, {size={"-",2}}):apply()
end,

--[[
Dress Up Extreme
]]
[200432] = function(player, opponent, my_idx, my_card)
  local mag = 0
  if not pred.A(player.character) then
    mag = mag - Card(my_card.id).size
  end
  for _,idx in ipairs(player:field_idxs_with_preds()) do
    mag = mag + Card(player.field[idx].id).size
  end
  if mag <= 5 or mag >= 10 then
    local idx = uniformly(opponent:field_idxs_with_preds(pred.spell))
    if idx then
      opponent:field_to_grave(idx)
    end
  end
  if mag >= 6 then
    local idxs = shuffle(opponent:field_idxs_with_preds(pred.follower))
    local buff = OnePlayerBuff(opponent)
    for i=1,min(2,#idxs) do
      buff[idxs[i]] = {atk={"-",3},sta={"-",3}}
    end
    buff:apply()
  end
  if mag >= 10 then
    local idx = uniformly(opponent:field_idxs_with_preds())
    if idx then
      opponent.field[idx].active = false
    end
  end
end,

--[[
Opposition
]]
[200433] = function(player)
  local idxs = shuffle(player:field_idxs_with_preds(pred.C, pred.follower))
  local buff = OnePlayerBuff(player)
  for i=1,min(2, #idxs) do
    local mag = ceil((player.field[idxs[1]].size +
        (player.field[idxs[2]] or player.field[idxs[1]]).size)/2)
    buff[idxs[i]] = {atk={"+",mag}, def={"=", 0}}
  end
  buff:apply()
end,

--[[
Witch Hunt
]]
[200434] = function(player, opponent)
  if not pred.C(player.character) then
    return
  end
  local idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if not idx then
    return
  end
  OneBuff(opponent, idx, {size={"+",1}}):apply()
  if opponent.field[idx].size >= 4 then
    opponent.field[idx]:gain_skill(1405)
  end
end,

--[[
Trace of Kana
]]
[200435] = function(player)
  local idx = uniformly(player:field_idxs_with_preds(pred.follower))
  if idx then
    OneBuff(player, idx, {atk={"+",2},sta={"+",2}}):apply()
    local card = player.field[idx]
    card:gain_skill(1407)
    if pred.C(player.character) then
      idx = uniformly(player:field_idxs_with_preds(pred.follower))
      OneBuff(player, idx, {atk={"+",2},sta={"+",2}}):apply()
      local card = player.field[idx]
      card:gain_skill(1407)
    end
  end
end,

-- apostle's scheme
[200436] = function(player, opponent, my_idx, my_card)
  local targets = shuffle(opponent:field_idxs_with_preds(pred.follower))
  local buff = OnePlayerBuff(opponent)
  for i=1,2 do
    if targets[i] then
      buff[targets[i]] = {atk={"-",random(1,3)}}
    end
  end
  buff:apply()
  if my_card.size < 2 and #player.hand < 5 then
    OneBuff(player, my_idx, {size={"+", 1}}):apply()
    player:field_to_hand(my_idx)
  end
end,

--[[
Trance
]]
[200437] = function(player, opponent, my_idx)
  local idx = player:field_idxs_with_least_and_preds(pred.sta, pred.follower)[1]
  if idx then
    player:field_to_exile(idx)
    idx = uniformly(player:grave_idxs_with_preds(pred.follower))
    if idx then
      player:grave_to_field(idx)
    end
  end
  player:field_to_exile(my_idx)
end,

--[[
Dark Sword Menelgart
]]
[200438] = function(player)
  local buff = GlobalBuff(player)
  local check = pred.D(player.character)
  for _,idx in ipairs(player:field_idxs_with_preds(pred.follower)) do
    local card = player.field[idx]
    local a_mag = card.sta + (check and (card.atk <= 10) and 3 or 0)
    local s_mag = card.atk + (check and (card.sta <= 10) and 4 or 0)
    buff.field[player][idx] = {atk={"=",a_mag},sta={"=",s_mag}}
  end
  for _,idx in ipairs(player:hand_idxs_with_preds(pred.follower)) do
    local card = player.hand[idx]
    local a_mag = card.sta + (check and (card.atk <= 10) and 3 or 0)
    local s_mag = card.atk + (check and (card.sta <= 10) and 4 or 0)
    buff.hand[player][idx] = {atk={"=",a_mag},sta={"=",s_mag}}
  end
  buff:apply()
end,

--[[
The day when the earth and sea switched places
]]
[200439] = function(player, opponent)
  OneBuff(player, 0, {life={"+",4}}):apply()
  opponent.shuffles = max(opponent.shuffles - 1, 0)
  local mag = player.character.life
  if mag >= 31 then
    local idxs = shuffle(opponent:hand_idxs_with_preds())
    for i = 1, min(2, #idxs) do
      opponent:hand_to_grave(idxs[i])
    end
  elseif mag >= 12 and mag <= 27 then
    local idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
    if idx then
      opponent:field_to_grave(idx)
    end
  elseif mag >= 5 and mag <= 8 then
    local idxs = shuffle(opponent:field_idxs_with_preds())
    for i=1,min(2,#idxs) do
      opponent:field_to_grave(idxs[i])
    end
  end
end,

-- steparu
[200440] = function(player, opponent, my_idx, my_card)
  local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if target then
    opponent.field[target].active = false
    opponent.field[target]:gain_skill(1175)
    opponent.field[target]:gain_skill(1408)
  end
end,

--[[
Student Council
]]
[200441] = function(player, opponent)
  local idx = player:field_idxs_with_preds(pred.follower, pred.student_council)[1]
  if not idx then
    return
  end
  OneBuff(player, idx, {atk={"+",3}}):apply()
  idx = opponent:field_idxs_with_preds(pred.follower,
      function(card) return card.atk < player.field[idx].atk end)[1]
  if idx then
    OneImpact(opponent, idx):apply()
    opponent.field[idx].active = false
  end
end,

--[[
Indecision
]]
[200442] = function(player)
  local mag = uniformly({3, 5})
  local buff = OnePlayerBuff(player)
  local idxs = shuffle(player:field_idxs_with_preds(pred.follower))
  for i=1,min(2,#idxs) do
    buff[idxs[i]] = {sta={"+",mag}}
  end
  buff:apply()
end,

--[[
Satisfactory Results
]]
[200443] = function(player)
  local pred_faction = pred[player.character.faction]
  local idx = player:field_idxs_with_preds(pred.follower, pred_faction)[1]
  if not idx then return end
  local mag = player.field[idx].size
  player:field_to_exile(idx)
  local deck_idx = player:deck_idxs_with_most_and_preds(pred.size)[1]
  if not deck_idx then return end
  player:deck_to_field(deck_idx, idx)
  OneBuff(player, idx, {size={"=",mag}}):apply()
end,

--[[
Garden Lady
]]
[200444] = function(player, opponent, my_idx)
  if pred.A(player.character) then
    OneBuff(player, 0, {life={"+",1 + ((#player.deck <= 15) and 3 or 0)}}):apply()
  end
  player:field_to_exile(my_idx)
end,

--[[
Everyone's Enemy
]]
[200445] = function(player, opponent)
  local idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if not idx then
    return
  end
  local mag = {atk={"-", 0}, def={"-", 0}, sta={"-", 0}}
  for i = 1, 4 do
    local stat = uniformly({"atk", "def", "sta"})
    mag[stat][2] = mag[stat][2] + 1
  end
  OneBuff(opponent, idx, mag):apply()
end,

--[[
Lady Maid Dream
]]
[200446] = function(player, opponent, my_idx, my_card)
  if my_card.size == 1 then
    if player.grave[1] and player:first_empty_field_slot() then
      player:grave_to_field(1)
    end
    player:field_to_exile(my_idx)
    return
  end
  local idx = uniformly(opponent:field_idxs_with_preds())
  if not idx then return end
  opponent.field[idx]:reset()
  table.insert(opponent.grave, 1, opponent.field[idx])
  opponent.field[idx] = nil
  idx = opponent:first_empty_field_slot()
  opponent.field[idx], player.field[my_idx] = my_card, nil
  OneBuff(opponent, idx, {size={"=",1}}):apply()
  my_card.active = false
end,

--[[
Discovery
]]
[200447] = function(player)
  while (not player.hand[4]) and player.deck[1] do
    player:deck_to_hand(#player.deck)
  end
  local mag = #player:hand_idxs_with_preds(pred.blue_cross)
  local buff = OnePlayerBuff(player)
  for _,idx in ipairs(player:field_idxs_with_preds(pred.follower)) do
    buff[idx] = {sta={"+",mag}}
  end
  buff:apply()
end,

--[[
Experience
]]
[200448] = function(player, opponent, my_idx, my_card)
  local op_idx = uniformly(opponent:field_idxs_with_preds(pred.spell,
      function(card) return card.name ~= my_card.name end))
  local pl_idx = player:first_empty_field_slot()
  if op_idx and pl_idx then
    player.field[pl_idx] = Card(opponent.field[op_idx].id)
  end
end,

--[[
Relapse
]]
[200449] = function(player)
  local idx = player:field_idxs_with_most_and_preds(pred.size, pred.follower)[1]
  if not idx then
    return
  end
  local card = player.field[idx]
  local buff = OnePlayerBuff(player)
  local mag_size = ceil(card.size / 2)
  local mag_atk = ceil(card.atk / 2)
  local mag_def = ceil(card.def / 2)
  local mag_sta = ceil(card.sta / 2)
  buff[idx] = {size={"=", mag_size}, atk={"=", mag_atk}, def={"=", mag_def}, sta={"=", mag_sta}}
  idx = player:first_empty_field_slot()
  if idx then
    player.field[idx] = Card(card.id)
    player.field[idx].active = true
    local mag_size2 = max(floor(card.size / 2), 1)
    local mag_atk2 = floor(card.atk / 2)
    local mag_def2 = floor(card.def / 2)
    local mag_sta2 = floor(card.sta / 2)
    buff[idx] = {size={"=", mag_size2}, atk={"=", mag_atk2}, def={"=", mag_def2}, sta={"=", mag_sta2}}
  end
  buff:apply()
end,

--[[
GS 5th Star's Strength
]]
[200450] = function(player, opponent)
  local mag = 0
  local mag2 = 0
  for i=1,min(3,#player.grave) do
    if pred[player.character.faction](player.grave[#player.grave + 1 - i]) then
      mag = mag + 1
    end
    if pred.gs(player.grave[#player.grave + 1 - i]) then
      mag2 = mag2 + 1
    end
  end
  local idxs = shuffle(opponent:field_idxs_with_preds(pred.follower))
  local buff = OnePlayerBuff(opponent)
  for i=1,min(2,#idxs) do
    buff[idxs[i]] = {atk={"-",mag},sta={"-",mag}}
  end
  buff:apply()
  local idx = uniformly(player:field_idxs_with_preds(pred.follower))
  if idx then
    OneBuff(player, idx, {size={"-",mag2}}):apply()
  end
end,

--[[
The Battle Begins
]]
[200451] = function(player, opponent)
  local impact = Impact(player)
  for _,idx in ipairs(player:field_idxs_with_preds(pred.follower)) do
    player.field[idx].skills = {1076}
    impact[player][idx] = true
  end
  for _,idx in ipairs(opponent:field_idxs_with_preds(pred.follower)) do
    opponent.field[idx].skills = {1076}
    impact[opponent][idx] = true
  end
  impact:apply()
end,

--[[
Engagement
]]
[200452] = function(player, opponent)
  if not pred.D(player.character) then
    return
  end
  local idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if idx then
    local card = opponent.field[idx]
    OneBuff(opponent, idx, {sta={"-",abs(card.atk-card.def)}}):apply()
  end
end,

--[[
Following Memory
]]
[200453] = function(player, opponent)
  local mag = 10 - player:field_size()
  local pred_def = function(card) return card.def == mag end
  local idx = uniformly(opponent:field_idxs_with_preds(pred.follower, pred_def))
  if idx then
    OneImpact(opponent, idx):apply()
    opponent:field_to_bottom_deck(idx)
  end
end,

--[[
Minority Report
]]
[200454] = function(player)
  local idxs = player:field_idxs_with_preds(pred.follower, pred.cook_club)
  if not idxs[2] then
    return
  end
  local card = player.field[idxs[2]]
  local skill = nil
  if pred.skill(card) then
    skill = card.skills[card:first_skill_idx()]
  end
  local buff = OnePlayerBuff(player)
  for _,idx in ipairs(idxs) do
    if idx ~= idxs[2] then
      local skill_idx = player.field[idx]:first_skill_idx()
      if skill and skill_idx then
        player.field[idx]:remove_skill(skill_idx)
        player.field[idx]:gain_skill(skill)
      end
      buff[idx] = {size={"=",card.size}}
    end
  end
  buff:apply()
end,

--[[
Talentium Veritas
]]
[200455] = function(player, opponent)
  OneBuff(player, 0, {life={"+",2}}):apply()
  if pred.V(player.character) then
    local rolls = {1, 2, 3, 4, 5}
    for i = 1, 2 do
      local roll = uniformly(rolls)
      table.remove(rolls, roll)
      if roll == 1 then
        for i2 = 1, min(3, #player.grave) do
          player:grave_to_bottom_deck(1)
        end
      elseif roll == 2 then
        local buff = OnePlayerBuff(player)
        for _, idx in ipairs(player:field_idxs_with_preds(pred.follower)) do
          buff[idx] = {atk={"+",3},sta={"+",3}}
        end
        buff:apply()
      elseif roll == 3 then
        OneBuff(opponent, 0, {life={"-",2}}):apply()
      elseif roll == 4 then
        local buff = OnePlayerBuff(opponent)
        for _,idx in ipairs(opponent:field_idxs_with_preds(pred.follower)) do
          buff[idx] = {atk={"-",3},sta={"-",3}}
        end
        buff:apply()
      else
        local idx = opponent:field_idxs_with_preds()[1]
        if idx then
          opponent:field_to_exile(idx)
        end
      end
    end
  end
end,

--[[
Altar of Kana
]]
[200456] = function(player, opponent)
  local buff = GlobalBuff(player)
  for _,idx in ipairs(player:field_idxs_with_preds(pred.follower)) do
    local card = player.field[idx]
    buff.field[player][idx] = {atk={"+",(card.sta % 2 == 0) and 3 or 0},
        sta={"-",(card.sta % 2 == 1) and 3 or 0}}
  end
  for _,idx in ipairs(opponent:field_idxs_with_preds(pred.follower)) do
    local card = opponent.field[idx]
    buff.field[opponent][idx] = {atk={"+",(card.sta % 2 == 0) and 3 or 0},
        sta={"-",(card.sta % 2 == 1) and 3 or 0}}
  end
  buff:apply()
end,

--[[
Rift
]]
[200457] = function(player, opponent, my_idx, my_card)
  if my_card.size >= 3 then
    local idxs = shuffle(player:field_idxs_with_preds(pred.follower))
    local buff = GlobalBuff(player)
    buff.field[opponent][0] = {life={"+", 2}}
    for i = 1, min(2, #idxs) do
      buff.field[player][idxs[i]] = {atk={"-", 2}, sta={"-", 2}}
    end
    buff:apply()
  else
    local idx = opponent:last_empty_field_slot()
    if not idx then
      return
    end
    player.field[my_idx], opponent.field[idx] = nil, my_card
    OneBuff(opponent, idx, {size={"+", random(2)}}):apply()
    my_card.active = false
  end
end,

--[[
Covert Operation
]]
[200458] = function(player, opponent)
  local idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if idx then
    opponent.field[idx] = Card(300402)
    OneBuff(opponent, idx, {size={"=",1}}):apply()
  end
  if pred.A(player.character) then
    local mag = min(4, #player:field_idxs_with_preds(pred.A, pred.follower) + #opponent:field_idxs_with_preds(pred.A, pred.follower))
    local idxs = shuffle(player:field_idxs_with_preds(pred.follower))
    local buff = OnePlayerBuff(player)
    for i = 1, min(2, #idxs) do
      buff[idxs[i]] = {atk={"+", mag}, sta={"+", mag}}
    end
    buff:apply()
  end
end,

--[[
Summon
]]
[200459] = function(player)
  local check1 = player:field_idxs_with_preds(pred.follower, pred.knight)[1]
  local check2 = player:field_idxs_with_preds(pred.follower, pred.seeker)[1]
  if not check1 or not check2 then
    return
  end
  local buff = OnePlayerBuff(player)
  for _,idx in ipairs(player:field_idxs_with_preds(pred.follower)) do
    buff[idx] = {atk={"+",4}}
  end
  buff:apply()
end,

--[[
Manhunt
]]
[200460] = function(player)
  local mag = 0
  for i=1,5 do
    local idx = player:hand_idxs_with_preds(pred.spell)[1]
    if idx and player:first_empty_field_slot() then
      player:hand_to_field(idx)
      mag = mag + 1
    end
  end
  OneBuff(player, 0, {life={"+",mag}}):apply()
end,

--[[
Backup
]]
[200461] = function(player, opponent)
  if not pred.C(player.character) then
    return
  end
  local mag = 0
  for i=1,5 do
    if opponent.field[i] and pred.spell(opponent.field[i]) then
      opponent:field_to_top_deck(i)
      mag = mag + 1
    end
  end
  for i=1,#opponent.hand do
    local idx = opponent:hand_idxs_with_preds(pred.spell)[1]
    if idx then
      opponent:hand_to_top_deck(idx)
      mag = mag + 1
    end
  end
  local buff = GlobalBuff(opponent)
  for _,idx in ipairs(opponent:field_idxs_with_preds(pred.follower)) do
    buff.field[opponent][idx] = {def={"-",mag}}
  end
  for _,idx in ipairs(opponent:hand_idxs_with_preds(pred.follower)) do
    buff.hand[opponent][idx] = {def={"-",mag}}
  end
  buff:apply()
end,

--[[
GS Network
]]
[200462] = function(player)
  local slot = player:first_empty_field_slot()
  if not slot then
    return
  end
  local idx = player:field_idxs_with_preds(pred.follower)[1]
  if not idx then
    return
  end
  local pred_faction = function(card) return card.faction == player.field[idx].faction end
  idx = player:deck_idxs_with_preds(pred.follower, pred_faction)[1]
  if idx then
    player:deck_to_field(idx)
    OneBuff(player, slot, {size={"-",1}}):apply()
  end
end,

--[[
Gossip
]]
[200463] = function(player, opponent)
  local pl_idxs = player:field_idxs_with_preds(pred.follower)
  table.remove(pl_idxs, 1)
  local mag = 1 + #pl_idxs
  local impact = Impact(player)
  for _, idx in ipairs(pl_idxs) do
    impact[player][idx] = true
  end
  local op_idxs = opponent:field_idxs_with_preds(pred.follower)
  table.remove(op_idxs, 1)
  for i = 1, math.min(mag, #op_idxs) do
    if op_idxs[i] then
      impact[opponent][op_idxs[i]] = true
    end
  end
  impact:apply()
  for _, idx in ipairs(pl_idxs) do
    player:field_to_top_deck(idx)
  end
  for i = 1, math.min(mag, #op_idxs) do
    opponent:field_to_top_deck(op_idxs[i])
  end
end,

--[[
Miracle
]]
[200464] = function(player, opponent)
  if not pred.D(player.character) then
    return
  end
  local idx = player:field_idxs_with_preds(pred.follower)[1]
  if idx then
    local card = player.field[idx]
    local a_mag = card.atk
    local d_mag = card.def
    local s_mag = card.sta
    local buff = OnePlayerBuff(opponent)
    for _,idx in ipairs(opponent:field_idxs_with_preds(pred.follower)) do
      buff[idx] = {atk={"=",a_mag},def={"=",d_mag},sta={"=",s_mag}}
    end
    buff:apply()
  end
end,

--[[
Discover Evidence
]]
[200468] = function(player)
  if player.field[5] and pred.follower(player.field[5]) then
    OneBuff(player, 5, {atk={"+",4},sta={"+",4}}):apply()
  end
end,

--[[
World is Cake
]]
[200469] = function(player)
  local idxs = player:deck_idxs_with_preds(pred.follower)
  for i=1,min(2,#idxs) do
    player:deck_to_top_deck(idxs[i])
  end
  if idxs[2] then
    local d = player.deck
    d[#d], d[#d - 1] = d[#d - 1], d[#d]
  end
  local mag = ceil(#player:empty_hand_slots() / 2)
  local buff = GlobalBuff(player)
  if idxs[1] then
    buff.deck[player][#player.deck] = {atk={"+",mag},sta={"+",mag}}
  end
  if idxs[2] then
    buff.deck[player][#player.deck - 1] = {atk={"+",mag},sta={"+",mag}}
  end
  buff:apply()
end,

--[[
Investigation Progress
]]
[200470] = function(player, opponent)
  for i = 1, 5 do
    local card = opponent.field[i]
    if card then
      local pred_name = function(card2) return card.name == card.name end
      local idxs = opponent:field_idxs_with_preds(pred_name)
      if idxs[2] then
        local impact = Impact(opponent)
        for _, idx in ipairs(idxs) do
          impact[opponent][idx] = true
        end
        impact:apply()
        for _, idx in ipairs(idxs) do
          opponent:field_to_grave(idx)
        end
      end
    end
  end
end,

--[[
  Maid Vacancy
]]
[200471] = function(player, opponent)
  local mag = 0
  for i = #opponent.grave, #opponent.grave-4, -1 do
    if opponent.grave[i] and pred.spell(opponent.grave[i]) then
      opponent:grave_to_exile(i)
      mag = mag + 1
    end
  end
  OneBuff(opponent, 0, {life={"-", mag}}):apply()
end,

--[[
  Parliament
]]
[200472] = function(player, opponent)
  for i = 1, 2 do
    if i == 2 and not pred.A(player.character) then return end
    local idx1 = uniformly(opponent:field_idxs_with_preds(pred.follower))
    local idx2 = uniformly(opponent:empty_field_slots())
    if idx1 and idx2 then
      opponent.field[idx1], opponent.field[idx2] = nil, opponent.field[idx1]
      local mag = abs(idx1 - idx2)
      OneBuff(opponent, idx2, {atk={"-", mag}, sta={"-", mag}}):apply()
    end
  end
end,

--[[
  Linia's Counterattack
]]
[200473] = function(player, opponent)
  local check = player:field_idxs_with_preds(pred.follower)[1]
  if check then
    local idx = uniformly(opponent:field_idxs_with_preds(pred.follower,
        function(card) return #card:squished_skills() >= 2 end))
    if idx then
      OneImpact(opponent, idx):apply()
      opponent:field_to_bottom_deck(idx)
      OneBuff(player, 0, {life={"-", 1}}):apply()
    end
  end
end,

--[[
  Situation Resolved
]]
[200474] = function(player)
  local idx = uniformly(player:field_idxs_with_preds(pred.C, pred.follower))
  if idx then
    OneImpact(player, idx):apply()
    player.field[idx]:gain_skill(1457)
  end
end,

--[[
  Sudden Turn
]]
[200475] = function(player)
  local idx = player:field_idxs_with_preds(pred.follower,
      function(card) return card.atk <= 5 end)[1]
  if idx then
    local mag = player.field[idx].atk * 2
    OneBuff(player, idx, {atk={"=", mag}}):apply()
  end
end,

--[[
  Party Time
]]
[200476] = function(player)
  local mag = 1
  while (not player.hand[4]) and player.deck[1] do
    player:deck_to_hand(#player.deck)
    mag = mag + 1
  end
  local idx = uniformly(player:field_idxs_with_preds(pred.follower))
  if idx then
    OneBuff(player, idx, {def={"+", mag}, sta={"+", mag}}):apply()
  end
end,

--[[
  Congregation Expansion
]]
[200477] = function(player, opponent)
  if player:field_idxs_with_preds(pred.follower)[1] then
    local idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
    if idx then
      OneBuff(opponent, idx, {def={"+", 1}}):apply()
      local idx2 = player:first_empty_field_slot()
      if opponent.field[idx].def >= 5 and idx2 then
        opponent.field[idx], player.field[idx2] = nil, opponent.field[idx]
        player.field[idx2].active = false
      end
    end
  end
end,

--[[
  Witness of Miracles
]]
[200478] = function(player, opponent)
  local idx1 = uniformly(player:hand_idxs_with_preds(pred.spell, function(card) return card.id ~= 200478 end))
  local idx2 = player:first_empty_field_slot()
  if player:field_idxs_with_preds(pred.follower)[1] and player:field_idxs_with_preds(pred.spell)[2]
      and opponent:field_idxs_with_preds(pred.spell)[1] and idx1 and idx2 then
    player.field[idx2] = Card(player.hand[idx1].id)
  end
end,

--[[
  Agent of God
]]
[200479] = function(player, opponent)
  local idx1 = opponent:grave_idxs_with_preds(pred.follower)[1]
  local idx2 = player:field_idxs_with_preds(pred.follower)[1]
  local idx3 = player:first_empty_field_slot()
  if idx1 and idx2 and idx3 and opponent.grave[idx1].size == player.field[idx2].size then
    local card = table.remove(opponent.grave, idx1)
    player.field[idx2] = card
  end
end,

[200655] = function(player, opponent, my_idx, my_card)
  if pred.D(player.character) then
    local amount = 1+floor(opponent.character.life/10)
    OneBuff(opponent, 0, {life={"-",amount}}):apply()
  end
  local sta_debuff_amount = 3-floor(opponent.character.life/10)
  local buff = GlobalBuff(player)
  local idxs = opponent:deck_idxs_with_preds(pred.follower)
  for _,idx in ipairs(idxs) do
    buff.deck[opponent][idx] = {sta={"-",sta_debuff_amount}}
  end
  buff:apply()
  if my_card.size >= 4 then
    player:field_to_exile(my_idx)
  else
    my_card.size = my_card.size + 1
    player:field_to_top_deck(my_idx)
  end
end,

--[[
  Library Club Member's Rest
]]
[200480] = function(player)
  local idxs = player:field_idxs_with_preds(pred.follower)
  local mag = 0
  local buff = OnePlayerBuff(player)
  for _, idx in ipairs(idxs) do
    buff[idx] = {size={"-", 1}, atk={"+", 2}, sta={"+", 2}}
  end
  buff:apply()
  idxs = reverse(player:deck_idxs_with_preds(pred.follower))
  buff = GlobalBuff(player)
  for i = 1, mag do
    if idxs[i] then
      buff.deck[player][idxs[i]] = {size={"+", 1}, atk={"-", 2}, sta={"-", 2}}
    end
  end
  buff:apply()
end,

--[[
  Student Council President and Morals Committee Leader
]]
[200481] = function(player)
  local idx1 = player:field_idxs_with_preds(pred.follower)[1]
  local idx2 = reverse(player:field_idxs_with_preds(pred.follower))[1]
  if idx1 and idx2 and idx1 ~= idx2 then
    local mag = abs(idx1 - idx2)
    local buff = OnePlayerBuff(player)
    buff[idx1] = {size={"-", mag}}
    buff[idx2] = {size={"-", mag}}
    buff:apply()
    player.field[idx1], player.field[idx2] = player.field[idx2], player.field[idx1]
  end
end,

--[[
  Sita's Delivery
]]
[200482] = function(player)
  for _,deck_idx in ipairs({5,7}) do
    if player.deck[deck_idx] and pred.V(player.deck[deck_idx]) then
      local field_idx = player:first_empty_field_slot()
      if field_idx then
        player.field[field_idx] = deepcpy(player.deck[deck_idx])
      end
    end
  end
  if player.deck[9] and pred.V(player.deck[9]) and #player.hand < 5 then
    player.hand[#player.hand + 1] = deepcpy(player.deck[9])
  end
end,

--[[
  Barter
]]
[200483] = function(player, opponent)
  local pl_idx = player:field_idxs_with_preds(pred.follower)[1]
  local op_idx = uniformly(opponent:hand_idxs_with_preds(pred.follower))
  if pl_idx and op_idx then
    local mag = abs(player.field[pl_idx].size - opponent.hand[op_idx].size)
    local buff = GlobalBuff(player)
    buff.field[player][pl_idx] = {size={"=", opponent.hand[op_idx].size}, atk={"+", mag}, sta={"+", mag}}
    buff.hand[opponent][op_idx] = {size={"=", player.field[pl_idx].size}}
    buff:apply()
  end
end,

--[[
  Private Room
]]
[200484] = function(player, opponent)
  local pl_idx = uniformly(player:field_idxs_with_preds(pred.follower))
  local pred_def = function(card) return card.def >= 0 end
  local op_idx = uniformly(opponent:field_idxs_with_preds(pred.follower, pred_def))
  if pl_idx and op_idx then
    local mag = opponent.field[op_idx].def * 2
    OneBuff(player, pl_idx, {atk={"+", mag}}):apply()
  end
end,

--[[
  Muzisitter's Song
]]
[200485] = function(player, opponent)
  if pred.A(player.character) then
    for pl_idx = 1,5,2 do
      local op_idx = opponent:first_empty_field_slot()
      if player.field[pl_idx] and op_idx then
        OneImpact(player, pl_idx):apply()
        player.field[pl_idx], opponent.field[op_idx] = nil, player.field[pl_idx]
      end
    end
    for op_idx = 2,4,2 do
      local pl_idx = player:first_empty_field_slot()
      if opponent.field[op_idx] and pl_idx then
        OneImpact(opponent, op_idx):apply()
        opponent.field[op_idx], player.field[pl_idx] = nil, opponent.field[op_idx]
      end
    end
  end
end,

--[[
  Meat Shield
]]
[200486] = function(player, opponent)
  local idx = opponent:field_idxs_with_most_and_preds(pred.size, pred.follower, pred.active)[1]
  if #player:field_idxs_with_preds(pred.follower) >= 2 and idx then
    OneImpact(opponent, idx):apply()
    opponent.field[idx].skills = {1076}
    opponent.field[idx].active = false
  end
end,

--[[
  Youngest's Resolve
]]
[200487] = function(player, opponent)
  local idx = player:field_idxs_with_most_and_preds(pred.def, pred.follower)[1]
  if idx then
    local mag = player.field[idx].def * 2
    local mag2 = min(player.field[idx].def * 2, 5)
    local buff = GlobalBuff(player)
    buff.field[player][idx] = {def={"-", mag}}
    idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
    if idx then
      buff.field[opponent][idx] = {atk={"-", mag2}, sta={"-", mag2}}
    end
    buff:apply()
  end
end,

--[[
  Awakening
]]
[200488] = function(player)
  player.shuffles = player.shuffles + 2
  if pred.C(player.character) then
    local mag = min(floor(player.shuffles / 2), 2)
    local buff = GlobalBuff(player)
    local idxs = player:deck_idxs_with_preds(pred.follower)
    for _, idx in ipairs(idxs) do
      buff.deck[player][idx] = {def={"+", mag}}
    end
    buff:apply()
  end
end,

--[[
  GS Executive's Command
]]
[200489] = function(player, opponent, my_idx, my_card)
  local pred_size = function(card) return card.size == my_card.size end
  local idxs = player:deck_idxs_with_preds(pred.follower, pred_size)
  local buff = GlobalBuff(player)
  for _, idx in ipairs(idxs) do
    buff.deck[player][idx] = {atk={"+", 1}, sta={"+", 1}}
  end
  buff:apply()
end,

--[[
  Undertaker's Visit
]]
[200490] = function(player, opponent)
  local idx = opponent:deck_idxs_with_most_and_preds(pred.size, pred.follower)[1]
  if idx then
    local buff = GlobalBuff(player)
    buff.deck[opponent][idx] = {atk={"-", 3}, sta={"-", 3}}
    buff:apply()
  end
end,

--[[
  I WANT YOU
]]
[200491] = function(player, opponent)
  if pred.D(player.character) and opponent.hand[4] then
    for i = 1, 2 do
      local op_idx = uniformly(opponent:field_idxs_with_preds())
      local pl_idx = player:first_empty_field_slot()
      if op_idx and pl_idx then
        OneImpact(opponent, op_idx):apply()
        opponent.field[op_idx], player.field[pl_idx] = nil, opponent.field[op_idx]
        player.field[pl_idx].active = false
      end
    end
  end
end,

--[[
  Loneliness
]]
[200492] = function(player)
  local buff = OnePlayerBuff(player)
  for i = 1, 2 do
    local idx = i * 2
    if player.field[idx] and pred.follower(player.field[idx]) then
      buff[idx] = {def={"+", 2}}
    end
  end
  buff:apply()
end,

--[[
  Waiting
]]
[200493] = function(player)
  local check1 = player:field_idxs_with_preds(pred.follower, pred.N)[1]
  local check2 = player:field_idxs_with_preds(pred.follower, pred.neg(pred.N))[1]
  if check1 and check2 then
    local idxs = shuffle(player:field_idxs_with_preds(pred.follower))
    local buff = OnePlayerBuff(player)
    for i = 1, 2 do
      if idxs[i] then
        buff[idxs[i]] = {atk={"+", 1}, def={"+", 1}, sta={"+", 3}}
      end
    end
    buff:apply()
  end
end,

--[[
  Isfeldt's Threat
]]
[200494] = function(player, opponent)
  local idxs = shuffle(opponent:field_idxs_with_preds(pred.follower))
  local impact = Impact(opponent)
  for i = 1, 2 do
    if idxs[i] then
      impact[opponent][idxs[i]] = true
    end
  end
  impact:apply()
  for i = 1, 2 do
    if idxs[i] then
      opponent.field[idxs[i]]:gain_skill(1440)
    end
  end
end,

--[[
  Gauntlet of Darkness
]]
[200495] = function(player)
  local idx = player:field_idxs_with_preds(pred.follower)[1]
  if idx then
    OneImpact(player, idx):apply()
    player.field[idx]:gain_skill(1482) -- Dark Soul Attack
  end
end,

--[[
  Boot of Darkness
]]
[200496] = function(player)
  local idx = player:field_idxs_with_preds(pred.follower)[1]
  if idx then
    OneImpact(player, idx):apply()
    player.field[idx]:gain_skill(1478) -- Dark Soul Unleashed
  end
end,

--[[
  Exceptional Strategy
]]
[200497] = function(player, opponent)
  local idx = uniformly(player:field_idxs_with_preds(pred.V, pred.follower))
  if idx then
    OneImpact(player, idx):apply()
    player.field[idx].active = false
    local idx = uniformly(opponent:field_idxs_with_preds(pred.spell))
    if idx and opponent:first_empty_hand_slot() then
      OneImpact(opponent, idx):apply()
      opponent:field_to_hand(idx)
    end
  end
end,

--[[
  Memory Loss
]]
[200498] = function(player)
  local mag = 0
  for i = 1, min(4, #player.deck) do
    mag = mag + (pred.follower(player.deck[i]) and 1 or 0)
  end
  local mag_atk = ceil(mag / 2)
  local mag_sta = mag_atk == 2 and 1 or 0
  local idxs = shuffle(player:field_idxs_with_preds(pred.follower))
  local buff = OnePlayerBuff(player)
  for i = 1, 2 do
    if idxs[i] then
      buff[idxs[i]] = {atk={"+", mag_atk}, sta={"+", mag_sta}}
    end
  end
  buff:apply()
end,

--[[
  The truth not meant to be known
]]
[200499] = function(player, opponent)
  local buff = GlobalBuff(player)
  for _, idx in ipairs(player:field_idxs_with_preds(pred.follower)) do
    buff.field[player][idx] = {def={"+", 1}}
  end
  for _, idx in ipairs(opponent:field_idxs_with_preds(pred.follower)) do
    buff.field[opponent][idx] = {def={"+", 1}}
  end
  buff:apply()
  local impact = Impact(player)
  for i = 1, 5 do
    if player.field[i] and pred.follower(player.field[i]) and (not pred.V(player.field[i])) and player.field[i].def >= 3 then
      impact[player][i] = true
    end
    if opponent.field[i] and pred.follower(opponent.field[i]) and opponent.field[i].def >= 3 then
      impact[opponent][i] = true
    end
  end
  impact:apply()
  local mag = 0
  for i = 1, 5 do
    if player.field[i] and pred.follower(player.field[i]) and (not pred.V(player.field[i])) and player.field[i].def >= 3 then
      player:field_to_grave(i)
      mag = mag + 1
    end
    if opponent.field[i] and pred.follower(opponent.field[i]) and opponent.field[i].def >= 3 then
      opponent:field_to_grave(i)
      mag = mag + 1
    end
  end
  if not pred.V(player.character) then
    mag = mag * 2
  end
  OneBuff(player, 0, {life={"-", mag}}):apply()
end,

--[[
  Liberation
]]
[200500] = function(player, opponent)
  local pred_size = function(card) return card.size >= 3 end
  local idxs = opponent:field_idxs_with_preds(pred.follower, pred_size)
  local mag = 0
  local buff = OnePlayerBuff(opponent)
  for _, idx in ipairs(idxs) do
    buff[idx] = {size={"-", 1}}
    mag = mag + 1
  end
  buff[0] = {life={"-", mag}}
  buff:apply()
end,

--[[
  Maid Part-Time Job
]]
[200501] = function(player)
  local idx = player:field_idxs_with_preds(pred.follower)[1]
  if idx then
    local card = player.field[idx]
    local orig = Card(player.field[idx].id)
    local mag_atk = (card.atk > orig.atk) and (card.atk - orig.atk) or 0
    local mag_def = (card.def > orig.def) and (card.def - orig.def) or 0
    local mag_sta = (card.sta > orig.sta) and (card.sta - orig.sta) or 0
    local buff = GlobalBuff(player)
    buff.field[player][idx] = {atk={"=", orig.atk}, def={"=", orig.def}, sta={"=", orig.sta}}
    local idx2 = player:hand_idxs_with_preds(pred.follower)[1]
    if idx2 then
      buff.hand[player][idx2] = {atk={"+", mag_atk}, def={"+", mag_def}, sta={"+", mag_sta}}
    end
    buff:apply()
  end
end,

--[[
  Entrapment
]]
[200502] = function(player, opponent)
  local mag = 0
  local mag_size = 0
  while player.hand[1] do
    if pred.follower(player.hand[1]) then
      mag = mag + 1
    else
      mag_size = mag_size + 1
    end
    player:hand_to_bottom_deck(1)
  end
  while opponent.hand[1] do
    if pred.follower(opponent.hand[1]) then
      mag = mag + 1
    else
      mag_size = mag_size + 1
    end
    opponent:hand_to_bottom_deck(1)
  end
  local idx = player:deck_idxs_with_preds(pred.A, pred.follower)[1]
  if idx then
    local idx2 = player:first_empty_field_slot()
    if idx2 then
      player:deck_to_field(idx)
      OneBuff(player, idx2, {size={"-", mag_size}, atk={"+", mag}, sta={"+", mag}}):apply()
    end
  end
end,

--[[
  The 2nd Volume's Whereabouts
]]
[200503] = function(player, opponent, my_idx, my_card)
  local pred_size = function(card) return card.size == my_card.size end
  local idx = player:deck_idxs_with_preds(pred_size, pred.spell)[1]
  if idx then
    local idx2 = player:first_empty_field_slot()
    if idx2 then
      player:deck_to_field(idx)
      OneImpact(player, idx2):apply()
    end
  end
end,

--[[
  Putting the plan into action
]]
[200504] = function(player, opponent)
  local idx = uniformly(opponent:grave_idxs_with_most_and_preds(pred.size, pred.spell))
  local idx2 = player:first_empty_field_slot()
  if idx and idx2 then
    player.field[idx2] = table.remove(opponent.grave, idx)
    OneImpact(player, idx2):apply()
    player.field[idx2].active = false
  end
end,

--[[
  Sanctuary's Legacy
]]
[200505] = function(player, opponent)
  local mag = 0
  for i = 1, 8 do
    if player.grave[1] then
      player:grave_to_exile(#player.grave)
      mag = mag + 1
    end
    if opponent.grave[1] then
      opponent:grave_to_exile(#opponent.grave)
      mag = mag + 1
    end
  end
  local buff = GlobalBuff(player)
  if mag >= 1 then
    for _, idx in ipairs(player:field_idxs_with_preds(pred.follower)) do
      buff.field[player][idx] = {atk={"+", 3}, sta={"+", 3}}
    end
  end
  if mag >= 8 then
    for _, idx in ipairs(player:hand_idxs_with_preds()) do
      buff.hand[player][idx] = {size={"-", 1}}
    end
  end
  if mag == 16 then
    buff.field[player][0] = {life={"+", 3}}
  end
  buff:apply()
end,

--[[
  Dark Sword Recovery
]]
[200506] = function(player, opponent, my_idx, my_card)
  local pred_size = function(card) return card.size == my_card.size end
  local impact = Impact(opponent)
  for _, idx in ipairs(opponent:field_idxs_with_preds(pred_size)) do
    impact[opponent][idx] = true
  end
  impact:apply()
  for _, idx in ipairs(opponent:field_idxs_with_preds(pred_size)) do
    opponent:field_to_top_deck(idx)
  end
end,

--[[
  Helena's Contact
]]
[200507] = function(player)
  local idx = uniformly(player:field_idxs_with_preds(pred.follower))
  if idx then
    local mag = min(30 - player.character.life, 9)
    OneBuff(player, idx, {atk={"-", mag}, sta={"+", mag}}):apply()
  end
end,

--[[
  Hindered Scheme
]]
[200508] = function(player, opponent, my_idx, my_card)
  if pred.D(player.character) then
    local mag = floor(player.character.life / 2) - 5
    OneBuff(player, 0, {life={"=", ceil(player.character.life / 2) + 5}}):apply()
    if my_card.size <= 2 then
      local idx = player:field_idxs_with_preds(pred.follower)[1]
      if idx then
        OneBuff(player, idx, {atk={"+", mag * 2}, sta={"+", mag * 2}}):apply()
      end
      my_card.size = my_card.size + 2
      player:field_to_top_deck(my_idx)
    else
      local idx = player:grave_idxs_with_preds(pred.follower)[1]
      if idx then
        player:grave_to_top_deck(idx)
      end
    end
  end
end,

--[[
  Loan Check
]]
[200510] = function(player)
  if player:field_idxs_with_preds(pred.follower)[1] and player:hand_idxs_with_preds(pred.follower)[1] then
    local idxs = player:field_idxs_with_preds(pred.follower)
    for _, idx in ipairs(player:hand_idxs_with_preds(pred.follower)) do
      table.insert(idxs, idx + 5)
    end
    local buff = GlobalBuff(player)
    local mag = uniformly({{atk={"+", 4}}, {def={"+", 4}}, {sta={"+", 4}}})
    local idx = uniformly(idxs)
    if idx <= 5 then
      buff.field[player][idx] = mag
    else
      buff.hand[player][idx - 5] = mag
    end
    buff:apply()
  end
end,

--[[
  Supporter
]]
[200511] = function(player)
  local idx = uniformly(player:field_idxs_with_preds(pred.follower))
  if idx then
    local pred_same = function(card) return card ~= player.field[idx] end
    local mag = #player:field_idxs_with_preds(pred.follower, pred.neg(pred.skill), pred_same)
    OneBuff(player, idx, {size={"+", 1}, atk={"+", mag}, def={"+", mag}, sta={"+", mag}}):apply()
  end
end,

--[[
  Clue Found
]]
[200512] = function(player, opponent)
  local idx = uniformly(player:field_idxs_with_preds(pred.follower))
  if idx then
    local buff = GlobalBuff(player)
    buff.field[player][idx] = {}
    local idx2 = reverse(opponent:field_idxs_with_preds(pred.follower))[1]
    if idx2 then
      buff.field[opponent][idx2] = {sta={"-", player.field[idx].atk - 1}}
    end
    buff:apply()
    player.field[idx].active = true
  end
end,

--[[
  The Final Means
]]
[200513] = function(player)
  local idx = reverse(player:deck_idxs_with_preds(pred.follower))[1]
  if idx and (pred.lady(player.deck[idx]) or pred.maid(player.deck[idx])) and player:first_empty_hand_slot() then
    local buff = GlobalBuff(player)
    buff.deck[player][idx] = {atk={"+", 2}, sta={"+", 2}}
    buff:apply()
    player:deck_to_hand(idx)
  end
end,

--[[
  Alliance Refusal
]]
[200514] = function(player, opponent)
  if player.won_flip then
    local impact = Impact(opponent)
    for _, idx in ipairs(opponent:field_idxs_with_preds(pred.spell)) do
      impact[opponent][idx] = true
    end
    impact:apply()
    for _, idx in ipairs(opponent:field_idxs_with_preds(pred.spell)) do
      opponent.field[idx].active = false
    end
  else
    local buff = OnePlayerBuff(player)
    local idxs = player:field_idxs_with_preds(pred.follower)
    for i = 1, 2 do
      if idxs[i] then
        buff[idxs[i]] = {atk={"-", 2}, sta={"-", 2}}
      end
    end
    buff:apply()
  end
end,

--[[
  Ripple
]]
[200515] = function(player, opponent)
  local idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if idx then
    local buff = GlobalBuff(opponent)
    local mag = opponent.field[idx].def
    buff.field[opponent][idx] = {def={"=", 0}}
    for _, idx in ipairs(opponent:hand_idxs_with_preds(pred.follower)) do
      buff.hand[opponent][idx] = {def={"-", mag}}
    end
    buff:apply()
  end
end,

--[[
  Sincerity
]]
[200516] = function(player, opponent)
  local idx = uniformly(opponent:field_idxs_with_preds(pred.follower, pred.neg(pred.skill)))
  if idx then
    OneImpact(opponent, idx):apply()
    opponent:field_to_top_deck(idx)
  end
end,

--[[
  Observation
]]
[200517] = function(player, opponent)
  local idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if idx then
    OneImpact(opponent, idx):apply()
    opponent.field[idx].skills = {}
    local idx = uniformly(player:field_idxs_with_preds(pred.follower))
    if idx then
      OneImpact(player, idx):apply()
      player.field[idx]:refresh()
    end
  end
end,

--[[
  Demotion
]]
[200518] = function(player)
  local idx = player:deck_idxs_with_preds(pred.blue_cross)[1]
  local amt = 0
  while idx and not player.hand[4] do
    player:deck_to_hand(idx)
    amt = amt + 1
    idx = player:deck_idxs_with_preds(pred.blue_cross)[1]
  end
  local buff = OnePlayerBuff(player)
  for _, idx in ipairs(player:field_idxs_with_preds(pred.follower)) do
    buff[idx] = {atk={"+", amt}, sta={"+", amt}}
  end
  buff:apply()
end,

--[[
  Master's Messenger
]]
[200519] = function(player, opponent)
  local idxs = shuffle(player:field_idxs_with_preds(pred.follower))
  local buff = OnePlayerBuff(player)
  for i = 1, 2 do
    if idxs[i] then
      buff[idxs[i]] = {atk={"+", #opponent.hand}}
    end
  end
  buff:apply()
end,

--[[
  New Operation
]]
[200520] = function(player, opponent)
  local buff = GlobalBuff(player)
  local mag = 0
  for i = 1, min(3, #player.deck) do
    local idx = #player.deck - i + 1
    if pred.union (pred.gs, pred.apostle, pred.aletheian) (player.deck[idx]) then
      buff.deck[player][idx] = {size={"-", 1}}
      mag = mag + 1
    end
  end
  local idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if idx then
    buff.field[opponent][idx] = {sta={"-", mag}}
  end
  buff:apply()
end,

--[[
  A Challenger Appears
]]
[200521] = function(player, opponent)
  local zombie = 300072
  local mag = 2
  for _, idx in ipairs(player:grave_idxs_with_preds(pred.spell)) do
    player:grave_to_exile(idx)
    mag = mag + 1
  end
  for i = 1, mag do
    player:to_grave(Card(zombie))
  end
  local idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if idx then
    local pred_zombie = function(card) return floor(card.id) == zombie end
    local mag = min(ceil(#player:grave_idxs_with_preds(pred_zombie) / 2), 6)
    OneBuff(opponent, idx, {sta={"-", mag}}):apply()
  end
end,

--[[
  Prohibition
]]
[200522] = function(player, opponent)
  local buff = GlobalBuff(player)
  local mag = 0
  for _, idx in ipairs(player:field_idxs_with_preds()) do
    buff.field[player][idx] = {size={"=", 2}}
    mag = mag + 1
  end
  for _, idx in ipairs(player:hand_idxs_with_preds()) do
    buff.hand[player][idx] = {size={"=", 1}}
  end
  for _, idx in ipairs(opponent:field_idxs_with_preds()) do
    buff.field[opponent][idx] = {size={"=", 2}}
    mag = mag + 1
  end
  for _, idx in ipairs(opponent:hand_idxs_with_preds()) do
    buff.hand[opponent][idx] = {size={"=", 2}}
    mag = mag + 1
  end
  local idxs = shuffle(opponent:field_idxs_with_preds(pred.follower))
  for i = 1, 2 do
    if idxs[i] then
      buff.field[opponent][idxs[i]].atk = {"-", mag}
      buff.field[opponent][idxs[i]].sta = {"-", floor(mag / 2)}
    end
  end
  buff:apply()
end,

--[[ Beginning of Change ]]
[200523] = function(player)
  local buff = OnePlayerBuff(player)
  for _, idx in ipairs(player:field_idxs_with_preds(pred.cook_club, pred.follower)) do
    local mag = abs(Card(player.field[idx].id).size - player.field[idx].size)
    buff[idx] = {atk={"+", mag}, sta={"+", mag}}
  end
  buff:apply()
end,

--[[ Master of Erasers ]]
[200524] = function(player)
  local idx = player:field_idxs_with_most_and_preds(pred.size, pred.V, pred.follower)[1]
  if idx then
    OneBuff(player, idx, {size={"-", 3}, sta={"-", 1}}):apply()
  end
end,

--[[ Myo Observer ]]
[200525] = function(player, opponent)
  if opponent.field[3] then
    OneImpact(opponent, 3):apply()
    opponent:field_to_bottom_deck(3)
  end
  local idx = opponent:deck_idxs_with_preds(pred.follower)[3]
  if idx then
    opponent.field[3] = table.remove(opponent.deck, idx)
    OneBuff(opponent, 3, pred.V(player.character) and {size={"+", 3}, sta={"-", 3}} or {}):apply()
  end
end,

--[[ Discovered Spy ]]
[200526] = function(player, opponent)
  local idxs = shuffle(opponent:field_idxs_with_preds(pred.follower))
  local mag = #player:field_idxs_with_preds(pred.A, pred.follower)
  local buff = OnePlayerBuff(opponent)
  for i = 1, min(2, #idxs) do
    buff[idxs[i]] = {def={"-", mag}}
  end
  buff:apply()
end,

--[[ Mass Recall ]]
[200527] = function(player, opponent)
  local idxs = player:field_idxs_with_preds(pred.neg(pred.A))
  for _, idx in ipairs(player:hand_idxs_with_preds(pred.neg(pred.A))) do
    table.insert(idxs, idx + 5)
  end
  local idx = uniformly(idxs)
  if idx then
    if idx > 5 then
      player:hand_to_grave(idx - 5)
    else
      OneImpact(player, idx):apply()
      player:field_to_grave(idx)
    end
    local idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
    if idx then
      OneImpact(opponent, idx):apply()
      opponent:field_to_grave(idx)
    end
  end
end,

--[[ Tighten Security ]]
[200528] = function(player, opponent)
  local mag1 = #player.hand
  local mag2 = #player:hand_idxs_with_preds(pred.A)
  local buff = GlobalBuff(player)
  for _, idx in ipairs(opponent:field_idxs_with_preds(pred.follower)) do
    buff.field[opponent][idx] = {atk={"-", mag1}}
  end
  for _, idx in ipairs(player:field_idxs_with_preds(pred.follower)) do
    buff.field[player][idx] = {def={"+", mag2}}
  end
  buff:apply()
end,

--[[ Shield Break ]]
[200529] = function(player, opponent)
  local idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if idx then
    OneBuff(opponent, idx, {def={"-", 3}}):apply()
    if opponent.field[idx].def >= 0 then
      OneBuff(opponent, idx, {def={"-", 2}}):apply()
    end
  end
end,

--[[ Entry Denied ]]
[200530] = function(player, opponent)
  local idx = uniformly(player:field_idxs_with_preds(pred.follower))
  if idx then
    OneImpact(player, idx):apply()
    player.field[idx].active = false
    local idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
    if idx then
      OneImpact(opponent, idx):apply()
      opponent:field_to_top_deck(idx)
    end
  end
end,

--[[ Sky Surprise ]]
[200531] = function(player, opponent)
  local my_idx = player:field_idxs_with_preds(pred.follower)[1]
  local op_idx = opponent:first_empty_field_slot()
  if my_idx and op_idx then
    local mag1 = min(pred.C(player.character) and 8 or 5, player.field[my_idx].sta - 1)
    local mag2 = player.field[my_idx].size - 1
    local buff = OnePlayerBuff(player)
    buff[0] = {life={"-", mag2}}
    buff[my_idx] = {size={"=", 1}, sta={"=", 1}}
    buff:apply()
    player.field[my_idx], opponent.field[op_idx] = opponent.field[op_idx], player.field[my_idx]
    local buff = OnePlayerBuff(opponent)
    for _, idx in ipairs(opponent:field_idxs_with_preds(pred.follower)) do
      buff[idx] = {sta={"-", mag1}}
    end
    buff:apply()
  end
end,

--[[ Pass the Blood ]]
[200532] = function(player)
  if player.field[3] and pred.follower(player.field[3]) then
    local mag = min(3, #player:field_idxs_with_preds(pred.follower))
    OneBuff(player, 3, {def={"+", mag}}):apply()
  end
end,

--[[ Vampiric Rites ]]
[200533] = function(player)
  local idx = player:field_idxs_with_most_and_preds(pred.size, pred.D, pred.follower)[1]
  local pred_diff = function(card) return card ~= player.field[idx] end
  local idxs = player:field_idxs_with_preds(pred_diff, pred.follower)
  local impact = Impact(player)
  for _, idx in ipairs(idxs) do
    impact[player][idx] = true
  end
  impact:apply()
  local mag = 0
  for _, idx in ipairs(idxs) do
    mag = mag + player.field[idx].size
    player:field_to_grave(idx)
  end
  if idx then
    OneBuff(player, idx, {atk={"+", mag}, def={"+", ceil(mag / 2)}, sta={"+", mag}}):apply()
  end
end,

--[[ Devilish Girl ]]
[200534] = function(player, opponent)
  local buff = GlobalBuff(player)
  for _, idx in ipairs(player:field_idxs_with_preds(pred.neg(pred.D), pred.follower)) do
    buff.field[player][idx] = {atk={"-", 2}, def={"-", 2}, sta={"-", 2}}
  end
  for _, idx in ipairs(opponent:field_idxs_with_preds(pred.follower)) do
    buff.field[opponent][idx] = {atk={"-", 2}, def={"-", 2}, sta={"-", 2}}
  end
  buff:apply()
  local buff = GlobalBuff(player)
  local pred_def = function(card) return card.def <= 0 end
  for _, idx in ipairs(player:field_idxs_with_preds(pred.follower, pred_def)) do
    buff.field[player][idx] = {atk={"-", 2}, sta={"-", 1}}
  end
  for _, idx in ipairs(opponent:field_idxs_with_preds(pred.follower, pred_def)) do
    buff.field[opponent][idx] = {atk={"-", 2}, sta={"-", 1}}
  end
  buff:apply()
end,

--[[ New Student Orientation ]]
[200535] = function(player, opponent)
  local mag = ceil(10 / (1 + #opponent:field_idxs_with_preds(pred.follower)))
  local buff = OnePlayerBuff(opponent)
  for _, idx in ipairs(opponent:field_idxs_with_preds(pred.follower)) do
    buff[idx] = {sta={"-", mag}}
  end
  buff:apply()
end,

--[[ Ascension ]]
[200536] = function(player)
  local idx = player:deck_idxs_with_least_and_preds(pred.size)[1]
  if idx then
    local mag = player.deck[idx].size
    OneBuff(player, 0, {life={"+", mag}}):apply()
    player:deck_to_exile(idx)
  end
end,

--[[ Blink ]]
[200537] = function(player, opponent)
  local idx = player:field_idxs_with_preds(pred.follower)[1]
  if idx then
    local idx2 = player:last_empty_field_slot()
    if idx2 then
      local mag = idx2 - idx
      local buff = GlobalBuff(player)
      local idxs = opponent:deck_idxs_with_preds(pred.follower)
      for i = 1, min(4, #idxs) do
        buff.deck[opponent][idxs[i]] = {sta={"-", mag}}
      end
      buff.field[player][idx] = {}
      buff:apply()
      player.field[idx], player.field[idx2] = nil, player.field[idx]
    end
  end
end,

--[[ Insight ]]
[200538] = function(player)
  local idxs = shuffle(player:field_idxs_with_preds(pred.follower))
  local impact = Impact(player)
  for i = 1, min(2, #idxs) do
    impact[player][idxs[i]] = true
  end
  impact:apply()
  for i = 1, min(2, #idxs) do
    player.field[idxs[i]].skills = { 1550 }
  end
end,

--[[ Waiting Garden ]]
[200539] = function(player)
  local idxs = player:deck_idxs_with_preds(pred.spell)
  while idxs[1] and not player.hand[5] do
    local idx = reverse(idxs)[1]
    player:deck_to_hand(idx)
    idxs = player:deck_idxs_with_preds(pred.spell)
  end
end,

--[[ Deja Vu ]]
[200540] = function(player, opponent)
  local hand_idx = opponent:hand_idxs_with_preds(pred.spell)[1]
  local field_idx = opponent:first_empty_field_slot()
  local mag = 0
  while hand_idx and field_idx do
    opponent:hand_to_field(hand_idx)
    OneImpact(opponent, field_idx):apply()
    mag = mag + 1
    hand_idx = opponent:hand_idxs_with_preds(pred.spell)[1]
    field_idx = opponent:first_empty_field_slot()
  end
  if not pred.A(player.character) then
    OneBuff(player, 0, {life={"-", mag}}):apply()
  end
end,

--[[ Jackpot ]]
[200541] = function(player)
  local idxs = shuffle(player:field_idxs_with_preds(pred.follower))
  local mags = { -1, 0, 1, 2, 3 }
  local buff = OnePlayerBuff(player)
  for i = 1, min(2, #idxs) do
    buff[idxs[i]] = {atk={"+", uniformly(mags)}, def={"+", uniformly(mags)}, sta={"+", uniformly(mags)}}
  end
  buff:apply()
end,

--[[ Wind Blade ]]
[200542] = function(player, opponent)
  local idxs = player:field_idxs_with_preds(pred.follower)
  if idxs[1] then
    for _, idx in ipairs(opponent:field_idxs_with_preds(pred.follower)) do
      table.insert(idxs, idx + 5)
    end
    local idx = uniformly(idxs)
    if idx > 5 then
      OneBuff(opponent, idx - 5, {size={"=", 1}, sta={"=", 1}}):apply()
    else
      OneBuff(player, idx, {size={"=", 1}, sta={"=", 1}}):apply()
    end
  end
end,

--[[ Sudden Bolt ]]
[200543] = function(player, opponent, my_idx, my_card)
  if pred.C(player.character) then
    local idx = uniformly(opponent:field_idxs_with_preds())
    if idx then
      local buff = GlobalBuff(player)
      buff.field[opponent][idx] = {}
      if pred.follower(opponent.field[idx]) then
        local idx = uniformly(player:field_idxs_with_preds(pred.follower))
        if idx then
          buff.field[player][idx] = {atk={"+", 2}, sta={"+", 2}}
        end
      else
        buff.field[player][my_idx] = {}
      end
      buff:apply()
      opponent:field_to_top_deck(idx)
      if buff.field[player][my_idx] then
        player:field_to_top_deck(my_idx)
      end
    end
  end
end,

--[[ Freezing Gale ]]
[200544] = function(player, opponent)
  local impact = Impact(player)
  local idxs = player:field_idxs_with_preds(pred.follower)
  local mag = #idxs
  for _, idx in ipairs(idxs) do
    impact[player][idx] = true
  end
  impact:apply()
  for _, idx in ipairs(idxs) do
    player.field[idx].active = false
  end
  local idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if idx then
    OneBuff(opponent, idx, {atk={"-", mag}}):apply()
  end
end,

--[[ Coin Toss ]]
[200545] = function(player, opponent, my_idx, my_card)
  local pred_size = function(card) return card.size <= my_card.size end
  local buff = GlobalBuff(player)
  for _, idx in ipairs(player:field_idxs_with_preds(pred.follower, pred_size)) do
    buff.field[player][idx] = {sta={"-", 4}}
  end
  for _, idx in ipairs(opponent:field_idxs_with_preds(pred.follower, pred_size)) do
    buff.field[opponent][idx] = {sta={"-", 4}}
  end
  buff:apply()
end,

--[[ Hand of Bacchus ]]
[200546] = function(player)
  local zombie = 300072
  local idxs = player:empty_field_slots()
  local buff = GlobalBuff(player)
  for i = 1, min(2, #idxs) do
    player.field[idxs[i]] = Card(zombie)
    buff.field[player][idxs[i]] = {size={"=", 1}, atk={"=", 7}, def={"=", 0}, sta={"=", 1}}
  end
  buff:apply()
end,

--[[ Glorious Sword of Pursuit ]]
[200547] = function(player, opponent)
  local idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if idx then
    local orig = Card(opponent.field[idx].id)
    OneBuff(opponent, idx, {atk={"=", orig.atk}, def={"=", orig.def}, sta={"=", orig.sta}}):apply()
    opponent:field_to_top_deck(idx)
  end
  if opponent:is_npc() then
    player.shuffles = player.shuffles + 1
  end
end,

--[[ Layna's Wish ]]
[200548] = function(player, opponent)
  local idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if idx then
    local mag = ceil(opponent.field[idx].sta / 2)
    OneBuff(opponent, idx, {sta={"=", mag}}):apply()
    if opponent.field[idx].def <= 3 then
      OneBuff(opponent, idx, {sta={"+", 3}}):apply()
    end
  end
end,

--[[ Amrita's Lost Property ]]
[200549] = function(player, opponent)
  local idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if idx then
    OneBuff(opponent, idx, {atk={"=", 0}}):apply()
    opponent.field[idx]:gain_skill(1570) --Comeback
  end
end,

--[[ Midnight Attack ]]
[200550] = function(player, opponent)
  if pred.V(player.character) then
    local f = opponent.field
    local idxs1 = {}
    local idxs2 = {}
    for i = 1, 5 do
      if f[i] and pred.spell(f[i]) then
        idxs2[i] = i
      else
        table.insert(idxs1, i)
      end
    end
    for i = 1, 5 do
      if not idxs2[i] then
        idxs2[i] = table.remove(idxs1, math.random(1, #idxs1))
      end
    end
    f[1], f[2], f[3], f[4], f[5] = f[idxs2[1]], f[idxs2[2]], f[idxs2[3]], f[idxs2[4]], f[idxs2[5]]
    local buff = OnePlayerBuff(opponent)
    local idxs = opponent:field_idxs_with_preds(pred.follower)
    for _, idx in ipairs(idxs) do
      buff[idx] = {atk={"-", 2 * idx}, sta={"-", 2 * idx}}
    end
    buff:apply()
  end
end,

--[[ Iri's Whereabouts ]]
[200551] = function(player, opponent)
  local buff = GlobalBuff(opponent)
  for i = 1, #opponent.hand do
    if pred.spell(opponent.hand[i]) then
      buff.hand[opponent][i] = {size={"+", 1}}
    end
  end
  buff:apply()
end,

--[[ Witch, Witch Meeting ]]
[200552] = function(player, opponent)
  local pred_def = function(card) return card.def >= (pred.A(player.character) and 2 or 3) end
  local idxs = opponent:field_idxs_with_preds(pred.follower, pred_def)
  local buff = OnePlayerBuff(opponent)
  for _, idx in ipairs(idxs) do
    buff[idx] = opponent.field[idx]:squished_skills()[1] and {def={"=", opponent.field[idx].def * 2}} or {}
  end
  buff:apply()
  for _, idx in ipairs(idxs) do
    opponent.field[idx].skills = {}
  end
end,

--[[ Dimensional Confinement ]]
[200553] = function(player, opponent, my_idx)
  if pred.A(player.character) then
    local mag = -1
    local impact = Impact(player)
    local idxs1 = player:field_idxs_with_preds()
    local idxs2 = opponent:field_idxs_with_preds(pred.follower)
    for _, idx in ipairs(idxs1) do
      impact[player][idx] = true
    end
    for _, idx in ipairs(idxs2) do
      impact[opponent][idx] = true
      mag = mag + 1
    end
    impact:apply()
    for _, idx in ipairs(idxs1) do
      player.field[idx].active = false
    end
    for _, idx in ipairs(idxs2) do
      opponent:field_to_bottom_deck(idx)
    end
    local buff = OnePlayerBuff(opponent)
    for i = 1, mag do
      local idx = opponent:first_empty_field_slot()
      if idx then
        opponent.field[idx] = Card(200016) --Bondage
        opponent.field[idx].active = false
        buff[idx] = {size={"=", 1}}
      end
    end
    buff:apply()
  end
end,

--[[ Office Attack ]]
[200554] = function(player, opponent)
  local my_idx = player:field_idxs_with_least_and_preds(pred.sta, pred.follower)[1]
  local op_idx = opponent:first_empty_field_slot()
  if my_idx and op_idx then
    opponent.field[op_idx], player.field[my_idx] = player.field[my_idx], nil
    OneBuff(opponent, op_idx, {atk={"+", 2}}):apply()
  end
end,

--[[ Request ]]
[200555] = function(player, opponent)
  local buff = GlobalBuff(opponent)
  local idxs = opponent:hand_idxs_with_preds(pred.follower)
  for _, idx in ipairs(idxs) do
    buff.hand[opponent][idx] = {sta={"-", 3}}
  end
  buff:apply()
end,

--[[ The Truth Revealed ]]
[200556] = function(player, opponent)
  local buff = GlobalBuff(opponent)
  for _, p in ipairs({player, opponent}) do
    for _, idx in ipairs(p:field_idxs_with_preds(pred.follower)) do
      local orig = Card(p.field[idx].id)
      local mag = -2
      if pred.C(p.field[idx]) then
        mag = 1
      end
      buff.field[p][idx] = {atk={"=", orig.atk + mag}, def={"=", orig.def + mag}, sta={"=", orig.sta + mag}}
    end
  end
  buff:apply()
end,

--[[ Attack Plans ]]
[200557] = function(player, opponent)
  local idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if idx then
    local mag = 10
    for _, idx in ipairs(player:field_idxs_with_preds(pred.follower)) do
      mag = mag - player.field[idx].size
    end
    OneBuff(opponent, idx, {sta={"-", mag}}):apply()
  end
end,

--[[ Unlikely Problem Solver ]]
[200558] = function(player, opponent)
  if not opponent.hand[5] then
    opponent.hand[#opponent.hand + 1] = Card(200071) --Pleased to meet you
  end
end,

--[[ Duress ]]
[200559] = function(player, opponent)
  if opponent.character.life >= 15 then
    local idx = uniformly(opponent:field_idxs_with_preds(pred.spell))
    if idx then
      OneImpact(opponent, idx):apply()
      opponent:field_to_grave(idx)
      player.shuffles = player.shuffles + 1
    end
  end
  if opponent.character.life >= 6 then
    local buff = OnePlayerBuff(opponent)
    for _, idx in ipairs(opponent:field_idxs_with_preds()) do
      buff[idx] = {size={"+", 1}}
    end
    buff:apply()
    opponent.shuffles = opponent.shuffles - 1
  end
  if opponent.character.life <= 5 then
    OneBuff(opponent, 0, {life={"=", 1}}):apply()
  end 
end,

--[[ Backup from another detective ]]
[200560] = function(player)
  local pred_card = function(card) return card.id == 200387 end --Secret Exploration
  local idx = player:deck_idxs_with_preds(pred_card)[1]
  if idx then
    player:deck_to_top_deck(idx)
  end
  if not player:field_idxs_with_preds()[2] then
    for i = 1, 2 do
      player:deck_to_field(#player.deck)
    end
  end
end,

--[[ Asmis's Power ]]
[200561] = function(player)
  local idx = uniformly(player:field_idxs_with_preds(pred.follower))
  if idx then
    local orig = Card(player.field[idx].id)
    OneBuff(player, idx, {atk={"=", orig.atk + 2}, def={"=", orig.def - 1}, sta={"=", orig.sta + 2}}):apply()
  end
end,

--[[ Second Encounter ]]
[200562] = function(player)
  if player.shuffles <= 1 then
    player.shuffles = player.shuffles + 1
  end
  local buff = GlobalBuff(player)
  for i = 1, min(2, #player.deck) do
    if pred.spell(player.deck[i]) then
      buff.deck[player][i] = {size={"-", 1}}
    else
      buff.deck[player][i] = {atk={"+", 1}, sta={"+", 1}}
    end
  end
  buff:apply()
  for i = 1, min(2, #player.deck) do
    player:deck_to_top_deck(1)
  end
end,

--[[ Dimensional Counterattack ]]
[200563] = function(player, opponent)
  local pred_stat = function(card)
    local orig = Card(card.id)
    return card.atk == orig.atk and card.def == orig.def and card.sta == orig.sta
  end
  local idx = opponent:field_idxs_with_preds(pred.follower, pred_stat)[1]
  if idx then
    OneImpact(opponent, idx):apply()
    opponent:field_to_bottom_deck(idx)
  end
end,

--[[ SHUTDOWN ]]
[200564] = function(player, opponent)
  local pred_stat = function(card)
    local orig = Card(card.id)
    return card.atk >= orig.atk and card.def >= orig.def and card.sta >= orig.sta
  end
  local idx = opponent:field_idxs_with_preds(pred.follower, pred_stat)[1]
  if idx then
    local orig = Card(opponent.field[idx].id)
    local stat = uniformly({"atk", "def", "sta"})
    local mag = {}
    mag[stat] = {"=", orig[stat]}
    OneBuff(opponent, idx, mag):apply()
  end
end,

--[[ Disrupted Pieces ]]
[200565] = function(player, opponent)
  if pred.A(player.character) then
    local idx = opponent:deck_idxs_with_preds(pred.neg(pred[opponent.character.faction]))[1]
    if idx then
      opponent:deck_to_exile(idx)
    end
    opponent:to_top_deck(Card(200565)) -- Disrupted Pieces
  else
    OneBuff(player, 0, {life={"+", 1}}):apply()
  end
end,

--[[ Start the Counterattack ]]
[200566] = function(player, opponent)
  local impact = Impact(player)
  local my_idxs = player:field_idxs_with_preds(pred.follower)
  for _, idx in ipairs(my_idxs) do
    impact[player][idx] = true
  end
  local op_idxs = opponent:field_idxs_with_preds(pred.follower)
  for _, idx in ipairs(op_idxs) do
    impact[player][idx] = true
  end
  impact:apply()
  local remove_atk_skills = function(card)
    for i = 1, 3 do
      if skill_id_to_type[card.skills[i]] == "attack" then
        card.skills[i] = nil
      end
    end
  end
  for _, idx in ipairs(my_idxs) do
    remove_atk_skills(player.field[idx])
  end
  for _, idx in ipairs(op_idxs) do
    remove_atk_skills(opponent.field[idx])
  end
end,

--[[ Unity ]]
[200567] = function(player)
  local idx = uniformly(player:field_idxs_with_preds(pred.follower, pred.C))
  if idx then
    OneImpact(player, idx):apply()
    player.field[idx].skills = {1587} -- Extinction
  end
end,

--[[ Sisters' Reunion ]]
[200568] = function(player, opponent)
  local mag = #player:field_idxs_with_preds(pred.follower, pred.C)
  if mag == 1 then
    local idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
    if idx then
      local mag = #player:empty_field_slots()
      OneBuff(opponent, idx, {atk={"-", mag}, def={"-", mag}, sta={"-", mag}}):apply()
    end
  elseif mag == 2 then
    local buff = OnePlayerBuff(player)
    for _, idx in ipairs(player:field_idxs_with_preds(pred.follower)) do
      buff[idx] = {atk={"+", 2}, sta={"+", 2}}
    end
    buff:apply()
  else
    local mag = floor(player:field_size() / 2)
    local buff = OnePlayerBuff(player)
    for _, idx in ipairs(player:field_idxs_with_preds(pred.follower)) do
      buff[idx] = {atk={"+", mag}, sta={"+", mag}}
    end
    buff:apply()
  end
end,

--[[ You have outlived your usefulness ]]
[200569] = function(player, opponent, my_idx, my_card)
  local pred_size = function(card) return card.size <= my_card.size end
  local idx = uniformly(opponent:field_idxs_with_preds(pred_size))
  if idx then
    OneImpact(opponent, idx):apply()
    opponent:field_to_bottom_deck(idx)
  end
end,

--[[ Ruin's Vortex ]]
[200570] = function(player, opponent)
  local mag = #player:field_idxs_with_preds(pred.follower, pred.gs)
  local buff = GlobalBuff(player)
  for _, p in ipairs({player, opponent}) do
    for _, idx in ipairs(p:field_idxs_with_preds(pred.follower)) do
      buff.field[p][idx] = {atk={"+", mag * 2}, sta={"-", mag}}
    end
  end
  buff:apply()
end,

--[[ Advent ]]
[200571] = function(player, opponent)
  if pred.D(player.character) then
    if opponent:field_idxs_with_preds(pred.spell)[1] then
      local buff = OnePlayerBuff(opponent)
      for _, idx in ipairs(opponent:field_idxs_with_preds(pred.follower)) do
        buff[idx] = {atk={"-", 4}, sta={"-", 4}}
      end
      buff:apply()
    else
      OneBuff(player, 0, {life={"-", 1}}):apply()
    end
  end
end,

--[[ Linia's World ]]
[200572] = function(player, opponent, my_card, my_idx)
  local mag = {A=0,C=0,D=0,V=0,N=0,E=0}
  for _, p in ipairs({player, opponent}) do
    for i = 1, 5 do
      if p.field[i] then
        mag[p.field[i].faction] = 1
      end
    end
  end
  local mag = mag.A + mag.C + mag.D + mag.V + mag.N + mag.E
  local mag2 = ceil(mag / 2)
  local buff = OnePlayerBuff(player)
  for _, idx in ipairs(player:field_idxs_with_preds()) do
    if pred.follower(player.field[idx]) then
      buff[idx] = {size={"-", mag2}, atk={"+", mag}, def={"+", mag2}, sta={"+", mag}}
    else
      buff[idx] = {size={"-", mag2}}
    end
  end
  buff:apply()
  for i = min(#player.grave, mag * 2), 1, -1 do
    player:grave_to_bottom_deck(i)
  end
  player:field_to_exile(my_idx)
end,

--[[ Witness ]]
[200573] = function(player, opponent)
  local buff = GlobalBuff(player)
  for _, p in ipairs({player, opponent}) do
    local idxs = p:field_idxs_with_preds(pred.follower)
    for _, idx in ipairs(idxs) do
      local card = p.field[idx]
      local mag = 0
      for i = (card:first_skill_idx() or 4) + 1, 3 do
        if card.skills[i] then
          card.skills[i] = nil
          mag = mag + 1
        end
      end
      buff.field[p][idx] = (p == player) and {atk={"+", mag}, def={"+", mag}, sta={"+", mag}} or {}
    end
  end
  buff:apply()
end,

--[[ Power Unleashed ]]
[200574] = function(player, opponent)
  local idxs = player:field_idxs_with_preds(pred.follower)
  local buff = GlobalBuff(player)
  local mag = 3 - #idxs
  for _, idx in ipairs(idxs) do
    buff.field[player][idx] = {atk={"+", 1}, sta={"+", 1}}
  end
  buff.field[opponent][0] = {life={"-", mag}}
  buff:apply()
end,

--[[ Secret of Kana ]]
[200575] = function(player, opponent)
  local buff = OnePlayerBuff(opponent)
  local idx = opponent:first_empty_field_slot()
  if idx then
    local idx2 = opponent:deck_idxs_with_preds(pred.follower)[1]
    if idx2 then
      opponent:deck_to_field(idx2)
      buff[idx] = {atk={"=", 5}}
    end
  end
  local idx = opponent:first_empty_field_slot()
  if idx then
    local idx2 = opponent:deck_idxs_with_preds()[1]
    if idx2 then
      opponent:deck_to_field(idx2)
      buff[idx] = pred.follower(opponent.field[idx]) and {atk={"=", 5}} or {}
    end
  end
  buff:apply()
end,

--[[ Three Swords ]]
[200576] = function(player)
  local idxs = shuffle(player:field_idxs_with_preds(pred.follower))
  if idxs[3] then
    local buff = OnePlayerBuff(player)
    local mag = ceil((max(player.field[idxs[1]].atk, player.field[idxs[2]].atk, player.field[idxs[3]].atk) + min(player.field[idxs[1]].atk, player.field[idxs[2]].atk, player.field[idxs[3]].atk)) / 2)
    for i = 1, 3 do
      buff[idxs[i]] = {atk={"=", mag}}
    end
    buff:apply()
  end
end,

--[[ Family's Reproach ]]
[200577] = function(player, opponent)
  local idx = uniformly(player:hand_idxs_with_preds(pred.follower, pred.maid))
  if idx then
    player:to_bottom_deck(table.remove(player.hand, idx))
    local idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
    if idx then
      local mag = {}
      for _, stat in ipairs({"atk", "def", "sta"}) do
        mag[stat] = {"=", opponent.field[opponent:field_idxs_with_least_and_preds(pred[stat], pred.follower)[1]][stat]}
      end
      OneBuff(opponent, idx, mag):apply()
    end
  end
end,

--[[ Maid's Obstruction ]]
[200578] = function(player)
  local idxs = player:deck_idxs_with_preds(pred.follower, pred.maid)
  local buff = OnePlayerBuff(player)
  for i = 1, min(#player:empty_field_slots(), #idxs) do
    buff[player:first_empty_field_slot()] = {size={"=", 2}}
    player:deck_to_field(idxs[i])
  end
  buff:apply()
end,

--[[ Discovery of a Gate ]]
[200579] = function(player)
  if player.deck[1] and pred.follower(player.deck[1]) then
    local buff = GlobalBuff(player)
    buff.deck[player][1] = {size={"-", 1}, atk={"+", 2}, sta={"+", 2}}
    buff:apply()
    if not player.hand[5] then
      player:deck_to_hand(1)
    end
  end
end,

--[[ Enhanced Talentium ]]
[200580] = function(player)
  --[[
  local mag = uniformly({}) -- Strong Attack, Strong Attack, Fountain
  local idx = uniformly(player:field_idxs_with_preds(pred.follower()))
  if idx then
    OneImpact(player, idx):apply()
    player.field[idx]:gain_skill(mag)
  end
  ]]
end,

--[[ Forced Return ]]
[200581] = function(player, opponent)
  local pl_idx = player:field_idxs_with_preds(pred.follower, pred.skill)[1]
  if pl_idx then
    local impact = Impact(player)
    impact[player][pl_idx] = true
    local op_idxs = opponent:field_idxs_with_preds(pred.follower, pred.skill)
    for _, idx in ipairs(op_idxs) do
      impact[opponent][idx] = true
    end
    local op_idx = uniformly(opponent:field_idxs_with_preds(pred.spell))
    if op_idx then
      impact[opponent][op_idx] = true
    end
    impact:apply()    
    player:field_to_bottom_deck(pl_idx)
    for _, idx in ipairs(op_idxs) do
      opponent:field_to_bottom_deck(idx)
    end
    if op_idx then
      opponent:field_to_bottom_deck(op_idx)
    end
  end
end,

--[[ Key Acquired ]]
[200582] = function(player)
  local buff = OnePlayerBuff(player)
  local idxs = shuffle(player:field_idxs_with_preds(pred.follower))
  for i = 1, min(#idxs, 2) do
    local mag = (i == 1) and 4 or 5
    buff[idxs[i]] = {sta={"+", mag}}
  end
  buff:apply()
end,

--[[ Relocation Recommendation ]]
[200583] = function(player, opponent)
  if opponent:field_idxs_with_preds(pred.spell)[2] then
    local idx = uniformly(opponent:field_idxs_with_preds())
    OneImpact(opponent, idx):apply()
    opponent:destroy(idx)
  end
end,

--[[ Altar's Ritual ]]
[200584] = function(player, opponent)
  local impact = Impact(player)
  for _, idx in ipairs(opponent:field_idxs_with_preds()) do
    impact[opponent][idx] = true
  end
  impact:apply()
  local idx = uniformly(opponent:field_idxs_with_preds(pred.spell))
  if idx then
    opponent:field_to_top_deck(idx)
  end
  for _, idx in ipairs(opponent:field_idxs_with_preds()) do
    opponent.field[idx].active = false
  end
end,

--[[ Kana Unleashed ]]
[200585] = function(player)
  local impact = Impact(player)
  local idxs = shuffle(player:grave_idxs_with_preds(pred.kana))
  if idxs[3] then
    for i = 1, 3 do
      local idx = player:first_empty_field_slot()
      if idx then
        player.field[idx] = Card(player.grave[idxs[i]].id)
        impact[player][idx] = true
      end
    end
  end
  impact:apply()
end,
}
setmetatable(spell_func, {__index = function()return function() end end})
