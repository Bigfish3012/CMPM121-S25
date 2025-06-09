-- credit file: for the credits screen

local Button = require "button"

Credit = {}

function Credit:new(width, height)
    local credit = {}
    local metadata = {__index = Credit}
    setmetatable(credit, metadata)
    
    -- Store screen dimensions
    credit.screenWidth = width or 1400
    credit.screenHeight = height or 800
    
    -- Load custom font
    credit.titleFont = love.graphics.newFont("asset/fonts/credit-font.ttf", 100)
    credit.contentFont = love.graphics.newFont("asset/fonts/credit-font.ttf", 32)
    credit.buttonFont = love.graphics.newFont("asset/fonts/credit-font.ttf", 36)
    
    -- Credits information
    credit.title = "CREDITS"
    credit.lines = {
        "Author: Chengkun Li",
        "Made for CMPM121 UCSC",
        "Start time: May 10, 2025",
        "Thanks for playing!"
    }
    
    -- Create back button using Button module
    credit.backButton = Button:new(100, height - 100, 150, 50, "Back", {
        color = {0.976, 0.710, 0.447, 0.7},
        hoverColor = {1.0, 0.810, 0.547, 0.9},
        textColor = {0, 0, 0},
        font = credit.buttonFont,
        cornerRadius = 10
    })
    
    return credit
end

function Credit:draw()
    -- Draw background
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", 0, 0, self.screenWidth, self.screenHeight)
    
    -- Draw credits title
    love.graphics.setColor(0, 0, 0)
    love.graphics.setFont(self.titleFont)
    love.graphics.printf(self.title, 0, 100, self.screenWidth, "center")
    
    -- Draw credits text
    love.graphics.setFont(self.contentFont)
    for i, line in ipairs(self.lines) do
        love.graphics.printf(line, 0, 300 + (i-1) * 50, self.screenWidth, "center")
    end
    
    -- Draw back button using Button module
    self.backButton:draw()
end

function Credit:mousepressed(x, y, button)
    if button == 1 then  -- Left mouse button
        if self.backButton:mousepressed(x, y, button) then
            return "title"  -- Signal to return to title screen
        end
    end
    return nil  -- No state change
end

function Credit:mousemoved(x, y)
    -- Update hover state for back button
    self.backButton:updateHover(x, y)
end
