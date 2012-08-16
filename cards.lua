id_to_canonical_card = {}
name_to_ids = {}
group_to_ids = {}

function cards_init()
  local file = love.filesystem.newFile("swogi.json")
  file:open("r")
  local teh_json = file:read(file:getSize())
  decoded = json.decode(teh_json)
  decoded.id_to_card.ID = nil
  decoded.name_to_ids.NAME = nil
  decoded.name_to_ids["KR NAME"] = nil
  cards = decoded.id_to_card
  for id,in_card in pairs(cards) do
    id = id + 0
    print("LOADING "..id)
    card = {}
    id_to_canonical_card[id] = card
    card.type = in_card.type:lower()
    card.faction = in_card.faction[1]
    card.name = in_card.name
    card.id = in_card.id + 0
    if card.type == "npc spell" then
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
      card.skills = in_card.skills
    else
      print("Got card "..in_card.name.." with id "..in_card.id..
        " and unexpected type "..card.type)
    end
  end
  for name,ids in pairs(decoded.name_to_ids) do
    for i=1,#ids do
      ids[i] = ids[i] + 0
    end
  end
  name_to_ids = decoded.name_to_ids
  group_to_ids = decoded.group_to_ids
end
