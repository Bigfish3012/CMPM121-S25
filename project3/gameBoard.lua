-- gameBoard: for the game board

GameBoard = {}

function GameBoard:new(width, height)
    local gameBoard = {}
    local metadata = {__index = GameBoard}
    setmetatable(gameBoard, metadata)
    
    -- Store screen dimensions
    gameBoard.screenWidth = width or 1400
    gameBoard.screenHeight = height or 800
    
    -- Card slot properties
    gameBoard.slotWidth = 800
    gameBoard.slotHeight = 120
    
    return gameBoard
end

function GameBoard:draw()
    -- Draw background
    love.graphics.setColor(0, 0.7, 0.2, 1)
    love.graphics.rectangle("fill", 0, 0, self.screenWidth, self.screenHeight)
    
    -- Draw the top card slot
    self:drawCardSlot(nil, 20)
    -- Draw the bottom card slot
    self:drawCardSlot(nil, self.screenHeight - 140)
    
    -- player's hand
    love.graphics.setColor(1, 1, 1)
end

-- Function to draw the semi-transparent card slot at the top or bottom
function GameBoard:drawCardSlot(x, y)
    -- Use provided coordinates or default values if not provided
    local slotX = x or (self.screenWidth - self.slotWidth) / 2  -- Default: centered horizontally
    local slotY = y or (self.screenHeight - self.slotHeight - 20)  -- Default: near the bottom
    
    -- Draw semi-transparent white card slot
    love.graphics.setColor(1, 1, 1, 0.5)  -- Semi-transparent white
    love.graphics.rectangle("fill", slotX, slotY, self.slotWidth, self.slotHeight, 10, 10)  -- Rounded corners (radius 10)
    
    -- Draw card slot border
    love.graphics.setColor(0.9, 0.9, 0.9, 0.7)  -- Semi-transparent light gray
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", slotX, slotY, self.slotWidth, self.slotHeight, 10, 10)
end
