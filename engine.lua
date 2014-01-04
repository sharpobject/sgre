local min,max = math.min,math.max
local love = love

Card = class(function(self, id, upgrade_lvl)
    self.upgrade_lvl = upgrade_lvl or 0
    --print("card init "..id)
    for k,v in pairs(id_to_canonical_card[id]) do
      self[k]=deepcpy(v)
      --print(k,v,self[k])
    end
    --TODO: apply upgrade
  end)

function Card:remove_skill(skill_idx)
  self.skills[skill_idx] = nil
end

function Card:refresh()
  local orig_skills = id_to_canonical_card[self.id].skills
  for i=1,3 do
    self.skills[i] = orig_skills[i]
  end
end

function Card:remove_skill_until_refresh(skill_idx)
  self.skills[skill_idx] = 1076
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
    self.name = self.character.name
  end)

function Player:check_hand()
  for i=1,4 do
    if self.hand[i+1] and not self.hand[i] then
      error("hand is wrong")
    end
  end
  if #self.hand > 5 then
    error("The #hand is too damn high.")
  end
  local ndeck = 0
  local ngrave = 0
  for _,__ in pairs(self.deck) do
    ndeck = ndeck + 1
  end
  for _,__ in pairs(self.grave) do
    ngrave = ngrave + 1
  end
  local str1 = "ndeck = "..ndeck.." #deck = "..#self.deck
  local str2 = "ngrave = "..ngrave.." #grave = "..#self.grave
  assert(ndeck == #self.deck, str1)
  assert(ngrave == #self.grave, str2)
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
    if card and card.skills then
      if pred.spell(card) then
        --print("Something is terribly wrong, a spell has a skill")
        error("asscom.de")
      end
      for skill_idx = 1,3 do
        local skill_id = card.skills[skill_idx]
        if skill_id and skill_id_to_type[skill_id] == "start" and
            self.field[idx] == card then
          --print("About to run skill func for id "..skill_id)
          self:check_hand()
          self.opponent:check_hand()
          card.trigger = true
          wait(50)
          card.trigger = nil
          self.game:send_trigger(self.player_index, idx, "start")
          if type(skill_id) == "number" and skill_id >= 100000 then
            characters_func[skill_id](self, self.opponent, card)
          else
            skill_func[skill_id](self, idx, card, skill_idx)
          end
          self.game:snapshot()
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
    self.lose = true
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
    self.game:send_shuffle(self.player_index)
    self.game:snapshot()
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

function Player:destroy_deck(n)
  if self.deck[n].type == "follower" then
    self.character.life = self.character.life - self.deck[n].size
  end
  self:deck_to_grave(n)
end

function Player:destroy_hand(n)
  if self.hand[n].type == "follower" then
    self.character.life = self.character.life - self.hand[n].size
  end
  self:hand_to_grave(n)
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

function Player:empty_field_slots()
  local t = {}
  for i=1,5 do
    if not self.field[i] then
      t[#t+1] = i
    end
  end
  return t
end

function Player:first_empty_field_slot()
  for i=1,5 do
    if not self.field[i] then return i end
  end
  return nil
end

function Player:last_empty_field_slot()
  for i=5,1,-1 do
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
  self.game:snapshot()
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
  --print(unpack(followers))
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
            --print("About to run skill func for id "..skill_id)
            local other_card = defender
            if other_card ~= defend_player.field[defend_idx] then
              other_card = nil
            end
            self:check_hand()
            self.opponent:check_hand()
            attacker.trigger = true
            wait(50)
            attacker.trigger = nil
            self.game:send_trigger(attack_player.player_index, attack_idx, "attack")
            skill_func[skill_id](attack_player, attack_idx, attacker, skill_idx,
                defend_idx, other_card)
            self.game:snapshot()
            self:check_hand()
            self.opponent:check_hand()
            self.game:clean_dead_followers()
            self.game:snapshot()
          end
        end
      end
      self.game:clean_dead_followers()
      self.game:snapshot()
      if self.game.combat_round_interrupted then
        --print("bail that shouldn't happen 1")
        return
      end

      if defender.type == "follower" then
        for skill_idx=1,3 do
          local skill_id = defender.skills[skill_idx]
          if defend_player.field[defend_idx] == defender and
              skill_id and skill_id_to_type[skill_id] == "defend" then
            --print("About to run skill func for id "..skill_id)
            local other_card = attacker
            if other_card ~= attack_player.field[attack_idx] then
              other_card = nil
            end
            self:check_hand()
            self.opponent:check_hand()
            defender.trigger = true
            wait(50)
            defender.trigger = nil
            self.game:send_trigger(defend_player.player_index, defend_idx, "defend")
            skill_func[skill_id](defend_player, defend_idx, defender, skill_idx,
                attack_idx, other_card)
            self.game:snapshot()
            self:check_hand()
            self.opponent:check_hand()
            self.game:clean_dead_followers()
            self.game:snapshot()
          end
        end
      end
      self.game:clean_dead_followers()
      self.game:snapshot()
      if self.game.combat_round_interrupted then
        --print("bail that shouldn't happen 2")
        return
      end

      self.game:attack_animation()
      self.game:defend_animation()
      local damage = math.max(0,attacker.atk-defender.def)
      self.game:send_attack(attack_player.player_index, attack_idx, defend_idx, damage)
      defender.sta = defender.sta - damage
      self.game:clean_dead_followers()
      self.game:snapshot()
      if self.game.combat_round_interrupted then --print("bail on combat damage")
        return
      end
    end
  else
    local attack_player, attack_idx = unpack(self.game.attacker)
    self.game:attack_animation()
    self.game:defend_animation()
    self.game:send_attack(attack_player.player_index, attack_idx, 0, card.size)
    target_card.life = target_card.life - card.size
    self.game:snapshot()
  end
end

function Player:combat_round()
  --print("NO INTERRUPTION")
  self.game.active_player = self.player_index
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
    --print("Got attack target! "..target_idx)
    self:follower_combat_round(idx, target_idx)
    card.active = false
    self.game:snapshot()
  else
    self.send_spell_to_grave = true
    --print("About to run spell func for id "..card.id)
    self:check_hand()
    self.opponent:check_hand()
    card.trigger = true
    wait(50)
    card.trigger = nil
    self.game:send_trigger(self.player_index, idx, "spell")
    spell_func[card.id](self, self.opponent, idx, card)
    self.game:snapshot()
    self:check_hand()
    self.opponent:check_hand()
    --print("Just ran spell func for id "..card.id)
    if self.send_spell_to_grave and self.field[idx] == card then
      self:field_to_grave(idx)
      self.game:snapshot()
    end
  end
end

function Player:is_npc()
  if self.character.id > 109999 then
    return true
  end
  return false
end

Game = class(function(self, ld, rd, client, active_character)
    self.P1 = Player("left", ld)
    self.P2 = Player("right", rd)
    self.P1.game = self
    self.P2.game = self
    self.P1.opponent = self.P2
    self.P2.opponent = self.P1
    self.turn = 0
    self.time_remaining = 0
    self.hover_card = Card(active_character or 200099)
    if client then
      self.client = true
      self.P1.client = true
      self.P2.client = true
    end
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
    for i=5,1,-1 do
      local card = player.field[i]
      if card and card.type == "follower" and card.sta < 1 then
        player:destroy(i)
      end
      card = player.hand[i]
      if card and card.type == "follower" and card.sta < 1 then
        player:destroy_hand(i)
      end
    end
    for i=#player.deck,1,-1 do
      local card = player.deck[i]
      if card and card.type == "follower" and card.sta < 1 then
        player:destroy_deck(i)
      end
    end
  end
  if self.attacker then
    local attacker = self.attacker[1].field[self.attacker[2]]
    local defender = self.defender[1].field[self.defender[2]]
    if not (attacker and defender) then
      --print("interrupted")
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
  local buff_msg = {}
  for i=1,2 do
    local tmp = {}
    tmp.field = buff.field[self["P"..i]] or {}
    -- move this from field[0] to character, so that it is representable in json
    tmp.character = tmp.field[0]
    tmp.field[0] = nil
    buff_msg[i] = tmp
  end
  self:snapshot(buff_msg)
  for i=1,2 do
    -- put it back!
    buff_msg[i].field[0] = buff_msg[i].character
  end
  if anything_happened then
    -- TODO: animation
    self:clean_dead_followers()
  end
  self:snapshot()
end

function card_summary(card)
  if not card then return false end
  local ret = {}
  if card.type == "follower" then
    ret.id = card.id
    ret.atk = card.atk
    ret.def = card.def
    ret.sta = card.sta
    ret.size = card.size
    ret.skills = {}
    for i=1,3 do
      ret.skills[i] = card.skills[i]
      if not ret.skills[i] then
        ret.skills[i] = false
      end
    end
    ret.active = card.active
  elseif card.type == "spell" then
    ret.id = card.id
    ret.size = card.size
    ret.active = card.active
  else
    ret.id = card.id
    ret.life = card.life
  end
  return ret
end

do
  local type_to_fields = {
    spell={"id", "size", "active"},
    follower={"id", "atk", "def", "sta", "size", "active"},
    character={"id", "life"},
  }

  local function id_to_type(id)
    if id >= 300000 then
      return "follower"
    elseif id >= 200000 then
      return "spell"
    else
      return "character"
    end
  end

  function card_diff(a,b)
    if (not a) and (not b) then
      return nil
    elseif a and b then
      local atype = id_to_type(a.id)
      local btype = id_to_type(b.id)
      if atype == btype then
        local ret = {}
        local modified = false
        if atype == "follower" then
          if a.skills[1] ~= b.skills[1] or
              a.skills[2] ~= b.skills[2] or
              a.skills[3] ~= b.skills[3] then
            modified = true
            ret.skills = b.skills
          end
        end
        for _,attr in ipairs(type_to_fields[atype]) do
          if a[attr] ~= b[attr] then
            modified = true
            ret[attr] = b[attr]
          end
        end
        if modified then
          return ret
        else
          return nil
        end
      end
    end
    return b
  end

  function view_diff(a,b)
    local diff = {}
    for i=1,2 do
      local p_diff = {}
      local av,bv = a[i],b[i]
      diff[i] = p_diff
      if av.grave ~= bv.grave then p_diff.grave = bv.grave end
      if av.shuffles ~= bv.shuffles then p_diff.shuffles = bv.shuffles end
      if av.deck ~= bv.deck then p_diff.deck = bv.deck end
      p_diff.character = card_diff(av.character, bv.character)
      local field = {}
      local hand = {}
      local hand_m, field_m, sum = false, false
      for j=1,5 do
        sum = card_diff(av.field[j], bv.field[j])
        if sum ~= nil then
          field_m = true
          field[j] = sum
        end
        sum = card_diff(av.hand[j], bv.hand[j])
        if sum ~= nil then
          hand_m = true
          hand[j] = sum
        end
      end
      if hand_m then p_diff.hand = hand end
      if field_m then p_diff.field = field end
    end
    return diff
  end

  function view_diff_apply(view, diff)
    for i=1,2 do
      local pv,pd = view[i],diff[i]
      pv.shuffles = pd.shuffles or pv.shuffles
      pv.grave = pd.grave or pv.grave
      pv.deck = pd.deck or pv.deck
      if pd.character then
        for k,v in pairs(pd.character) do
          pv.character[k]=v
        end
      end
      for _,zone in ipairs({"hand","field"}) do
        if pd[zone] then
          for j=1,5 do
            if pd[zone][j] == false then
              pv[zone][j] = false
            elseif pd[zone][j] then
              if pv[zone][j] then
                if pd[zone][j].id and id_to_type(pd[zone][j].id) == "spell" then
                  pv[zone][j].atk = nil
                  pv[zone][j].def = nil
                  pv[zone][j].sta = nil
                  pv[zone][j].skills = nil
                end
                for k,v in pairs(pd[zone][j]) do
                  pv[zone][j][k] = v
                end
              else
                pv[zone][j] = pd[zone][j]
              end
            end
          end
        end
      end
    end
    return view
  end
end

function Game:snapshot(buff_msg)
  if self.client or self.winner then
    return
  end
  local new_view = {}
  local players = {self.P1, self.P2}
  for i=1,2 do
    local p = players[i]
    local p_view = {}
    p_view.field = {}
    p_view.hand = {}
    p_view.deck = #p.deck
    p_view.grave = #p.grave
    p_view.shuffles = p.shuffles
    p_view.character = card_summary(p.character)
    for j=1,5 do
      p_view.field[j] = card_summary(p.field[j])
      p_view.hand[j] = card_summary(p.hand[j])
    end
    new_view[i] = p_view
  end
  if not self.state_view then
    local msg = {type="snapshot",snapshot=new_view}
    self:send(msg)
    if love then
      print("snapshot"..json.encode(msg))
    end
    self.state_view = new_view
  end
  if self.state_view then
    local diff = view_diff(self.state_view,new_view)
    --print("state" .. json.encode(new_view))
    local msg = {type="diff",buff=buff_msg,diff=diff}
    self:send(msg)
    if love then
      print("diff" .. json.encode(msg))
    end
    --assert(deepeq(json.decode(json.encode(diff)), diff))
    --assert(deepeq(view_diff_apply(self.state_view, diff), new_view))
  end
  self.state_view = new_view
  --print(json.encode(new_view))

  if self.P1.character.life <= 0 then
    self.P1.lose = true
  end
  if self.P2.character.life <= 0 then
    self.P2.lose = true
  end
  local winner = nil
  if self.P1.lose and self.P2.lose then
    winner = self.active_player
  elseif self.P1.lose then
    winner = 2
  elseif self.P2.lose then
    winner = 1
  end

  if winner then
    self:game_over(winner)
  end
end

function Game:send_trigger(player, slot, what)
  local msg = {type="trigger", trigger={player=player, slot=slot, what=what}}
  self:send(msg)
  if love then
    print("trigger"..json.encode(msg))
  end
end

function Game:send_attack(player, atk_slot, def_slot, damage)
  local msg = {type="attack", trigger={
      player=player, atk_slot=atk_slot, def_slot=def_slot, damage=damage}}
  self:send(msg)
  if love then
    print("attack"..json.encode(msg))
  end
end

function Game:send_shuffle(player)
  local msg = {type="shuffle",player=player}
  self:send(msg)
  if love then
    print("shuffle"..json.encode(msg))
  end
end

function Game:send_coin(player)
  local msg = {type="coin",player=player}
  self:send(msg)
  if love then
    print("coin"..json.encode(msg))
  end
end

function Game:game_over(player)
  if self.winner then return end
  local msg = {type="game_over",winner=player}
  self:send(msg)
  if love then
    print("game_over"..json.encode(msg))
  end
  self.winner = player
end

function Game:send_turn(turn)
  local msg = {type="turn",turn=turn}
  self:send(msg)
  if love then
    print("turn"..json.encode(msg))
  end
end

function Game:censor(t)
  local ret = {}
  for k,v in pairs(t) do
    ret[k] = v
  end
  if ret.hand then
    ret.hand = {}
  end
  if ret.field and self.censor_field then
    ret.field = {}
    for i=1,5 do
      if type(t.field[i]) == "table" then
        ret.field[i] = true
      else
        ret.field[i] = t.field[i]
      end
    end
  end
  return ret
end

function Game:send(msg)
  assert(type(msg) == "table")
  if love or self.winner then
    return
  end
  local typ = msg.type
  if self.P1.connection then
    if typ == "diff" or typ == "snapshot" then
      tmp = msg[typ][2]
      msg[typ][2] = self:censor(tmp)
      self.P1.connection:send(msg)
      msg[typ][2] = tmp
    else
      self.P1.connection:send(msg)
    end
  end
  if self.P2.connection then
    if typ == "diff" or typ == "snapshot" then
      tmp = msg[typ][1]
      msg[typ][1] = self:censor(tmp)
      self.P2.connection:send(msg)
      msg[typ][1] = tmp
    else
      self.P2.connection:send(msg)
    end
  end
end

function Game:send_player_idxs()
  if self.P1.connection then
    self.P1.connection:send({type="game_start",player_index=1})
  end
  if self.P2.connection then
    self.P2.connection:send({type="game_start",player_index=2})
  end
end

function Player:receive(msg)
  if self.ready then
    return
  end
  if msg.type == "shuffle" then
    self:attempt_shuffle()
  elseif msg.type == "ready" then
    self.ready = true
  elseif msg.type == "play" then
    if self:can_play_card(msg.index) then
      self:play_card(msg.index)
    end
  else
    print("Got an unexpected message in player:receive "..json.encode(msg))
  end
end

function Game:run()
  local P1,P2 = self.P1,self.P2
  local P1_first, P1_first_upkeep = nil, nil
  local real_turn = 0

  P1.player_index = 1
  P2.player_index = 2

  self:send_player_idxs()
  self:snapshot()

  while true do
    if GO_HARD and real_turn >= 8 then
      return
    end
    real_turn = real_turn + 1
    self.turn = self.turn + 1
    self:send_turn(self.turn)
    if P1_first_upkeep == nil then
      P1_first_upkeep = self:coin_flip()
      self.active_player = P1_first_upkeep and 1 or 2
      self:send_coin(self.active_player)
    else
      P1_first_upkeep = not P1_first_upkeep
      self.active_player = P1_first_upkeep and 1 or 2
    end
    if real_turn > 100 or self.turn > 100 then
      self:game_over(self.active_player)
    end
    if self.turn > 1 then
      wait(20)
    end
    self:snapshot()
    P1:untap_phase()
    P2:untap_phase()
    self:snapshot()
    if P1_first_upkeep then
      P1:upkeep_phase()
      P2:upkeep_phase()
    else
      P2:upkeep_phase()
      P1:upkeep_phase()
    end
    P1:draw_phase()
    P2:draw_phase()
    self:snapshot()
    if self.winner then
      return self.winner
    end
    self.censor_field = true
    if love then
      P2:ai_act()
      P1:user_act()
    else
      for _,p in ipairs({P1, P2}) do
        if p.connection then
          p.ready = false
          p.connection:send({type="can_act",can_act=true})
        else
          p:ai_act()
          p.ready = true
        end
      end
      while not (P1.ready and P2.ready) do
        coroutine.yield()
      end
    end
    self.censor_field = false
    self.state_view = nil
    self:snapshot()
    P1_first = self:coin_flip()
    self:send_coin(P1_first and 1 or 2)
    local n_combat_rounds = 0
    while (P1:has_active_cards() or P2:has_active_cards()) and n_combat_rounds < 50 do
      if P1_first and P1:has_active_cards() and n_combat_rounds < 50 then
        P1:combat_round()
        n_combat_rounds = n_combat_rounds + 1
        wait(30)
      end
      P1_first = true
      if P2:has_active_cards() and n_combat_rounds < 50 then
        P2:combat_round()
        n_combat_rounds = n_combat_rounds + 1
        wait(30)
      end
    end
  end
end

function card_from_view(view, other)
  if not view then
    return nil
  end
  if view == true then
    local ret = Card(200099)
    ret.hidden = true
    return ret
  end
  local card = Card(view.id)
  if other and view.id == other.id then
    card = other
  end
  for k,v in pairs(view) do
    card[k] = v
  end
  return card
end

function Game:from_view(view)
  local players = {self.P1, self.P2}
  for i=1,2 do
    local p = players[i]
    local pv = view[i]
    p.field = {}
    p.hand = {}
    p.deck = pv.deck
    p.grave = pv.grave
    p.shuffles = pv.shuffles
    p.character = card_from_view(pv.character, p.character)
    for j=1,5 do
      p.field[j] = card_from_view(pv.field[j], p.field[j])
      p.hand[j] = card_from_view(pv.hand[j], p.hand[j])
    end
    p.field[0] = p.character
  end
end

function Game:client_run()
  while true do
    while net_q:len() == 0 do
      wait()
    end
    local msg = net_q:pop()
    if msg.type == "game_start" then
      if msg.player_index == 2 then
        self.P1.side = "right"
        self.P2.side = "left"
        self.P1.name = self.opponent_name
        self.P2.name = self.my_name
      end
    elseif msg.type == "snapshot" then
      self.view = msg.snapshot
      self:from_view(self.view)
    elseif msg.type == "diff" then
      view_diff_apply(self.view, msg.diff)
      self:from_view(self.view)
      if msg.buff then
        --TODO
      end
    elseif msg.type == "trigger" then
      local card = self["P"..msg.trigger.player].field[msg.trigger.slot]
      card.trigger = true
      wait(50)
      card.trigger = nil
    elseif msg.type == "attack" then
      self.attacker = {self["P"..msg.trigger.player], msg.trigger.atk_slot}
      self.defender = {self.attacker[1].opponent, msg.trigger.def_slot}
      self.print_attack_info = true
      wait(50)
      self.print_attack_info = nil
    elseif msg.type == "shuffle" then
      --TODO PLAY A SHUFFLING SOUND?????
    elseif msg.type == "coin" then
        --TODO
    elseif msg.type == "game_over" then
      game = nil
      return
    elseif msg.type == "turn" then
      self.turn = msg.turn
    elseif msg.type == "opponent_disconnected" then
      error("opponent disconnected :((((")
    elseif msg.type == "can_act" then
      self.act_buttons = msg.can_act
    elseif msg.type == "ping" then
      net_send({type="pong"})
    elseif msg.type == "pong" then
      -- do nothing
    else
      error(json.encode(msg))
      error("unknown message type "..msg.type)
    end
  end
end
