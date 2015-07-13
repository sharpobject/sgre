bgm = nil

local bgm_table = {}
bgm_table["lobby"] = love.audio.newSource("sg_bgm/SwordGirls_Waiting_Room.mp3")
bgm_table["dungeon"] = love.audio.newSource("sg_bgm/4_sg_bgm_dugeon.mp3")
bgm_table["rewards"] = love.audio.newSource("sg_bgm/3_sg_bgm_result.mp3")
bgm_table["fight"] = love.audio.newSource("sg_bgm/2_sg_bgm_vs_02.mp3")
bgm_table["other_main"] = love.audio.newSource("sg_bgm/5_sg_bgm_main_2.mp3")

local sounds_table = {}
sounds_table["attack"] = "sg_sounds/attack.wav"
sounds_table["buff"] = "sg_sounds/buff.wav"
sounds_table["death"] = "sg_sounds/death.wav"
sounds_table["defend"] = "sg_sounds/defend.wav"
sounds_table["life_buff"] = "sg_sounds/life_buff.wav"
sounds_table["trigger_attack"] = "sg_sounds/trigger_attack.wav"
sounds_table["trigger_defend"] = "sg_sounds/trigger_defend.wav"
sounds_table["trigger_start"] = "sg_sounds/trigger_start.wav"
sounds_table["trigger_spell"] = "sg_sounds/trigger_spell.wav"
sounds_table["trigger_vanish"] = "sg_sounds/trigger_vanish.wav"
sounds_table["coin_start"] = "sg_sounds/coin_start.wav"
sounds_table["coin_end"] = "sg_sounds/coin_end.wav"

local button_sound = love.audio.newSource("sg_sounds/btn_click01.wav")
local cancel_sound = love.audio.newSource("sg_sounds/btn_click02.wav")

for state, source in pairs(bgm_table) do
    source:setLooping(true)
end

function play_bgm(state)
    if bgm and bgm:isPlaying() and bgm_table[state] == bgm then
        return --do nothing if we are already playing the right music for the requested state
    end
    if bgm then
        bgm:stop()
    end
    bgm = bgm_table[state]
    bgm:setVolume(options.music_volume)
    bgm:play()
end

function play_button_sound()
    button_sound:stop()
    button_sound:setVolume(options.sfx_volume)
    button_sound:play()
end

function play_cancel_sound()
    cancel_sound:stop()
    cancel_sound:setVolume(options.sfx_volume)
    cancel_sound:play()
end

function play_sound(kind)
    sound = sounds_table[kind]
    if (sound == nil) then
    else
        source = love.audio.newSource(sound)
        source:setVolume(options.sfx_volume)
        source:play()
    end
end