-- helper file: for helper functions

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
    gameOverBox.buttonWidth = 120
    gameOverBox.buttonHeight = 50
    
    -- State
    gameOverBox.visible = false
    gameOverBox.result = nil  -- "win" or "lose"
    
    -- Button hover states
    gameOverBox.restartHover = false
    gameOverBox.titleHover = false
    gameOverBox.quitHover = false
    
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
    love.graphics.setFont(love.graphics.newFont("asset/fonts/game.TTF", 24))
    
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
    
    -- Draw buttons
    local buttonY = self.y + 180
    local buttonSpacing = 20
    local totalButtonsWidth = 3 * self.buttonWidth + 2 * buttonSpacing
    local startX = self.x + (self.width - totalButtonsWidth) / 2
    
    -- Restart button
    if self.restartHover then
        love.graphics.setColor(0.306, 0.941, 0.051, 1)
    else
        love.graphics.setColor(0.259, 0.812, 0.035, 1)
    end
    love.graphics.rectangle("fill", startX, buttonY, self.buttonWidth, self.buttonHeight, 5, 5)
    
    -- Title button
    if self.titleHover then
        love.graphics.setColor(1.0, 0.810, 0.547, 1)
    else
        love.graphics.setColor(0.976, 0.710, 0.447, 1)
    end
    love.graphics.rectangle("fill", startX + self.buttonWidth + buttonSpacing, buttonY, self.buttonWidth, self.buttonHeight, 5, 5)
    
    -- Quit button
    if self.quitHover then
        love.graphics.setColor(1.0, 0.508, 0.508, 1)
    else
        love.graphics.setColor(1.0, 0.408, 0.408, 1)
    end
    love.graphics.rectangle("fill", startX + 2 * (self.buttonWidth + buttonSpacing), buttonY, self.buttonWidth, self.buttonHeight, 5, 5)
    
    -- Button text
    love.graphics.setFont(love.graphics.newFont("asset/fonts/game.TTF", 16))
    love.graphics.setColor(1, 1, 1, 1)
    
    local restartText = "Restart"
    local restartWidth = love.graphics.getFont():getWidth(restartText)
    love.graphics.print(restartText, startX + (self.buttonWidth - restartWidth) / 2, buttonY + 15)
    
    local titleText = "Title"
    local titleWidth = love.graphics.getFont():getWidth(titleText)
    love.graphics.print(titleText, startX + self.buttonWidth + buttonSpacing + (self.buttonWidth - titleWidth) / 2, buttonY + 15)
    
    local quitText = "Quit"
    local quitWidth = love.graphics.getFont():getWidth(quitText)
    love.graphics.print(quitText, startX + 2 * (self.buttonWidth + buttonSpacing) + (self.buttonWidth - quitWidth) / 2, buttonY + 15)
    
    -- Reset font
    love.graphics.setFont(love.graphics.getFont())
end

function GameOverBox:mousemoved(x, y)
    if not self.visible then
        return
    end
    
    -- Check button hover states
    local buttonY = self.y + 180
    local buttonSpacing = 20
    local totalButtonsWidth = 3 * self.buttonWidth + 2 * buttonSpacing
    local startX = self.x + (self.width - totalButtonsWidth) / 2
    
    -- Restart button
    self.restartHover = 
        x > startX and 
        x < startX + self.buttonWidth and
        y > buttonY and
        y < buttonY + self.buttonHeight
    
    -- Title button
    self.titleHover = 
        x > startX + self.buttonWidth + buttonSpacing and
        x < startX + 2 * self.buttonWidth + buttonSpacing and
        y > buttonY and
        y < buttonY + self.buttonHeight
    
    -- Quit button
    self.quitHover = 
        x > startX + 2 * (self.buttonWidth + buttonSpacing) and
        x < startX + 3 * self.buttonWidth + 2 * buttonSpacing and
        y > buttonY and
        y < buttonY + self.buttonHeight
end

function GameOverBox:mousepressed(x, y, button)
    if not self.visible or button ~= 1 then
        return nil
    end
    
    -- Check if restart button clicked
    if self.restartHover then
        self:hide()
        return "restart"
    end
    
    -- Check if title button clicked
    if self.titleHover then
        self:hide()
        return "title"
    end
    
    -- Check if quit button clicked
    if self.quitHover then
        self:hide()
        return "quit"
    end
    
    return nil
end

