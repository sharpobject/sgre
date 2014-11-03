options = {music_volume = 0.1}
if love.filesystem.exists("options.json") then
  options = json.decode(file_contents("options.json"))
end