-- title file: for the title screen

Title = {}

function Title:new()
    local title = {}
    local metadata = {__index = Title}
    setmetatable(title, metadata)
    
    -- Load custom font
    title.titleFont = love.graphics.newFont("asset/fonts/Angels.ttf", 64)
    title.subtitleFont = love.graphics.newFont("asset/fonts/Angels.ttf", 32)
    
    return title
end

function Title:draw()
    -- Draw background
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", 0, 0, 1200, 700)
    
    -- Draw title text with custom font
    love.graphics.setColor(0, 0, 0)
    love.graphics.setFont(self.titleFont)
    love.graphics.printf("C C C G", 0, 200, 1200, "center")
    
    -- Draw subtitle with custom font
    love.graphics.setFont(self.subtitleFont)
    love.graphics.printf("Click anywhere to start", 0, 500, 1200, "center")
end

function Title:mousepressed(x, y, button)
    if button == 1 then  -- Left mouse button
        return true  -- Signal to start the game
    end
    return false
end
    