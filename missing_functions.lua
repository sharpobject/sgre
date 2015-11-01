json = require("dkjson")
require("util")
require("class")
require("cards")
require("buff")
require("skills")
require("spells")
require("characters")
require("giftable")
recipes = fix_num_keys(json.decode(file_contents("recipes_current.json")))
npc_decks = fix_num_keys(json.decode(file_contents("npc_decks.json")))
npc_decks_manual = fix_num_keys(json.decode(file_contents("npc_decks_manual.json")))
dungeons = fix_num_keys(json.decode(file_contents("dungeons.json")))
for k,v in pairs(npc_decks_manual) do
  npc_decks[k] = v
  local total = 0
  for id, count in pairs(v) do
    total = total + count
  end
  if total ~= 30 then
    print(k,total)
  end
end
cards = {}
char_ids = {}
spell_ids = {}
skill_ids = {}
for k,v in pairs(recipes) do
  cards[k] = true
end
for k,v in pairs(npc_decks) do
  cards[k] = true
  for kk,_ in pairs(v) do
    cards[kk] = true
  end
end

local cafe_chars = {}
for k,_ in pairs(cards) do
  if giftable[k] then
    for _,v in pairs(giftable[k]) do
      cafe_chars[v] = true
    end
  end
end
for k,_ in pairs(cafe_chars) do
  cards[k] = true
end

for _,dungeon_data in pairs(dungeons.rewards) do
  for _,floornum_data in pairs(dungeon_data) do
    for _,reps_data in pairs(floornum_data) do
      if type(reps_data) == "table" and reps_data.cards then
        for card,_ in pairs(reps_data.cards) do
          cards[card] = true
        end
      end
    end
  end
end

for id,_ in pairs(cards) do
  local card = id_to_canonical_card[id]
  if card.type == "follower" then
    for k,v in pairs(card.skills) do
      skill_ids[v] = true
    end
  elseif card.type == "spell" then
    if card.size ~= 0 then
      spell_ids[id] = true
    end
  elseif card.type == "character" then
    char_ids[id] = true
  end
end

for k,_ in pairs(char_ids) do
  if not rawget(characters_func, k) then
    print(k)
  end
end
for k,_ in pairs(skill_ids) do
  if not rawget(skill_func, k) then
    print(k)
  end
end
for k,_ in pairs(spell_ids) do
  if not rawget(spell_func, k) then
    print(k)
  end
end