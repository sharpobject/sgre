require "util"
json = require "dkjson"
input = io.read("*a")
cards = json.decode(input)
id_to_card = fix_num_keys(json.decode(file_contents("swogi.json")).id_to_card)
for k,v in ipairs(cards) do
  print(v, id_to_card[v].episode, id_to_card[v].name)
end