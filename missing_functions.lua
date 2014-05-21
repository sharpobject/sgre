json = require("dkjson")
require("util")
require("class")
require("cards")
require("buff")
require("skills")
require("spells")
require("characters")
recipes = fix_num_keys(json.decode(file_contents("recipes_current.json"), nil))
npc_decks = fix_num_keys(json.decode(file_contents("npc_decks.json"), nil))
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
for id,_ in pairs(cards) do
  local card = id_to_canonical_card[id]
  if card.type == "follower" then
    for k,v in pairs(card.skills) do
      skill_ids[v] = true
    end
  elseif card.type == "spell" then
    spell_ids[id] = true
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