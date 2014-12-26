local json = require "dkjson"
require "stridx"

id_to_canonical_card = {}
name_to_ids = {}
group_to_ids = {}
skill_text = {}
recipes = {}
skill_id_to_type = {}
setmetatable(skill_id_to_type, {__index = function() return "start" end})

local letter_to_skill_type = {T="start",A="attack",D="defend",B="defend"}

function cards_init()
  local teh_json = file_contents("swogi.json")
  local decoded = json.decode(teh_json)
  decoded.id_to_card.ID = nil
  decoded.name_to_ids.NAME = nil
  decoded.name_to_ids["KR NAME"] = nil
  local cards = decoded.id_to_card
  for id,in_card in pairs(cards) do
    id = id + 0
    --print("LOADING "..id)
    local card = {}
    id_to_canonical_card[id] = card
    card.type = in_card.type:lower()
    card.faction = in_card.faction[1]
    card.name = in_card.name
    card.episode = in_card.episode
    card.limit = in_card.limit + 0
    card.kr_name = in_card.kr_name
    card.id = in_card.id + 0
    card.points = in_card.points + 0
    card.rarity = in_card.rarity
    card.flavor = in_card.flavor
    if card.type == "npc spell" or card.type == "material" then
      card.type = "spell"
    end
    if card.type == "npc follower" then
      card.type = "follower"
    end
    if card.type == "follower" then
      card.atk = in_card.attack + 0
      card.def = in_card.defense + 0
      card.sta = in_card.stamina + 0
      card.size = in_card.size + 0
      card.skills = in_card.skills or {}
      card.active = true
    elseif card.type == "spell" then
      card.size = in_card.size + 0
      card.active = true
    elseif card.type == "character" then
      card.life = in_card.life + 0
      card.skills = {card.id}
      --assert(deepeq(card.skills, {card.id}))
    else
      error("Got card "..in_card.name.." with id "..in_card.id..
        " and unexpected type "..card.type)
    end
  end
  for name,ids in pairs(decoded.name_to_ids) do
    for i=1,#ids do
      ids[i] = ids[i] + 0
    end
  end
  name_to_ids = decoded.name_to_ids

  --construct groups_to_ids

  local group_json_raw = file_contents("groups.json")
  local group_json = json.decode(group_json_raw)
  group_to_ids = {}
  for group, k_group in pairs(group_json) do
    group_to_ids[group] = {}
  end
  for id,card in pairs(id_to_canonical_card) do
    local korean_name = card.kr_name
    for group, k_group in pairs(group_json) do
      if korean_name:match(k_group) then
        table.insert(group_to_ids[group], id)
        --print(card.name .. " is a ".. group)
      end
    end
  end

  for k,v in pairs(decoded.skill_text) do
    skill_text[0+k] = v
    if 0+k < 10000 then
      local type = letter_to_skill_type[v[4]]
      if v[4] == "B" and love then print(v) end
      assert(type, k)
      skill_id_to_type[0+k] = type
    end
  end

  -- recipes
  recipes = fix_num_keys(json.decode(file_contents("recipes_current.json")))
end

function get_obtainable_cards()
  local recipes = recipes
  local dungeons = fix_num_keys(json.decode(file_contents("dungeons.json")))
  local cards = {}

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

  for k,v in pairs(recipes) do
    cards[k] = true
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
  return cards
end

cards_init()
