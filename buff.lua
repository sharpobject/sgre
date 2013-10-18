GlobalBuff = class(function(self, player)
    self.game = player.game
    self.field = {[player] = {}, [player.opponent]={}}
    self.hand = {[player] = {}, [player.opponent]={}}
    self.deck = {[player] = {}, [player.opponent]={}}
  end)

function GlobalBuff:apply()
  self.game:apply_buff(self)
end

OnePlayerBuff = class(function(self, player)
    self.player = player
  end)

function OnePlayerBuff:apply()
  local gb = GlobalBuff(self.player)
  for k,v in pairs(self) do
    if k~= "player" then
      gb.field[self.player][k]=v
    end
  end
  gb:apply()
end

OneBuff = class(function(self, player, idx, buff)
    self.player = player
    self.idx = idx
    self.buff = buff
  end)

function OneBuff:apply()
  local gb = GlobalBuff(self.player)
  gb.field[self.player][self.idx] = self.buff
  gb:apply()
end

pred = {}

function groups_init()
  print("GROUPS")
  for group,ids in pairs(group_to_ids) do
    print(group)
    pred[group] = function(card)
      local t = {}
      for k,v in ipairs(ids) do
        t[v+0]=true
      end
      pred[group] = function(card) return t[card.id] end
      return pred[group](card)
    end
  end
end

pred.faction = {}
for _,v in ipairs({"V","A","D","C","N","E"}) do
  local faction = v
  pred.faction[faction] = function(card) print(card.faction.." is a faction")return card.faction == faction end
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
