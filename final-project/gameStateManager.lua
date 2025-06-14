-- gameStateManager.lua: Handles game state transitions and management
local GameStateManager = {}

-- Initialize game state manager
function GameStateManager:init(gameLogic)
    self.gameLogic = gameLogic
end

-- Start the next turn
function GameStateManager:startNextTurn(gameLogic)
    -- Reset submission states
    gameLogic.player:resetForNewTurn()
    gameLogic.ai:resetForNewTurn()
    gameLogic.gamePhase = "staging"
    
    -- Reset placed card list for new turn
    gameLogic.placedCardList = {}
    gameLogic.currentRevealIndex = nil
    gameLogic.allCardRevealed = true
    
    -- Increment turn number
    gameLogic.turnNumber = gameLogic.turnNumber + 1
    
    -- Set mana to turn number (max 10)
    local baseMana = math.min(10, gameLogic.turnNumber)
    
    gameLogic.player:setManaForTurn(baseMana, gameLogic.gameBoard)
    gameLogic.ai:setManaForTurn(baseMana, gameLogic.gameBoard)
end

-- Draw cards at start of turn (only for player now, AI draws during opponent turn)
function GameStateManager:drawCards(gameLogic)
    if not gameLogic.gameBoard then return end
    
    -- Player draws a card using Player class method
    gameLogic.player:drawCard(gameLogic.gameBoard)
    
    -- Reposition cards
    gameLogic.gameBoard:positionHandCards()
end

-- Check win conditions
function GameStateManager:checkWinCondition(gameLogic, gameBoard)
    -- Check if either player has reached the target score using Player and AI classes
    local playerWon = gameLogic.player:hasWon(gameLogic.targetScore)
    local aiWon = gameLogic.ai:hasWon(gameLogic.targetScore)
    
    if playerWon and aiWon then
        -- Both reached target, higher score wins
        if gameLogic.player.score > gameLogic.ai.score then
            return "player"
        elseif gameLogic.ai.score > gameLogic.player.score then
            return "opponent"
        else
            return nil  -- Tie, continue playing
        end
    elseif playerWon then
        return "player"
    elseif aiWon then
        return "opponent"
    end
    
    return nil  -- No winner yet
end

-- Handle game end (called after scoring)
function GameStateManager:handleGameEnd(gameLogic)
    local winner = self:checkWinCondition(gameLogic, gameLogic.gameBoard)
    if winner then
        -- Stop all animations when game ends
        gameLogic:stopAllAnimations()
        
        -- Call the game end callback if it exists
        if gameLogic.onGameEnd then
            gameLogic.onGameEnd(winner)
        end
        
        return true  -- Game ended
    end
    return false  -- Game continues
end

-- Calculate scores for each location and award points
function GameStateManager:calculateLocationScores(gameLogic, gameBoard)
    local totalPlayerPoints = 0
    local totalOpponentPoints = 0
    
    -- Helper function to calculate location power
    local function calculateLocationPower(locationSlots)
        local totalPower = 0
        for slot = 1, 4 do
            local card = locationSlots[slot]
            if card and card.faceUp then
                totalPower = totalPower + (card.power or 0)
            end
        end
        return totalPower
    end
    
    -- Check each of the 3 locations
    for locationIndex = 1, 3 do
        local playerPower = calculateLocationPower(gameBoard.locations[locationIndex].playerSlots)
        local opponentPower = calculateLocationPower(gameBoard.locations[locationIndex].opponentSlots)
        
        -- Award points based on power difference
        if playerPower > opponentPower then
            totalPlayerPoints = totalPlayerPoints + (playerPower - opponentPower)
        elseif opponentPower > playerPower then
            totalOpponentPoints = totalOpponentPoints + (opponentPower - playerPower)
        end
        -- If tied, no points awarded
    end
    
    -- Add points to total scores using Player and AI classes
    gameLogic.player:addScore(totalPlayerPoints)
    gameLogic.ai:addScore(totalOpponentPoints)
    
    -- Check for game end after scoring
    self:handleGameEnd(gameLogic)
    
    return totalPlayerPoints, totalOpponentPoints
end

return GameStateManager 