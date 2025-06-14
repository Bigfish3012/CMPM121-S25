-- helper file: for helper functions

local Button = require("button")
local ResourceManager = require("resourceManager")

-- GameOver box module
GameOverBox = {}

function GameOverBox:new(width, height)
    local gameOverBox = {}
    local metadata = {__index = GameOverBox}
    setmetatable(gameOverBox, metadata)
    
    -- Store screen dimensions
    gameOverBox.screenWidth = width or 1400
    gameOverBox.screenHeight = height or 800
    
    -- Game over box properties
    gameOverBox.width = 500
    gameOverBox.height = 300
    gameOverBox.x = (width - 500) / 2
    gameOverBox.y = (height - 300) / 2
    
    -- Button properties
    local buttonWidth = 120
    local buttonHeight = 50
    local buttonY = gameOverBox.y + 180
    local buttonSpacing = 20
    local totalButtonsWidth = 3 * buttonWidth + 2 * buttonSpacing
    local startX = gameOverBox.x + (gameOverBox.width - totalButtonsWidth) / 2
    
    -- Create buttons using Button module
    gameOverBox.buttons = {
        restart = Button:new(startX, buttonY, buttonWidth, buttonHeight, "Restart", {
            color = {0.259, 0.812, 0.035, 1},
            hoverColor = {0.306, 0.941, 0.051, 1},
            textColor = {1, 1, 1},
            font = ResourceManager:getGameFont(16),
            cornerRadius = 5
        }),
        title = Button:new(startX + buttonWidth + buttonSpacing, buttonY, buttonWidth, buttonHeight, "Title", {
            color = {0.976, 0.710, 0.447, 1},
            hoverColor = {1.0, 0.810, 0.547, 1},
            textColor = {1, 1, 1},
            font = ResourceManager:getGameFont(16),
            cornerRadius = 5
        }),
        quit = Button:new(startX + 2 * (buttonWidth + buttonSpacing), buttonY, buttonWidth, buttonHeight, "Quit", {
            color = {1.0, 0.408, 0.408, 1},
            hoverColor = {1.0, 0.508, 0.508, 1},
            textColor = {1, 1, 1},
            font = ResourceManager:getGameFont(16),
            cornerRadius = 5
        })
    }
    
    -- State
    gameOverBox.visible = false
    gameOverBox.result = nil  -- "win" or "lose"
    
    return gameOverBox
end

function GameOverBox:show(result)
    self.visible = true
    self.result = result
end

function GameOverBox:hide()
    self.visible = false
end

function GameOverBox:draw()
    if not self.visible then
        return
    end
    
    -- Darken the background
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, self.screenWidth, self.screenHeight)
    
    -- Draw game over box
    love.graphics.setColor(0.2, 0.2, 0.2, 0.9)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 10, 10)
    
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height, 10, 10)
    
    -- Draw title
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(ResourceManager:getGameFont(30))
    
    local titleText = "Game Over"
    if self.result == "win" then
        titleText = "Victory!"
        love.graphics.setColor(0.2, 1, 0.2, 1)  -- Green for win
    elseif self.result == "lose" then
        titleText = "Defeat"
        love.graphics.setColor(1, 0.2, 0.2, 1)  -- Red for lose
    end
    
    local titleWidth = love.graphics.getFont():getWidth(titleText)
    love.graphics.print(titleText, self.x + (self.width - titleWidth) / 2, self.y + 30)
    
    -- Draw buttons using Button module
    for _, button in pairs(self.buttons) do
        button:draw()
    end
end

function GameOverBox:mousemoved(x, y)
    if not self.visible then
        return
    end
    
    -- Update button hover states using Button module
    for _, button in pairs(self.buttons) do
        button:updateHover(x, y)
    end
end

function GameOverBox:mousepressed(x, y, button)
    if not self.visible or button ~= 1 then
        return nil
    end
    
    -- Check button clicks using Button module
    if self.buttons.restart:mousepressed(x, y, button) then
        self:hide()
        return "restart"
    elseif self.buttons.title:mousepressed(x, y, button) then
        self:hide()
        return "title"
    elseif self.buttons.quit:mousepressed(x, y, button) then
        self:hide()
        return "quit"
    end
    
    return nil
end

