-- main file: for the game loop
io.stdout:setvbuf("no")

require "gameBoard"
require "card"
require "vector"
require "title"
require "credit"
require "helper"
require "grabber"
require "player"
require "ai"
require "setting"

local GameLogic = require "game"

-- Background music variable
local bgMusic = nil
local bgMusic2 = nil

local currentScreen = "title"
local screenWidth = 1400
local screenHeight = 800
local titleScreen = nil
local creditScreen = nil
local gameOverBox = nil
local settingBox = nil
local gameBoard = nil

function love.load()
    -- Load background music
    bgMusic = love.audio.newSource("asset/music/bg-music.mp3", "stream")
    bgMusic:setLooping(true)
    bgMusic:setVolume(0.3)
    bgMusic:play()

    bgMusic2 = love.audio.newSource("asset/music/bg-music2.mp3", "stream")
    bgMusic2:setLooping(true)
    bgMusic2:setVolume(0.3)

    initializeGame()
end

-- Function to initialize or restart the game
function initializeGame()
    love.window.setTitle("C C C G")
    love.window.setMode(screenWidth, screenHeight)
    love.graphics.setBackgroundColor(0, 0.7, 0.2, 1)
    
    -- Initialize screens with dimensions
    if not titleScreen then
        titleScreen = Title:new(screenWidth, screenHeight)
    end
    
    if not creditScreen then
        creditScreen = Credit:new(screenWidth, screenHeight)
    end
    
    if not gameOverBox then
        gameOverBox = GameOverBox:new(screenWidth, screenHeight)
    end
    
    if not settingBox then
        settingBox = SettingBox:new(screenWidth, screenHeight)
    end
    
    -- Always reinitialize the game board on restart
    gameBoard = GameBoard:new(screenWidth, screenHeight)
    grabber = GrabberClass:new(gameBoard)
    GameLogic.init(gameBoard)

end

function love.update()
    -- Update game logic here
    if currentScreen == "game" then
        -- Update game board and grabber
        grabber:update()
        
        -- Check win conditions
        local winner = GameLogic:checkWinCondition(gameBoard)
        if winner then
            if winner == "player" then
                showGameOver("win")
            else
                showGameOver("lose")
            end
        end
    end
end

function love.draw()
    if currentScreen == "title" then
        titleScreen:draw()
    elseif currentScreen == "credits" then
        creditScreen:draw()
    else
        gameBoard:draw()
    end
    gameOverBox:draw()
    settingBox:draw()
end

function love.mousepressed(x, y, button)
    -- First check if setting box is interacted with
    if settingBox.visible then
        local result = settingBox:mousepressed(x, y, button)
        if result == "restart" then
            initializeGame()
            currentScreen = "game"
            switchMusic("game")
            return
        elseif result == "title" then
            initializeGame()
            currentScreen = "title"
            switchMusic("title")
            return
        elseif result == "quit" then
            love.event.quit()
            return
        elseif result == "close" then
            return
        end
    end
    
    -- Then check if game over box is interacted with
    if gameOverBox.visible then
        local result = gameOverBox:mousepressed(x, y, button)
        if result == "title" then
            initializeGame()
            currentScreen = "title"
            switchMusic("title")
            return
        elseif result == "restart" then
            initializeGame()
            currentScreen = "game"
            switchMusic("game")
            return
        end
    end
    
    -- Process other screens if no overlay is visible or was not interacted with
    if currentScreen == "title" then
        local result = titleScreen:mousepressed(x, y, button)
        if result == "game" then
            currentScreen = "game"
            switchMusic("game")
        elseif result == "credits" then
            currentScreen = "credits"
            switchMusic("credits")
        elseif result == "quit" then
            love.event.quit()
        end
    elseif currentScreen == "credits" then
        local result = creditScreen:mousepressed(x, y, button)
        if result == "title" then
            currentScreen = "title"
            switchMusic("title")
        end
    elseif currentScreen == "game" then
        -- Check if settings button was clicked
        if gameBoard and gameBoard:isPointInSettingsButton(x, y) then
            settingBox:show()
            return
        end
        
        -- Check if end turn button was clicked
        if gameBoard and gameBoard:isPointInEndTurnButton(x, y) then
            if GameLogic.gamePhase == "staging" and not GameLogic.player.submitted then
                GameLogic:submitTurn()
            end
        end
    end
end

function love.mousemoved(x, y, dx, dy)
    -- Update setting box
    settingBox:mousemoved(x, y)
    
    -- Update game over box
    gameOverBox:mousemoved(x, y)
    
    -- Update other screens
    if currentScreen == "title" then
        titleScreen:mousemoved(x, y)
    elseif currentScreen == "credits" then
        creditScreen:mousemoved(x, y)
    end
end

-- Function to show game over message
function showGameOver(result)
    gameOverBox:show(result)  -- "win" or "lose"
end

-- Function to manage music based on current screen
function switchMusic(screen)
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

function getCurrentMusic()
    if currentScreen == "title" or currentScreen == "credits" then
        return bgMusic
    elseif currentScreen == "game" then
        return bgMusic2
    end
    return nil
end

-- Clean up when the game is closed
function love.quit()
    if bgMusic then
        bgMusic:stop()
    end
    if bgMusic2 then
        bgMusic2:stop()
    end
end
