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
end

function Game:await_animations()
  wait(30)
end
