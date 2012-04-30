local floor,ceil = math.floor, math.ceil

spell_func = {
-- tighten security
[200015] = function(player)
  local buff = Buff(player)
  local target_idx = player:field_idxs_with_preds({pred.faction.A, pred.follower})[1]
  local how_much = #(player:hand_idxs_with_preds({pred.faction.A}))
  if target_idx then
    buff.field[player][target_idx] = {def={"+", how_much}}
    buff:apply()
  end
end,

-- curse
[200017] = function(player)
  if player.character.faction == "A" then
    local debuff = Buff(player)
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

-- vampiric rites
[200033] = function(player)
  local idxs = player:get_follower_idxs()
  local reduced_atk, reduced_sta, debuff, buff = 0, 0, Buff(player), Buff(player)
  for _,idx in ipairs(idxs) do
    debuff.field[player][idx] = {}
    if player.field[idx].atk > 0 then
      debuff.field[player][idx].atk = {"-", player.field[idx].atk - 1}
      reduced_atk = reduced_atk + debuff.field[player][idx].atk[2]
    end
    debuff.field[player][idx].sta = {"-", player.field[idx].sta - 1}
    reduced_sta = reduced_sta + debuff.field[player][idx].sta[2]
  end
  debuff:apply()
  local target_idx = player:field_idxs_with_least_and_preds(
    pred.size, {pred.follower, pred.faction.D})[1]
  if target_idx then
    buff.field[player][target_idx] = {}
    buff.field[player][target_idx].atk = {"+", reduced_atk}
    buff.field[player][target_idx].sta = {"+", reduced_sta}
    buff:apply()
  end
end,
}
setmetatable(spell_func, {__index = function()return function() end end})
