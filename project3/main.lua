-- main file: for the game loop
io.stdout:setvbuf("no")

require "gameBoard"
require "card"
require "game"
require "vector"
require "title"

local currentScreen = "title"
local titleScreen = Title:new()

function love.load()
    love.window.setTitle("C C C G")
    love.window.setMode(1200, 700)
    love.graphics.setBackgroundColor(0, 0.7, 0.2, 1)
end

function love.update()
    -- Update game logic here
end

function love.draw()
    if currentScreen == "title" then
        titleScreen:draw()
    else
        GameBoard:draw()
    end
end

function love.mousepressed(x, y, button)
    if currentScreen == "title" then
        if titleScreen:mousepressed(x, y, button) then
            currentScreen = "game"
        end
    else
        -- Handle game mouse events here
    end
end