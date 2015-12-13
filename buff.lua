GlobalBuff = class(function(self, player)
    self.game = player.game
    self.field = {[player] = {}, [player.opponent]={}}
    self.hand = {[player] = {}, [player.opponent]={}}
    self.deck = {[player] = {}, [player.opponent]={}}
    if GO_HARD then
      BUFF_COUNTER = (BUFF_COUNTER or 0) + 1
    end
  end)

function GlobalBuff:apply()
  self.game:apply_buff(self)
  if GO_HARD then
    BUFF_COUNTER = BUFF_COUNTER - 1
  end
end

OnePlayerBuff = class(function(self, player)
    self.player = player
    if GO_HARD then
      BUFF_COUNTER = (BUFF_COUNTER or 0) + 1
    end
  end)

function OnePlayerBuff:apply()
  local gb = GlobalBuff(self.player)
  for k,v in pairs(self) do
    if k~= "player" then
      gb.field[self.player][k]=v
    end
  end
  gb:apply()
  if GO_HARD then
    BUFF_COUNTER = BUFF_COUNTER - 1
  end
end

OneBuff = class(function(self, player, idx, buff)
    self.player = player
    self.idx = idx
    self.buff = buff
    if GO_HARD then
      assert(buff)
      BUFF_COUNTER = (BUFF_COUNTER or 0) + 1
    end
  end)

function OneBuff:apply()
  local gb = GlobalBuff(self.player)
  gb.field[self.player][self.idx] = self.buff
  gb:apply()
  if GO_HARD then
    BUFF_COUNTER = BUFF_COUNTER - 1
  end
end

Impact = class(function(self, player)
    self.player = player
    self[player] = {}
    self[player.opponent] = {}
  end)

function Impact:apply()
  local gb = GlobalBuff(self.player)
  for p,slots in pairs(self) do
    if p ~= "player" then
      gb.field[p] = {}
      for slot,_ in pairs(slots) do
        gb.field[p][slot] = {}
      end
    end
  end
  gb:apply()
end

OneImpact = class(function(self, player, idx)
    self.player = player
    self.idx = idx
  end)

function OneImpact:apply()
  local gb = GlobalBuff(self.player)
  gb.field[self.player][self.idx] = {}
  gb:apply()
end

pred = setmetatable({}, {__index=function()error("420 blaze it") end})

function groups_init()
  --print("GROUPS")
  for group,ids in pairs(group_to_ids) do
    --print(group)
    pred[group] = function(card)
      local t = {}
      for k,v in ipairs(ids) do
        t[v+0]=true
      end
      pred[group] = function(card) return not not t[card.id] end
      return pred[group](card)
    end
  end
end

pred.faction = {}
for _,v in ipairs({"V","A","D","C","N","E"}) do
  local faction = v
  pred.faction[faction] = function(card)
    --print(card.faction.." is a faction")
    return card.faction == faction
  end
  pred[faction] = pred.faction[faction]
end
for _,v in ipairs({"follower", "spell"}) do
  local type = v
  pred[v] = function(card) return card.type == type end
end
for _,v in ipairs({"size","atk","def","sta"}) do
  local stat=v
  pred[v] = function(card) return card[stat] or -9000 end
end
pred.exists = function(card) return not not card end
pred.active = function(card) return card.active end
pred.skill = function(card) return #card:squished_skills() > 0 end
pred.neg = function(func) return function(card) return not func(card) end end
pred.union = function(...)
  local t = {...}
  return function(card)
    for _,f in ipairs(t) do
      if f(card) then
        return true
      end
    end
    return false
  end
end
pred.inter = function(...)
  local t = {...}
  return function(card)
    for _,f in ipairs(t) do
      if not f(card) then
        return false
      end
    end
    return true
  end
end
pred.add = function(...)
  local t = {...}
  return function(card)
    local ret = 0
    for _,f in ipairs(t) do
      ret = ret + f(card)
    end
    return ret
  end
end

pred.t = function() return true end
pred.f = function() return false end

groups_init()