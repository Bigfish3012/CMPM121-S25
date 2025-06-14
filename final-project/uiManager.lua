-- uiManager.lua: Manages UI elements and interactions
local GameLogic = require "game"
local CardAnimation = require "cardAnimation"
local Button = require "button"
local ResourceManager = require "resourceManager"

local UIManager = {}

function UIManager:new(screenWidth, screenHeight)
    local ui = {}
    local metadata = {__index = UIManager}
    setmetatable(ui, metadata)
    
    ui.screenWidth = screenWidth
    ui.screenHeight = screenHeight
    
    -- Create buttons using Button module
    local buttonWidth = 150
    local buttonHeight = 40
    local buttonX = (screenWidth - buttonWidth) / 2
    local buttonY = screenHeight - buttonHeight - 20
    
    ui.endTurnButton = Button:new(buttonX, buttonY, buttonWidth, buttonHeight, "SUBMIT", {
        color = {0.2, 0.6, 0.8, 0.8},
        hoverColor = {0.3, 0.7, 0.9, 0.8},
        disabledColor = {0.4, 0.4, 0.4, 0.6},
        textColor = {1, 1, 1, 1},
        disabledTextColor = {0.6, 0.6, 0.6, 1},
        borderColor = {0.1, 0.4, 0.6, 1},
        borderWidth = 2,
        font = ResourceManager:getGameFont(16),
        cornerRadius = 5
    })
    
    ui.settingsButton = Button:new(buttonX + 200, buttonY, 100, buttonHeight, "Settings", {
        color = {0.5, 0.5, 0.5, 0.8},
        hoverColor = {0.6, 0.6, 0.6, 0.8},
        textColor = {1, 1, 1, 1},
        borderColor = {0.3, 0.3, 0.3, 1},
        borderWidth = 2,
        font = ResourceManager:getGameFont(14),
        cornerRadius = 5
    })
    
    return ui
end

-- Check if any cards are currently animating
function UIManager:areCardsAnimating(gameBoard)
    if not gameBoard or not gameBoard.cards then
        return false
    end
    
    -- Check all cards for animation
    for _, card in ipairs(gameBoard.cards) do
        if card and card.isCurrentlyAnimating and card:isCurrentlyAnimating() then
            return true
        end
    end
    
    -- Check if any mana animations are running
    if gameBoard.playerManaAnimations then
        for i = 1, 10 do
            if gameBoard.playerManaAnimations[i] and CardAnimation:isAnimating(gameBoard.playerManaAnimations[i]) then
                return true
            end
        end
    end
    
    return false
end

-- Draw end turn button
function UIManager:drawEndTurnButton(gameBoard)
    -- Get game state
    local gamePhase = GameLogic.gamePhase or "staging"
    local playerSubmitted = GameLogic.player and GameLogic.player.submitted or false
    local cardsAnimating = self:areCardsAnimating(gameBoard)
    
    -- Update button state and text based on game phase
    local buttonText = "SUBMIT"
    local disabled = cardsAnimating or playerSubmitted or gamePhase == "revealing"
    
    if cardsAnimating then
        buttonText = "ANIMATING..."
    elseif playerSubmitted then
        buttonText = "SUBMITTED"
    elseif gamePhase == "revealing" then
        buttonText = "REVEALING"
    end
    
    -- Update button properties
    self.endTurnButton:setText(buttonText)
    self.endTurnButton:setDisabled(disabled)
    
    -- Set specific colors based on state
    if gamePhase == "revealing" then
        self.endTurnButton:setColors(
            {0.8, 0.6, 0.2, 0.8},  -- color
            {0.9, 0.7, 0.3, 0.8},  -- hoverColor
            {1, 1, 1, 1}           -- textColor
        )
        self.endTurnButton.borderColor = {0.6, 0.4, 0.1, 1}
    else
        self.endTurnButton:setColors(
            {0.2, 0.6, 0.8, 0.8},  -- color
            {0.3, 0.7, 0.9, 0.8},  -- hoverColor
            {1, 1, 1, 1}           -- textColor
        )
        self.endTurnButton.borderColor = {0.1, 0.4, 0.6, 1}
    end
    
    -- Draw the button
    self.endTurnButton:draw()
end

-- Draw settings button
function UIManager:drawSettingsButton()
    self.settingsButton:draw()
end

-- Update button hover states
function UIManager:updateButtonHover(x, y)
    self.endTurnButton:updateHover(x, y)
    self.settingsButton:updateHover(x, y)
end

-- Check if point is inside end turn button and button is not disabled
function UIManager:isPointInEndTurnButton(x, y)
    return self.endTurnButton:mousepressed(x, y, 1)
end

-- Check if point is inside settings button
function UIManager:isPointInSettingsButton(x, y)
    return self.settingsButton:mousepressed(x, y, 1)
end

return UIManager 