-- helper file: for helper functions

-- GameOver box module
GameOverBox = {}

function GameOverBox:new(width, height)
    local box = {}
    local metadata = {__index = GameOverBox}
    setmetatable(box, metadata)
    
    -- Store screen dimensions
    box.screenWidth = width or 1400
    box.screenHeight = height or 800
    
    -- Load custom font
    box.titleFont = love.graphics.newFont("asset/fonts/Angels.ttf", 64)
    box.messageFont = love.graphics.newFont("asset/fonts/Angels.ttf", 36)
    box.buttonFont = love.graphics.newFont("asset/fonts/Angels.ttf", 32)
    
    -- Box dimensions and properties
    box.width = 600
    box.height = 400
    box.x = (width - box.width) / 2
    box.y = (height - box.height) / 2
    box.color = {1, 1, 1, 0.95}
    box.borderColor = {0.8, 0.8, 0.8, 1}
    box.visible = false
    box.result = "" -- "win" or "lose"
    
    -- Back button
    box.backButton = {
        text = "Menu",
        x = box.x + 50,
        y = box.y + box.height - 80,
        width = 220,
        height = 50,
        color = {0.8, 0.8, 1, 0.8},
        hoverColor = {0.9, 0.9, 1, 0.9},
        textColor = {0, 0, 0},
        hover = false
    }
    
    -- Restart button
    box.restartButton = {
        text = "Restart",
        x = box.x + box.width - 270,
        y = box.y + box.height - 80,
        width = 220,
        height = 50,
        color = {0.8, 1, 0.8, 0.8},
        hoverColor = {0.9, 1, 0.9, 0.9},
        textColor = {0, 0, 0},
        hover = false
    }
    
    -- Message for win/lose
    box.messages = {
        win = "Congratulations! You Won!",
        lose = "Game Over! Try Again?"
    }
    
    return box
end

function GameOverBox:show(result)
    self.visible = true
    self.result = result -- "win" or "lose"
end

function GameOverBox:hide()
    self.visible = false
end

function GameOverBox:draw()
    if not self.visible then return end
    
    -- Draw semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, self.screenWidth, self.screenHeight)
    
    -- Draw box background
    love.graphics.setColor(self.color)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 15, 15)
    
    -- Draw box border
    love.graphics.setColor(self.borderColor)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height, 15, 15)
    
    -- Draw result message
    love.graphics.setColor(0, 0, 0)
    love.graphics.setFont(self.titleFont)
    love.graphics.printf(self.result == "win" and "You Win!" or "Game Over", 
                         self.x, self.y + 50, self.width, "center")
    
    -- Draw detailed message
    love.graphics.setFont(self.messageFont)
    love.graphics.printf(self.messages[self.result] or "", 
                         self.x, self.y + 150, self.width, "center")
    
    -- Draw back button
    self:drawButton(self.backButton)
    
    -- Draw restart button
    self:drawButton(self.restartButton)
end

function GameOverBox:drawButton(button)
    -- Set button color based on hover state
    if button.hover then
        love.graphics.setColor(button.hoverColor)
    else
        love.graphics.setColor(button.color)
    end
    
    -- Draw button background
    love.graphics.rectangle("fill", button.x, button.y, 
                           button.width, button.height, 10, 10)
    
    -- Draw button text
    love.graphics.setColor(button.textColor)
    love.graphics.setFont(self.buttonFont)
    love.graphics.printf(button.text, button.x, 
                        button.y + 10, button.width, "center")
end

function GameOverBox:mousepressed(x, y, button)
    if not self.visible then return nil end
    
    if button == 1 then  -- Left mouse button
        if self:isMouseOver(self.backButton) then
            self:hide() -- Hide the box
            return "title"  -- Signal to return to title screen
        elseif self:isMouseOver(self.restartButton) then
            self:hide() -- Hide the box
            return "restart"  -- Signal to restart the game
        end
    end
    return nil  -- No state change
end

function GameOverBox:mousemoved(x, y)
    if not self.visible then return end
    
    -- Update hover state for buttons
    self.backButton.hover = self:isMouseOver(self.backButton)
    self.restartButton.hover = self:isMouseOver(self.restartButton)
end

function GameOverBox:isMouseOver(button)
    local mx, my = love.mouse.getPosition()
    return mx >= button.x and mx <= button.x + button.width and 
           my >= button.y and my <= button.y + button.height
end

