local function dp_to_bracket(dp)
  if dp <= 100 then return "100" end
  if dp <= 300 then return "300" end
  if dp <= 700 then return "700" end
  return "9001"
end

function list_to_bracket(list)
  local dp = 0
  for k,v in pairs(list) do
    local card = Card(v)
    dp = dp + card.points
  end
  return dp_to_bracket(dp)
end

function deck_to_bracket(deck)
  local dp = 0
  for k,v in pairs(deck) do
    local card = Card(k)
    dp = dp + card.points * v
  end
  return dp_to_bracket(dp)
end