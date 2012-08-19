local min,max = math.min,math.max

Card = class(function(self, id, upgrade_lvl)
    self.upgrade_lvl = upgrade_lvl or 0
    for k,v in pairs(id_to_canonical_card[id]) do
      self[k]=deepcpy(v)
      print(k,v,self[k])
    end
    --TODO: apply upgrade
  end)

function Card:remove_skill(skill_idx)
  self.skills[skill_idx] = nil
end

function Card:refresh()
  self.skills = deepcpy(id_to_canonical_card[self.id].skills)
end

function Card:remove_skill_until_refresh(skill_idx)
  self.skills[skill_idx] = "refresh"
end

function Card:first_empty_skill_slot()
  for i=1,3 do
    if not self.skills[i] then
      return i
    end
  end
end

function Card:first_skill_idx()
  for i=1,3 do
    if self.skills[i] then
      return i
    end
  end
end

function Card:gain_skill(skill_id)
  local slot = self:first_empty_skill_slot()
  if slot then
    self.skills[slot] = skill_id
  end
end

function Card:squished_skills()
  local t = {}
  local skills = self.skills or {}
  for i=1,3 do
    t[#t+1] = skills[i]
  end
  return t
end

function Card:reset()
  for k,v in pairs(id_to_canonical_card[self.id]) do
    self[k] = deepcpy(v)
  end
  --TODO: apply upgrade
  return self
end

local grave_mt = {__newindex=function(table, key, value)
  if value then
    value:reset()
  end
  rawset(table, key, value)
end}

Player = class(function(self, side, deck)
    deck = shallowcpy(deck)
    if not deck then
      deck = {}
      for i=1,30 do
        deck[i] = 300019
      end
      deck[31] = 100089
    end
    assert(side == "left" or side == "right")
    self.side = side
    map_inplace(function(x) if type(x) == "number" then return x end return x.id end, deck)
    table.sort(deck, function(a,b) return a>b end)
    self.character = Card(deck[#deck])
    deck[#deck] = nil
    self.deck = map(Card, deck)
    shuffle(self.deck)
    self.hand = {}
    self.field = {}
    self.field[0] = self.character
    self.grave = {}
    setmetatable(self.grave, grave_mt)
    self.exile = {}
    self.shuffles = 2
  end)

function Player:check_hand()
  for i=1,4 do
    if self.hand[i+1] and not self.hand[i] then
      error("hand is wrong")
    end
  end
end

function Player:untap_phase()
  for i=1,5 do
    if self.field[i] then
      self.field[i].active = true
    end
  end
end

function Player:upkeep_phase()
  for idx=0,5 do
    local card = self.field[idx]
    if card then
      local skills = card.skills or {}
      for skill_idx = 1,3 do
        local skill_id = skills[skill_idx]
        if skill_id and skill_id_to_type[skill_id] == "start" and
            self.field[idx] == card then
          print("About to run skill func for id "..skill_id)
          if type(skill_id) == "number" and skill_id >= 100000 then
            characters_func[skill_id](self, self.opponent, card)
          else
            skill_func[skill_id](self, idx, card, skill_idx)
          end
          self:check_hand()
          self.opponent:check_hand()
        end
      end
    end
  end
end

function Player:draw_a_card()
  self.hand[#self.hand + 1] = self.deck[#self.deck]
  self.hand[#self.hand].active = true
  self.deck[#self.deck] = nil
end

function Player:draw_from_bottom_deck()
  self.hand[#self.hand + 1] = table.remove(self.deck, 1)
end

function Player:draw_phase()
  if #self.hand == 5 then
    self:hand_to_grave(1)
  end
  if #self.deck == 0 then
    --error("I lost the game :(")
  end
  for i=1,math.min(5-#self.hand, #self.deck) do
    self:draw_a_card()
  end
end

function Player:to_bottom_deck(card)
  table.insert(self.deck, 1, card)
end

function Player:to_top_deck(card)
  self.deck[#self.deck + 1] = card
end

function Player:attempt_shuffle()
  if self.shuffles > 0 then
    self.shuffles = self.shuffles - 1
    local n_cards = #self.hand
    for i=1,n_cards do
      self:to_bottom_deck(self.hand[i])
      self.hand[i] = nil
    end
    for i=1,n_cards do
      self:draw_a_card()
    end
  end
end

function Player:grave_to_exile(n)
  self.exile[#self.exile+1]=table.remove(self.grave,n)
end

function Player:grave_to_bottom_deck(n)
  self:to_bottom_deck(table.remove(self.grave,n))
end

function Player:grave_to_field(n)
  self.field[self:first_empty_field_slot()]=table.remove(self.grave,n)
end

function Player:field_to_exile(n)
  self.exile[#self.exile+1] = self.field[n]
  self.field[n] = nil
end

function Player:hand_to_bottom_deck(n)
  self:to_bottom_deck(self.hand[n])
  for i=n,5 do
    self.hand[i] = self.hand[i+1]
  end
end

function Player:hand_to_top_deck(n)
  self:to_top_deck(self.hand[n])
  for i=n,5 do
    self.hand[i] = self.hand[i+1]
  end
end

function Player:remove_from_hand(n)
  local ret = self.hand[n]
  for i=n,5 do
    self.hand[i] = self.hand[i+1]
  end
  return ret
end

-- discards the card at index n
function Player:hand_to_grave(n)
  self.grave[#self.grave + 1] = self.hand[n]
  for i=n,5 do
    self.hand[i] = self.hand[i+1]
  end
end

function Player:field_to_bottom_deck(n)
  self:to_bottom_deck(self.field[n])
  self.field[n] = nil
end

function Player:field_to_top_deck(n)
  self:to_top_deck(self.field[n])
  self.field[n] = nil
end

function Player:deck_to_hand(n)
  self.hand[#self.hand + 1] = table.remove(self.deck, n)
end

function Player:deck_to_grave(n)
  self.grave[#self.grave + 1] = table.remove(self.deck, n)
end

function Player:to_grave(card)
  self.grave[#self.grave + 1] = card
end

function Player:mill(n)
  for i=1,n do
    self.grave[#self.grave + 1] = self.deck[#self.deck]
    self.deck[#self.deck] = nil
  end
end

function Player:deck_to_field(n)
  local card = table.remove(self.deck, n)
  self.field[self:first_empty_field_slot()] = card
end

function Player:hand_to_exile(n)
  local card = table.remove(self.hand, n)
end

function Player:hand_to_field(n)
  local card = table.remove(self.hand, n)
  self.field[self:first_empty_field_slot()] = card
end

function Player:has_follower()
  return #self:field_idxs_with_preds(pred.follower) ~= 0
end

function Player:field_to_grave(n)
  self.grave[#self.grave + 1] = self.field[n]
  self.field[n] = nil
end

function Player:destroy(n)
  if self.field[n].type == "follower" then
    self.character.life = self.character.life - self.field[n].size
  end
  self:field_to_grave(n)
end

function Player:field_size()
  local ret = 0
  for i=1,5 do
    if self.field[i] then
      ret = ret + self.field[i].size
    end
  end
  return ret
end

function Player:ncards_in_field()
  local ret = 0
  for i=1,5 do
    if self.field[i] then
      ret = ret + 1
    end
  end
  return ret
end

function Player:grave_idxs_with_preds(...)
  local preds = {...}
  if type(preds[1]) == "table" then
    preds = preds[1]
  end
  local ret = {}
  for i=1,#self.grave do
    local incl = true
    for j=1,#preds do
      incl = incl and preds[j](self.grave[i])
    end
    if incl then
      ret[#ret+1] = i
    end
  end
  return ret
end

function Player:hand_idxs_with_preds(...)
  local preds = {...}
  if type(preds[1]) == "table" then
    preds = preds[1]
  end
  local ret = {}
  for i=1,5 do
    if self.hand[i] then
      local incl = true
      for j=1,#preds do
        incl = incl and preds[j](self.hand[i])
      end
      if incl then
        ret[#ret+1] = i
      end
    end
  end
  return ret
end

function Player:field_idxs_with_preds(...)
  local preds = {...}
  if type(preds[1]) == "table" then
    preds = preds[1]
  end
  local ret = {}
  for i=1,5 do
    if self.field[i] then
      local incl = true
      for j=1,#preds do
        incl = incl and preds[j](self.field[i])
      end
      if incl then
        ret[#ret+1] = i
      end
    end
  end
  return ret
end

function Player:deck_idxs_with_preds(...)
  local preds = {...}
  if type(preds[1]) == "table" then
    preds = preds[1]
  end
  local ret = {}
  for i=#self.deck,1,-1 do
    if self.deck[i] then
      local incl = true
      for j=1,#preds do
        incl = incl and preds[j](self.deck[i])
      end
      if incl then
        ret[#ret+1] = i
      end
    end
  end
  return ret
end

function Player:field_idxs_with_least_and_preds(func, ...)
  local idxs = self:field_idxs_with_preds(...)
  local best = 99999
  local ret = {}
  for i=1,#idxs do
    local card = self.field[idxs[i]]
    local score = func(card)
    if score < best then
      ret = {idxs[i]}
      best = score
    elseif score == best then
      ret[#ret+1] = idxs[i]
    end
  end
  return ret
end

function Player:field_idxs_with_most_and_preds(func, ...)
  return self:field_idxs_with_least_and_preds(function(...)return -func(...) end, ...)
end

function Player:hand_idxs_with_least_and_preds(func, ...)
  local idxs = self:hand_idxs_with_preds(...)
  local best = 99999
  local ret = {}
  for i=1,#idxs do
    local card = self.hand[idxs[i]]
    local score = func(card)
    if score < best then
      ret = {idxs[i]}
      best = score
    elseif score == best then
      ret[#ret+1] = idxs[i]
    end
  end
  return ret
end

function Player:hand_idxs_with_most_and_preds(func, ...)
  return self:hand_idxs_with_least_and_preds(function(...)return -func(...) end, ...)
end

function Player:first_empty_field_slot()
  for i=1,5 do
    if not self.field[i] then return i end
  end
  return nil
end

function Player:grave_idxs_with_least_and_preds(func, preds)
  local idxs = self:grave_idxs_with_preds(preds)
  local best = 99999
  local ret = {}
  for i=1,#idxs do
    local card = self.grave[idxs[i]]
    local score = func(card)
    if score < best then
      ret = {idxs[i]}
      best = score
    elseif score == best then
      ret[#ret+1] = idxs[i]
    end
  end
  return ret
end

function Player:grave_idxs_with_most_and_preds(func, preds)
  return self:grave_idxs_with_least_and_preds(function(...)return -func(...) end, preds)
end

function Player:first_empty_field_slot()
  for i=1,5 do
    if not self.field[i] then return i end
  end
  return nil
end

function Player:squish_hand()
  local newhand = {}
  for i=1,5 do
    newhand[#newhand+1] = self.hand[i]
  end
  for i=1,5 do
    self.hand[i] = newhand[i]
  end
end

function Player:has_active_cards()
  for i=1,5 do
    if self.field[i] and self.field[i].active then
      return true
    end
  end
  return false
end

function Player:can_play_card(n)
  return self.hand[n] and (self:field_size() + self.hand[n].size <= 10) and
    self:first_empty_field_slot()
end

function Player:play_card(n)
  self.hand[n].active = true
  self.field[self:first_empty_field_slot()] = self.hand[n]
  for i=n,5 do
    self.hand[i] = self.hand[i+1]
  end
end

function Player:ai_act()
  for i=1,3 do
    if #self.hand > 0 then
      idx = math.random(#self.hand)
      if self:can_play_card(idx) then
        self.hand[idx].hidden = true
        self:play_card(idx)
      end
    end
  end
end

function Player:user_act()
  self.game.act_buttons = true
  local end_time = love.timer.getTime() + 30
  self.game.ready = false
  while not self.game.ready do
    self.game.time_remaining = math.ceil(end_time-love.timer.getTime())
    if self.game.time_remaining <= 0 then
      self.game.ready = true
    end
    wait()
  end
  for i=1,5 do
    if self.opponent.field[i] then
      self.opponent.field[i].hidden = false
    end
  end
  self.game.act_buttons = false
end

function Player:get_follower_idxs()
  local ret = {}
  for i=1,5 do
    if self.field[i] and self.field[i].type == "follower" then
      ret[#ret+1] = i
    end
  end
  return ret
end

function Player:get_atk_target()
  local followers = self:get_follower_idxs()
  print(unpack(followers))
  if #followers > 0 then
    return uniformly(followers)
  end
  return 0
end

function Player:follower_combat_round(idx, target_idx)
  local card = self.field[idx]
  local target_card = self.opponent.field[target_idx]
  self.game.attacker = {self, idx}
  self.game.defender = {self.opponent, target_idx}
  if target_card.type == "follower" then
    for i=1,2 do
      if i==2 then
        self.game.attacker, self.game.defender = self.game.defender, self.game.attacker
      end
      local attack_player, attack_idx = unpack(self.game.attacker)
      local defend_player, defend_idx = unpack(self.game.defender)
      local attacker = attack_player.field[attack_idx]
      local defender = defend_player.field[defend_idx]

      if defender.type == "follower" then
        for skill_idx=1,3 do
          local skill_id = attacker.skills[skill_idx]
          if attack_player.field[attack_idx] == attacker and
              skill_id and skill_id_to_type[skill_id] == "attack" then
            print("About to run skill func for id "..skill_id)
            local other_card = defender
            if other_card ~= defend_player.field[defend_idx] then
              other_card = nil
            end
            skill_func[skill_id](attack_player, attack_idx, attacker, skill_idx,
                defend_idx, other_card)
            self:check_hand()
            self.opponent:check_hand()
            self.game:clean_dead_followers()
          end
        end
      end
      self.game:clean_dead_followers()
      if self.game.combat_round_interrupted then print("bail that shouldn't happen 1")return end

      if defender.type == "follower" then
        for skill_idx=1,3 do
          local skill_id = defender.skills[skill_idx]
          if defend_player.field[defend_idx] == defender and
              skill_id and skill_id_to_type[skill_id] == "defend" then
            print("About to run skill func for id "..skill_id)
            local other_card = attacker
            if other_card ~= attack_player.field[attack_idx] then
              other_card = nil
            end
            skill_func[skill_id](defend_player, defend_idx, defender, skill_idx,
                attack_idx, other_card)
            self:check_hand()
            self.opponent:check_hand()
            self.game:clean_dead_followers()
          end
        end
      end
      self.game:clean_dead_followers()
      if self.game.combat_round_interrupted then print("bail that shouldn't happen 2")return end

      self.game:attack_animation()
      self.game:defend_animation()
      local damage = math.max(0,attacker.atk-defender.def)
      defender.sta = defender.sta - damage
      self.game:clean_dead_followers()
      if self.game.combat_round_interrupted then print("bail on combat damage") return end
    end
  else
    self.game:attack_animation()
    self.game:defend_animation()
    target_card.life = target_card.life - card.size
  end
end

function Player:combat_round()
  print("NO INTERRUPTION")
  self.game.combat_round_interrupted = false
  local active = {spell={}, follower={}}
  for i=1,5 do
    local card = self.field[i]
    if card and card.active then
      table.insert(active[card.type],i)
    end
  end
  if #active.spell>0 then
    active = active.spell
  else
    active = active.follower
  end
  local idx = uniformly(active)
  local card = self.field[idx]
  if card.type == "follower" then
    local target_idx = self.opponent:get_atk_target()
    print("Got attack target! "..target_idx)
    self:follower_combat_round(idx, target_idx)
    card.active = false
  else
    self.send_spell_to_grave = true
    print("About to run spell func for id "..card.id)
    spell_func[card.id](self, self.opponent, idx, card)
    self:check_hand()
    self.opponent:check_hand()
    print("Just ran spell func for id "..card.id)
    if self.send_spell_to_grave and self.field[idx] == card then
      self:field_to_grave(idx)
    end
  end
end

Game = class(function(self, ld, rd)
    self.P1 = Player("left", ld)
    self.P2 = Player("right", rd)
    self.P1.game = self
    self.P2.game = self
    self.P1.opponent = self.P2
    self.P2.opponent = self.P1
    self.turn = 0
    self.time_remaining = 0
  end)

function Game:update()
end

function Game:attack_animation()
  self.print_attack_info = true
  wait(50)
  self.print_attack_info = false
end

function Game:defend_animation()
end

function Game:coin_flip()
  return math.random(2) == 1
end

function Game:clean_dead_followers()
  for _,playername in ipairs({"P1","P2"}) do
    local player = self[playername]
    for i=1,5 do
      local card = player.field[i]
      if card and card.type == "follower" and card.sta < 1 then
        player:destroy(i)
      end
    end
  end
  if self.attacker then
    local attacker = self.attacker[1].field[self.attacker[2]]
    local defender = self.defender[1].field[self.defender[2]]
    if not (attacker and defender) then
      print("interrupted")
      self.combat_round_interrupted = true
    end
  end
end

local buff_effects = {
["="]=function(card,stat,n)
  card[stat] = n
end,
["+"]=function(card,stat,n)
  card[stat] = card[stat] + n
end,
["-"]=function(card,stat,n)
  card[stat] = card[stat] - n
end
}

function Game:apply_buff(buff)
  local anything_happened = false
  for _,zone in ipairs({"field", "hand", "deck"}) do
    for player,idx_to_effect in pairs(buff[zone]) do
      for idx,effects in pairs(idx_to_effect) do
        for stat,effect in pairs(effects) do
          anything_happened = true
          local which, howmuch = unpack(effect)
          if which == "-" and stat == "size" then
            howmuch = min(player[zone][idx].size-1, howmuch)
          end
          if which == "=" and stat == "size" then
            howmuch = max(1,howmuch)
          end
          buff_effects[which](player[zone][idx],stat,howmuch)
        end
      end
    end
  end
  if anything_happened then
    -- TODO: animation
    self:clean_dead_followers()
  end
end

function Game:run()
  local P1,P2 = self.P1,self.P2
  local P1_first, P1_first_upkeep = nil, nil
  while true do
    if GO_HARD and self.turn >= 8 then
      return
    end
    self.turn = self.turn+1
    if P1_first_upkeep == nil then
      P1_first_upkeep = self:coin_flip()
    else
      P1_first_upkeep = not P1_first_upkeep
    end
    wait(20)
    P1:untap_phase()
    P2:untap_phase()
    if P1_first_upkeep then
      P1:upkeep_phase()
      P2:upkeep_phase()
    else
      P2:upkeep_phase()
      P1:upkeep_phase()
    end
    P1:draw_phase()
    P2:draw_phase()
    P2:ai_act()
    P1:user_act()
    P1_first = self:coin_flip()
    while P1:has_active_cards() or P2:has_active_cards() do
      if P1_first and P1:has_active_cards() then
        P1:combat_round()
        wait(30)
      end
      P1_first = true
      if P2:has_active_cards() then
        P2:combat_round()
        wait(30)
      end
    end
  end
end
