local max = math.max

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
  for i=skill_idx,2 do
    self.skills[i] = self.skills[i+1]
  end
end

function Card:refresh()
  self.skills = deepcpy(id_to_canonical_card[self.id])
end

function Card:remove_skill_until_refresh(skill_idx)
  self.skills[skill_idx] = "refresh"
end

function Card:reset()
  for k,v in pairs(id_to_canonical_card[self.id]) do
    self[k] = deepcpy(v)
  end
  --TODO: apply upgrade
end

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
    assert(#deck == 31)
    print(deck[31])
    map_inplace(function(x) if type(x) == "number" then return x end return x.id end, deck)
    print(deck[31])
    table.sort(deck, function(a,b) return a>b end)
    assert(deck[31] < 200000)
    assert(deck[30] >= 200000)
    print(deck[31])
    self.character = Card(deck[31])
    deck[31] = nil
    self.deck = map(Card, deck)
    shuffle(self.deck)
    self.hand = {}
    self.field = {}
    self.field[0] = self.character
    self.grave = {}
    self.exile = {}
    self.shuffles = 2
  end)

function Player:untap_phase()
  for i=1,5 do
    if self.field[i] then
      self.field[i].active = true
    end
  end
end

function Player:upkeep_phase()
  local slot_order = shuffle({[0]=0,1,2,3,4,5})
  for i=0,5 do
    local idx = slot_order[i]
    local card = self.field[idx]
    if card then
      for skill_idx,skill_id in ipairs(card.skills or {}) do
        if skill_id_to_type[skill_id] == "start" then
          skill_func[skill_id](self, idx, card, skill_idx)
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

function Player:draw_phase()
  if #self.hand == 5 then
    self:hand_to_grave(1)
  end
  if #self.deck == 0 then
    error("I lost the game :(")
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
  self.grave[#self.grave]:reset()
  for i=n,5 do
    self.hand[i] = self.hand[i+1]
  end
end

function Player:field_to_bottom_deck(n)
  self:to_bottom_deck(self.field[n])
  self.field[n] = nil
end

function Player:field_to_grave(n)
  self.grave[#self.grave + 1] = self.field[n]
  self.grave[#self.grave]:reset()
  self.field[n] = nil
end

function Player:field_to_exile(n)
  self.exile[#self.exile + 1] = self.field[n]
  self.exile[#self.exile]:reset()
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

function Player:grave_idxs_with_preds(preds)
  if type(preds) ~= "table" then
    preds = {preds}
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

function Player:grave_idxs_with_size(n)
  local ret = {}
  for i=1,#self.grave do
    if self.grave[i].size == n then
      ret[#ret+1] = i
    end
  end
  return ret
end

function Player:hand_idxs_with_preds(preds)
  if type(preds) ~= "table" then
    preds = {preds}
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

function Player:field_idxs_with_preds(preds)
  if type(preds) ~= "table" then
    preds = {preds}
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

function Player:field_idxs_with_least_and_preds(func, preds)
  local idxs = self:field_idxs_with_preds(preds)
  local best = 99999
  local ret = {}
  for i=1,#idxs do
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

function Player:field_idxs_with_most_and_preds(func, preds)
  return self:field_idxs_with_least_and_preds(function(...)return -func(...) end, preds)
end

function Player:first_empty_slot()
  for i=1,5 do
    if not self.field[i] then return i end
  end
  return nil
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
    self:first_empty_slot()
end

function Player:play_card(n)
  self.hand[n].active = true
  self.field[self:first_empty_slot()] = self.hand[n]
  for i=n,5 do
    self.hand[i] = self.hand[i+1]
  end
end

function Player:ai_act()
  for i=1,3 do
    if self:can_play_card(1) then
      self:play_card(1)
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
        for skill_idx,skill_id in ipairs(attacker.skills) do
          if skill_id_to_type[skill_id] == "attack" then
            skill_func[skill_id](attack_player, attack_idx, attacker, skill_idx,
                defend_idx, defender)
            self.game:clean_dead_followers()
            if self.game.combat_round_interrupted then print("bail on attack skill") return end
          end
        end
      end
      self.game:clean_dead_followers()
      if self.game.combat_round_interrupted then print("bail that shouldn't happen 1")return end

      if defender.type == "follower" then
        for skill_idx,skill_id in ipairs(defender.skills) do
          if skill_id_to_type[skill_id] == "defend" then
            skill_func[skill_id](defend_player, defend_idx, defender, skill_idx,
                attack_idx, attacker)
            self.game:clean_dead_followers()
            if self.game.combat_round_interrupted then print("bail on defend skill") return end
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
    spell_func[card.id](self, self.opponent, idx, card)
    if self.send_spell_to_grave then
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
            howmuch = max(player[zone][idx].size-1, howmuch)
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
  local P1_first = nil
  while true do
    self.turn = self.turn+1
    if P1_first == nil then
      P1_first = self:coin_flip()
    end
    wait(20)
    P1:untap_phase()
    P2:untap_phase()
    if P1_first then
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
      if skip_P1 then
        skip_P1 = false
      elseif P1:has_active_cards() then
        P1:combat_round()
        wait(30)
      end
      if P2:has_active_cards() then
        P2:combat_round()
        wait(30)
      end
    end
  end
end
