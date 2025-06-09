-- setting.lua: Settings box for in-game options

local Button = require "button"

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
    local buttonWidth = 200
    local buttonHeight = 50
    local buttonX = settingBox.x + (settingBox.width - buttonWidth) / 2
    
    -- Create buttons using Button module
    settingBox.buttons = {
        restart = Button:new(buttonX, settingBox.y + 70, buttonWidth, buttonHeight, "Restart", {
            color = {0.259, 0.812, 0.035, 1},
            hoverColor = {0.306, 0.941, 0.051, 1},
            textColor = {1, 1, 1},
            font = love.graphics.newFont("asset/fonts/game.TTF", 18),
            cornerRadius = 5
        }),
        titleScreen = Button:new(buttonX, settingBox.y + 140, buttonWidth, buttonHeight, "Title Screen", {
            color = {0.976, 0.710, 0.447, 1},
            hoverColor = {1.0, 0.810, 0.547, 1},
            textColor = {1, 1, 1},
            font = love.graphics.newFont("asset/fonts/game.TTF", 18),
            cornerRadius = 5
        }),
        quitGame = Button:new(buttonX, settingBox.y + 210, buttonWidth, buttonHeight, "Quit Game", {
            color = {1.0, 0.408, 0.408, 1},
            hoverColor = {1.0, 0.508, 0.508, 1},
            textColor = {1, 1, 1},
            font = love.graphics.newFont("asset/fonts/game.TTF", 18),
            cornerRadius = 5
        })
    }
    
    -- State
    settingBox.visible = false
    
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
    love.graphics.setFont(love.graphics.newFont("asset/fonts/game.TTF", 24))
    
    local titleText = "Settings"
    local titleWidth = love.graphics.getFont():getWidth(titleText)
    love.graphics.print(titleText, self.x + (self.width - titleWidth) / 2, self.y + 20)
    
    -- Draw buttons using Button module
    for _, button in pairs(self.buttons) do
        button:draw()
    end
end

function SettingBox:mousepressed(x, y, button)
    if not self.visible or button ~= 1 then
        return nil
    end
    
    -- Check button clicks using Button module
    if self.buttons.restart:mousepressed(x, y, button) then
        self:hide()
        return "restart"
    elseif self.buttons.titleScreen:mousepressed(x, y, button) then
        self:hide()
        return "title"
    elseif self.buttons.quitGame:mousepressed(x, y, button) then
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
    
    -- Update button hover states using Button module
    for _, button in pairs(self.buttons) do
        button:updateHover(x, y)
    end
end

return SettingBox
