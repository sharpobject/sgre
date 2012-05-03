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
  local gb = GlobalBuff()
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
  local gb = GlobalBuff()
  gb.field[self.player][self.idx] = self.buff
  gb:apply()
end

local groups = {}
groups.maid = arr_to_set({200012, 200082, 200148, 200446, 300019, 300020,
                300021, 300022, 300023, 300024, 300025, 300026,
                300033, 300034, 300117, 300118, 300120, 300147,
                300177, 300183, 300184, 300212, 300214, 300215,
                300239})

groups.sita = arr_to_set({100001, 100010, 100015, 100020, 100025, 100036,
                100050, 100054, 100090, 100102, 100108, 100124, 100140,
                100147, 110018, 110114, 110215, 200239, 300111, 300210,
                300320, 300321, 300332, 300427, 300433, 300496, 300533})

groups.cook_club = arr_to_set({110105, 300001, 300002, 300003, 300004, 300005,
                300006, 300007, 300008, 300112, 300140, 300245, 300247, 300280,
                300400, 300415, 300416, 300417, 300463, 300464, 300509, 300520})

groups.luthica = arr_to_set({100003, 100012, 100017, 100022, 100027, 100038,
                100052, 100056, 100092, 100104, 100110, 100126, 100142, 100149,
                110020, 110116, 110216, 200061, 200245, 300226, 300324, 300325,
                300334, 300429, 300437, 300498, 300535})

groups.knight = arr_to_set({100043, 100067, 100119, 100123, 110051, 110059,
                110136, 110151, 110156, 110162, 110244, 120017, 200027, 200271,
                200421, 300037, 300038, 300039, 300040, 300041, 300042, 300043,
                300044, 300046, 300096, 300122, 300129, 300155, 300158, 300159,
                300160, 300189, 300192, 300221, 300224, 300259, 300261, 300265,
                300266, 300289, 300290, 300294, 300310, 300311, 300334, 300343,
                300345, 300366, 300397, 300405, 300422, 300423, 300438, 300439,
                300454, 300455, 300456, 300457, 300468, 300469, 300481, 300482,
                300514, 300516, 300526, 300527, 300528})

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
for v in pairs(groups) do
  local name = v
  pred[v] = function(card) return groups[name][card.id] end
end

pred.t = function() return true end
pred.f = function() return false end
