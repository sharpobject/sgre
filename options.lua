options = {}
if love.filesystem.exists("options.json") then
  options = json.decode(file_contents("options.json"))
end
if options.music_volume == nil then
  options.music_volume = 0.1
end
if options.sfx_volume == nil then
  options.sfx_volume = 0.3
end
if options.remember_me == nil then
  options.remember_me = true
end
if options.remember_me_name == nil then
  options.remember_me_name = ""
end
if options.remember_me_password == nil then
  options.remember_me_password = ""
end