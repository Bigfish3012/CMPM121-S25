-- game file: for the game logic

require "card"
local CardEffects = require "cards_eff"
local Player = require "player"
local AI = require "ai"

GameLogic = {}

-- Game state tracking
GameLogic.currentPlayer = "player"
GameLogic.turnNumber = 1 
GameLogic.gameBoard = nil

-- Player and AI instances
GameLogic.player = nil
GameLogic.ai = nil

-- Game settings
GameLogic.targetScore = 20
GameLogic.gamePhase = "staging"

-- Initialize game logic with reference to game board
function GameLogic.init(gameBoard)
    GameLogic.gameBoard = gameBoard
    CardEffects.init(GameLogic)
    
    -- Create player and AI instances
    GameLogic.player = Player:new()
    GameLogic.ai = AI:new()
    
    -- Reset game state
    GameLogic.turnNumber = 1
    GameLogic.gamePhase = "staging"
end

-- Check if a card belongs to the player
function GameLogic:isPlayerCard(card, gameBoard)
    -- Check player hand
    for _, playerCard in ipairs(gameBoard.playerHand) do
        if playerCard == card then
            return true
        end
    end
    
    -- Check player slots in all locations
    for locationIndex = 1, 3 do
        for slotIndex = 1, 4 do
            local playerCard = gameBoard.locations[locationIndex].playerSlots[slotIndex]
            if playerCard == card then
                return true
            end
        end
    end
    
    return false
end

-- Discard a card from the game
function GameLogic:discardCard(card, gameBoard)
    -- Check for Hydra discard effect before removing the card
    CardEffects:handleHydraDiscard(card, gameBoard)
    
    -- Remove from player hand
    for i, playerCard in ipairs(gameBoard.playerHand) do
        if playerCard == card then
            table.remove(gameBoard.playerHand, i)
            break
        end
    end
    
    -- Remove from opponent hand
    for i, opponentCard in ipairs(gameBoard.opponentHand) do
        if opponentCard == card then
            table.remove(gameBoard.opponentHand, i)
            break
        end
    end
    
    -- Remove from main cards array
    for i, gameCard in ipairs(gameBoard.cards) do
        if gameCard == card then
            table.remove(gameBoard.cards, i)
            break
        end
    end
end

-- Trigger card effect when a card is revealed (played)
function GameLogic:triggerCardEffect(card, gameBoard)
    if not card or not card.name then
        return false
    end
    
    -- Use the CardEffects system
    return CardEffects:triggerEffect(card.name, card, gameBoard)
end

-- Function to be called when a card is played/revealed
function GameLogic:onCardPlayed(card, gameBoard)
    card.faceUp = true
    gameBoard:positionHandCards()
end

-- Check if player can afford to play a card
function GameLogic:canPlayCard(card, isPlayer)
    if isPlayer then
        return self.player:canPlayCard(card)
    else
        return self.ai:canPlayCard(card)
    end
end

-- Play a card (spend mana and trigger effects)
function GameLogic:playCard(card, gameBoard, isPlayer)
    if not self:canPlayCard(card, isPlayer) then
        return false
    end
    
    -- Spend mana using Player or AI class
    local success = false
    if isPlayer then
        success = self.player:spendMana(card.manaCost)
    else
        success = self.ai:spendMana(card.manaCost)
    end
    
    if not success then
        return false
    end
    
    -- Trigger card effects
    self:onCardPlayed(card, gameBoard)
    
    return true
end

-- Submit player's turn
function GameLogic:submitTurn()
    if self.gamePhase == "staging" then
        -- Player submits
        self.player:submitTurn()
        
        -- AI automatically submits (plays cards using AI logic)
        self:playAITurn()
        self.ai:submitTurn()
        
        -- Both players submitted, start revealing
        if self.player.submitted and self.ai.submitted then
            self:startRevealPhase()
        end
    end
end

-- AI plays cards using AI logic
function GameLogic:playAITurn()
    if not self.gameBoard or not self.ai then return end
    
    -- Use AI's strategic play method
    self.ai:playTurn(self.gameBoard, self)
end

-- Start the reveal phase
function GameLogic:startRevealPhase()
    self.gamePhase = "revealing"
    
    -- Reveal all cards (flip face up)
    for locationIndex = 1, 3 do
        for slot = 1, 4 do
            local playerCard = self.gameBoard.locations[locationIndex].playerSlots[slot]
            local opponentCard = self.gameBoard.locations[locationIndex].opponentSlots[slot]
            
            if playerCard then
                playerCard.faceUp = true
            end
            if opponentCard then
                opponentCard.faceUp = true
            end
        end
    end
    
    -- Calculate scores for this turn
    self:calculateLocationScores(self.gameBoard)
    
    -- Start next turn after a brief delay
    self:startNextTurn()
end

-- Start the next turn
function GameLogic:startNextTurn()
    -- Reset submission states
    self.player:resetForNewTurn()
    self.ai:resetForNewTurn()
    self.gamePhase = "staging"
    
    -- Increment turn number
    self.turnNumber = self.turnNumber + 1
    
    -- Set mana to turn number (max 10)
    local baseMana = math.min(10, self.turnNumber)
    
    self.player:setManaForTurn(baseMana)
    self.ai:setManaForTurn(baseMana)
    
    -- Draw cards for both players
    self:drawCards()
end

-- Draw cards at start of turn
function GameLogic:drawCards()
    if not self.gameBoard then return end
    
    -- Player draws a card using Player class method
    self.player:drawCard(self.gameBoard)
    
    -- AI draws a card using AI class method
    self.ai:drawCard(self.gameBoard)
    
    -- Reposition cards
    self.gameBoard:positionHandCards()
end

-- Check win conditions
function GameLogic:checkWinCondition(gameBoard)
    -- Check if either player has reached the target score using Player and AI classes
    local playerWon = self.player:hasWon(self.targetScore)
    local aiWon = self.ai:hasWon(self.targetScore)
    
    if playerWon and aiWon then
        -- Both reached target, higher score wins
        if self.player.score > self.ai.score then
            return "player"
        elseif self.ai.score > self.player.score then
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

-- Calculate scores for each location and award points
function GameLogic:calculateLocationScores(gameBoard)
    local totalPlayerPoints = 0
    local totalOpponentPoints = 0
    
    -- Check each of the 3 locations
    for locationIndex = 1, 3 do
        local playerPower = 0
        local opponentPower = 0
        
        -- Calculate total power for each player at this location
        for slot = 1, 4 do
            local playerCard = gameBoard.locations[locationIndex].playerSlots[slot]
            local opponentCard = gameBoard.locations[locationIndex].opponentSlots[slot]
            
            if playerCard and playerCard.faceUp then
                playerPower = playerPower + (playerCard.power or 0)
            end
            
            if opponentCard and opponentCard.faceUp then
                opponentPower = opponentPower + (opponentCard.power or 0)
            end
        end
        
        -- Award points based on power difference
        if playerPower > opponentPower then
            totalPlayerPoints = totalPlayerPoints + (playerPower - opponentPower)
        elseif opponentPower > playerPower then
            totalOpponentPoints = totalOpponentPoints + (opponentPower - playerPower)
        end
        -- If tied, no points awarded
    end
    
    -- Add points to total scores using Player and AI classes
    self.player:addScore(totalPlayerPoints)
    self.ai:addScore(totalOpponentPoints)
    
    return totalPlayerPoints, totalOpponentPoints
end

return GameLogic