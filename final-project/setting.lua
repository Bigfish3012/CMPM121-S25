-- setting.lua: Settings box for in-game options

SettingBox = {}

function SettingBox:new(width, height)
    local settingBox = {}
    local metadata = {__index = SettingBox}
    setmetatable(settingBox, metadata)
    
    -- Store screen dimensions
    settingBox.screenWidth = width or 1400
    settingBox.screenHeight = height or 800
    
    -- Setting box properties
    settingBox.width = 350
    settingBox.height = 320
    settingBox.x = (width - 350) / 2
    settingBox.y = (height - 320) / 2
    
    -- Button properties
    settingBox.buttonWidth = 200
    settingBox.buttonHeight = 50
    
    -- State
    settingBox.visible = false
    
    -- Button hover states
    settingBox.restartHover = false
    settingBox.titleScreenHover = false
    settingBox.quitGameHover = false
    
    return settingBox
end

function SettingBox:show()
    self.visible = true
end

function SettingBox:hide()
    self.visible = false
end

function SettingBox:draw()
    if not self.visible then
        return
    end
    
    -- Darken the background
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, self.screenWidth, self.screenHeight)
    
    -- Draw setting box
    love.graphics.setColor(0.3, 0.3, 0.3, 0.95)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 10, 10)
    
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height, 10, 10)
    
    -- Draw title
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(24))
    
    local titleText = "Settings"
    local titleWidth = love.graphics.getFont():getWidth(titleText)
    love.graphics.print(titleText, self.x + (self.width - titleWidth) / 2, self.y + 20)
    
    -- Button positioning
    local buttonX = self.x + (self.width - self.buttonWidth) / 2
    
    -- Draw restart button
    local restartButtonY = self.y + 70
    
    if self.restartHover then
        love.graphics.setColor(0.5, 0.8, 0.5, 1)
    else
        love.graphics.setColor(0.3, 0.6, 0.3, 1)
    end
    love.graphics.rectangle("fill", buttonX, restartButtonY, self.buttonWidth, self.buttonHeight, 5, 5)
    
    -- Draw title screen button
    local titleButtonY = self.y + 140
    
    if self.titleScreenHover then
        love.graphics.setColor(0.9, 0.5, 0.5, 1)
    else
        love.graphics.setColor(0.7, 0.3, 0.3, 1)
    end
    love.graphics.rectangle("fill", buttonX, titleButtonY, self.buttonWidth, self.buttonHeight, 5, 5)
    
    -- Draw quit game button
    local quitButtonY = self.y + 210
    
    if self.quitGameHover then
        love.graphics.setColor(1, 0.4, 0.4, 1)
    else
        love.graphics.setColor(0.8, 0.2, 0.2, 1)
    end
    love.graphics.rectangle("fill", buttonX, quitButtonY, self.buttonWidth, self.buttonHeight, 5, 5)
    
    -- Button text
    love.graphics.setFont(love.graphics.newFont(18))
    love.graphics.setColor(1, 1, 1, 1)
    
    -- Restart button text
    local restartButtonText = "Restart"
    local restartTextWidth = love.graphics.getFont():getWidth(restartButtonText)
    local restartTextHeight = love.graphics.getFont():getHeight()
    local restartTextX = buttonX + (self.buttonWidth - restartTextWidth) / 2
    local restartTextY = restartButtonY + (self.buttonHeight - restartTextHeight) / 2
    love.graphics.print(restartButtonText, restartTextX, restartTextY)
    
    -- Title screen button text
    local titleButtonText = "Back to Title Screen"
    local titleTextWidth = love.graphics.getFont():getWidth(titleButtonText)
    local titleTextHeight = love.graphics.getFont():getHeight()
    local titleTextX = buttonX + (self.buttonWidth - titleTextWidth) / 2
    local titleTextY = titleButtonY + (self.buttonHeight - titleTextHeight) / 2
    love.graphics.print(titleButtonText, titleTextX, titleTextY)
    
    -- Quit game button text
    local quitButtonText = "Quit Game"
    local quitTextWidth = love.graphics.getFont():getWidth(quitButtonText)
    local quitTextHeight = love.graphics.getFont():getHeight()
    local quitTextX = buttonX + (self.buttonWidth - quitTextWidth) / 2
    local quitTextY = quitButtonY + (self.buttonHeight - quitTextHeight) / 2
    love.graphics.print(quitButtonText, quitTextX, quitTextY)
end

function SettingBox:mousepressed(x, y, button)
    if not self.visible or button ~= 1 then
        return nil
    end
    
    local buttonX = self.x + (self.width - self.buttonWidth) / 2
    
    -- Check restart button
    local restartButtonY = self.y + 70
    if x >= buttonX and x <= buttonX + self.buttonWidth and 
       y >= restartButtonY and y <= restartButtonY + self.buttonHeight then
        self:hide()
        return "restart"
    end
    
    -- Check title screen button
    local titleButtonY = self.y + 140
    if x >= buttonX and x <= buttonX + self.buttonWidth and 
       y >= titleButtonY and y <= titleButtonY + self.buttonHeight then
        self:hide()
        return "title"
    end
    
    -- Check quit game button
    local quitButtonY = self.y + 210
    if x >= buttonX and x <= buttonX + self.buttonWidth and 
       y >= quitButtonY and y <= quitButtonY + self.buttonHeight then
        self:hide()
        return "quit"
    end
    
    -- Check if clicked outside the box to close
    if x < self.x or x > self.x + self.width or 
       y < self.y or y > self.y + self.height then
        self:hide()
        return "close"
    end
    
    return nil
end

function SettingBox:mousemoved(x, y)
    if not self.visible then
        return
    end
    
    local buttonX = self.x + (self.width - self.buttonWidth) / 2
    
    -- Update restart button hover state
    local restartButtonY = self.y + 70
    self.restartHover = (x >= buttonX and x <= buttonX + self.buttonWidth and 
                        y >= restartButtonY and y <= restartButtonY + self.buttonHeight)
    
    -- Update title screen button hover state
    local titleButtonY = self.y + 140
    self.titleScreenHover = (x >= buttonX and x <= buttonX + self.buttonWidth and 
                            y >= titleButtonY and y <= titleButtonY + self.buttonHeight)
    
    -- Update quit game button hover state
    local quitButtonY = self.y + 210
    self.quitGameHover = (x >= buttonX and x <= buttonX + self.buttonWidth and 
                         y >= quitButtonY and y <= quitButtonY + self.buttonHeight)
end

return SettingBox
