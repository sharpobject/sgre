json = require"dkjson"
dungeons = {}
dungeons[1] = {
  {110004},
  {110006},
  {120001},
}
dungeons[2] = {
  {110002},
  {110009},
  {110010},
  {120002},
}
dungeons[3] = {
  {110018},
  {110019},
  {110020},
  {110021},
  {120003},
}

print(json.encode(dungeons))