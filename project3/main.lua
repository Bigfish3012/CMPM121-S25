-- main file: for the game loop
io.stdout:setvbuf("no")

require "gameBoard"
require "card"
require "game"
require "vector"
require "title"
require "credit"
require "helper"
require "grabber"

local currentScreen = "title"
local screenWidth = 1400
local screenHeight = 800
local titleScreen = nil
local creditScreen = nil
local gameOverBox = nil
local gameBoard = nil

function love.load()
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
    
    -- Always reinitialize the game board on restart
    gameBoard = GameBoard:new(screenWidth, screenHeight)
    grabber = GrabberClass:new()
    
    -- For testing the game over box
    -- gameOverBox:show("win")
    -- gameOverBox:show("lose")
end

function love.update()
    -- Update game logic here
    if currentScreen == "game" then
        -- Update game board and grabber
        grabber:update()
        
        -- Check for game over conditions
        if gameState.hasWon then
            showGameOver("win")
        elseif gameState.showRestartConfirm then
            showGameOver("lose")
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
    
    -- Always draw game over box if it's visible (it will overlay on top)
    gameOverBox:draw()
end

function love.mousepressed(x, y, button)
    -- First check if game over box is interacted with
    if gameOverBox.visible then
        local result = gameOverBox:mousepressed(x, y, button)
        if result == "title" then
            currentScreen = "title"
            return  -- Stop processing other clicks when game over box is visible
        elseif result == "restart" then
            -- Restart the game while staying on the game screen
            initializeGame()
            currentScreen = "game"
            return
        end
    end
    
    -- Process other screens if game over box is not visible or was not interacted with
    if currentScreen == "title" then
        local result = titleScreen:mousepressed(x, y, button)
        if result == "game" then
            currentScreen = "game"
        elseif result == "credits" then
            currentScreen = "credits"
        end
    elseif currentScreen == "credits" then
        local result = creditScreen:mousepressed(x, y, button)
        if result == "title" then
            currentScreen = "title"
        end
    end
end

function love.mousemoved(x, y, dx, dy)
    -- Update game over box first
    gameOverBox:mousemoved(x, y)
    
    -- Update other screens
    if currentScreen == "title" then
        titleScreen:mousemoved(x, y)
    elseif currentScreen == "credits" then
        creditScreen:mousemoved(x, y)
    else
        -- Handle game mouse movement here
    end
end

-- Function to show game over message
function showGameOver(result)
    gameOverBox:show(result)  -- "win" or "lose"
end