local substr

local eps = require("episodes")

function add_craft_filters()
  state = "craft"
  craft_filters = {}
  craft_filter_values = {}

  crafttypefilter = loveframes.Create("multichoice")
  crafttypefilter:SetState(state)
  crafttypefilter:SetChoice("Type")
  crafttypefilter:AddChoice("Type")
  crafttypefilter:AddChoice("Character")
  crafttypefilter:AddChoice("Follower")
  crafttypefilter:AddChoice("Spell")
  crafttypefilter:SetX(216)
  crafttypefilter:SetY(530)
  crafttypefilter:SetWidth(70)

--onchoiceselected, repopulate card list: change populate function to get values
--probably need to change it so the populate function
  function crafttypefilter:OnChoiceSelected(choice)
    filter_type = crafttypefilter:GetValue()
    if filter_type == "Type" then filter_type = nil
    else filter_type = filter_type:lower() end
    craft_filter_values[1] = filter_type
    frames.craft.populate_card_list(recipes, substr)
  end
  craft_filters[1] = crafttypefilter


  craftepisodefilter = loveframes.Create("multichoice")
  craftepisodefilter:SetState(state)
  craftepisodefilter:SetChoice("Episode")
  craftepisodefilter:AddChoice("Episode")
  for i=1,#eps do
    craftepisodefilter:AddChoice(eps[i])
  end
  craftepisodefilter:SetX(285)
  craftepisodefilter:SetY(530)
  craftepisodefilter:SetWidth(59)
  function craftepisodefilter:OnChoiceSelected(choice)
    filter_episode = craftepisodefilter:GetValue()
    if filter_episode == "Episode" then filter_episode = nil end
    craft_filter_values[2] = filter_episode
    frames.craft.populate_card_list(recipes, substr)
  end
  craft_filters[2] = craftepisodefilter

  craftrarityfilter = loveframes.Create("multichoice")
  craftrarityfilter:SetState(state)
  craftrarityfilter:SetChoice("Rarity")
  craftrarityfilter:AddChoice("Rarity")
  craftrarityfilter:AddChoice("Common")
  craftrarityfilter:AddChoice("Uncommon")
  craftrarityfilter:AddChoice("Rare")
  craftrarityfilter:AddChoice("D.Rare")
  craftrarityfilter:AddChoice("T.Rare")
  craftrarityfilter:AddChoice("Event")
  craftrarityfilter:SetX(343)
  craftrarityfilter:SetY(530)
  craftrarityfilter:SetWidth(78)
  function craftrarityfilter:OnChoiceSelected(choice)
    filter_rarity = craftrarityfilter:GetValue()
    if filter_rarity == "Rarity" then filter_rarity = nil
    elseif filter_rarity == "Common" then filter_rarity = "C"
    elseif filter_rarity == "Uncommon" then filter_rarity = "UC"
    elseif filter_rarity == "Rare" then filter_rarity = "R"
    elseif filter_rarity == "D.Rare" then filter_rarity = "DR"
    elseif filter_rarity == "Event" then filter_rarity = "EV"
    else filter_rarity = "TR" end
    craft_filter_values[3] = filter_rarity
    frames.craft.populate_card_list(recipes, substr)
  end
  craft_filters[3] = craftrarityfilter

  craftfactionfilter = loveframes.Create("multichoice")
  craftfactionfilter:SetState(state)
  craftfactionfilter:SetChoice("Faction")
  craftfactionfilter:AddChoice("Faction")
  craftfactionfilter:AddChoice("Vita")
  craftfactionfilter:AddChoice("Academy")
  craftfactionfilter:AddChoice("Crux")
  craftfactionfilter:AddChoice("Darklore")
  craftfactionfilter:AddChoice("Neutral")

  craftfactionfilter:SetX(420)
  craftfactionfilter:SetY(530)
  craftfactionfilter:SetWidth(67)
  function craftfactionfilter:OnChoiceSelected(choice)
    filter_faction = craftfactionfilter:GetValue()
    if filter_faction == "Faction" then filter_faction = nil
    else filter_faction = filter_faction[1] end
    craft_filter_values[4] = filter_faction
    frames.craft.populate_card_list(recipes, substr)
  end
  craft_filters[4] = craftfactionfilter

  craftsizefilter = loveframes.Create("multichoice")
  craftsizefilter:SetState(state)
  craftsizefilter:SetChoice("Size")
  craftsizefilter:AddChoice("Size")
  for i=0,10 do
    craftsizefilter:AddChoice(tostring(i))
  end

  craftsizefilter:SetX(486)
  craftsizefilter:SetY(530)
  craftsizefilter:SetWidth(40)

  function craftsizefilter:OnChoiceSelected(choice)
    if craftsizefilter:GetValue() == "Size" then filter_size = nil
    else filter_size = tonumber(craftsizefilter:GetValue()) end
    craft_filter_values[5] = filter_size
    frames.craft.populate_card_list(recipes, substr)
  end
  craft_filters[5] = craftsizefilter

end

function add_decks_filters()
  state = "decks"
  decks_filters = {}
  decks_filter_values = {}
  decktypefilter = loveframes.Create("multichoice")
  decktypefilter:SetState(state)
  decktypefilter:SetChoice("Type")
  decktypefilter:AddChoice("Type")
  decktypefilter:AddChoice("Character")
  decktypefilter:AddChoice("Follower")
  decktypefilter:AddChoice("Spell")
  decktypefilter:SetX(216)
  decktypefilter:SetY(530)
  decktypefilter:SetWidth(70)
  --onchoiceselected, repopulate card list: change populate function to get values
  --probably need to change it so the populate function
  function decktypefilter:OnChoiceSelected(choice)
    filter_type = decktypefilter:GetValue()
    if filter_type == "Type" then filter_type = nil
    else filter_type = filter_type:lower() end
    decks_filter_values[1] = filter_type
    frames.decks.update_list()
  end
  decks_filters[1] = decktypefilter

  deckepisodefilter = loveframes.Create("multichoice")
  deckepisodefilter:SetState(state)
  deckepisodefilter:SetChoice("Episode")
  deckepisodefilter:AddChoice("Episode")
  for i=1,#eps do
    deckepisodefilter:AddChoice(eps[i])
  end
  deckepisodefilter:SetX(285)
  deckepisodefilter:SetY(530)
  deckepisodefilter:SetWidth(59)
  function deckepisodefilter:OnChoiceSelected(choice)
    filter_episode = deckepisodefilter:GetValue()
    if filter_episode == "Episode" then filter_episode = nil end

    decks_filter_values[2] = filter_episode
    frames.decks.update_list()
  end

  decks_filters[2] = deckepisodefilter

  deckrarityfilter = loveframes.Create("multichoice")
  deckrarityfilter:SetState(state)
  deckrarityfilter:SetChoice("Rarity")
  deckrarityfilter:AddChoice("Rarity")
  deckrarityfilter:AddChoice("Common")
  deckrarityfilter:AddChoice("Uncommon")
  deckrarityfilter:AddChoice("Rare")
  deckrarityfilter:AddChoice("D.Rare")
  deckrarityfilter:AddChoice("T.Rare")
  deckrarityfilter:AddChoice("Event")
  deckrarityfilter:SetX(343)
  deckrarityfilter:SetY(530)
  deckrarityfilter:SetWidth(78)
  function deckrarityfilter:OnChoiceSelected(choice)
    filter_rarity = deckrarityfilter:GetValue()
    if filter_rarity == "Rarity" then filter_rarity = nil
    elseif filter_rarity == "Common" then filter_rarity = "C"
    elseif filter_rarity == "Uncommon" then filter_rarity = "UC"
    elseif filter_rarity == "Rare" then filter_rarity = "R"
    elseif filter_rarity == "D.Rare" then filter_rarity = "DR"
    elseif filter_rarity == "Event" then filter_rarity = "EV"
    else filter_rarity = "TR" end

    decks_filter_values[3] = filter_rarity
    frames.decks.update_list()
  end
  decks_filters[3] = deckrarityfilter



  deckfactionfilter = loveframes.Create("multichoice")
  deckfactionfilter:SetState(state)
  deckfactionfilter:SetChoice("Faction")
  deckfactionfilter:AddChoice("Faction")
  deckfactionfilter:AddChoice("Vita")
  deckfactionfilter:AddChoice("Academy")
  deckfactionfilter:AddChoice("Crux")
  deckfactionfilter:AddChoice("Darklore")
  deckfactionfilter:AddChoice("Neutral")

  deckfactionfilter:SetX(420)
  deckfactionfilter:SetY(530)
  deckfactionfilter:SetWidth(67)
  function deckfactionfilter:OnChoiceSelected(choice)
    filter_faction = deckfactionfilter:GetValue()
    if filter_faction == "Faction" then filter_faction = nil
    else filter_faction = filter_faction[1] end

    decks_filter_values[4] = filter_faction
    frames.decks.update_list()
  end
  decks_filters[4] = deckfactionfilter

  decksizefilter = loveframes.Create("multichoice")
  decksizefilter:SetState(state)
  decksizefilter:SetChoice("Size")
  decksizefilter:AddChoice("Size")
  for i=0,10 do
    decksizefilter:AddChoice(tostring(i))
  end

  decksizefilter:SetX(486)
  decksizefilter:SetY(530)
  decksizefilter:SetWidth(40)

  function decksizefilter:OnChoiceSelected(choice)
    if decksizefilter:GetValue() == "Size" then filter_size = nil
    else filter_size = tonumber(decksizefilter:GetValue()) end

    decks_filter_values[5] = filter_size
    frames.decks.update_list()
  end
  decks_filters[5] = decksizefilter
end

function reset_filters(state)
  if state == "craft" then
    craft_filters[1]:SelectChoice("Type")
  craft_filters[2]:SelectChoice("Episode")
  craft_filters[3]:SelectChoice("Rarity")
  craft_filters[4]:SelectChoice("Faction")
  craft_filters[5]:SelectChoice("Size")
  for i=1,5 do craft_filter_values[i] = nil end
  craft_search_bar:SetText("")
  substr = ""
  frames.craft.populate_text_card_list(recipes, substr, true)
  elseif state == "decks" then
    decks_filters[1]:SelectChoice("Type")
  decks_filters[2]:SelectChoice("Episode")
  decks_filters[3]:SelectChoice("Rarity")
  decks_filters[4]:SelectChoice("Faction")
  decks_filters[5]:SelectChoice("Size")
  for i=1,5 do decks_filter_values[i] = nil end
  end
end

function add_search_bar(pane)
  craft_search_bar = loveframes.Create("textinput", pane)
  craft_search_bar:SetState("craft")
  craft_search_bar:SetWidth(math.floor(pane:GetWidth() * 0.9))
  local x,y,w,h = left_hover_frame_pos()
  craft_search_bar:SetPos(math.floor(pane:GetWidth()*0.05),34)
  function craft_search_bar:OnTextChanged(key)
    substr = string.lower(craft_search_bar:GetText())
  frames.craft.populate_text_card_list(recipes, substr, true)
  frames.craft.populate_card_list(recipes, substr)
  end

end