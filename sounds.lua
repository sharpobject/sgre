bgm = nil

local bgm_table = {}
bgm_table["lobby"] = love.audio.newSource("sg_bgm/SwordGirls_Waiting_Room.mp3")
bgm_table["dungeon"] = love.audio.newSource("sg_bgm/4_sg_bgm_dugeon.mp3")
bgm_table["rewards"] = love.audio.newSource("sg_bgm/3_sg_bgm_result.mp3")
bgm_table["fight"] = love.audio.newSource("sg_bgm/2_sg_bgm_vs_02.mp3")
bgm_table["other_main"] = love.audio.newSource("sg_bgm/5_sg_bgm_main_2.mp3")

local sounds_table = {}
sounds_table["attack"] = "sg_sounds/attack.wav"
sounds_table["buff"] = "sg_sounds/affected.wav"
sounds_table["death"] = "sg_sounds/destroyed.wav"
sounds_table["life_buff"] = "sg_sounds/affected.wav"
sounds_table["trigger_attack"] = "sg_sounds/follower_effect.wav"
sounds_table["trigger_defend"] = "sg_sounds/counter.wav"
sounds_table["trigger_start"] = "sg_sounds/char_effect.wav"
sounds_table["trigger_spell"] = "sg_sounds/spell_effect.wav"
sounds_table["trigger_vanish"] = "sg_sounds/spell_destroyed.wav"

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

function play_sound(kind)
    sound = sounds_table[kind]
    if (sound == nil) then
    else
        source = love.audio.newSource(sound)
        source:setVolume(options.sfx_volume)
        source:play()
    end
end