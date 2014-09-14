local bgm = nil

local bgm_table = {}
bgm_table["lobby"] = love.audio.newSource("sg_assets/bgm/SwordGirls_Waiting_Room.mp3")
bgm_table["dungeon"] = love.audio.newSource("sg_assets/bgm/4_sg_bgm_dugeon.mp3")
bgm_table["rewards"] = love.audio.newSource("sg_assets/bgm/3_sg_bgm_result.mp3")
bgm_table["fight"] = love.audio.newSource("sg_assets/bgm/2_sg_bgm_vs_02.mp3")
bgm_table["other_main"] = love.audio.newSource("sg_assets/bgm/5_sg_bgm_main_2.mp3")

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
    bgm:play()
end
