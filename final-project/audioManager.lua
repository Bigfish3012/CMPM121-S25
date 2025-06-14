-- audioManager.lua: Centralized audio management
local AudioManager = {}

-- Audio sources
local bgMusic = nil
local bgMusic2 = nil
local winSound = nil
local loseSound = nil
local flipSound = nil
local button1 = nil  -- for "play" and "restart"
local button2 = nil  -- for other buttons

-- Sound effect management
local soundCallback = nil
local soundTimer = 0
local soundDuration = 0

-- Initialize audio system
function AudioManager:init()
    -- Load background music
    bgMusic = love.audio.newSource("asset/music/bg-music.mp3", "stream")
    bgMusic:setLooping(true)
    bgMusic:setVolume(0.3)
    bgMusic:play()

    bgMusic2 = love.audio.newSource("asset/music/bg-music2.mp3", "stream")
    bgMusic2:setLooping(true)
    bgMusic2:setVolume(0.3)

    winSound = love.audio.newSource("asset/music/win.mp3", "static")
    winSound:setVolume(0.3)

    loseSound = love.audio.newSource("asset/music/lose.mp3", "static")
    loseSound:setVolume(0.3)
    
    flipSound = love.audio.newSource("asset/music/flip.mp3", "static")
    flipSound:setVolume(3)
    
    button1 = love.audio.newSource("asset/music/button1.mp3", "static")
    button1:setVolume(0.7)
    
    button2 = love.audio.newSource("asset/music/button2.mp3", "static")
    button2:setVolume(0.7)
end

-- Update audio system
function AudioManager:update(dt)
    -- Handle sound effect callbacks
    if soundCallback and soundTimer > 0 then
        soundTimer = soundTimer - dt
        if soundTimer <= 0 then
            local callback = soundCallback
            soundCallback = nil
            soundTimer = 0
            callback()  -- Execute the callback after sound finishes
        end
    end
end

-- Play flip sound
function AudioManager:playFlipSound()
    if flipSound then
        flipSound:stop()
        flipSound:play()
    end
end

-- Play button sound for "play" and "restart" with callback
function AudioManager:playbutton1(callback)
    if button1 then
        button1:stop()
        button1:play()
        
        if callback then
            soundCallback = callback
            soundDuration = button1:getDuration()
            soundTimer = soundDuration
        end
    elseif callback then
        -- If no sound, execute callback immediately
        callback()
    end
end

-- Play button sound for other buttons with callback
function AudioManager:playbutton2(callback)
    if button2 then
        button2:stop()
        button2:play()
        
        if callback then
            soundCallback = callback
            soundDuration = button2:getDuration()
            soundTimer = soundDuration
        end
    elseif callback then
        -- If no sound, execute callback immediately
        callback()
    end
end

-- Play win sound
function AudioManager:playWinSound()
    if bgMusic2 then bgMusic2:stop() end
    if winSound then winSound:play() end
end

-- Play lose sound
function AudioManager:playLoseSound()
    if bgMusic2 then bgMusic2:stop() end
    if loseSound then loseSound:play() end
end

-- Switch music based on screen
function AudioManager:switchMusic(screen)
    if screen == "title" or screen == "credits" then
        -- Stop game music and play title music
        if bgMusic2 and bgMusic2:isPlaying() then
            bgMusic2:stop()
        end
        if bgMusic and not bgMusic:isPlaying() then
            bgMusic:play()
        end
    elseif screen == "game" then
        -- Stop title music and play game music
        if bgMusic and bgMusic:isPlaying() then
            bgMusic:stop()
        end
        if bgMusic2 and not bgMusic2:isPlaying() then
            bgMusic2:play()
        end
    end
end

-- Make flip sound globally accessible
function playFlipSound()
    AudioManager:playFlipSound()
end

return AudioManager 