-- title file: for the title screen

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
    
    -- Define buttons
    title.buttons = {
        play = {
            text = "Play",
            x = width / 2 - 100,
            y = height / 2 + 50,
            width = 200,
            height = 50,
            color = {0.8, 0.8, 1, 0.7},
            hoverColor = {0.9, 0.9, 1, 0.9},
            textColor = {0, 0, 0},
            hover = false
        },
        credits = {
            text = "Credits",
            x = width / 2 - 100,
            y = height / 2 + 150,
            width = 200,
            height = 50,
            color = {0.8, 0.8, 1, 0.7},
            hoverColor = {0.9, 0.9, 1, 0.9},
            textColor = {0, 0, 0},
            hover = false
        },
        quit = {
            text = "Quit",
            x = width / 2 - 100,
            y = height / 2 + 250,
            width = 200,
            height = 50,
            color = {1, 0.8, 0.8, 0.7},
            hoverColor = {1, 0.9, 0.9, 0.9},
            textColor = {0, 0, 0},
            hover = false
        }
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
        
    -- Draw buttons
    self:drawButtons()
end

function Title:drawButtons()
    -- Draw the Play button
    love.graphics.setFont(self.buttonFont)
    
    for _, button in pairs(self.buttons) do
        -- Set button color (normal or hover)
        if button.hover then
            love.graphics.setColor(button.hoverColor)
        else
            love.graphics.setColor(button.color)
        end
        
        -- Draw button background
        love.graphics.rectangle("fill", button.x, button.y, button.width, button.height, 10, 10)
        
        -- Draw button text
        love.graphics.setColor(button.textColor)
        love.graphics.printf(button.text, button.x, button.y + 10, button.width, "center")
    end
end

function Title:mousepressed(x, y, button)
    if button == 1 then  -- Left mouse button
        -- Check if a button was clicked
        if self:isMouseOver(self.buttons.play.x, self.buttons.play.y, 
                           self.buttons.play.width, self.buttons.play.height) then
            return "game"  -- Signal to start the game
        elseif self:isMouseOver(self.buttons.credits.x, self.buttons.credits.y, 
                               self.buttons.credits.width, self.buttons.credits.height) then
            return "credits"  -- Signal to show credits
        elseif self:isMouseOver(self.buttons.quit.x, self.buttons.quit.y, 
                               self.buttons.quit.width, self.buttons.quit.height) then
            return "quit"  -- Signal to quit the game
        end
    end
    return nil  -- No state change
end

function Title:mousemoved(x, y)
    -- Update hover state for buttons
    for _, button in pairs(self.buttons) do
        button.hover = self:isMouseOver(button.x, button.y, button.width, button.height)
    end
end

function Title:isMouseOver(x, y, width, height)
    local mx, my = love.mouse.getPosition()
    return mx >= x and mx <= x + width and my >= y and my <= y + height
end
    