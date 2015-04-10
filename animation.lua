local ani_to_framecount = {
  attack = 9,
  buff = 10,
  death = 9,
  defend = 11,
  life_buff = 14,
  trigger_attack = 9,
  trigger_defend = 7,
  trigger_start = 9,
  trigger_spell = 13,
  spell_death = 13,
}

local ani_to_dx = {
  trigger_attack = 1,
  trigger_start = 3,
}

local ani_to_dy = {
  trigger_attack = 4,
}

function Game:set_animation(kind, player_idx, slot)
  local players = {self.P1, self.P2}
  players[player_idx].animation[slot] = {kind=kind,
      framecount=ani_to_framecount[kind], frame = 0,
      dx = ani_to_dx[kind] or 0, dy = ani_to_dy[kind] or 0,}
  play_sound(kind)
end

function Game:await_animations()
  self:await_target_animations()
end

function Game:set_buff_animation(buff, player_idx, slot)
  local players = {self.P1, self.P2}
  local t = {}
  for k,v in pairs(buff) do
    t[k] = v
  end
  t.frame = 0
  players[player_idx].buff_animation[slot] = t
end

function Game:await_buff_animations()
  wait(22)
end

function Game:await_target_animations()
  local keep_waiting = true
  local players = {self.P1, self.P2}
  while keep_waiting do
    local any_animations = false
    for _,p in pairs(players) do
      for i=0,5 do
        if p.animation[i] then
          any_animations = true
        end
      end
    end
    if any_animations then
      wait(1)
    else
      keep_waiting = false
    end
  end
  wait(2)
end
