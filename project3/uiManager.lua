-- uiManager.lua: Manages UI elements and interactions
local GameLogic = require "game"

local UIManager = {}

function UIManager:new(screenWidth, screenHeight)
    local ui = {}
    local metadata = {__index = UIManager}
    setmetatable(ui, metadata)
    
    ui.screenWidth = screenWidth
    ui.screenHeight = screenHeight
    ui.endTurnButton = nil
    
    return ui
end

-- Draw end turn button
function UIManager:drawEndTurnButton()
    -- Get game state
    local gamePhase = GameLogic.gamePhase or "staging"
    local playerSubmitted = GameLogic.player and GameLogic.player.submitted or false
    
    -- Button dimensions and position
    local buttonWidth = 150
    local buttonHeight = 40
    local buttonX = (self.screenWidth - buttonWidth) / 2
    local buttonY = self.screenHeight - buttonHeight - 20
    
    -- Store button position for click detection
    self.endTurnButton = {
        x = buttonX,
        y = buttonY,
        width = buttonWidth,
        height = buttonHeight
    }
    
    -- Determine button color and text based on game state
    local buttonText = "SUBMIT"
    local bgColor = {0.2, 0.6, 0.8, 0.8}
    local borderColor = {0.1, 0.4, 0.6, 1}
    
    if playerSubmitted then
        buttonText = "SUBMITTED"
        bgColor = {0.6, 0.6, 0.6, 0.8}
        borderColor = {0.4, 0.4, 0.4, 1}
    elseif gamePhase == "revealing" then
        buttonText = "REVEALING"
        bgColor = {0.8, 0.6, 0.2, 0.8}
        borderColor = {0.6, 0.4, 0.1, 1}
    end
    
    -- Draw button background
    love.graphics.setColor(bgColor)
    love.graphics.rectangle("fill", buttonX, buttonY, buttonWidth, buttonHeight, 5, 5)
    
    -- Draw button border
    love.graphics.setColor(borderColor)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", buttonX, buttonY, buttonWidth, buttonHeight, 5, 5)
    
    -- Draw button text
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(16))
    local textWidth = love.graphics.getFont():getWidth(buttonText)
    local textHeight = love.graphics.getFont():getHeight()
    local textX = buttonX + (buttonWidth - textWidth) / 2
    local textY = buttonY + (buttonHeight - textHeight) / 2
    love.graphics.print(buttonText, textX, textY)
end

-- Check if point is inside end turn button
function UIManager:isPointInEndTurnButton(x, y)
    if not self.endTurnButton then
        return false
    end
    
    return x >= self.endTurnButton.x and 
           x <= self.endTurnButton.x + self.endTurnButton.width and
           y >= self.endTurnButton.y and 
           y <= self.endTurnButton.y + self.endTurnButton.height
end

return UIManager 