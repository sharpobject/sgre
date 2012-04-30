Buff = class(function(self, player)
    self.game = player.game
    self.field = {[player] = {}, [player.opponent]={}}
    self.hand = {[player] = {}, [player.opponent]={}}
    self.deck = {[player] = {}, [player.opponent]={}}
  end)

function Buff:apply()
  self.game:apply_buff(self)
end

local maids = arr_to_set({200012, 200082, 200148, 200446, 300019, 300020,
                300021, 300022, 300023, 300024, 300025, 300026,
                300033, 300034, 300117, 300118, 300120, 300147,
                300177, 300183, 300184, 300212, 300214, 300215,
                300239})

pred = {}
pred.faction = {}
for _,v in ipairs({"V","A","D","C","N"}) do
  local faction = v
  pred.faction[faction] = function(card) print(card.faction.." is a faction")return card.faction == faction end
end
for _,v in ipairs({"follower", "spell"}) do
  local type = v
  pred[v] = function(card) return card.type == type end
end
for _,v in ipairs({"size","atk","def","sta"}) do
  local stat=v
  pred[v] = function(card) return card[stat] or -9000 end
end
pred.maid = function(card) return maids[card.id] end
