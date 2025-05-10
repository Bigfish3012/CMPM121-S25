-- gameBoard: for the game board

GameBoard = {}

function GameBoard:new()
    local gameBoard = {}
    local metadata = {__index = GameBoard}
    setmetatable(gameBoard, metadata)    
    
    return gameBoard
end

function GameBoard:draw()
    -- player's hand
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", 0, 0, 30, 70)
end
