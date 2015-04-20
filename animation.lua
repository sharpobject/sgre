local ani_to_framecount = {
  attack = 13,
  buff = 13,
  death = 13,
  defend = 13,
  life_buff = 13,
  trigger_attack = 13,
  trigger_defend = 13,
  trigger_start = 13,
  trigger_spell = 13,
  trigger_vanish = 13,
}

local ani_to_dx = {

}

local ani_to_dy = {

}

local ani_coin_blue = {
  {"gray", 42},
  {"gray", 85},
  {"gray", 127},
  {"gray", 170},
  {"gray", 212},
  {"gray", 255},
  {"gray", 255},
  {"gray", 255},
  {"start0", 255},
  {"start1", 255},
  {"red_tl", 255},
  {"red_4l2", 255},
  {"red", 255},
  {"red_tr", 255},
  {"blue_tl", 255},
  {"blue", 255},
  {"blue_tr", 255},
  {"red_tl", 255},
  {"red", 255},
  {"red_tr", 255},
  {"blue_tl", 255},
  {"blue_4l2", 255},
  {"blue", 255},
  {"blue_mr", 255},
  {"blue_tr", 255},
  {"red_tl", 255},
  {"red_2l0", 255},
  {"red_2l1", 255},
  {"red", 255},
  {"red_3r0", 255},
  {"red_3r1", 255},
  {"red_3r2", 255},
  {"red_tr", 255},
  {"blue_tl", 255},
  {"blue_4l0", 255},
  {"blue_4l1", 255},
  {"blue_4l2", 255},
  {"blue", 255},
  {"blue", 255},
  {"blue", 255},
  {"blue", 255},
  {"blue", 255},
  {"blue", 255},
  {"blue", 255},
  {"blue", 255},
  {"blue", 255},
  {"blue", 255},
  {"blue", 255},
  {"blue", 255},
  {"blue", 201},
  {"blue", 153},
  {"blue", 102},
  {"blue", 51}
}

local ani_coin_red = {
  {"gray", 42},
  {"gray", 85},
  {"gray", 127},
  {"gray", 170},
  {"gray", 212},
  {"gray", 255},
  {"gray", 255},
  {"gray", 255},
  {"start0", 255},
  {"start1", 255},
  {"blue_tl", 255},
  {"blue_4l2", 255},
  {"blue", 255},
  {"blue_tr", 255},
  {"red_tl", 255},
  {"red", 255},
  {"red_tr", 255},
  {"blue_tl", 255},
  {"blue", 255},
  {"blue_tr", 255},
  {"red_tl", 255},
  {"red_4l2", 255},
  {"red", 255},
  {"red_mr", 255},
  {"red_tr", 255},
  {"blue_tl", 255},
  {"blue_2l0", 255},
  {"blue_2l1", 255},
  {"blue", 255},
  {"blue_3r0", 255},
  {"blue_3r1", 255},
  {"blue_3r2", 255},
  {"blue_tr", 255},
  {"red_tl", 255},
  {"red_4l0", 255},
  {"red_4l1", 255},
  {"red_4l2", 255},
  {"red", 255},
  {"red", 255},
  {"red", 255},
  {"red", 255},
  {"red", 255},
  {"red", 255},
  {"red", 255},
  {"red", 255},
  {"red", 255},
  {"red", 255},
  {"red", 255},
  {"red", 255},
  {"red", 201},
  {"red", 153},
  {"red", 102},
  {"red", 51}
}

function Game:set_coin_animation(player)
  if player == 1 then
    self.coin_anim = ani_coin_red
  else
    self.coin_anim = ani_coin_blue
  end
  self.coin_flip = true
end

function Game:await_coin_animation()
  local keep_waiting = true
  local players = {self.P1, self.P2}
  while keep_waiting do
    if self.coin_flip then
      wait(1)
    else
      keep_waiting = false
    end
  end
end

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
  wait(5)
end