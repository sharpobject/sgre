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
  local buff = GlobalBuff(player)
  local target_idx = player:field_idxs_with_preds({pred.faction.A, pred.follower})[1]
  if target_idx then
    local def_amt = #(player:hand_idxs_with_preds({pred.faction.A}))
    local other_amt = ceil(abs(def_amt - player.field[target_idx].def)/2)
    buff.field[player][target_idx] = {def={"=", other_amt},atk={"+", other_amt},
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
  local target_idxs = player:field_idxs_with_preds(pred.C, pred.follower)
  local buff = OnePlayerBuff(player)
  for _,idx in ipairs(target_idxs) do
    buff[idx] = {sta={"+",3}}
    if pred.luthica(player.field[0]) then
      buff[idx].atk = {"+",3}
    end
  end
  if #target_idxs > 0 then
    buff:apply()
  end
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
        buff[i]={size={"-",1},atk={"+",2},sta={"+",2}}
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
  local debuff, buff = GlobalBuff(player), GlobalBuff(player)
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
  local idxs = opponent:field_idxs_with_preds(pred.follower)
  if #idxs == 0 then
    return
  end
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
  local old_idx = uniformly(opponent:field_idxs_with_preds(pred.follower,
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
  -- should that be + 2 instead of + 3?
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
	--buff:apply()
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
[200074] = court_jester(pred.student_council),

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
    local vampires = player:field_idxs_with_preds(pred.union(
      pred.scardel, pred.crescent, pred.flina))
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
    local myhand = player.hand[1]
    local opphand = opponent.hand[1]
    if myhand then
      myhand.size = max(1, myhand.size-1)
      player:hand_to_bottom_deck(1)
    end
    if opphand then
      opphand.size = opphand.size + 1
      opponent:hand_to_bottom_deck(1)
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
  if foll then
    local lifeloss = floor(player.hand[foll].size / 2)
    OneBuff(player, 0, {life={"-",lifeloss}}):apply()
    local buff = OnePlayerBuff(player)
    for _,idx in ipairs(player:field_idxs_with_preds(pred.follower)) do
      buff[idx] = {atk={"+",lifeloss},sta={"+",lifeloss}}
    end
    buff:apply()
  end
end,

--[[
Meeting
Random enemy follower with same faction as your character
is moved to your first empty slot and deactivated
]]
[200229] = function(player, opponent)
  local old_idx = uniformly(opponent:field_idxs_with_preds(pred.follower,
      function(card) return card.faction == player.field[0].faction end))
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
  local idxs = player:field_idxs_with_preds(pred.follower)
  for i=1,3 do
    if idxs[i] then
      buff[idxs[i]] = {atk={"+",abs(4-player.field[idxs[i]].size)},sta={"+",abs(4-player.field[idxs[i]].size)}}
    end
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
  if opponent.grave[1] then
    local mag = opponent.grave[1].size
    opponent:grave_to_exile(1)
    local idx = player:first_empty_field_slot()
    if mag <= 3 then
      player.field[idx] = Card(300072)
      player.field[idx]:gain_skill(1151)
    else
      player.field[idx] = Card(300319)
    end
  end
end,

--[[
Sisters
The first 3 cards in your Grave are exiled
2 random allied followers get ATK+/STA+ equal to the number of exiled Darklore Followers
]]
[200234] = function(player)
  local mag = 0
  for i=1,3 do
    if player.grave[1] then
      if pred.faction.D(player.grave[1]) then
        mag = mag + 1
      end
      player:grave_to_exile(1)
    end
  end
  local buff = OnePlayerBuff(player)
  local idxs = shuffle(player:field_idxs_with_preds(pred.follower))
  for i=1,2 do
    if idxs[i] then
      buff[idxs[i]] = {atk={"+",mag},sta={"+",mag}}
    end
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
  local idx = 1
  while true do
    if player.grave[idx] then
      if pred.follower(player.grave[idx]) and pred.faction.D(player.grave[idx]) then
        player:grave_to_exile(idx)
        mag = mag + 1
        idx = idx - 1
      end
    else
      break
    end
  end
  idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
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
  for i=1,count do
    if player.hand[1] then
      player:hand_to_bottom_deck(1)
      mag = mag + 1
    end
    if opponent.hand[1] then
      opponent:hand_to_bottom_deck(1)
      mag = mag + 1
    end
  end
  local idx = uniformly(player:field_idxs_with_preds(pred.follower))
  if idx then
    OneBuff(player, idx, {sta={"+",mag}})
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
  OneBuff(player, 0, {life={"+",count}}):apply()
  local buff = OnePlayerBuff(player)
  for _,idx in ipairs(player:field_idxs_with_preds(pred.follower)) do
    buff[idx] = {sta={"+",count}}
  end
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
      size_m = size_m - 1
    end
    if count["N"] then
      atk_m = atk_m + 2
      sta_m = sta_m + 2
    end
    OneBuff(player, idx, {size={"-",size_m},atk={"+",atk_m},at={"+",sta_m}}):apply()
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
  local target = uniformly(opponent:field_idxs_with_preds(pred.follower, pred.skill))
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
  if true then return end -- I think this spell is bugged and actually does nothing...
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
  local my_idx = player:field_idxs_with_least_and_preds(pred.def, {pred.follower})[1]
  local op_idx = opponent:field_idxs_with_most_and_preds(pred.def, {pred.follower})[1]
  if my_idx and op_idx then
    OneBuff(player, my_idx, {def={"=",opponent.field[op_idx].def}}):apply()
  end
end,

--[[
Hiking Lesson
All enemy Followers get -STA equal to average Size on your Field
]]
[200302] = function(player, opponent)
  local idxs = player:field_idxs_with_preds(function(card) return true end)
  local total = 0
  local count = #idxs
  for _,idx in ipairs(idxs) do
    total = total + player.field[idx].size
  end
  idxs = opponent:field_idxs_with_preds(pred.follower)
  local buff = OnePlayerBuff(opponent)
  for _, idx in ipairs(idxs) do
    buff[idx] = {sta={"-",floor(total / count)}}
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
  for i=#player.deck,1,-1 do
    if pred.follower(player.deck[i]) and pred.faction.V(player.deck[i]) then
      buff.deck[player][i] = {atk={"+",mag},sta={"+",mag}}
      mag = mag - 1
    end
    if mag == 0 then
      break
    end
  end
  buff:apply()
  player.shuffles = player.shuffles + 1
end,

--[[
Protection
If there is an enemy Spell on the Field, a random enemy Follower gets -4 DEF
]]
[200304] = function(player, opponent)
  if #opponent:field_idxs_with_preds(pred.spell) > 0 then
    local op_idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
    if op_idx then
      OneBuff(opponent, op_idx, {def={"-",4}}):apply()
    end
  end
end,

--[[
Lady's Rest
For each allied Lady Follower, the first Spell in the enemy Deck is sent to the bottom of the enemy Deck
]]
[200305] = function(player, opponent)
  local mag = #player:field_idxs_with_preds({pred.follower, pred.lady})
  for i=1,mag do
    local idx = opponent:deck_idxs_with_preds(pred.spell)[1]
    if idx then
      player:deck_to_bottom_deck(idx)
    end
  end
end,

--[[
Crossroads of Chaos
If you have an Academy Character and your Field SIZE is at least 3, all cards on the Field are randomly
rearranged
The number of movements will not exceed the total number of cards on the Field
]]
[200306] = function(player, opponent)
  if player:field_size() >= 3 then
    local mag = #player:field_idxs_with_preds() + #opponent:field_idxs_with_preds()
  
  end
end,

--[[
Sanctuary Exploration
The first Sanctuary card in your Deck is sent to the top
If this happens, your Character gets LIFE+ equal to the card's SIZE / 2 rounded up
]]
[200307] = function(player)
  local idx = player:deck_idxs_with_preds(pred.sanctuary)
  if idx then
    local mag = ceil(player.deck[idx].size / 2)
    player:deck_to_top_deck(idx)
    OneBuff(player, 0, {life={"+",mag}}):apply()
  end
end,

--[[
Quick as the Wind
2 allied Followers get -Size/+STA equal to the number of allied Spells
]]
[200308] = function(player)
  local count = #player:field_idxs_with_preds(pred.spell)
  local target_idxs = shuffle(player:field_idxs_with_preds(pred.follower))
  local buff = OnePlayerBuff(player)
  for i=1,2 do
    if target_idxs[i] then
      buff[target_idxs[i]] = {size={"-",count},sta={"+",count}}
    end
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
  if pred.faction.C(player.field[0]) then
    local check = false;
    for i=1,5 do
      if player.field[i] and pred.spell(player.field[i]) then
        player:field_to_grave(i)
        check = true
      end
      if opponent.field[i] and pred.spell(opponent.field[i]) then
        player:field_to_grave(i)
        check = true
      end
    end
    if check then
      local idx = player:hand_idxs_with_preds(pred.spell)[1]
      if idx then
        if player:first_empty_field_slot() then
          player:hand_to_field(idx)
        end
      end
      idx = opponent:first_empty_field_slot()
      if idx then
        opponent.field[idx] = Card(200286)
        opponent.field[idx].size = 2
      end
    end
  end
end,

--[[
Protective Instinct
The first allied Follower is sent to the top of the Deck
If that happens, the next allied Follower gets ATK+4/STA+x x = the sent card's DEF
That Follower also gets SIZE-1 if the sent card was an Aletheian
]]
[200310] = function(player)
  local idx = player:field_idxs_with_preds(pred.follower)[1]
  if idx then
    local size_m = 0
    if pred.aletheian(player.field[idx]) then
      size_m = 1
    end
    local sta_m = player.field[idx].def
    player:field_to_top_deck(idx)
    idx = player:field_idxs_with_preds(pred.follower)[1]
    if idx then
      OneBuff(player, idx, {size={"-",size_m},atk={"+",4},sta={"+",sta_m}}):apply()
    end
  end
end,

--[[
GS Attack Formation
The first allied GS Follower is sent to the enemy Field, gets ATK=0/STA+ its old ATK / 2 rounded down
Its skills become Break and Death
]]
[200311] = function(player, opponent)
  local pl_idx = player:field_idxs_with_preds({pred.follower, pred.gs})
  if pl_idx then
    local op_idx = opponent:first_empty_field_slot()
    if op_idx then
      local card = player.field[pl_idx]
      player.field[pl_idx], opponent.field[op_idx] = nil, player.field[pl_idx]
      OneBuff(opponent, op_idx, {atk={"=",0},sta={"+",floor(card.atk/2)}}):apply()
      card:remove_skill(1)
      card:remove_skill(2)
      card:remove_skill(3)
      card:gain_skill(1274)
      card:gain_skill(1151)
    end
  end
end,

--200312

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
If there are any active enemy cards of the same spell, this card remains active on the Field
]]
[200322] = function(player, opponent, my_idx, my_card)
  local idx = uniformly(player:field_idxs_with_preds(pred.follower))
  if idx then
    OneBuff(player, idx, {atk={"+",1},sta={"+",1}}):apply()
  end
  idx = opponent:field_idxs_with_preds({pred.active,
      function(card) return card.id ~= my_card.id end})[1]
  if idx then
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
  for i=1,2 do
    if idxs[i] then
      buff[idxs[i]] = {atk={"-",1},sta={"-",1}}
    end
  end
  buff:apply()
  local buff2 = OnePlayerBuff(opponent)
  for i=1,2 do
    if idxs[i] and opponent.field[idxs[i]].sta % 2 == 0 then
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
  local mag = #player:field_idxs_with_preds({pred.follower, pred.lady})
  local count = 0
  for i=1,mag do
    if opponent:first_empty_hand_slot() then
      local idx = opponent:deck_idxs_with_preds(pred.follower)[1]
      if idx then
        opponent:deck_to_hand(idx)
        count = count + 1
      end
    end
  end
  if count >= 3 then
    local idx = uniformly(opponent:field_idxs_with_preds())
    if idx then
      opponent:field_to_top_deck(idx)
    end
  end
end,

--[[
Warning
All enemy Followers get -ATK/-STA equal to empty Slots in your Hand
All cards in both Hands are sent to the bottom of the Decks
]]
[200325] = function(player, opponent)
  local mag = 5 - #player.hand
  local idxs = opponent:field_idxs_with_preds(pred.follower)
  local buff = OnePlayerBuff(opponent)
  for i=1,5 do
    if idxs[i] then
      buff[idxs[i]] = {atk={"-",mag},sta={"-",mag}}
    end
  end
  buff:apply()
  for i=1,5 do
    if player.hand[1] then
      player:hand_to_bottom_deck(1)
    end
    if opponent.hand[1] then
      opponent:hand_to_bottom_deck(1)
    end
  end
end,

--[[
Crossing Sanctuary
If you have Crux Character and this card's SIZE is 1, this card gets SIZE=2 and is sent to the enemy Field and deactivated
If this card's SIZE is 2, it gets SIZE=1 and is sent to the enemy Field
]]
[200326] = function(player, opponent, my_idx, my_card)
  if pred.faction.C(player.field[0]) and my_card.size == 1 then
    local new_idx = opponent:first_empty_field_slot()
    if new_idx then
      my_card.active = false
      player.field[my_idx], opponent.field[new_idx] = nil, my_card
      OneBuff(opponent, new_idx, {size={"=",2}}):apply()
    end
  elseif my_card.size == 2 then
    local new_idx = opponent:first_empty_field_slot()
    if new_idx then
      my_card.active = false
      player.field[my_idx], opponent.field[new_idx] = nil, my_card
      OneBuff(opponent, new_idx, {size={"=",1}}):apply()
    end
  end
end,

--[[
Holy Researcher
The first Follower in your Hand is sent to the Grave
The Follower in your Field with the lowest STA gets STA changed equal to the sent Follower's STA
]]
[200327] = function(player)
  local hand_idx = player:hand_idxs_with_preds(pred.follower)[1]
  if hand_idx then
    local mag = player.hand[hand_idx].sta
    player:hand_to_grave(hand_idx)
    local tar_idx = player:field_idxs_with_least_and_preds(pred.sta, pred.follower)[1]
    if tar_idx then
      OneBuff(player, tar_idx, {sta={"=",mag}}):apply()
    end
  end
end,

--[[
Back From Sanctuary
2 random allied Crux Followers get +STA equal to ATK of first enemy Follower.
]]
[200328] = function(player, opponent)
  local op_idx = opponent:field_idxs_with_preds(pred.follower)[1]
  if op_idx then
    local mag = opponent.field[op_idx].atk
    local buff = OnePlayerBuff(player)
    local idxs = shuffle(player:field_idxs_with_preds(pred.follower))
    for i=1,2 do
      if idxs[i] then
        buff[idxs[i]] = {sta={"+",mag}}
      end
    end
    buff:apply()
  end
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
  for i=1,5 do
    if player.field[i] and i ~= tar_idx and i ~= my_idx then
      if player.field[i].size > 1 then
        mag = mag + 1
      end
      buff.field[player][i] = {size={"-",1}}
    end
    if opponent.field[i] then
      if opponent.field[i].size > 1 then
        mag = mag + 1
      end
      buff.field[opponent][i] = {size={"-",1}}
    end
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
    if opponent.field[i] then
      op_size = op_size + opponent.field[op_idxs[i]].size
    end
  end
  if my_size > op_size then
    local op_idx = uniformly(op_idxs)
    local op_card = opponent.field[op_idx]
    OneBuff(opponent, op_idx, {atk={"=",floor(op_card.atk / 2)},def={"=",floor(op_card.atk / 2)},
        sta={"=",floor(op_card.atk / 2)}}):apply()
  end
end,

--[[
Forgotten God's Ritual
If there is an enemy Spell, the first Follower in your Deck is sent to the field and gets ATK+ 4/STA +4
If the Follower is not the same faction as your Character, it gets SIZE- 1
]]
[200331] = function(player, opponent)
  local check = opponent:field_idxs_with_preds(pred.spell)[1]
  if check then
    local idx = player:deck_idxs_with_preds(pred.follower)[1]
    local new_idx = player:first_empty_field_slot()
    if idx and new_idx then
      player:deck_to_field(idx)
      if player.field[new_idx].faction == player.field[0].faction then
        OneBuff(player, new_idx, {size={"-",1},atk={"+",4},sta={"+",4}}):apply()
      else
        OneBuff(player, new_idx, {atk={"+",4},sta={"+",4}}):apply()
      end
    end
  end
end,

--[[
Musiciter Mentor
All cards in your Hand/Deck with SIZE= 10 are sent to the bottom of your Deck
For each card sent, a random enemy card is sent to the top of their Deck and all allied Followers
  get STA+ 1
All allied Followers are deactivated
]]
[200332] = function(player)
  local mag = 0
  for i=1,#player.deck do
    if player.deck[i].size == 10 then
      player:deck_to_bottom_deck(i)
      mag = mag + 1
    end
  end
  for i=1,5 do
    if player.hand[i] and player.hand[i].size == 10 then
      player:hand_to_bottom_deck(i)
      mag = mag + 1
      i = i - 1
    end
  end
  local idxs = shuffle(opponent:field_idxs_with_preds())
  for i=1,mag
    if idxs[i] then
      opponent:field_to_top_deck(idxs[i])
    end
  end
  local buff = OnePlayerBuff(player)
  idxs = player:field_idxs_with_preds(pred.follower)
  for _,idx in ipairs(idxs) do
    buff[idx] = {sta={"+",mag}}
  end
  buff:apply()
  for _,idx in ipairs(idxs) do
    player.field[idx].active = false
  end
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
  if pl_idx then
    player:deck_to_field(pl_idx)
    if player.field[pl_new_idx].size % 2 == 1 then
      player:field_to_grave(pl_new_idx)
    end
  end
  local op_idx = opponent:deck_idxs_with_preds(pred.spell)[1]
  local op_new_idx = opponent:first_empty_field_slot()
  if op_idx then
    opponent:deck_to_field(pl_idx)
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
  local my_idx = player:field_idxs_with_preds(pred.follower)[1]
  if my_idx then
    local my_card = player.field[my_idx]
    local op_idx = uniformly(opponent:field_idxs_with_preds({pred.follower,
        function(card) return card.size <= my_card.size * 2 end}))
    if op_idx then
      local op_card = opponent.field[op_idx]
      local mag = floor((my_card.atk + my_card.sta + op_card.atk + op_card.sta) / 2)
      local buff = GlobalBuff(player)
      buff.field[player][my_idx] = {atk={"=",mag},sta={"=",mag}}
      buff.field[opponent][op_idx] = {atk={"=",mag},sta={"=",mag}}
      buff:apply()
    end
  end
end,

--[[
Petrifying Curse
If you have a Vita Character, all Followers with a SIZE < this card's SIZE are exiled
If this card's SIZE >= 6, this card is exiled
Otherwise, this card gets SIZE+ 2 and is sent to the top of your Deck
]]
[200338] = function(player, opponent, my_idx, my_card)
  if pred.faction.V(player.field[0]) then
    for i=1,5 do
      if player.field[i] and pred.follower(player.field[i]) and 
          player.field[i].size < my_card.size then
        player:field_to_exile(i)
      end
      if opponent.field[i] and pred.follower(opponent.field[i]) and 
          opponent.field[i].size < my_card.size then
        opponent:field_to_exile(i)
      end
    end
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
--200339

--[[
Appointment
Check the top 5 cards of your Deck
2 random allied Followers get ATK+ the number of Spells and STA+ the number of Followers
]]
[200340] = function(player)
  local atk_m = 0
  local sta_m = 0
  for i=0,4 do
    if player.deck[#player.deck - i] then
      if pred.follower(player.deck[#player.deck - i] then
        atk_m = atk_m + 1
      else
        sta_m = sta_m + 1
      end
    end
  end
  local idxs = shuffle(player:field_idxs_with_preds(pred.follower))
  local buff = OnePlayerBuff(player)
  for i=1,2 do
    if idxs[i] then
      buff[idxs[i]] = {atk={"+",atk_m},sta={"+",sta_m}}
    end
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
  if pred.faction.A(player.field[0]) and s_count >= f_count then
    local op_idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
    local mag = min(10, opponent.field[op_idx].size * 2)
    opponent:field_to_grave(op_idx)
    OneBuff(opponent, 0, {life={"-",mag}}):apply()
  end
end,

--[[
Excavation
If you have a Follower, a random enemy Follower gets -1 Size/-1 ATK happens x times where x is
the difference in the number of cards in your and the enemy Fields
]]
[200342] = function(player, opponent)
  if player:field_idxs_with_preds(pred.follower)[1] then
    local mag = abs(player:ncards_in_field() - opponent:ncards_in_field())
    for i=1,mag do
      local op_idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
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
  if pl_idx then
    player:destroy(pl_idx)
    local mag = floor(player.field[pl_idx].size / 2)
    local op_idxs = shuffle(opponent:field_idxs_with_preds(pred.follower))
    for i=1,mag do
      if op_idxs[i] then
        opponent:field_to_grave(op_idxs[i])
      end
    end
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

--200345

--[[
Shaman's Prayer
2 random allied Darklore Followers get ATK + total DEF of all enemy Followers and 
STA - total DEF of all enemy Followers / 2 rounded up + 1
]]
[200346] = function(player, opponent)
  local op_idxs = opponent:field_idxs_with_preds(pred.follower)
  local mag = 0;
  for i=1,5 do
    if op_idxs[i] then
      mag = mag + opponent.field[op_idxs[i]].def
    end
  end
  local pl_idxs = player:field_idxs_with_preds({pred.follower, pred.faction.D})
  local buff = OnePlayerBuff(player)
  for i=1,2 do
    if pl_idxs[i] then
      buff[pl_idxs[i]] = {atk={"+",mag},sta={"-",ceil(mag/2)+1}}
    end
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
      opponent.shuffles = opponent.shuffles - 1
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
  for i=1,5 do
    if player.field[i] and pred.follower(player.field[i]) then
      buff.field[player][i] = {atk={"+",1},sta={"+",1}}
    end
    if opponent.field[i] and pred.follower(opponent.field[i]) then
      buff.field[opponent][i] = {atk={"-",1},sta={"-",1}}
    end
  end
  for i=1,5 do
    if player.hand[i] and pred.follower(player.hand[i]) then
      buff.hand[player][i] = {atk={"+",1},sta={"+",1}}
    end
    if opponent.hand[i] and pred.follower(opponent.hand[i]) then
      buff.hand[opponent][i] = {atk={"-",1},sta={"-",1}}
    end
  end
  for i=1,#player.deck do
    if pred.follower(player.deck[i]) then
      buff.deck[player][i] = {atk={"+",1},sta={"+",1}}
    end
  end
  for i=1,#player.deck do
    if pred.follower(player.deck[i]) then
      buff.deck[player][i] = {atk={"-",1},sta={"-",1}}
    end
  end
  buff.field[player][0] = {life={"+",1}}
  buff:apply()
  player.shuffles = player.shuffles + 1
  player:field_to_exile(my_idx)
end,

--[[
Message
All cards in your Grave of the type of the first card on your Field that is not this card
  are sent to the top of your Deck
This card is exiled
]]
[200352] = function(player, opponent, my_idx, my_card)
  local idx = player:field_idxs_with_preds({pred.follower,
      function(card) return card.id ~= my_card.id end})
  if idx then
    for i=1,#player.grave do
      if player.grave[i] and player.grave[i].id == player.field[idx].id then
        player:grave_to_top_deck(i)
      end
    end
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
  for i=1,2 do
    if idxs[i] then
      local mag = max(4 - player.field[idxs[i]].size, 0)
      buff[idxs[i]] = {size={"=",4},atk={"+",mag},def={"+",mag},sta={"+",mag}}
    end
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
  if pl_idx and op_idx then
    player.field[pl_idx], opponent.field[op_idx] = opponent.field[op_idx], nil
    player.field[pl_idx].active = false
  end
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

--200357

[200358] = function(player, opponent, my_idx, my_card)
  if my_card.size > 3 then
    my_card.size = 3
  end
  OneBuff(player, 0, {life={"+", my_card.size + 1}}):apply()
  if my_card.size > 1 then
    player.send_spell_to_grave = false
    my_card.size = my_card.size - 1
    my_card.active = false
  end
end,

--[[
Kinship
If all cards in your Hand/Field other than this shares your Character's faction, 2 random
enemy Followers get ATK-/DEF- equal to the number of cards in your Hand/Field / 2
]]
[200359] = function(player, opponent, my_idx)
  local check = true
  local mag = 1
  for i=1,5 do
    if player.field[i] and i ~= my_idx then
      check = check and player.field[i].faction == player.field[0].faction
      mag = mag + 1
    end
    if player.hand[i] then
      check = check and player.hand[i].faction == player.field[0].faction
      mag = mag + 1
    end
  end
  if check then
    local idxs = shuffle(opponent:field_idxs_with_preds(pred.follower))
    local buff = OnePlayerBuff(opponent)
    for i=1,2 do
      buff[idxs[i]] = {atk={"-",floor(mag/2)},def={"-",floor(mag/2)}}
    end
    buff:apply()
  end
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
    for i=1,#idxs do
      buff[idxs[i]] = {atk={"-",4},sta={"-",4}}
    end
    buff:apply()
  else
    local buff = OnePlayerBuff(player)
    local idxs = player:field_idxs_with_preds(pred.follower)
    for i=1,#idxs do
      buff[idxs[i]] = {atk={"-",4},sta={"-",4}}
    end
    buff:apply()
  end
end,

--[[
Lonely Operation
All allied GS, Aletheian, and Apostle Followers get ATK+3
]]
[200361] = function(player)
  local idxs = player:field_idxs_with_preds()
  local buff = OnePlayerBuff(player)
  for i=1,#idxs do
    local pl_card = player.field[i]
    if pred.gs(pl_card) or pred.aletheian(pl_card) or pred.apostle(pl_card) then
      buff[idxs[i]] = {atk={"+",3}}
    end
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
  local pl_idxs = player:field_idxs_with_preds({pred.follower, pred.faction.D})
  local mag = 0
  for _,idx in ipairs(pl_idxs) do
    player.field[idx].active = false
    mag = mag + 1
  end
  local op_idx = uniformly(opponent:field_idxs_with_preds({pred.follower,
      function(card) return card.size <= mag end})
  if op_idx then
    if pred.follower(opponent.field[op_idx]) then
      opponent:field_to_bottom_deck(op_idx)
    else
      opponent:field_to_grave(op_idx)
    end
  end
end,
  
--200363

--[[
Nether Cafe
Exile the first card in your Hand
If that happens, destroy a random enemy Follower
]]
[200364] = function(player, opponent)
  if player.hand[1] then
    player:hand_to_exile(1)
    local idx = uniformly(opponent:field_idxs_with_preds(pred.follower))
    opponent:destroy(idx)
  end
end,

--[[
Think Twice Seal
]]
[200365] = function(player, opponent)
  local idxs = shuffle(opponent:field_idxs_with_preds(pred.follower))
  local buff = OnePlayerBuff(opponent)
  for i=1,2 do
    if targets[i] then
      buff[idxs[i]] = {}
      local orig = Card(opponent.field[idx].id)
      for _,attr in ipairs({"atk","def","sta"}) do
        if opponent.field[idxs[i]][attr] > orig[attr] then
          buff[idxs[i]][attr] = {"=", orig[attr])}
        end
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
    local orig = Card(opponent.field[idx].id)
    for _,attr in ipairs({"atk","def","sta"}) do
      if opponent.field[idx][attr] > orig[attr] then
        buff[idx][attr] = {"-", 2*(opponent.field[idx][attr] - orig[attr])}
      end
    end
  end
  buff:apply()
end,

--200367
--200368
--200369
--200370

--[[
Lady's Dinner
If you have a card with SIZE >= 6 on the Field, 2 random enemy Followers get ATK-2/STA-4 
Otherwise, they get ATK-1/STA-2
]]
[200371] = function(player, opponent)
  local check = player:field_idxs_with_preds(function(card) return card.size >= 6 end)[1]
  local buff = OnePlayerBuff(opponent)
  if check then
    local idxs = shuffle(opponent:field_idxs_with_preds(pred.follower))
    for i=1,2 do
      buff[idxs[i]] = {atk={"-",2},sta={"-",4}}
    end
  else
    local idxs = shuffle(opponent:field_idxs_with_preds(pred.follower))
    for i=1,2 do
      buff[idxs[i]] = {atk={"-",1},sta={"-",2}}
    end
  end
  buff:apply()
end,
    
--200372
--200373

--[[
Strength of Determination
2 random allied Crux Followers with DEF >= 1 get ATK + their DEF * 4/DEF - their DEF * 2
]]
[200374] = function(player)
  local idxs = uniformly(player:field_idxs_with_preds({pred.follower,
      function(card) return card.def >= 1 end}))
  local buff = OnePlayerBuff(player)
  for i=1,2 do
    if idxs[i] then
      local card = player.field[idxs[i]]
      buff[idxs[i]] = {atk={"+",card.def * 4},def={"-",card.def * 2}}
    end
  end
  buff:apply()
end,

--200375

--[[
Dignity
x = number of allied Crux Followers
x random enemy Followers get ATK/DEF/STA / (x + 1) rounding down
]]
[200376] = function(player, opponent)
  local mag = #player:field_idxs_with_preds({pred.follower, pred.faction.C})
  local idxs = opponent:field_idxs_with_preds(pred.follower)
  local buff = OnePlayerBuff(opponent)
  for _,idx in ipairs(idxs) do
    local card = opponent.field[idx]
    buff[idx] = {atk={"=",floor(card.atk / (mag + 1))},def={"=",floor(card.def / (mag + 1))}
        sta={"=",floor(card.sta / (mag + 1))}}
  end
  buff:apply()
end,

--[[
She who stands at the top
If your Shuffles >= 1, then all Followers in your Field/Hand get ATK +2/STA +2
]]
[200377] = function(player)
  if player.shuffles >= 1 then
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
  end
end,

--200378
--200379

--[[
Blissful Moment
2 random allied Followers get ATK +2/STA +2
]]
[200380] = function(player)
  local idxs = shuffle(player:field_idxs_with_preds(pred.follower))
  local buff = OnePlayerBuff(player)
  for i=1,2 do
    if idxs[i] then
      buff[idxs[i]] = {atk={"+",2},sta={"+",2}}
    end
  end
  buff:apply()
end,

--200381
--200382
--200383

--[[
Messy Business
A random allied Follower is moved to this card's Slot and gets ATK/STA + new Slot number
]]
[200384] = function(player, opponent, my_idx)
  local idx = uniformly(player:field_idxs_with_preds(pred.follower))
  if idx then
    player.field[my_idx], player.field[idx] = player.field[idx], nil
    OneBuff(player, my_idx, {atk={"+",my_idx},sta={"+",my_idx}}):apply()
  end
end,

--200385
--200386
--200387
--200388
--200389
--200390
--200391
--200392
--200393
--200394
--200395
--200396
--200397
--200398
--200399
--200400
--200401
--200402
--200403
--200404
--200405
--200406

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

--200408
--200409
--200410
--200411
--200412
--200413

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

--200415
--200416
--200417
--200418
--200419
--200420
--200421
--200422
--200423
--200424
--200425
--200426
--200427
--200428
--200429
--200430
--200431
--200432
--200433
--200434
--200435

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
    my_card.size = my_card.size + 1
    player.hand[#player.hand+1] = my_card
    player.field[my_idx] = nil
  end
end,

--200437
--200438
--200439

-- steparu
[200440] = function(player, opponent, my_idx, my_card)
  local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if target then
    opponent.field[target].active = false
    opponent.field[target]:gain_skill(1175)
    opponent.field[target]:gain_skill(1408)
  end
end,

--200441
--200442
--200443
--200444
--200445




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
}
setmetatable(spell_func, {__index = function()return function() end end})
