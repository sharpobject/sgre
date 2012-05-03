local floor,ceil,min,max = math.floor, math.ceil, math.min, math.max
local abs = math.abs

local new_student_orientation = function(player, my_idx, my_card)
  local target_idxs = shuffle(player:field_idxs_with_preds({pred.faction[my_card.faction]}))
  local buff = OnePlayerBuff(player)
  for i=1,2 do
    if target_idxs[i] then
      buff[target_idxs[i]] = {atk={"+",2},sta={"+",2}}
    end
  end
  buff:apply()
end

spell_func = {
-- heartless blow
[200001] = function(player)
  local target_idxs = shuffle(player.opponent:field_idxs_with_preds({pred.follower}))
  if target_idxs[1] then
    OneBuff(player.opponent, target_idxs[1], {sta={"-",4}}):apply()
  end
  if pred.sita(player.character) then
    if target_idxs[2] then
      target_idxs[1] = target_idxs[1]
    end
    if player.opponent.field[target_idxs[1]] then
      OneBuff(player.opponent, target_idxs[1], {sta={"-",2}}):apply()
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
[200004] = function(player)
  local card, other_card = player.field[3], player.opponent.field[3]
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
[200006] = function(player)
  local target_idx = player.opponent:field_idxs_with_most_and_preds(
      pred.size, {pred.follower})[1]
  if target_idx then
    local card = player.opponent.field[target_idx]
    OneBuff(player.opponent,target_idx,{sta={"=",floor(card.sta/2)},
      atk={"=",floor(card.atk/2)},def={"=",floor(card.def/2)},
      size={"=",floor(card.size/2)}}):apply()
  end
end,

-- balance
[200007] = function(player)
  if abs(player.character.life - player.opponent.character.life) <= 25 then
    local buff = GlobalBuff()
    local new_life = ceil((player.character.life + player.opponent.character.life)/2)
    buff.field[player][0] = {life={"=",new_life}}
    buff.field[player.opponent][0] = {life={"=",new_life}}
    buff:apply()
  end
  local more_stuff,less_stuff = player, player.opponent
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
[200010] = function(player)
  local target_idx = uniformly(player.opponent:field_idxs_with_preds(pred.follower))
  if target_idx then
    local x = #player:hand_idxs_with_preds(pred.faction.V)
    OneBuff(player.opponent, target_idx, {atk={"-",x},def={"-",x},sta={"-",x}}):apply()
  end
end,

-- accident
[200011] = function(player)
  local debuff_amount = #player:field_idxs_with_preds({pred.maid,pred.follower})
  local target_idxs = player.opponent:field_idxs_with_preds(pred.follower)
  local buff = OnePlayerBuff(player.opponent)
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
[200016] = function(player)
  local buff = OnePlayerBuff(player.opponent)
  local target_idxs = player.opponent:field_idxs_with_preds(pred.follower)
  for i=1,min(3,target_idxs) do
    buff[target_idxs[i]] = {size={"+",1}}
  end
  buff:apply()
end,

-- curse
[200017] = function(player)
  if player.character.faction == "A" then
    local debuff = GlobalBuff(player)
    local tar1, tar2 = unpack(shuffled(
        player.opponent:field_idxs_with_preds({pred.follower})))
    for _,idx in ipairs({tar1,tar2}) do
      debuff.field[player.opponent][idx] = {atk={"-",2},sta={"-",2}}
    end
    if tar1 then
      debuff:apply()
    end
  end
end,

-- swap spell
[200018] = function(player)
  local card = player.field[3]
  local idx = player.opponent:field_idxs_with_preds(pred.follower)
  if card and idx then
    local other_card = player.opponent.field[idx]
    local buff = GlobalBuff(player)
    buff.field[player][3],buff.field[player.opponent][idx] = {},{}
    for _,stat in ipairs({"atk","def","sta","size"}) do
      buff.field[player][3][stat] = {"=",other_card[stat]}
      buff.field[player.opponent][idx][stat] = {"=",card[stat]}
    end
    buff:apply()
  end
end,

-- mass recall
[200019] = function(player)
  for i=1,5 do
    if player.opponent.field[i] and player.opponent.field[i].size <= 3 then
      player.opponent:field_to_grave(i)
    end
    if player.field[i] and player.field[i].faction ~= "A" then
      player:field_to_grave(i)
    end
  end
end,

-- forced entry
[200020] = function(player)
  if player.field[3] and player.opponent.field[3] then
    if player.field[3].size < player.opponent.field[3].size then
      player:destroy(3)
    elseif player.field[3].size > player.opponent.field[3].size then
      player.opponent:destroy(3)
    else
      player.opponent:field_to_grave(3)
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
[200023] = function(player)
  local my_idx = player:field_idxs_with_preds({pred.follower})[1]
  local other_idx = player.opponent:field_idxs_with_most_and_preds(
    pred.size, {pred.follower})[1]
  -- TODO: can this deactivate an allied follower that is already deactivated?
  -- TODO: can this deactivate an enemy follower that is already deactivated?
  print("entry denied: ", my_idx, other_idx)
  if my_idx and other_idx then
    player.field[my_idx].active = false
    player.opponent.field[other_idx].active = false
  end
end,

-- healing magic
[200024] = function(player)
  OneBuff(player, 0, {life = {"+", #player.hand}}):apply()
end,

-- sky surprise
[200025] = function(player)
  local old_idx = player:get_follower_idxs()[1]
  local new_idx = player.opponent:first_empty_slot()
  if old_idx and new_idx then
    local card = player.field[old_idx]
    player.opponent.field[new_idx] = card
    player.field[old_idx] = nil
    player.opponent.character.life = player.opponent.character.life - ceil(card.size/2)
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
[200027] = function(player)
  if player:ncards_in_field() == player.opponent:ncards_in_field() then
    local target_idxs = shuffle(player.opponent:field_idxs_with_preds())
    for i=1,min(2,#target_idxs) do
      player.opponent:field_to_bottom_deck(target_idxs[i])
    end
  end
end,

-- shield break
[200028] = function(player)
  local target_idx = player.opponent:field_idxs_with_most_and_preds(pred.def,pred.follower)[1]
  if target_idx then
    local def = player.opponent.field[target_idx].def
    if def > 0 then
      OneBuff(player.opponent,target_idx,{def={"-",2*def}})
    end
  end
end,

-- sentry's testimony
[200029] = function()

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
  debuff:apply()
  local target_idx = player:field_idxs_with_least_and_preds(
    pred.size, {pred.follower, pred.faction.D})[1]
  if target_idx then
    buff.field[player][target_idx] = buff_stats
    buff:apply()
  end
end,
}
setmetatable(spell_func, {__index = function()return function() end end})
