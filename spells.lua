local floor,ceil,min,max = math.floor, math.ceil, math.min, math.max
local abs = math.abs

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
  local function inner_court_jester(player, opponend, my_idx, my_card)
    local target_idxs = shuffle(player:field_idxs_with_preds({pred.follower,
        pred.faction[my_card.faction]}))
    local group_idxs = player:field_idxs_with_preds({pred.follower,
        pred.faction[my_card.faction], group_pred})
    if #group_idx ~= 0 and #group_idxs ~= #target_idxs then
      local buff = OnePlayerBuff(player)
      for i=1,2 do
        buff[target_idxs[i]] = {atk={"+",3},sta={"+",3}}
      end
      buff:apply()
    end
  end
  return inner_court_jester
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
  if #player.field_idxs_with_preds({pred.cook_club}) then
    local target_idxs = shuffle(player.field_idxs_with_preds({pred.follower, pred.faction.V}))
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
    local amount = abs(card.size - other.size)
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
    local buff = GlobalBuff()
    local new_life = ceil((player.character.life + opponent.character.life)/2)
    buff.field[player][0] = {life={"=",new_life}}
    buff.field[opponent][0] = {life={"=",new_life}}
    buff:apply()
  end
  local more_stuff,less_stuff = player, opponent
  if less_stuff:ncards_in_field() > more_stuff:ncards_in_field() then
    more_stuff,less_stuff = less_stuff,more_stuff
  end
  while less_stuff:ncards_in_field() < more_stuff:ncards_in_field() do
    more_stuff:field_to_grave(more_stuff:field_idxs_with_preds({})[1])
  end
  local hand_pred = preds.t
  if pred.faction.V(player.character) then
    hand_pred = preds.follower
  end
  for i=1,#player.hand do
    while player.hand[i] and hand_pred(player.hand[i]) do
      player:hand_to_grave(i)
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
    local buff = OnePlayerBuff()
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
  if #player:field_idxs_with_preds({pred.maid,pred.follower}) then
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
  for i=1,min(3,target_idxs) do
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
  local idx = opponent:field_idxs_with_preds(pred.follower)
  if card and idx then
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
    if preds.luthica(player.field(0)) then
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
  OneBuff(player,target_idx,{atk={"+",#knight_idxs},sta={"+",#knight_idxs}}):apply()
  for _,idx in ipairs(reverse(knight_idxs)) do
    player:grave_to_exile(idx)
  end
  assert(0==player:grave_idxs_with_preds(pred.knight))
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
  local target_idxs = shuffle(player:field_idxs_with_preds({pred.faction.D}))
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
  local target_idx = player:field_idxs_with_preds({pred.follower,pred.faction.D})
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
  local buff = GlobalBuff()
  buff.field[player][0] = {life={"-",1}}
  buff.field[opponent][0] = {life={"-",4}}
  buff:apply()
end,

-- full moon power
[200036] = function(player)
  local targets = player:field_idxs_with_preds({pred.follower,pred.vampire})
  local buff = OnePlayerBuff(player)
  for _,idx in ipairs(targets) do
    buff[idx] = {atk={"+",3}}
  end
  buff:apply()
end,

-- pass the blood
[200037] = function(player)
  local card = player.field[3]
  if card and preds.follower(card) and preds.faction.D(card) then
    local def = 0
    for i=1,5 do
      if preds.follower(player.field[i]) then
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
    if opponent.field[i] and opponent.field[i].sta + opponent.field[i].def > life then
      buff[i]={def={"-",floor(life/2)}}
    end
  end
  buff:apply()
end,

-- forced confinement
[200039] = function(player, opponent)
  local target = opponent:field_idxs_with_most_and_preds(preds.sta,preds.follower)[1]
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
  if kicker and target then
    -- TODO: can this spell heal the enemy follower??
    OneBuff(opponent, target, {sta={"-",opponent.field[kicker].atk + 1}}):apply()
  end
end,

-- book thief
[200043] = function(player, opponent)
  local nlibrarians = #player:field_idxs_with_preds({pred.follower, pred.lib})
  local spells = #opponent:field_idxs_with_preds(pred.spell)
  local new_idx = player:first_empty_field_slot()
  if nlibrarians > #spells and new_idx then
    local old_idx = uniformly(spells)
    player.field[new_idx] = opponent.field[old_idx]
    opponent.field[old_idx] = nil
  end
end,

-- tower of books
[200044] = function(player, opponent)
  local nvita = #player:field_idxs_with_preds({pred.follower, pred.faction.V})
  local spell = opponent:hand_idxs_with_preds({pred.spell,
    function(card) return card.size < 3 end})[1]
  if spell and nvita > 0 then
    local buff = GlobalBuff()
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
  local new_idx = player:fiest_empty_idx()
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
  local idx = player:hand_idxs_with_preds(pred.faction.A)
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
      opponent:destroy(uniformly(his_guys))
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
    player:field_to_grave(follower)
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
  local card2 = opponent.field[2] or fake
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
    {pred.follower, pred.witch})
  if witch then
    local buff = GlobalBuff()
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
  local buff = GlobalBuff()
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
  local buff = GlobalBuff()
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
  local buff = GlobalBuff()
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
  local new_idx = player:fiest_empty_field_slot()
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
  local buff = OnePlayerBuff(player)
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
    end
    player.field_to_exile(my_idx)
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
    local size_cap = my_guy.size
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
    local buff = GlobalBuff()
    buff.field[player][my_follower] = {atk={"=",0},def={"=",0}}
    local debuff_amt = floor(player.field[my_follower].atk +
        player.field[my_follower].def)
    local targets = shuffle(opponent:field_idxs_with_preds(pred.follower))
    for i=1,2 do
      buff.field[opponent][targets[i]] = {atl={"-",debuff_amt}}
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
    player.hand_to_bottom_deck(1)
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
  for i=1,2 do
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
  local cards = shuffle(player.grave_idxs_with_preds(pred.spell))
  if #cards >= 6 then
    for i=1,6 do
      local card = uniformly(player.grave_idxs_with_preds(pred.spell))
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
  for i=1,ndebuff do
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
  local target = opponent.field_idxs_with_preds(
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
      buff[target_idxs[i]] = {atk={"+",buff_amt},sta={"+",buff_amt}}
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
      opponent:hand_to_grave(1)
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
    local target = uniformly(player:field_idxs_with({pred.faction.C, pred.follower}))
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
        local buff = GlobalBuff()
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
[200112] = function(player, opponent)

end,
}
setmetatable(spell_func, {__index = function()return function() end end})
