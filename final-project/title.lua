-- title file: for the title screen

local Button = require "button"

Title = {}

function Title:new(width, height)
    local title = {}
    local metadata = {__index = Title}
    setmetatable(title, metadata)
    
    -- Store screen dimensions
    title.screenWidth = width or 1400
    title.screenHeight = height or 800
    
    -- Load custom font
    title.titleFont = love.graphics.newFont("asset/fonts/Angels.ttf", 120)
    title.subtitleFont = love.graphics.newFont("asset/fonts/Angels.ttf", 32)
    title.buttonFont = love.graphics.newFont("asset/fonts/Angels.ttf", 32)
    
    -- Create buttons using the Button module
    local buttonWidth = 200
    local buttonHeight = 50
    local buttonX = width / 2 - buttonWidth / 2
    
    title.buttons = {
        play = Button:new(buttonX, height / 2 + 50, buttonWidth, buttonHeight, "Play", {
            color = {0.976, 0.710, 0.447, 0.7},
            hoverColor = {1.0, 0.810, 0.547, 0.9},
            textColor = {0, 0, 0},
            font = title.buttonFont,
            cornerRadius = 10
        }),
        credits = Button:new(buttonX, height / 2 + 150, buttonWidth, buttonHeight, "Credits", {
            color = {0.976, 0.710, 0.447, 0.7},
            hoverColor = {1.0, 0.810, 0.547, 0.9},
            textColor = {0, 0, 0},
            font = title.buttonFont,
            cornerRadius = 10
        }),
        quit = Button:new(buttonX, height / 2 + 250, buttonWidth, buttonHeight, "Quit", {
            color = {1.0, 0.408, 0.408, 0.7},
            hoverColor = {1.0, 0.508, 0.508, 0.9},
            textColor = {0, 0, 0},
            font = title.buttonFont,
            cornerRadius = 10
        })
    }
    
    return title
end

function Title:draw()
    -- Draw background
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", 0, 0, self.screenWidth, self.screenHeight)
    
    -- Draw title text with custom font
    love.graphics.setColor(0, 0, 0)
    love.graphics.setFont(self.titleFont)
    love.graphics.printf("C C C G", 0, self.screenHeight / 2 - 200, self.screenWidth, "center")
        
    -- Draw buttons using Button module
    for _, button in pairs(self.buttons) do
        button:draw()
    end
end

function Title:mousepressed(x, y, button)
    if button == 1 then  -- Left mouse button
        -- Check button clicks using Button module
        if self.buttons.play:mousepressed(x, y, button) then
            return "game"  -- Signal to start the game
        elseif self.buttons.credits:mousepressed(x, y, button) then
            return "credits"  -- Signal to show credits
        elseif self.buttons.quit:mousepressed(x, y, button) then
            return "quit"  -- Signal to quit the game
        end
    end
    return nil  -- No state change
end

function Title:mousemoved(x, y)
    -- Update hover state for all buttons
    for _, button in pairs(self.buttons) do
        button:updateHover(x, y)
    end
end
    