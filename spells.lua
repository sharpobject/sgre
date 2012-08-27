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
  return function(player, opponend, my_idx, my_card)
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
  return function(player, opponend, my_idx, my_card)
    local amt = 2
    for _,tar_pred in ipairs({pred[my_card.faction], group_pred}) do
      local target_idxs = shuffle(player:field_idxs_with_preds({pred.follower,
          tar_pred}))
      local buff = OnePlayerBuff(player)
      print("Sita's suit found "..#target_idxs.." followers")
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
  local target_idxs = shuffle(opponent:field_idxs_with_preds({pred.follower}))
  if target_idxs[1] then
    OneBuff(opponent, target_idxs[1], {sta={"-",4}}):apply()
  end
  if pred.sita(player.character) then
    if target_idxs[2] then
      target_idxs[1] = target_idxs[2]
    end
    if opponent.field[target_idxs[1]] then
      OneBuff(opponent, target_idxs[1], {sta={"-",2}}):apply()
    end
  end
end,

-- new student orientation
[200002] = new_student_orientation,

-- cooking failure
[200003] = function(player)
  if #player:field_idxs_with_preds({pred.cook_club}) then
    local target_idxs = shuffle(player:field_idxs_with_preds({pred.follower, pred.faction.V}))
    local buff = OnePlayerBuff(player)
    for i=1,min(2,#target_idxs) do
      buff[target_idxs[i]] = {atk={"+",1},def={"+",1},sta={"+",2},size={"+",1}}
    end
    buff:apply()
  end
end,

-- ward rupture
[200004] = function(player, opponent)
  local card, other_card = player.field[3], opponent.field[3]
  if card and other_card and pred.faction.V(card) and pred.follower(card) then
    local amount = abs(card.size - other_card.size)
    OneBuff(player, 3, {atk={"+",amount},sta={"+",amount}}):apply()
  end
end,

-- new recipe
[200005] = function(player)
  OneBuff(player,0,{life={"+",min(5,10-player:field_size())}}):apply()
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
  if abs(player.character.life - opponent.character.life) <= 25 then
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
  if #target_idxs then
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
    local x = #player:hand_idxs_with_preds(pred.faction.V)
    OneBuff(opponent, target_idx, {atk={"-",x},def={"-",x},sta={"-",x}}):apply()
  end
end,

-- accident
[200011] = function(player, opponent)
  local debuff_amount = #player:field_idxs_with_preds({pred.maid,pred.follower})
  local target_idxs = shuffle(opponent:field_idxs_with_preds(pred.follower))
  local buff = OnePlayerBuff(opponent)
  for i=1,min(2,#target_idxs) do
    buff[target_idxs[i]] = {atk={"-",debuff_amount},sta={"-",debuff_amount}}
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
      reduced_amount = reduced_amount + player.field[idx].size
      buff[idx] = {size={"=",1}}
    end
    buff:apply()
    OneBuff(player,uniformly(target_idxs),{size={"+",reduced_amount},
      sta={"+",floor(reduced_amount/2)}}):apply()
  end
end,

-- noble sacrifice
[200014] = function(player)
  local target_idx = player:field_idxs_with_most_and_preds(pred.size,
      {pred.follower, pred.faction.A})[1]
  if target_idx then
    local life_gain = player.field[target_idx].size*2
    player:field_to_grave(target_idx)
    OneBuff(player,0,{life={"+",life_gain}}):apply()
  end
end,

-- tighten security
[200015] = function(player)
  local buff = GlobalBuff(player)
  local target_idx = player:field_idxs_with_preds({pred.faction.A, pred.follower})[1]
  local how_much = #(player:hand_idxs_with_preds({pred.faction.A}))
  if target_idx then
    buff.field[player][target_idx] = {def={"+", how_much}}
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
    if tar1 then
      debuff:apply()
    end
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
  local target_idxs = player:field_idxs_with_preds(pred.knight)
  local buff = OnePlayerBuff(player)
  for _,idx in ipairs(target_idxs) do
    buff[idx] = {sta={"+",3}}
    if pred.luthica(player.field[0]) then
      buff[idx].atk = {"+",3}
    end
  end
end,

-- close encounter
[200022] = new_student_orientation,

-- entry denied
[200023] = function(player, opponent)
  local my_idx = player:field_idxs_with_preds({pred.follower})[1]
  local other_idx = opponent:field_idxs_with_most_and_preds(
    pred.size, {pred.follower})[1]
  -- TODO: can this deactivate an allied follower that is already deactivated?
  -- TODO: can this deactivate an enemy follower that is already deactivated?
  print("entry denied: ", my_idx, other_idx)
  if my_idx and other_idx then
    player.field[my_idx].active = false
    opponent.field[other_idx].active = false
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
    opponent.character.life = opponent.character.life - ceil(card.size/2)
    card.active = false
    card.size = 1
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
      OneBuff(opponent,target_idx,{def={"-",2*def}})
    end
  end
end,

-- sentry's testimony
[200029] = function(player)
  local knight_idxs = player:grave_idxs_with_preds(pred.knight)
  local target_idx = uniformly(player:field_idxs_with_preds(pred.follower))
  if target_idx then
    OneBuff(player,target_idx,{atk={"+",#knight_idxs},sta={"+",#knight_idxs}}):apply()
    for _,idx in ipairs(reverse(knight_idxs)) do
      player:grave_to_exile(idx)
    end
    assert(0==#player:grave_idxs_with_preds(pred.knight))
  end
end,

-- pacifism
[200030] = function(player, opponent)
  local buff = OnePlayerBuff(player)
  for i=1,5 do
    if player.field[i] and pred.follower(player.field[i]) then
      player.field[i].active = false
      if pred.faction.C(player.field[i]) then
        buff[i]={size={"-",1}}
      end
    end
    if opponent.field[i] and pred.follower(opponent.field[i]) then
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
end,

-- blood reversal
[200032] = new_student_orientation,

-- vampiric rites
[200033] = function(player)
  local idxs = player:get_follower_idxs()
  local reduced_atk, reduced_sta, debuff, buff = 0, 0, GlobalBuff(player), GlobalBuff(player)
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
    buff[target_idx] = {sta={"=",1}}
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

-- magic eye
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
end,

-- student council justice
[200041] = function(player, opponent)
  local n_council = #player:field_idxs_with_preds({pred.follower, pred.council})
  local n_vita = #player:field_idxs_with_preds({pred.follower, pred.faction.V})
  if n_council then
    local targets = shuffle(opponent:field_idxs_with_preds(pred.follower))
    local buff = OnePlayerBuff(opponent)
    for i=1,min(2,#targets) do
      if n_vita == 1 then
        buff[targets[i]] = {atk={"-",2}}
      elseif n_vita == 2 then
        buff[targets[i]] = {sta={"-",3}}
      else
        buff[targets[i]] = {atk={"-",2},def={"-",1},sta={"-",2}}
      end
    end
  end
end,

-- student council kick
[200042] = function(player, opponent)
  local kicker = player:field_idxs_with_preds({pred.follower, pred.active, pred.council})[1]
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
  local nlibrarians = #player:field_idxs_with_preds({pred.follower, pred.lib})
  local spells = opponent:field_idxs_with_preds(pred.spell)
  local new_idx = player:first_empty_field_slot()
  if nlibrarians > #spells and new_idx then
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
  local sac = player:field_idxs_with_least_and_preds(pred.sta, pred.follower)[1]
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
  local first = player.field[0]
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
      opponent:field_to_bottom_deck(sidx)
    end
  end
end,

-- no turning back
[200055] = function(player, opponent)
  local my_guys = player:field_idxs_with_preds(pred.follower)
  local his_guys = opponent:field_idxs_with_preds(pred.follower)
  if #my_guys > 0 then
    if opponent:field_size() % 2 == 1 then
      if #his_guys > 0 then
        opponent:destroy(uniformly(his_guys))
      end
    else
      player:field_to_grave(uniformly(my_guys))
    end
  end
end,

-- sense of belonging
[200056] = function(player, opponent)
  local old_idx = uniformly(opponent:field_idxs_with_preds(
    function(card) return card.faction ~= opponent.character.faction end))
  local new_idx = player:first_empty_field_slot()
  if old_idx and new_idx then
    player.field[new_idx] = opponent.field[old_idx]
    opponent.field[old_idx] = nil
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
    function(card) return card.size <= #followers + 3 end })[1]
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
    opponent:destroy(2)
  end
end,

-- luthica's ward
[200061] = function(player, opponent)
  local amt = 2
  -- This 3 will later be buffed to 4...
  for i=1,3 do
    local idx = uniformly(player:grave_idxs_with_preds(pred.faction.C))
    if idx then
      player:grave_to_exile(idx)
      amt = amt + 1
    end
  end
  local targets = shuffle(player:field_idxs_with_preds({pred.follower, pred.faction.C}))
  local buff = OnePlayerBuff(player)
  for i=1,min(#targets,2) do
    buff[targets[i]] = {atk={"+",amt},sta={"+",amt}}
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
    local target = opponent:field_idxs_with_preds(pred.follower)
    if target then
      buff.field[opponent][target] = {sta={"-",reduced_amount}}
    end
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
[200074] = court_jester(pred.council),

-- sage's sermon
[200075] = function(player, opponent)
  local target_idx = uniformly(opponent:field_idxs_with_preds({pred.follower, pred.skill}))
  if target_idx then
    opponent.field[target_idx].skills = {}
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
      local slot = opponent:first_empty_field_slot()
      opponent.field[slot] = deepcpy(my_card)
      opponent.field[slot].size = opponent.field[slot].size - 1
      opponent.field[slot].active = false
    end
    player:field_to_exile(my_idx)
  end
end,

-- say no evil
[200085] = function(player, opponent)
  local acad = player:hand_idxs_with_preds(pred.faction.A)[1]
  if acad then
    while acad do
      player.hand[acad].size = max(player.hand[acad].size-1, 1)
      player:hand_to_bottom_deck(acad)
      acad = player:hand_idxs_with_preds(pred.faction.A)[1]
    end
    for i=1,5 do
      if opponent.field[i] then
        opponent.field[i].active = false
      end
    end
    local target = opponent:hand_idxs_with_preds(pred.spell)
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
    local debuff_amt = floor(player.field[my_follower].atk +
        player.field[my_follower].def)
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
    print("hand to bottom deck 1")
    print("foo "..#player.hand)
    player:hand_to_bottom_deck(1)
  end
  if ncards >= 2 and target then
    opponent:field_to_bottom_deck(target)
  end
end,

-- crux command
[200092] = function(player, opponent)
  local targets = shuffle(player:field_idxs_with_preds(pred.follower))
  local teh_buff = {def={"+",2},sta={"+",1}}
  if #player.deck < 10 then
    teh_buff = {size={"+",1},atk={"+",6},sta={"+",6}}
  end
  local buff = OnePlayerBuff(player)
  for i=1,min(2,#targets) do
    buff[targets[i]] = teh_buff
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
      if opponent.field[i] then
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
      local card = player.deck[#player.deck]
      if pred.faction.D(card) and pred.follower(card) then
        ndebuff = ndebuff + 1
      end
      player:deck_to_grave(#player.deck)
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
    local target_idxs = shuffle(opponent:field_idxs_with_preds({pred.follower}))
    if target_idxs[1] then
      OneBuff(opponent, target_idxs[1], {sta={"-",5}}):apply()
    end
    if #player.deck >= 8 then
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
  if myspells[1] then
    player:hand_to_grave(myspells[1])
  end
  if opspells[1] then
    opponent:hand_to_grave(opspells[1])
  end
  local target = opponent:field_idxs_with_preds(pred.spell)[1]
  if target then
    opponent:field_to_grave(target)
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
      function(card) return map[card.id] end)[1]
  if target then
    local dressup_id = map[player.field[target].id]
    player:field_to_grave(target)
    local deck_target = player:deck_idxs_with_preds(
        function(card) return card.id == dressup_id end)[1]
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
  local dl_in_grave = player:grave_idxs_with_preds({pred.follower, pred.faction.D})
  if #dl_in_grave ~= 0 then
    local card = table.remove(player.grave, dl_in_grave[#dl_in_grave])
    -- For the rest of the spell to happen, we need a vampire and an empty slot.
    local slot = player:first_empty_field_slot()
    local vampires = player:field_idxs_with_preds(pred.vampire)
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
      elseif pred.lib(card) then
        teh_buff.atk[2] = teh_buff.atk[2] + 1
        teh_buff.sta[2] = teh_buff.sta[2] + 1
      elseif pred.council(card) then
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

-- fast forward
[200126] = function(player, opponent, my_idx, my_card)
  local buff_amt = 0
  for i=1,5 do
    while player.hand[i] and pred.C(player.hand[i]) and pred.follower(player.hand[i]) do
      player:hand_to_grave(i)
      buff_amt = buff_amt + 2
    end
  end
  local targets = player:field_idxs_with_preds(pred.follower)
  if target then
    OneBuff(player, targets[#targets], {atk={"+",buff_amt},sta={"+",buff_amt}}):apply()
  end
end,

-- cross cut
[200127] = function(player, opponent, my_idx, my_card)
  local hand_idxs = player:hand_idxs_with_preds(pred.C)
  if #hand_idxs >= 2 then
    player:hand_to_bottom_deck(hand_idxs[#hand_idxs-1])
    player:hand_to_bottom_deck(hand_idxs[#hand_idxs]-1)
    local targets = opponent:field_idxs_with_preds(pred.follower)
    local buff = OnePlayerBuff(opponent)
    for i=1,2 do
      if targets[i] then
        buff[targets[i]] = {sta={"-",2}}
        opponent.field[targets[i]].active = false
      end
    end
    if #player:field_idxs_with_preds(pred.union(pred.knight, pred.blue_cross)) > 0 then
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
    while player.hand[1] do
      player:hand_to_top_deck(1)
    end
    OneBuff(player, 0, {life={"+",ceil(ncards*1.5)}}):apply()
  end
end,

-- false delivery
[200131] = function(player, opponent, my_idx, my_card)
  for _,p in ipairs(player, opponent) do
    for i=1,5 do
      while p.hand[i].faction ~= p.character.faction do
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
  if #player:field_idxs_with_preds(pred.dress_up) > 0 then
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
      opponent:field_to_grave(idx)
    end
    OneBuff(opponent, 0, {life={"-",nlife}}):apply()
  elseif #opp_spell == 0 then
    local nlife = #my_spell
    for _,idx in ipairs(my_spell) do
      player:field_to_grave(idx)
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
    local target = player:field_idxs_with_preds(pred.follower)
    OneBuff(player, target, {atk={"+",4},sta={"+",4}}):apply()
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
  if #player:field_idxs_with_preds(pred.follower, pred.tennis) > 1 then
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
    for _,stat in ipairs({"atk","def","sta","size","skills"}) do
      buff.field[player][my_idx][stat] = {"=",op_card[stat]}
      buff.field[opponent][op_idx][stat] = {"=",my_card[stat]}
    end
    buff:apply()
  end
end,

-- secret art: wind slash
[200146] = function(player, opponent, my_idx, my_card)
  local cards = opponent:field_idxs_with_preds()
  local followers = opponent:field_idxs_with_preds(pred.follower)
  local teh_buff = {sta={"-",floor(#cards/2)}}
  if pred.sita(player.character) then
    teh_buff.def = {"-", #cards}
  end
  local buff = OnePlayerBuff(opponent)
  for _,idx in ipairs(cards) do
    opponent.field[idx].active = false
  end
  for _,idx in ipairs(followers) do
    buff[idx]=teh_buff
  end
  buff:apply()
end,

-- home study
[200147] = function(player, opponent, my_idx, my_card)
  local buff_amt = 1 + #player:grave_idxs_with_preds(
      function(card) return card.id == player.field[my_idx].id end)
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
      -- opponent.field[target].active = false
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
    for i=1,5 do
      local card = opponent.field[i]
      if card and pred.follower(card) and (card.size + player.game.turn + i) % 2 == 1 then
        opponent:field_to_grave(i)
        nlife = nlife + 1
      end
    end
    OneBuff(player, 0, {life={"-",nlife}}):apply()
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
  local amt = floor(player.game.turn / 2)
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
  local targets = opponent:field_idxs_with_preds(pred.follower,
      function(card) return card.atk + card.sta >= 22 end)
  local buff = OnePlayerBuff(opponent)
  for _,idx in ipairs(targets) do
    buff[idx] = {atk={"=",amt},sta={"=",amt}}
  end
  buff:apply()
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
    for _,idx in ipairs(targets) do
      local card = opponent.field[idx]
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
    local amt = 0
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
        teh_buff.sta[2] = teh_buff.sta[2] + p.field[idx].def
      end
    end
    buff:apply()
  end
end,

-- encounter
[200178] = function(player, opponent, my_idx, my_card)
  local amt = 1
  for _,p in ipairs({player, opponent}) do
    local idxs = p:field_idxs_with_preds(pred.spell)
    for _,idx in ipairs(idxs) do
      amt = amt + 1
      p:field_to_grave(idx)
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
  local idxs = player:field_idxs_with_preds(pred.follower, pred.A,
      function(card) return card.size <= 2 end)
  local buff = GlobalBuff(player)
  local atk,sta = 0,0
  for _,idx in ipairs(idxs) do
    buff.field[player][idx] = {atk={"=",1},sta={"=",1}}
    atk = atk + (player.field[idx].atk - 1)
    sta = sta + (player.field[idx].sta - 1)
  end
  local target = player:hand_idxs_with_preds(pred.follower, pred.A)[1]
  if target then
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
  if #player.deck > 0 then
    player:deck_to_grave(#player.deck)
    local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
    if target then
      opponent:field_to_bottom_deck(target)
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
    my_buff.atk = {"+",1}
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
    local gs = player:grave_idxs_with_preds(pred.follower, pred.gs)
    gs = gs[#gs]
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
  --[[ nerf!
  if my_card.size > 5 then
    my_card.size = 5
  end --]]
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
  if pred.D(player.character) then
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
  local buff = OnePlayerBuff(player)
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
  local buff = 0
  for i=1,5 do
    local card = player.field[i]
    if card and pred.follower(card) and card.faction == "C" then
      buff = buff + #card.skills
      card.skills = {}
    end
  end
  for i=1,5 do
    local card = player.field[i]
    if card and pred.follower(card) and card.faction == "C" then
      OneBuff(player, i, {atk={"+",buff},sta={"+",buff}}):apply()
    end
  end
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
      if card and pred.spell(card) and size < card.size then
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
    OneBuff(player, target, {def={"+",1},sta={"+",3}}):apply()
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
  for i=1,5 do
    local myhand = player.hand[i]
    local opphand = opponent.hand[i]
    if myhand then
      myhand.size = max(1, myhand.size-1)
      player:hand_to_bottom_deck(i)
    end
    if opphand then
      opphand.size = opphand.size + 1
      opponent:hand_to_bottom_deck(i)
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

-- sita's suit
[200239] = sitas_suit(pred.sita),

-- perky girl
[200240] = function(player, opponent, my_idx, my_card)
  for i=1,2 do
    if #player.hand < 5 then
      local target = player:deck_idxs_with_preds(pred.sita)[1]
      player:deck_to_hand(target)
      player.hand[#player.hand].size = max(1, player.hand[#player.hand].size - 2)
    end
  end
end,

-- halloween minidevil
[200241] = function(player, opponent, my_idx, my_card)
  local my_guy = player:hand_idxs_with_preds(pred.follower)[1]
  local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if my_guy and target then
    OneBuff(opponent, target, {sta={"-",player.hand[my_guy].atk}}):apply()
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
  local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if target and #player:field_idxs_with_preds(pred.follower) > 0 then
    local idx = opponent.field[target]:first_skill_idx()
    if idx then
      opponent.field[target]:remove_skill(idx)
    end
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

-- halloween wolf
[200250] = function(player, opponent, my_idx, my_card)
  if player:first_empty_field_slot() then
    local myhand = player.hand[1]
    if myhand then
      myhand.size = floor(myhand.size/2)
      player:hand_to_field(1)
      halloween(player, opponent)
    end
  end
end,

-- double student council kick
[200251] = function(player, opponent, my_idx, my_card)
  local kicker = shuffle(player:field_idxs_with_preds({pred.follower, pred.active, pred.council}))
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
  for i=1,5 do
    local card = opponent.field[i]
    if card and pred.follower(card) then
      OneBuff(opponent, i, {atk={"-",#targets + 1}}):apply()
    end
  end
  for i=1,5 do
    if targets[i] then
      OneBuff(player, targets[i], {atk={"+",#targets}}):apply()
    end
  end
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
  local targets = opponent:field_idxs_with_preds(pred.union(pred.sion, pred.rion))
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
  if #player:field_idxs_with_preds(pred.follower, pred.council) > 0 and
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
  local targets = opponent:field_idxs_with_preds(pred.spell)
  for _,idx in ipairs(targets) do
    opponent:field_to_bottom_deck(idx)
  end
  for i=1,#targets + 1 do
    local idx = opponent:first_empty_field_slot()
    if idx then
      opponent.field[idx] = Card(200071)
      opponent.field[idx].active = false
    end
  end
  player.send_spell_to_grave = false
  player.field[my_idx] = nil
end,

-- artificer
[200270] = function(player, opponent, my_idx, my_card)
  targets = shuffle(player:field_idxs_with_preds(pred.follower, pred.seeker))
  buff = OnePlayerBuff(player)
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
  for _,idx in ipairs({my_idx-1,my_idx+1}) do
    local card = player.field[idx]
    if card and pred.follower(card) then
      buff[idx] = {sta={"+",3}}
      if pred.seeker(card) then
        buff[idx].atk={"+",2}
      end
    end
  end
  buff:apply()
  my_card.active = false
  player.send_spell_to_grave = false
  if player.game.turn % 2 == 0 then
    local target = uniformly(opponent:field_idxs_with_preds(pred.spell))
    if target then
      opponent.field[target].active = false
    end
  end
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
  local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if target then
    OneBuff(opponent, target, {atk={"-",atk[my_idx]},sta={"-",sta[my_idx]}}):apply()
  end
  if player.game.turn % 2 == 1 then
    target = uniformly(opponent:field_idxs_with_preds(pred.spell))
    if target then
      opponent.field[target].active = false
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
  local buff = OnePlayerBuff(opponent)
  for _,idx in ipairs(targets) do
    buff[idx] = {atk={"-",2},sta={"-",2}}
  end
end,

-- library explorer
[200280] = function(player, opponent, my_idx, my_card)
  local cards = player:hand_idxs_with_preds(pred.lib)
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
    OneBuff(player, slot, {atk={"+",2},sta={"+",2}}):apply()
    player.field[slot].skills = {"refresh"}
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
    buff[targets[i]] = {atk={"-",floor(amt/2)},sta={"-",floor(amt/2)}}
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
      OneBuff(opponent, target, {atk={"=",id_to_canonical_card[opponent.field[target].id].atk}}):apply()
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
    local skills = opponent.field[idx].skills
    for i=1,3 do
      if skills[i] and skill_id_to_type[skills[i]] == "attack" then
        skills[i] = nil
      end
    end
  end
  targets = opponent:hand_idxs_with_preds(pred.follower)
  for _,idx in ipairs(targets) do
    local skills = opponent.hand[idx].skills
    for i=1,3 do
      if skills[i] and skill_id_to_type[skills[i]] == "attack" then
        skills[i] = nil
      end
    end
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

-- steparu
[200440] = function(player, opponent, my_idx, my_card)
  local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if target then
    opponent.field[target].active = false
    opponent.field[target]:gain_skill(1175)
    opponent.field[target]:gain_skill(1408)
  end
end,
}
setmetatable(spell_func, {__index = function()return function() end end})
