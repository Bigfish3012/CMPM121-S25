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
local ResourceManager = require "resourceManager"
local AudioManager = require "audioManager"
local InputManager = require "inputManager"

local currentScreen = "title"
local screenWidth = 1400
local screenHeight = 800
local gameEnded = false

-- Screen references
local screens = {}
local gameBoard = nil
local grabber = nil

function love.load()
    -- Preload resources
    ResourceManager:preloadCommonResources()
    
    -- Initialize audio system
    AudioManager:init()
    
    initializeGame()
end

-- Function to initialize or restart the game
function initializeGame()
    love.window.setTitle("C C C G")
    love.window.setMode(screenWidth, screenHeight)
    love.graphics.setBackgroundColor(0, 0.7, 0.2, 1)
    
    -- Initialize screens with dimensions
    if not screens.titleScreen then
        screens.titleScreen = Title:new(screenWidth, screenHeight)
    end
    
    if not screens.creditScreen then
        screens.creditScreen = Credit:new(screenWidth, screenHeight)
    end
    
    if not screens.gameOverBox then
        screens.gameOverBox = GameOverBox:new(screenWidth, screenHeight)
    end
    
    if not screens.settingBox then
        screens.settingBox = SettingBox:new(screenWidth, screenHeight)
    end
    
    -- Add initializeGame reference to screens for InputManager
    screens.initializeGame = initializeGame
    
    -- Always reinitialize the game board on restart
    gameBoard = GameBoard:new(screenWidth, screenHeight)
    grabber = GrabberClass:new(gameBoard)
    GameLogic.init(gameBoard)
    
    -- Set up game end callback
    GameLogic.onGameEnd = function(winner)
        gameEnded = true
        if winner == "player" then
            AudioManager:playWinSound()
            showGameOver("win")
        else
            AudioManager:playLoseSound()
            showGameOver("lose")
        end
    end
    
    gameEnded = false
end

function love.update(dt)
    -- Update audio system
    AudioManager:update(dt)
    
    -- Update game logic
    if currentScreen == "game" and not gameEnded then
        GameLogic:update(dt)
        
        -- Update game board and grabber (only if player can interact)
        if GameLogic:canPlayerInteract() then
            grabber:update()
        end
        
        -- Update card animations
        if gameBoard and gameBoard.cards then
            for _, card in ipairs(gameBoard.cards) do
                if card and card.updateAnimation then
                    card:updateAnimation()
                end
            end
        end
        
        -- Update mana display states
        if gameBoard and gameBoard.updateManaDisplay then
            gameBoard:updateManaDisplay()
        end
    end
end

function love.draw()
    if currentScreen == "title" then
        screens.titleScreen:draw()
    elseif currentScreen == "credits" then
        screens.creditScreen:draw()
    else
        gameBoard:draw()
        -- Draw turn animation overlay (only if game hasn't ended)
        if not gameEnded then
            GameLogic:drawTurnAnimation(screenWidth, screenHeight)
        end
    end
    screens.gameOverBox:draw()
    screens.settingBox:draw()
end

function love.mousepressed(x, y, button)
    currentScreen = InputManager:handleMousePressed(x, y, button, currentScreen, gameEnded, screens, gameBoard, GameLogic, AudioManager) or currentScreen
end

function love.mousemoved(x, y, dx, dy)
    InputManager:handleMouseMoved(x, y, dx, dy, currentScreen, screens, gameBoard)
end

-- Function to show game over message
function showGameOver(result)
    screens.gameOverBox:show(result)  -- "win" or "lose"
end

-- Legacy function wrappers for compatibility
function playButton1Sound(callback)
    AudioManager:playbutton1(callback)
end

function playButton2Sound(callback)
    AudioManager:playbutton2(callback)
end

function switchMusic(screen)
    AudioManager:switchMusic(screen)
end
