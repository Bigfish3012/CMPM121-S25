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
    gameOverBox.width = 400
    gameOverBox.height = 250
    gameOverBox.x = (width - 400) / 2
    gameOverBox.y = (height - 250) / 2
    
    -- Button properties
    gameOverBox.buttonWidth = 150
    gameOverBox.buttonHeight = 50
    
    -- State
    gameOverBox.visible = false
    gameOverBox.result = nil  -- "win" or "lose"
    
    -- Button hover states
    gameOverBox.restartHover = false
    gameOverBox.titleHover = false
    
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
    love.graphics.setFont(love.graphics.newFont(24))
    
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
    local buttonY = self.y + 150
    
    -- Restart button
    if self.restartHover then
        love.graphics.setColor(0.4, 0.4, 0.9, 1)
    else
        love.graphics.setColor(0.2, 0.2, 0.7, 1)
    end
    love.graphics.rectangle("fill", self.x + 40, buttonY, self.buttonWidth, self.buttonHeight, 5, 5)
    
    -- Title button
    if self.titleHover then
        love.graphics.setColor(0.9, 0.4, 0.4, 1)
    else
        love.graphics.setColor(0.7, 0.2, 0.2, 1)
    end
    love.graphics.rectangle("fill", self.x + self.width - 40 - self.buttonWidth, buttonY, self.buttonWidth, self.buttonHeight, 5, 5)
    
    -- Button text
    love.graphics.setFont(love.graphics.newFont(16))
    love.graphics.setColor(1, 1, 1, 1)
    
    local restartText = "Restart"
    local restartWidth = love.graphics.getFont():getWidth(restartText)
    love.graphics.print(restartText, self.x + 40 + (self.buttonWidth - restartWidth) / 2, buttonY + 15)
    
    local titleText = "Title Screen"
    local titleWidth = love.graphics.getFont():getWidth(titleText)
    love.graphics.print(titleText, self.x + self.width - 40 - self.buttonWidth + (self.buttonWidth - titleWidth) / 2, buttonY + 15)
    
    -- Reset font
    love.graphics.setFont(love.graphics.getFont())
end

function GameOverBox:mousemoved(x, y)
    if not self.visible then
        return
    end
    
    -- Check button hover states
    local buttonY = self.y + 150
    
    -- Restart button
    self.restartHover = 
        x > self.x + 40 and 
        x < self.x + 40 + self.buttonWidth and
        y > buttonY and
        y < buttonY + self.buttonHeight
    
    -- Title button
    self.titleHover = 
        x > self.x + self.width - 40 - self.buttonWidth and
        x < self.x + self.width - 40 and
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
    
    return nil
end

