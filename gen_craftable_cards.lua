require "util"
local json = require "dkjson"
local recipes = fix_num_keys(json.decode(file_contents("recipes.json")))
local id_to_card = fix_num_keys(json.decode(file_contents("swogi.json")).id_to_card)

local eps = arr_to_set(require("episodes"))
require("giftable")

for k,v in pairs(recipes) do
  if not eps[(id_to_card[k] or {episode="ASS"}).episode] then
    recipes[k] = nil
  end
end

local s1_fight = {
  210001, -- sword
  210002, -- glasses
  210003, -- shoes
  210004, -- socks
  210005, -- ribbon
  210006, -- cat doll
  210007, -- book
}
local s2_fight = {
  210022, -- dagger
  210023, -- panda doll
  210024, -- trump
  210025, -- gloves
  210026, -- perfume
  210027, -- lipstick
  210028, -- pendant
}
local ore = {
  210008, -- red ore
  210009, -- green ore
  210010, -- white ore
  210011, -- blue ore
  210012, -- black ore
}
local dungeon_mats = {
  210013, -- ruins fragment
  210014, -- heart stone
  210015, -- holy water tear
  210016, -- bamboo
  210017, -- lily
  210018, -- blood pack
  210019, -- good job stamp
  210020, -- spiral fragment
  210029, -- aletheian brick
  210033, -- pass
  210034, -- receipt (ep9)
  210036, -- cat paw stamp (ex3)
  210038, -- library card (ep10)
  210039, -- mystery parchment (ep11)
  210040, -- Police I.D. (ep12)
  210045, -- replica stick (ep13)
  210046, -- commemorative medal (ex4)
  210047, -- Dimensional Fragment (ep14)
  210048, -- Kana's Fragment (ep15)
}
local materials = {s1_fight, s2_fight, ore, dungeon_mats}
local reachable_cards = {}
for _,t in ipairs(materials) do
  for _,v in ipairs(t) do
    reachable_cards[v] = true
  end
end

local found = true
while found do
  found = false
  for out_card,recipe in pairs(recipes) do
    local got_it = true
    for in_card,_ in pairs(recipe) do
      got_it = got_it and reachable_cards[in_card]
    end
    if got_it then
      found = true
      reachable_cards[out_card] = true
      recipes[out_card] = nil
      if giftable[out_card] then
        for _,transformation in ipairs(giftable[out_card]) do
          reachable_cards[transformation] = true
        end
      end
    end
  end
end

local ret = set_to_arr(reachable_cards)
table.sort(ret)
--print(json.encode(ret))
-- jk lol

local ret = {}
recipes = fix_num_keys(json.decode(file_contents("recipes.json")))
for k,v in pairs(reachable_cards) do
  ret[k] = recipes[k]
end
recipes = fix_num_keys(json.decode(file_contents("recipes_manual.json")))
for k,v in pairs(recipes) do
  ret[k] = recipes[k]
end
print(json.encode(ret))